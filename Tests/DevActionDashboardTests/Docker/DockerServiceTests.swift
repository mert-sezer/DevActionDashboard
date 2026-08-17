import Foundation
import Testing
@testable import DevActionDashboard

@Suite("DockerError classification")
struct DockerErrorClassificationTests {
    @Test("Detects modern Docker Desktop socket failures as daemon unavailable")
    func detectsSocketFailure() {
        let message = """
        failed to connect to the docker API at unix:///Users/developer/.docker/run/docker.sock; \
        check if the path is correct and if the daemon is running: \
        dial unix /Users/developer/.docker/run/docker.sock: connect: no such file or directory
        """
        let error = DockerError.fromCLIFailure(message)
        #expect(error == .daemonUnavailable(message))
        #expect(error.localizedDescription.contains("Engine isn’t running"))
        #expect(!error.localizedDescription.contains("docker.sock"))
    }

    @Test("Leaves unrelated CLI failures as commandFailed")
    func leavesOtherFailures() {
        let error = DockerError.fromCLIFailure("permission denied while trying to connect")
        guard case .commandFailed = error else {
            Issue.record("Expected commandFailed")
            return
        }
    }
}

@Suite("DockerOutputParser")
struct DockerOutputParserTests {
    @Test("Parses docker ps JSON lines")
    func parsesPS() throws {
        let output = """
        {"ID":"abc123def456","Names":"api","Image":"node:20","Status":"Up 2 minutes","State":"running","Ports":"0.0.0.0:3000->3000/tcp","CreatedAt":"2026-08-06 01:00:00 +0300 EEST"}
        {"ID":"fff111aaa222","Names":"db","Image":"postgres:16","Status":"Exited (0) 1 hour ago","State":"exited","Ports":"","CreatedAt":"2026-08-06 00:00:00 +0300 EEST"}
        """
        let containers = try DockerOutputParser.containers(fromPSOutput: output)
        #expect(containers.count == 2)
        #expect(containers[0].name == "api")
        #expect(containers[0].state == .running)
        #expect(containers[1].state == .exited)
    }

    @Test("Parses docker stats percentages and memory")
    func parsesStats() throws {
        let output = """
        {"Container":"abc123def456","Name":"api","CPUPerc":"12.50%","MemUsage":"10.5MiB / 2GiB","MemPerc":"0.51%"}
        """
        let stats = try DockerOutputParser.stats(fromStatsOutput: output)
        #expect(stats.count == 1)
        #expect(stats[0].cpuUsageRatio == 0.125)
        #expect(stats[0].memoryUsageRatio == 0.0051)
        #expect(stats[0].memoryUsageBytes != nil)
        #expect(stats[0].memoryLimitBytes != nil)
    }

    @Test("Parses byte quantities")
    func byteQuantities() {
        #expect(DockerOutputParser.parseByteQuantity("10.5MiB") == UInt64(10.5 * 1_024 * 1_024))
        #expect(DockerOutputParser.parseByteQuantity("2GiB") == UInt64(2 * 1_024 * 1_024 * 1_024))
        #expect(DockerOutputParser.parsePercentage("42.0%") == 0.42)
    }
}

@Suite("DockerService control")
@MainActor
struct DockerServiceTests {
    @Test("Sends control actions through provider")
    func controlActions() async {
        let provider = StubDockerProvider()
        let defaults = UserDefaults(suiteName: "DockerServiceTests.\(UUID().uuidString)")!
        let settings = SettingsStore(defaults: defaults)
        settings.dockerCLIPath = "/opt/homebrew/bin/docker"

        let service = DockerService(provider: provider, settingsStore: settings)
        let container = DockerContainer(
            containerID: "abc",
            name: "api",
            image: "node",
            status: "Up",
            state: .exited,
            ports: "",
            createdAt: ""
        )

        await service.control(container, action: .start)

        #expect(provider.actions == [.start])
        #expect(provider.controlledIDs == ["abc"])
        #expect(service.actionMessage != nil)
    }

    @Test("Loads logs through provider")
    func loadsLogs() async {
        let provider = StubDockerProvider(logText: "hello from container")
        let defaults = UserDefaults(suiteName: "DockerServiceLogs.\(UUID().uuidString)")!
        let service = DockerService(provider: provider, settingsStore: SettingsStore(defaults: defaults))
        let container = DockerContainer(
            containerID: "abc",
            name: "api",
            image: "node",
            status: "Up",
            state: .running,
            ports: "",
            createdAt: ""
        )

        await service.loadLogs(for: container)

        #expect(service.logText == "hello from container")
        #expect(service.logContainerName == "api")
    }
}

@Suite("SettingsStore docker path")
@MainActor
struct SettingsDockerPathTests {
    @Test("Persists docker CLI path")
    func persistsDockerPath() {
        let suite = "SettingsDockerPathTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = SettingsStore(defaults: defaults)
        store.dockerCLIPath = "/usr/local/bin/docker"

        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.dockerCLIPath == "/usr/local/bin/docker")
    }
}

private final class StubDockerProvider: DockerProviding, @unchecked Sendable {
    private(set) var actions: [DockerControlAction] = []
    private(set) var controlledIDs: [String] = []
    private let logText: String

    init(logText: String = "") {
        self.logText = logText
    }

    func snapshot(dockerPath: String) async throws -> DockerSnapshot {
        DockerSnapshot(
            isAvailable: true,
            dockerPath: dockerPath,
            engineVersion: "27.0.0",
            containers: []
        )
    }

    func control(dockerPath: String, containerID: String, action: DockerControlAction) async throws {
        _ = dockerPath
        actions.append(action)
        controlledIDs.append(containerID)
    }

    func logs(dockerPath: String, containerID: String, tail: Int) async throws -> String {
        _ = (dockerPath, containerID, tail)
        return logText
    }
}
