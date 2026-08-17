import Foundation

/// Typed application errors suitable for logging and user presentation.
public enum AppError: Error, LocalizedError, Sendable, Equatable {
    case featureUnavailable(FeatureID)
    case persistenceFailure(String)
    case invalidConfiguration(String)

    public var errorDescription: String? {
        switch self {
        case .featureUnavailable(let featureID):
            return "Feature unavailable: \(featureID.rawValue)"
        case .persistenceFailure(let reason):
            return "Could not save preferences: \(reason)"
        case .invalidConfiguration(let reason):
            return "Invalid configuration: \(reason)"
        }
    }
}
