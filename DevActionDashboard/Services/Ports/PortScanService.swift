import Foundation
import Observation

/// Application facade for localhost port scanning and browser launching.
@MainActor
@Observable
final class PortScanService {
    private(set) var latest: PortScanSnapshot?
    private(set) var lastErrorMessage: String?
    private(set) var actionMessage: String?
    private(set) var isRefreshing = false

    private let scanner: any PortScanning
    private let browser: any BrowserLaunching
    private let settingsStore: SettingsStore
    private var pollingTask: Task<Void, Never>?
    private var consumerCount = 0

    init(
        scanner: any PortScanning,
        browser: any BrowserLaunching,
        settingsStore: SettingsStore
    ) {
        self.scanner = scanner
        self.browser = browser
        self.settingsStore = settingsStore
    }

    func startMonitoring() {
        consumerCount += 1
        guard consumerCount == 1 else { return }

        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            await self?.runPollingLoop()
        }
        AppLog.ports.info("Port scan monitoring started")
    }

    func stopMonitoring() {
        consumerCount = max(consumerCount - 1, 0)
        guard consumerCount == 0 else { return }

        pollingTask?.cancel()
        pollingTask = nil
        AppLog.ports.info("Port scan monitoring stopped")
    }

    func refreshNow() async {
        await collect()
    }

    func openInBrowser(_ entry: LocalPortEntry) async {
        guard let url = entry.browserURL, LocalNetworkPolicy.isLoopbackHTTP(url) else {
            lastErrorMessage = PortError.invalidURL(entry.port).localizedDescription
            actionMessage = nil
            return
        }

        do {
            try await browser.open(url)
            actionMessage = "Opened \(url.absoluteString)"
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            actionMessage = nil
        }
    }

    private func runPollingLoop() async {
        await collect()

        while !Task.isCancelled {
            // Port HTTP probing is heavier; never poll faster than 5 seconds.
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
            latest = try await scanner.scan()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            AppLog.ports.error("Port scan failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
