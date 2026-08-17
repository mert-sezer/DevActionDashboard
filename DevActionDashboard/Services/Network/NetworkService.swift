import Foundation
import Observation

/// Shared network observability facade with settings-driven polling.
@MainActor
@Observable
final class NetworkService {
    private(set) var latest: NetworkSnapshot?
    private(set) var lastErrorMessage: String?
    private(set) var isRefreshing = false

    private let provider: any NetworkProviding
    private let settingsStore: SettingsStore
    private var pollingTask: Task<Void, Never>?
    private var consumerCount = 0

    init(provider: any NetworkProviding, settingsStore: SettingsStore) {
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
        AppLog.network.info("Network monitoring started")
    }

    func stopMonitoring() {
        consumerCount = max(consumerCount - 1, 0)
        guard consumerCount == 0 else { return }

        pollingTask?.cancel()
        pollingTask = nil
        AppLog.network.info("Network monitoring stopped")
    }

    func refreshNow() async {
        await collect()
    }

    private func runPollingLoop() async {
        await collect()

        if latest?.throughput.downloadBytesPerSecond == nil {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await collect()
        }

        while !Task.isCancelled {
            let seconds = settingsStore.refreshInterval.rawValue
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            await collect()
        }
    }

    private func collect() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            latest = try await provider.sample()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            AppLog.network.error("Network sample failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
