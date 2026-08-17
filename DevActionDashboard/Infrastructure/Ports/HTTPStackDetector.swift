import Foundation

/// Fingerprints local HTTP servers and process names to detect common stacks.
struct HTTPStackDetector: Sendable {
    private let redirectGuard = LoopbackRedirectGuard()
    private let session: URLSession

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = 0.6
            configuration.timeoutIntervalForResource = 0.8
            configuration.waitsForConnectivity = false
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            configuration.httpShouldSetCookies = false
            configuration.httpMaximumConnectionsPerHost = 2
            self.session = URLSession(
                configuration: configuration,
                delegate: redirectGuard,
                delegateQueue: nil
            )
        }
    }

    func fingerprint(socket: ListeningSocket) async -> HTTPFingerprint {
        let processHint = processHint(for: socket)
        let http = await probeHTTP(port: socket.port)

        return merge(processHint: processHint, http: http)
    }

    func processHint(for socket: ListeningSocket) -> HTTPFingerprint {
        let name = socket.processName.lowercased()
        let path = (socket.processPath ?? "").lowercased()
        let haystack = name + " " + path

        if haystack.contains("dotnet") || haystack.contains("aspnet") {
            return HTTPFingerprint(stack: .aspNet, confidence: .medium, title: nil, serverHeader: nil, bodySnippet: nil)
        }
        if haystack.contains("java") || haystack.contains("spring") {
            return HTTPFingerprint(stack: .springBoot, confidence: .low, title: nil, serverHeader: nil, bodySnippet: nil)
        }
        if haystack.contains("php") || haystack.contains("artisan") || haystack.contains("laravel") {
            return HTTPFingerprint(stack: .laravel, confidence: .medium, title: nil, serverHeader: nil, bodySnippet: nil)
        }
        if haystack.contains("next") {
            return HTTPFingerprint(stack: .nextJS, confidence: .medium, title: nil, serverHeader: nil, bodySnippet: nil)
        }
        if haystack.contains("node") || haystack.contains("bun") || haystack.contains("deno") {
            return HTTPFingerprint(stack: .nodeJS, confidence: .low, title: nil, serverHeader: nil, bodySnippet: nil)
        }
        return .empty
    }

    func classifyHTTP(headers: [String: String], body: String) -> HTTPFingerprint {
        let loweredHeaders = Dictionary(uniqueKeysWithValues: headers.map { ($0.key.lowercased(), $0.value) })
        let server = loweredHeaders["server"]
        let poweredBy = loweredHeaders["x-powered-by"]
        let combinedHeaders = loweredHeaders.map { "\($0.key): \($0.value)" }.joined(separator: "\n").lowercased()
        let loweredBody = body.lowercased()
        let title = extractTitle(from: body)

        if combinedHeaders.contains("next.js")
            || loweredBody.contains("__next_data__")
            || loweredBody.contains("/_next/")
            || loweredHeaders.keys.contains(where: { $0.hasPrefix("x-nextjs") }) {
            return HTTPFingerprint(stack: .nextJS, confidence: .high, title: title, serverHeader: server ?? poweredBy, bodySnippet: snippet(body))
        }

        if combinedHeaders.contains("asp.net")
            || (server?.lowercased().contains("kestrel") ?? false)
            || loweredHeaders.keys.contains("x-aspnet-version") {
            return HTTPFingerprint(stack: .aspNet, confidence: .high, title: title, serverHeader: server ?? poweredBy, bodySnippet: snippet(body))
        }

        if combinedHeaders.contains("php")
            || loweredBody.contains("laravel")
            || loweredHeaders["set-cookie"]?.lowercased().contains("laravel_session") == true {
            return HTTPFingerprint(stack: .laravel, confidence: .high, title: title, serverHeader: server ?? poweredBy, bodySnippet: snippet(body))
        }

        if combinedHeaders.contains("x-application-context")
            || loweredBody.contains("whitelabel error page")
            || loweredBody.contains("spring boot")
            || loweredHeaders.keys.contains("x-spring-") {
            return HTTPFingerprint(stack: .springBoot, confidence: .high, title: title, serverHeader: server ?? poweredBy, bodySnippet: snippet(body))
        }

        if loweredBody.contains("react")
            || loweredBody.contains("data-reactroot")
            || loweredBody.contains("webpack-dev-server")
            || loweredBody.contains("/static/js/main.") {
            return HTTPFingerprint(stack: .react, confidence: .medium, title: title, serverHeader: server ?? poweredBy, bodySnippet: snippet(body))
        }

        if poweredBy?.lowercased().contains("express") == true || server?.lowercased().contains("node") == true {
            return HTTPFingerprint(stack: .nodeJS, confidence: .medium, title: title, serverHeader: server ?? poweredBy, bodySnippet: snippet(body))
        }

        if title != nil || server != nil || !body.isEmpty {
            return HTTPFingerprint(stack: .unknown, confidence: .low, title: title, serverHeader: server ?? poweredBy, bodySnippet: snippet(body))
        }

        return .empty
    }

    // MARK: - Private

    private func probeHTTP(port: UInt16) async -> HTTPFingerprint {
        guard let url = URL(string: "http://127.0.0.1:\(port)/") else {
            return .empty
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("DevActionDashboard/0.1", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: request)
            let http = response as? HTTPURLResponse
            var headers: [String: String] = [:]
            http?.allHeaderFields.forEach { key, value in
                if let key = key as? String {
                    headers[key] = String(describing: value)
                }
            }
            let body = String(decoding: data.prefix(8_192), as: UTF8.self)
            return classifyHTTP(headers: headers, body: body)
        } catch {
            return .empty
        }
    }

    private func merge(processHint: HTTPFingerprint, http: HTTPFingerprint) -> HTTPFingerprint {
        let ranked = [http, processHint].filter { $0.stack != .unknown || $0.confidence != .none }
        guard let best = ranked.max(by: { lhs, rhs in
            confidenceRank(lhs.confidence) < confidenceRank(rhs.confidence)
        }) else {
            return .empty
        }

        // Prefer HTTP title/server metadata when available.
        return HTTPFingerprint(
            stack: best.stack,
            confidence: best.confidence,
            title: http.title ?? processHint.title,
            serverHeader: http.serverHeader ?? processHint.serverHeader,
            bodySnippet: http.bodySnippet
        )
    }

    private func confidenceRank(_ confidence: DetectionConfidence) -> Int {
        switch confidence {
        case .none: 0
        case .low: 1
        case .medium: 2
        case .high: 3
        }
    }

    private func extractTitle(from html: String) -> String? {
        guard
            let start = html.range(of: "<title>", options: .caseInsensitive),
            let end = html.range(of: "</title>", options: .caseInsensitive, range: start.upperBound..<html.endIndex)
        else {
            return nil
        }
        let title = html[start.upperBound..<end.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? nil : String(title.prefix(120))
    }

    private func snippet(_ body: String) -> String? {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(160))
    }
}

private final class LoopbackRedirectGuard: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest
    ) async -> URLRequest? {
        guard LocalNetworkPolicy.isLoopbackHTTP(request.url) else { return nil }
        return request
    }
}
