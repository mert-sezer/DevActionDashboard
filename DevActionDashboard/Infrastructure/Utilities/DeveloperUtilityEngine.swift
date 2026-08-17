import CryptoKit
import Foundation

/// Pure utility transforms used by the Utilities feature.
enum DeveloperUtilityEngine {
    // MARK: UUID

    static func generateUUID(uppercase: Bool) -> String {
        let value = UUID().uuidString
        return uppercase ? value.uppercased() : value.lowercased()
    }

    // MARK: Base64

    static func base64Encode(_ input: String) -> String {
        Data(input.utf8).base64EncodedString()
    }

    static func base64Decode(_ input: String) -> Result<String, UtilityTransformError> {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = Data(base64Encoded: cleaned) else {
            return .failure(.invalidBase64)
        }
        guard let string = String(data: data, encoding: .utf8) else {
            return .failure(.invalidUTF8)
        }
        return .success(string)
    }

    // MARK: JSON

    static func formatJSON(_ input: String) -> Result<String, UtilityTransformError> {
        guard let data = input.data(using: .utf8) else {
            return .failure(.invalidUTF8)
        }
        do {
            let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            let pretty = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
            guard let string = String(data: pretty, encoding: .utf8) else {
                return .failure(.invalidUTF8)
            }
            return .success(string)
        } catch {
            return .failure(.invalidJSON(error.localizedDescription))
        }
    }

    static func compareJSON(left: String, right: String) -> Result<JSONCompareResult, UtilityTransformError> {
        switch (canonicalJSON(left), canonicalJSON(right)) {
        case (.success(let l), .success(let r)):
            return .success(JSONCompareResult(leftCanonical: l, rightCanonical: r, areEqual: l == r))
        case (.failure(let error), _):
            return .failure(error)
        case (_, .failure(let error)):
            return .failure(error)
        }
    }

    private static func canonicalJSON(_ input: String) -> Result<String, UtilityTransformError> {
        guard let data = input.data(using: .utf8) else { return .failure(.invalidUTF8) }
        do {
            let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            let canonical = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
            guard let string = String(data: canonical, encoding: .utf8) else {
                return .failure(.invalidUTF8)
            }
            return .success(string)
        } catch {
            return .failure(.invalidJSON(error.localizedDescription))
        }
    }

    // MARK: Hash

    static func hash(_ input: String, algorithm: HashAlgorithm) -> String {
        let data = Data(input.utf8)
        switch algorithm {
        case .sha256:
            return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        case .sha1:
            return Insecure.SHA1.hash(data: data).map { String(format: "%02x", $0) }.joined()
        case .md5:
            return Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
        }
    }

    // MARK: JWT

    static func decodeJWT(_ token: String) -> Result<JWTDecodeResult, UtilityTransformError> {
        let parts = token.split(separator: ".").map(String.init)
        guard parts.count >= 2 else { return .failure(.invalidJWT) }

        func decodePart(_ part: String) -> Result<String, UtilityTransformError> {
            var base64 = part
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            let remainder = base64.count % 4
            if remainder > 0 {
                base64.append(String(repeating: "=", count: 4 - remainder))
            }
            guard let data = Data(base64Encoded: base64) else {
                return .failure(.invalidJWT)
            }
            guard let raw = String(data: data, encoding: .utf8) else {
                return .failure(.invalidUTF8)
            }
            if case .success(let pretty) = formatJSON(raw) {
                return .success(pretty)
            }
            return .success(raw)
        }

        let header = decodePart(parts[0])
        let payload = decodePart(parts[1])
        switch (header, payload) {
        case (.success(let h), .success(let p)):
            return .success(JWTDecodeResult(headerJSON: h, payloadJSON: p, signaturePresent: parts.count >= 3))
        case (.failure(let error), _):
            return .failure(error)
        case (_, .failure(let error)):
            return .failure(error)
        }
    }

    // MARK: Regex

    static func testRegex(pattern: String, text: String) -> Result<RegexTestResult, UtilityTransformError> {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            let matches = regex.matches(in: text, range: range).compactMap { match -> RegexMatch? in
                guard let full = Range(match.range, in: text) else { return nil }
                var groups: [String] = []
                for index in 0..<match.numberOfRanges {
                    guard let groupRange = Range(match.range(at: index), in: text) else { continue }
                    groups.append(String(text[groupRange]))
                }
                return RegexMatch(value: String(text[full]), groups: groups)
            }
            return .success(RegexTestResult(isValidPattern: true, matches: matches))
        } catch {
            return .failure(.invalidRegex(error.localizedDescription))
        }
    }

    // MARK: Cron

    static func describeCron(_ expression: String) -> Result<String, UtilityTransformError> {
        CronExpressionParser.describe(expression)
    }

    // MARK: Timestamp

    static func convertTimestamp(_ input: String) -> Result<TimestampConversion, UtilityTransformError> {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            let now = Date()
            return .success(TimestampConversion(date: now, unixSeconds: now.timeIntervalSince1970, unixMilliseconds: now.timeIntervalSince1970 * 1000))
        }

        if let value = Double(trimmed) {
            let seconds = value > 1_000_000_000_000 ? value / 1000.0 : value
            let date = Date(timeIntervalSince1970: seconds)
            return .success(TimestampConversion(date: date, unixSeconds: seconds, unixMilliseconds: seconds * 1000))
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: trimmed) ?? ISO8601DateFormatter().date(from: trimmed) {
            return .success(TimestampConversion(date: date, unixSeconds: date.timeIntervalSince1970, unixMilliseconds: date.timeIntervalSince1970 * 1000))
        }

        return .failure(.invalidTimestamp)
    }
}

public enum HashAlgorithm: String, CaseIterable, Identifiable, Sendable {
    case sha256
    case sha1
    case md5

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .sha256: "SHA-256"
        case .sha1: "SHA-1"
        case .md5: "MD5"
        }
    }
}

public enum UtilityTransformError: Error, LocalizedError, Sendable, Equatable {
    case invalidBase64
    case invalidUTF8
    case invalidJSON(String)
    case invalidJWT
    case invalidRegex(String)
    case invalidCron(String)
    case invalidTimestamp

    public var errorDescription: String? {
        switch self {
        case .invalidBase64: "Invalid Base64 input."
        case .invalidUTF8: "Input is not valid UTF-8."
        case .invalidJSON(let detail): "Invalid JSON: \(detail)"
        case .invalidJWT: "Invalid JWT format."
        case .invalidRegex(let detail): "Invalid regex: \(detail)"
        case .invalidCron(let detail): "Invalid cron expression: \(detail)"
        case .invalidTimestamp: "Unrecognized timestamp."
        }
    }
}

public struct JWTDecodeResult: Sendable, Equatable {
    public let headerJSON: String
    public let payloadJSON: String
    public let signaturePresent: Bool
}

public struct JSONCompareResult: Sendable, Equatable {
    public let leftCanonical: String
    public let rightCanonical: String
    public let areEqual: Bool
}

public struct RegexMatch: Sendable, Equatable, Identifiable {
    public var id: String { value + groups.joined() }
    public let value: String
    public let groups: [String]
}

public struct RegexTestResult: Sendable, Equatable {
    public let isValidPattern: Bool
    public let matches: [RegexMatch]
}

public struct TimestampConversion: Sendable, Equatable {
    public let date: Date
    public let unixSeconds: TimeInterval
    public let unixMilliseconds: TimeInterval
}
