import Foundation
import Observation

/// Application facade for Docker container listing, control, stats, and logs.
@MainActor
@Observable
final class DockerService {
    private(set) var latest: DockerSnapshot?
    private(set) var lastErrorMessage: String?
    private(set) var actionMessage: String?
    private(set) var isRefreshing = false
    private(set) var logText: String = ""
    private(set) var logContainerName: String?

    private let provider: any DockerProviding
    private let settingsStore: SettingsStore
    private var pollingTask: Task<Void, Never>?
    private var consumerCount = 0

    init(provider: any DockerProviding, settingsStore: SettingsStore) {
        self.provider = provider
        self.settingsStore = settingsStore
    }

    func startMonitoring() {
        consumerCount += 1
        guard consumerCount == 1 else { return }

        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            await self?.runPollingLoop()
        }
        AppLog.docker.info("Docker monitoring started")
    }

    func stopMonitoring() {
        consumerCount = max(consumerCount - 1, 0)
        guard consumerCount == 0 else { return }

        pollingTask?.cancel()
        pollingTask = nil
        AppLog.docker.info("Docker monitoring stopped")
    }

    func refreshNow() async {
        await collect()
    }

    func control(_ container: DockerContainer, action: DockerControlAction) async {
        do {
            try await provider.control(
                dockerPath: settingsStore.dockerCLIPath,
                containerID: container.containerID,
                action: action
            )
            actionMessage = "\(action.title) sent to \(container.name)."
            lastErrorMessage = nil
            await collect()
        } catch {
            lastErrorMessage = error.localizedDescription
            actionMessage = nil
            AppLog.docker.error("Docker \(action.rawValue, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func loadLogs(for container: DockerContainer, tail: Int = 200) async {
        do {
            let text = try await provider.logs(
                dockerPath: settingsStore.dockerCLIPath,
                containerID: container.containerID,
                tail: tail
            )
            logText = text.isEmpty ? "(no log output)" : text
            logContainerName = container.name
            lastErrorMessage = nil
        } catch {
            logText = ""
            logContainerName = container.name
            lastErrorMessage = error.localizedDescription
        }
    }

    func clearLogs() {
        logText = ""
        logContainerName = nil
    }

    private func runPollingLoop() async {
        await collect()

        while !Task.isCancelled {
            let seconds = max(settingsStore.refreshInterval.rawValue, 5)
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            await collect()
        }
    }

    private func collect() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            latest = try await provider.snapshot(dockerPath: settingsStore.dockerCLIPath)
            // Expected unavailability (CLI missing / daemon stopped) is shown in the empty state,
            // not as a repeating error banner.
            lastErrorMessage = nil
            if latest?.isAvailable == false, let message = latest?.availabilityMessage {
                AppLog.docker.info("Docker unavailable: \(message, privacy: .public)")
            }
        } catch {
            lastErrorMessage = error.localizedDescription
            AppLog.docker.error("Docker snapshot failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
