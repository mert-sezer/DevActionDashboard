import Foundation

/// Built-in feature modules shown in the sidebar.
@MainActor
final class DefaultFeatureRegistry: FeatureRegistry {
    let modules: [any FeatureModule]

    init(
        settingsStore: SettingsStore,
        navigationStore: AppNavigationStore,
        notificationService: NotificationService,
        metricsService: SystemMetricsService,
        processService: ProcessService,
        networkService: NetworkService,
        portScanService: PortScanService,
        dockerService: DockerService,
        environmentToolingService: EnvironmentToolingService,
        environmentVariableService: EnvironmentVariableService,
        systemActionService: SystemActionService
    ) {
        modules = [
            DashboardFeature(metricsService: metricsService, networkService: networkService),
            SystemFeature(metricsService: metricsService, networkService: networkService),
            ProcessesFeature(processService: processService),
            NetworkFeature(networkService: networkService),
            PortsFeature(portScanService: portScanService),
            DockerFeature(dockerService: dockerService),
            EnvironmentFeature(toolingService: environmentToolingService),
            EnvVarsFeature(service: environmentVariableService),
            UtilitiesFeature(navigation: navigationStore),
            ActionsFeature(service: systemActionService),
            SettingsFeature(store: settingsStore, notificationService: notificationService),
            AboutFeature()
        ]
        .sorted { $0.sidebarSortOrder < $1.sidebarSortOrder }
    }
}
