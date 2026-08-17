import Foundation

/// Accepts only loopback http(s) URLs for local developer tooling.
enum LocalNetworkPolicy {
    static func isLoopbackHTTP(_ url: URL?) -> Bool {
        guard let url else { return false }
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return false
        }
        guard let host = url.host?.lowercased() else { return false }
        switch host {
        case "127.0.0.1", "localhost", "::1", "[::1]":
            return true
        default:
            return false
        }
    }
}
