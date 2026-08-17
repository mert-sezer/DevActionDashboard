import Foundation

/// Failures while scanning local ports or opening browsers.
public enum PortError: Error, LocalizedError, Sendable, Equatable {
    case enumerationFailed(String)
    case invalidURL(UInt16)
    case browserOpenFailed
    case remoteURLRejected

    public var errorDescription: String? {
        switch self {
        case .enumerationFailed(let detail):
            return "Could not enumerate listening ports: \(detail)"
        case .invalidURL(let port):
            return "Could not build a browser URL for port \(port)."
        case .browserOpenFailed:
            return "The default browser could not be opened."
        case .remoteURLRejected:
            return "Only local http(s) addresses can be opened from Ports."
        }
    }
}
