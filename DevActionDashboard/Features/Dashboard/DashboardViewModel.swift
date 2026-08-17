import Foundation
import Observation

/// Dashboard overview: live system metrics and a network summary.
@MainActor
@Observable
final class DashboardViewModel {
    private(set) var operatingSystemVersion: String
    private(set) var architecture: String
    private(set) var appVersion: String
    private(set) var buildNumber: String

    private let processInfo: ProcessInfo
    private let bundle: Bundle
    private let metricsService: SystemMetricsService
    private let networkService: NetworkService

    var snapshot: SystemMetricsSnapshot? { metricsService.latest }
    var networkSnapshot: NetworkSnapshot? { networkService.latest }
    var metricsError: String? { metricsService.lastErrorMessage }
    var isRefreshing: Bool { metricsService.isRefreshing || networkService.isRefreshing }

    init(
        metricsService: SystemMetricsService,
        networkService: NetworkService,
        processInfo: ProcessInfo = .processInfo,
        bundle: Bundle = .main
    ) {
        self.metricsService = metricsService
        self.networkService = networkService
        self.processInfo = processInfo
        self.bundle = bundle

        operatingSystemVersion = Self.formatOSVersion(processInfo.operatingSystemVersion)
        architecture = Self.currentArchitecture()
        appVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        buildNumber = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    func onAppear() {
        metricsService.startMonitoring()
        networkService.startMonitoring()
        refreshHostIdentity()
    }

    func onDisappear() {
        metricsService.stopMonitoring()
        networkService.stopMonitoring()
    }

    func refresh() {
        refreshHostIdentity()
        Task {
            await metricsService.refreshNow()
            await networkService.refreshNow()
        }
    }

    private func refreshHostIdentity() {
        operatingSystemVersion = Self.formatOSVersion(processInfo.operatingSystemVersion)
        architecture = Self.currentArchitecture()
        AppLog.ui.debug("Dashboard host identity refreshed")
    }

    private static func formatOSVersion(_ version: OperatingSystemVersion) -> String {
        "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    private static func currentArchitecture() -> String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "unknown"
        #endif
    }
}
