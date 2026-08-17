import Foundation
import Observation

/// Shared live system metrics. Multiple views can subscribe without extra sampling.
@MainActor
@Observable
final class SystemMetricsService {
    private(set) var latest: SystemMetricsSnapshot?
    private(set) var lastErrorMessage: String?
    private(set) var isRefreshing = false

    private let provider: any SystemMetricsProviding
    private let settingsStore: SettingsStore
    private var pollingTask: Task<Void, Never>?
    private var consumerCount = 0

    init(provider: any SystemMetricsProviding, settingsStore: SettingsStore) {
        self.provider = provider
        self.settingsStore = settingsStore
    }

    /// Begins shared polling. Balanced with `stopMonitoring()`.
    func startMonitoring() {
        consumerCount += 1
        guard consumerCount == 1 else { return }

        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            await self?.runPollingLoop()
        }
        AppLog.system.info("System metrics monitoring started")
    }

    func stopMonitoring() {
        consumerCount = max(consumerCount - 1, 0)
        guard consumerCount == 0 else { return }

        pollingTask?.cancel()
        pollingTask = nil
        AppLog.system.info("System metrics monitoring stopped")
    }

    func refreshNow() async {
        await collect()
    }

    private func runPollingLoop() async {
        await collect()

        // CPU delta becomes meaningful after a short baseline gap.
        if latest?.cpu.usageRatio == nil {
            try? await Task.sleep(for: .milliseconds(400))
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
            AppLog.system.error("Metrics sample failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
