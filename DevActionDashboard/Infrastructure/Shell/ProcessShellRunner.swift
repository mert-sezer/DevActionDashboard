import Foundation

/// Runs local executables and captures stdout/stderr.
struct ProcessShellRunner: ShellCommandRunning {
    func run(executable: String, arguments: [String], timeoutSeconds: TimeInterval) async throws -> ShellCommandResult {
        try await Task.detached(priority: .utility) {
            guard FileManager.default.isExecutableFile(atPath: executable) else {
                throw ShellError.launchFailed("Not executable at \(executable)")
            }
            guard executable.hasPrefix("/") else {
                throw ShellError.launchFailed("Refusing to launch a relative executable path")
            }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr
            process.standardInput = FileHandle.nullDevice

            do {
                try process.run()
            } catch {
                throw ShellError.launchFailed(error.localizedDescription)
            }

            let deadline = Date().addingTimeInterval(max(timeoutSeconds, 0.1))
            while process.isRunning {
                if Date() > deadline {
                    process.terminate()
                    // Give the process a moment to flush pipes.
                    process.waitUntilExit()
                    throw ShellError.timedOut
                }
                Thread.sleep(forTimeInterval: 0.05)
            }

            process.waitUntilExit()
            let output = stdout.fileHandleForReading.readDataToEndOfFile()
            let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
            return ShellCommandResult(
                exitCode: process.terminationStatus,
                standardOutput: output,
                standardError: errorData
            )
        }.value
    }
}
