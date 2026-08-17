import Foundation

/// Scans listening TCP ports and fingerprints local development servers.
actor CompositePortScanProvider: PortScanning {
    private let enumerator = ListeningPortEnumerator()
    private let detector = HTTPStackDetector()

    /// Cache fingerprints by pid+port while the listener remains.
    private var fingerprintCache: [String: HTTPFingerprint] = [:]

    func scan() async throws -> PortScanSnapshot {
        let sockets = try enumerator.enumerate()
        // Prefer localhost-facing and wildcard binds; keep others for completeness.
        let prioritized = sockets.sorted { lhs, rhs in
            localityScore(lhs.address) > localityScore(rhs.address)
        }

        var nextCache: [String: HTTPFingerprint] = [:]
        var entries: [LocalPortEntry] = []
        entries.reserveCapacity(prioritized.count)

        for socket in prioritized {
            let key = cacheKey(socket)
            let fingerprint: HTTPFingerprint
            if let cached = fingerprintCache[key] {
                fingerprint = cached
            } else {
                fingerprint = await detector.fingerprint(socket: socket)
            }
            nextCache[key] = fingerprint

            entries.append(
                LocalPortEntry(
                    port: socket.port,
                    address: socket.address,
                    pid: socket.pid,
                    processName: socket.processName,
                    processPath: socket.processPath,
                    detectedStack: fingerprint.stack,
                    httpTitle: fingerprint.title,
                    serverHeader: fingerprint.serverHeader,
                    detectionConfidence: fingerprint.confidence
                )
            )
        }

        fingerprintCache = nextCache
        return PortScanSnapshot(entries: entries)
    }

    private func cacheKey(_ socket: ListeningSocket) -> String {
        "\(socket.pid):\(socket.port):\(socket.address)"
    }

    private func localityScore(_ address: String) -> Int {
        switch address {
        case "127.0.0.1", "::1": 3
        case "0.0.0.0", "::", "*": 2
        default: 1
        }
    }
}
