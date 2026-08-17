import Foundation

/// Talks to the local Docker Engine through the Docker CLI.
public protocol DockerProviding: Sendable {
    func snapshot(dockerPath: String) async throws -> DockerSnapshot
    func control(dockerPath: String, containerID: String, action: DockerControlAction) async throws
    func logs(dockerPath: String, containerID: String, tail: Int) async throws -> String
}

/// Executes local subprocesses for infrastructure adapters.
public protocol ShellCommandRunning: Sendable {
    func run(executable: String, arguments: [String], timeoutSeconds: TimeInterval) async throws -> ShellCommandResult
}

public struct ShellCommandResult: Sendable, Equatable {
    public let exitCode: Int32
    public let standardOutput: Data
    public let standardError: Data

    public init(exitCode: Int32, standardOutput: Data, standardError: Data) {
        self.exitCode = exitCode
        self.standardOutput = standardOutput
        self.standardError = standardError
    }

    public var stdoutString: String {
        String(decoding: standardOutput, as: UTF8.self)
    }

    public var stderrString: String {
        String(decoding: standardError, as: UTF8.self)
    }
}
