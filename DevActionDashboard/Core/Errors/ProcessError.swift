import Foundation

/// Failures while listing or controlling processes.
public enum ProcessError: Error, LocalizedError, Sendable, Equatable {
    case enumerationFailed(String)
    case processNotFound(Int32)
    case terminationDenied(Int32)
    case terminationFailed(Int32, String)
    case protectedProcess(Int32)
    case activityMonitorUnavailable

    public var errorDescription: String? {
        switch self {
        case .enumerationFailed(let detail):
            return "Could not list processes: \(detail)"
        case .processNotFound(let pid):
            return "Process \(pid) is no longer running."
        case .terminationDenied(let pid):
            return "Permission denied when terminating process \(pid)."
        case .terminationFailed(let pid, let detail):
            return "Failed to terminate process \(pid): \(detail)"
        case .protectedProcess(let pid):
            return "Process \(pid) is protected and cannot be terminated from DAD."
        case .activityMonitorUnavailable:
            return "Activity Monitor could not be opened."
        }
    }
}
