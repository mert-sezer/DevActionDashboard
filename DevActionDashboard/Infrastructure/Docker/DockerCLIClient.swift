import Foundation

/// Docker Engine access through the official Docker CLI (`docker`).
struct DockerCLIClient: DockerProviding {
    private let shell: any ShellCommandRunning

    init(shell: any ShellCommandRunning = ProcessShellRunner()) {
        self.shell = shell
    }

    func snapshot(dockerPath: String) async throws -> DockerSnapshot {
        guard let executable = DockerOutputParser.resolveDockerExecutable(preferredPath: dockerPath) else {
            return DockerSnapshot(
                isAvailable: false,
                dockerPath: dockerPath,
                engineVersion: nil,
                containers: [],
                availabilityMessage: DockerError.executableNotFound(dockerPath).localizedDescription
            )
        }

        do {
            let version = try await runDocker(executable, arguments: ["version", "--format", "{{.Server.Version}}"], timeout: 8)
            let ps = try await runDocker(
                executable,
                arguments: ["ps", "-a", "--format", "{{json .}}"],
                timeout: 12
            )
            let containers = try DockerOutputParser.containers(fromPSOutput: ps)

            var statsByID: [String: DockerContainerStats] = [:]
            if containers.contains(where: { $0.state == .running }) {
                let statsOutput = try await runDocker(
                    executable,
                    arguments: ["stats", "--no-stream", "--format", "{{json .}}"],
                    timeout: 15
                )
                let stats = try DockerOutputParser.stats(fromStatsOutput: statsOutput)
                for item in stats {
                    statsByID[item.containerID] = item
                    // docker stats Container field may be truncated ID; also index by prefix.
                    if item.containerID.count >= 12 {
                        statsByID[String(item.containerID.prefix(12))] = item
                    }
                }
            }

            let merged = containers.map { container in
                let stats = statsByID[container.containerID]
                    ?? statsByID[String(container.containerID.prefix(12))]
                    ?? statsByID.first(where: { container.containerID.hasPrefix($0.key) || $0.key.hasPrefix(String(container.containerID.prefix(12))) })?.value
                return container.merging(stats: stats)
            }

            return DockerSnapshot(
                isAvailable: true,
                dockerPath: executable,
                engineVersion: version.trimmingCharacters(in: .whitespacesAndNewlines),
                containers: merged
            )
        } catch let error as DockerError {
            if let detail = error.technicalDetail {
                AppLog.docker.info("Docker unavailable (\(error.localizedDescription, privacy: .public)): \(detail, privacy: .public)")
            }
            return DockerSnapshot(
                isAvailable: false,
                dockerPath: executable,
                engineVersion: nil,
                containers: [],
                availabilityMessage: error.localizedDescription
            )
        } catch {
            let mapped = DockerError.fromCLIFailure(error.localizedDescription)
            return DockerSnapshot(
                isAvailable: false,
                dockerPath: executable,
                engineVersion: nil,
                containers: [],
                availabilityMessage: mapped.localizedDescription
            )
        }
    }

    func control(dockerPath: String, containerID: String, action: DockerControlAction) async throws {
        try Self.validateContainerID(containerID)
        let executable = try requireExecutable(dockerPath)
        _ = try await runDocker(executable, arguments: [action.rawValue, containerID], timeout: 30)
    }

    func logs(dockerPath: String, containerID: String, tail: Int) async throws -> String {
        try Self.validateContainerID(containerID)
        let executable = try requireExecutable(dockerPath)
        return try await runDocker(
            executable,
            arguments: ["logs", "--tail", "\(max(tail, 1))", containerID],
            timeout: 20
        )
    }

    // MARK: - Private

    private func requireExecutable(_ dockerPath: String) throws -> String {
        guard let executable = DockerOutputParser.resolveDockerExecutable(preferredPath: dockerPath) else {
            if DockerOutputParser.isDockerBinary(at: dockerPath) {
                throw DockerError.executableNotFound(dockerPath)
            }
            throw DockerError.invalidExecutable(dockerPath)
        }
        return executable
    }

    private static func validateContainerID(_ containerID: String) throws {
        guard DockerOutputParser.isContainerID(containerID) else {
            throw DockerError.invalidContainerID
        }
    }

    private func runDocker(_ executable: String, arguments: [String], timeout: TimeInterval) async throws -> String {
        let result: ShellCommandResult
        do {
            result = try await shell.run(executable: executable, arguments: arguments, timeoutSeconds: timeout)
        } catch ShellError.timedOut {
            throw DockerError.timedOut
        } catch {
            throw DockerError.commandFailed(error.localizedDescription)
        }

        if result.exitCode != 0 {
            let detail = result.stderrString.trimmingCharacters(in: .whitespacesAndNewlines)
            let message = detail.isEmpty ? "exit \(result.exitCode)" : detail
            throw DockerError.fromCLIFailure(message)
        }

        return result.stdoutString
    }
}
