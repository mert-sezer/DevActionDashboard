import Foundation

/// Composition root dependencies shared across the app shell and features.
@MainActor
final class AppEnvironment {
    let settingsStore: SettingsStore
    let navigationStore: AppNavigationStore
    let notificationService: NotificationService
    let systemMetricsService: SystemMetricsService
    let processService: ProcessService
    let networkService: NetworkService
    let portScanService: PortScanService
    let dockerService: DockerService
    let environmentToolingService: EnvironmentToolingService
    let environmentVariableService: EnvironmentVariableService
    let systemActionService: SystemActionService
    let featureRegistry: FeatureRegistry

    init(
        settingsStore: SettingsStore = SettingsStore(),
        systemMetricsProvider: (any SystemMetricsProviding)? = nil,
        processProvider: (any ProcessProviding)? = nil,
        activityMonitorLauncher: (any ActivityMonitorLaunching)? = nil,
        networkProvider: (any NetworkProviding)? = nil,
        portScanner: (any PortScanning)? = nil,
        browserLauncher: (any BrowserLaunching)? = nil,
        dockerProvider: (any DockerProviding)? = nil,
        toolingProvider: (any ToolingProviding)? = nil,
        environmentVariableProvider: (any EnvironmentVariableProviding)? = nil,
        systemActionRunner: (any SystemActionRunning)? = nil,
        featureRegistry: FeatureRegistry? = nil
    ) {
        self.settingsStore = settingsStore

        let navigationStore = AppNavigationStore(initialFeatureID: .dashboard)
        self.navigationStore = navigationStore

        let notificationService = NotificationService(settingsStore: settingsStore)
        self.notificationService = notificationService

        let metricsProvider = systemMetricsProvider ?? DarwinSystemMetricsProvider()
        let metricsService = SystemMetricsService(provider: metricsProvider, settingsStore: settingsStore)
        self.systemMetricsService = metricsService

        let processes = processProvider ?? DarwinProcessProvider()
        let activityMonitor = activityMonitorLauncher ?? ActivityMonitorLauncher()
        let processService = ProcessService(
            provider: processes,
            activityMonitor: activityMonitor,
            settingsStore: settingsStore
        )
        self.processService = processService

        let network = networkProvider ?? CompositeNetworkProvider()
        let networkService = NetworkService(provider: network, settingsStore: settingsStore)
        self.networkService = networkService

        let scanner = portScanner ?? CompositePortScanProvider()
        let browser = browserLauncher ?? BrowserLauncher()
        let portScanService = PortScanService(
            scanner: scanner,
            browser: browser,
            settingsStore: settingsStore
        )
        self.portScanService = portScanService

        let docker = dockerProvider ?? DockerCLIClient()
        let dockerService = DockerService(provider: docker, settingsStore: settingsStore)
        self.dockerService = dockerService

        let tooling = toolingProvider ?? LocalToolchainDetector()
        let environmentToolingService = EnvironmentToolingService(provider: tooling)
        self.environmentToolingService = environmentToolingService

        let envVarsProvider = environmentVariableProvider ?? ProcessEnvironmentVariableProvider()
        let environmentVariableService = EnvironmentVariableService(provider: envVarsProvider)
        self.environmentVariableService = environmentVariableService

        let actions = systemActionRunner ?? DarwinSystemActionRunner()
        let systemActionService = SystemActionService(
            runner: actions,
            settingsStore: settingsStore,
            notificationService: notificationService
        )
        self.systemActionService = systemActionService

        self.featureRegistry = featureRegistry ?? DefaultFeatureRegistry(
            settingsStore: settingsStore,
            navigationStore: navigationStore,
            notificationService: notificationService,
            metricsService: metricsService,
            processService: processService,
            networkService: networkService,
            portScanService: portScanService,
            dockerService: dockerService,
            environmentToolingService: environmentToolingService,
            environmentVariableService: environmentVariableService,
            systemActionService: systemActionService
        )
        AppLog.app.info("AppEnvironment initialized with \(self.featureRegistry.modules.count) features")
    }
}
