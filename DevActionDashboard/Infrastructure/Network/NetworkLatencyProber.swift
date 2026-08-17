import Foundation
import Network

/// Measures real network latency without privileged ICMP.
struct NetworkLatencyProber: Sendable {
    private let session: URLSession
    private let httpsProbeURL: URL
    private let tcpHost: NWEndpoint.Host
    private let tcpPort: NWEndpoint.Port

    init(
        session: URLSession = .shared,
        httpsProbeURL: URL = URL(string: "https://captive.apple.com/hotspot-detect.html")!,
        tcpHost: NWEndpoint.Host = "1.1.1.1",
        tcpPort: NWEndpoint.Port = 443
    ) {
        self.session = session
        self.httpsProbeURL = httpsProbeURL
        self.tcpHost = tcpHost
        self.tcpPort = tcpPort
    }

    func probeHTTPS() async -> NetworkLatencySample {
        var request = URLRequest(url: httpsProbeURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 5)
        request.httpMethod = "GET"

        let started = ContinuousClock.now
        do {
            let (_, response) = try await session.data(for: request)
            let milliseconds = durationMilliseconds(ContinuousClock.now - started)
            let status = (response as? HTTPURLResponse)?.statusCode
            return NetworkLatencySample(
                destination: httpsProbeURL.host ?? httpsProbeURL.absoluteString,
                milliseconds: milliseconds,
                didSucceed: true,
                detail: status.map { "HTTP \($0)" }
            )
        } catch {
            return NetworkLatencySample(
                destination: httpsProbeURL.host ?? httpsProbeURL.absoluteString,
                milliseconds: durationMilliseconds(ContinuousClock.now - started),
                didSucceed: false,
                detail: error.localizedDescription
            )
        }
    }

    func probeTCP() async -> NetworkLatencySample {
        await withCheckedContinuation { continuation in
            let connection = NWConnection(host: tcpHost, port: tcpPort, using: .tcp)
            let started = ContinuousClock.now
            let destination = "\(tcpHost):\(tcpPort)"
            let lock = NSLock()
            var didResume = false

            func resumeOnce(_ sample: NetworkLatencySample) {
                lock.lock()
                defer { lock.unlock() }
                guard !didResume else { return }
                didResume = true
                connection.cancel()
                continuation.resume(returning: sample)
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    resumeOnce(
                        NetworkLatencySample(
                            destination: destination,
                            milliseconds: self.durationMilliseconds(ContinuousClock.now - started),
                            didSucceed: true,
                            detail: "TCP connect"
                        )
                    )
                case .failed(let error):
                    resumeOnce(
                        NetworkLatencySample(
                            destination: destination,
                            milliseconds: self.durationMilliseconds(ContinuousClock.now - started),
                            didSucceed: false,
                            detail: error.localizedDescription
                        )
                    )
                default:
                    break
                }
            }

            connection.start(queue: DispatchQueue.global(qos: .utility))

            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 5) {
                resumeOnce(
                    NetworkLatencySample(
                        destination: destination,
                        milliseconds: self.durationMilliseconds(ContinuousClock.now - started),
                        didSucceed: false,
                        detail: "Timed out"
                    )
                )
            }
        }
    }

    private func durationMilliseconds(_ duration: Duration) -> Double {
        let seconds = Double(duration.components.seconds)
        let nanos = Double(duration.components.attoseconds) / 1_000_000_000_000_000_000
        return (seconds + nanos) * 1_000
    }
}
