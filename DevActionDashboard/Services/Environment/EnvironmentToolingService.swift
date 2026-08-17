import Foundation
import Observation

/// Application facade for developer toolchain discovery.
@MainActor
@Observable
final class EnvironmentToolingService {
    private(set) var latest: ToolingSnapshot?
    private(set) var lastErrorMessage: String?
    private(set) var isRefreshing = false

    private let provider: any ToolingProviding
    private var consumerCount = 0

    init(provider: any ToolingProviding) {
        self.provider = provider
    }

    func startMonitoring() {
        consumerCount += 1
        guard consumerCount == 1 else { return }
        Task { await refreshNow() }
        AppLog.environment.info("Environment tooling probe started")
    }

    func stopMonitoring() {
        consumerCount = max(consumerCount - 1, 0)
        if consumerCount == 0 {
            AppLog.environment.info("Environment tooling probe stopped")
        }
    }

    func refreshNow() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            latest = try await provider.probe()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            AppLog.environment.error("Tooling probe failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
