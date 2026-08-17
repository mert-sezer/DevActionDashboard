import Foundation
import Observation

/// Application facade for process listing, termination, and Activity Monitor.
@MainActor
@Observable
final class ProcessService {
    private(set) var latest: ProcessListSnapshot?
    private(set) var lastErrorMessage: String?
    private(set) var isRefreshing = false
    private(set) var actionMessage: String?

    private let provider: any ProcessProviding
    private let activityMonitor: any ActivityMonitorLaunching
    private let settingsStore: SettingsStore
    private var pollingTask: Task<Void, Never>?
    private var consumerCount = 0

    init(
        provider: any ProcessProviding,
        activityMonitor: any ActivityMonitorLaunching,
        settingsStore: SettingsStore
    ) {
        self.provider = provider
        self.activityMonitor = activityMonitor
        self.settingsStore = settingsStore
    }

    func startMonitoring() {
        consumerCount += 1
        guard consumerCount == 1 else { return }

        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            await self?.runPollingLoop()
        }
        AppLog.processes.info("Process monitoring started")
    }

    func stopMonitoring() {
        consumerCount = max(consumerCount - 1, 0)
        guard consumerCount == 0 else { return }

        pollingTask?.cancel()
        pollingTask = nil
        AppLog.processes.info("Process monitoring stopped")
    }

    func refreshNow() async {
        await collect()
    }

    func terminate(pid: Int32, force: Bool) async {
        do {
            try await provider.terminateProcess(pid: pid, force: force)
            actionMessage = force ? "Force quit sent to PID \(pid)." : "Quit signal sent to PID \(pid)."
            await collect()
        } catch {
            lastErrorMessage = error.localizedDescription
            actionMessage = nil
            AppLog.processes.error("Terminate failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func openActivityMonitor() async {
        do {
            try await activityMonitor.openActivityMonitor()
            actionMessage = "Opened Activity Monitor."
        } catch {
            lastErrorMessage = error.localizedDescription
            actionMessage = nil
        }
    }

    private func runPollingLoop() async {
        await collect()

        if latest?.processes.contains(where: { $0.cpuUsageRatio == nil }) == true {
            try? await Task.sleep(for: .milliseconds(450))
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
            latest = try await provider.listProcesses()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            AppLog.processes.error("Process list failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
