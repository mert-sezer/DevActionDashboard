import Foundation

/// Failures while sampling network state.
public enum NetworkError: Error, LocalizedError, Sendable, Equatable {
    case pathMonitorUnavailable
    case interfaceEnumerationFailed
    case publicIPUnavailable
    case probeFailed(String)

    public var errorDescription: String? {
        switch self {
        case .pathMonitorUnavailable:
            return "Network path monitoring is unavailable."
        case .interfaceEnumerationFailed:
            return "Could not enumerate network interfaces."
        case .publicIPUnavailable:
            return "Public IP could not be determined."
        case .probeFailed(let detail):
            return "Network probe failed: \(detail)"
        }
    }
}
