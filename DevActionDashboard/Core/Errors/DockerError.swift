import Foundation

/// Failures while talking to Docker.
public enum DockerError: Error, LocalizedError, Sendable, Equatable {
    case executableNotFound(String)
    case invalidExecutable(String)
    case invalidContainerID
    case commandFailed(String)
    case daemonUnavailable(String)
    case decodingFailed(String)
    case timedOut

    public var errorDescription: String? {
        switch self {
        case .executableNotFound:
            return "Docker CLI not found. Install Docker Desktop or set the CLI path in Settings."
        case .invalidExecutable:
            return "The Docker CLI path must point to a binary named docker."
        case .invalidContainerID:
            return "Refusing to run Docker against an invalid container ID."
        case .commandFailed(let detail):
            return "Docker command failed: \(detail)"
        case .daemonUnavailable:
            return "Docker Engine isn’t running. Start Docker Desktop, then refresh."
        case .decodingFailed(let detail):
            return "Could not parse Docker output: \(detail)"
        case .timedOut:
            return "Docker command timed out."
        }
    }

    /// Technical detail for logs / optional disclosure (not primary UI copy).
    public var technicalDetail: String? {
        switch self {
        case .executableNotFound(let path), .invalidExecutable(let path):
            return path
        case .commandFailed(let detail), .daemonUnavailable(let detail), .decodingFailed(let detail):
            return detail
        case .invalidContainerID, .timedOut:
            return nil
        }
    }

    /// Maps CLI stderr / exit text into a typed Docker error.
    public static func fromCLIFailure(_ message: String) -> DockerError {
        if isDaemonConnectionFailure(message) {
            return .daemonUnavailable(message)
        }
        return .commandFailed(message)
    }

    public static func isDaemonConnectionFailure(_ message: String) -> Bool {
        let lowered = message.lowercased()
        let needles = [
            "cannot connect to the docker daemon",
            "is the docker daemon running",
            "failed to connect to the docker api",
            "check if the path is correct and if the daemon is running",
            "docker.sock",
            "connect: no such file or directory",
            "connection refused",
            "error during connect",
            "docker desktop is unable to start"
        ]
        return needles.contains { lowered.contains($0) }
    }
}

public enum ShellError: Error, LocalizedError, Sendable, Equatable {
    case launchFailed(String)
    case timedOut

    public var errorDescription: String? {
        switch self {
        case .launchFailed(let detail):
            return "Could not launch process: \(detail)"
        case .timedOut:
            return "Process timed out."
        }
    }
}
