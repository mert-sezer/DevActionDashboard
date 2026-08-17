import Foundation

/// Executes supported macOS system actions.
public protocol SystemActionRunning: Sendable {
    func perform(_ action: SystemActionKind) async throws -> SystemActionResult
}

public enum SystemActionError: Error, LocalizedError, Sendable, Equatable {
    case commandFailed(String)
    case pathUnavailable(String)
    case appleScriptFailed(String)

    public var errorDescription: String? {
        switch self {
        case .commandFailed(let detail):
            return detail
        case .pathUnavailable(let path):
            return "Path unavailable: \(path)"
        case .appleScriptFailed(let detail):
            return "AppleScript failed: \(detail)"
        }
    }
}
