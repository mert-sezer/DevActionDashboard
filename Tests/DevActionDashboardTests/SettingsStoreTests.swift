import Foundation
import Testing
@testable import DevActionDashboard

@Suite("SettingsStore")
@MainActor
struct SettingsStoreTests {
    @Test("Persists appearance to UserDefaults")
    func persistsAppearance() {
        let suiteName = "SettingsStoreTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.appearance = .dark

        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.appearance == .dark)
    }

    @Test("Persists refresh interval to UserDefaults")
    func persistsRefreshInterval() {
        let suiteName = "SettingsStoreTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.refreshInterval = .thirtySeconds

        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.refreshInterval == .thirtySeconds)
    }

    @Test("Persists accent, notifications, and menu bar preferences")
    func persistsChromePreferences() {
        let suiteName = "SettingsStoreTests.chrome.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.accentColor = .orange
        store.notificationsEnabled = true
        store.notifyOnActionCompletion = false
        store.menuBarEnabled = false

        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.accentColor == .orange)
        #expect(reloaded.notificationsEnabled == true)
        #expect(reloaded.notifyOnActionCompletion == false)
        #expect(reloaded.menuBarEnabled == false)
    }

    @Test("Defaults welcome as incomplete until dismissed")
    func welcomeDefaultsIncomplete() {
        let suiteName = "SettingsStoreTests.welcome.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        #expect(store.hasCompletedWelcome == false)
        store.hasCompletedWelcome = true
        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.hasCompletedWelcome == true)
    }
}

@Suite("DefaultFeatureRegistry")
@MainActor
struct DefaultFeatureRegistryTests {
    @Test("Registers core modules in sidebar order")
    func registersCoreModules() {
        let defaults = UserDefaults(suiteName: "DefaultFeatureRegistryTests.\(UUID().uuidString)")!
        let settings = SettingsStore(defaults: defaults)
        let navigation = AppNavigationStore(initialFeatureID: .dashboard)
        let notifications = NotificationService(settingsStore: settings)
        let metrics = SystemMetricsService(
            provider: DarwinSystemMetricsProvider(),
            settingsStore: settings
        )
        let processes = ProcessService(
            provider: DarwinProcessProvider(),
            activityMonitor: ActivityMonitorLauncher(),
            settingsStore: settings
        )
        let network = NetworkService(
            provider: CompositeNetworkProvider(),
            settingsStore: settings
        )
        let ports = PortScanService(
            scanner: CompositePortScanProvider(),
            browser: BrowserLauncher(),
            settingsStore: settings
        )
        let docker = DockerService(
            provider: DockerCLIClient(),
            settingsStore: settings
        )
        let tooling = EnvironmentToolingService(provider: LocalToolchainDetector())
        let envVars = EnvironmentVariableService(provider: ProcessEnvironmentVariableProvider())
        let actions = SystemActionService(
            runner: DarwinSystemActionRunner(),
            settingsStore: settings,
            notificationService: notifications
        )
        let registry = DefaultFeatureRegistry(
            settingsStore: settings,
            navigationStore: navigation,
            notificationService: notifications,
            metricsService: metrics,
            processService: processes,
            networkService: network,
            portScanService: ports,
            dockerService: docker,
            environmentToolingService: tooling,
            environmentVariableService: envVars,
            systemActionService: actions
        )
        let ids = registry.modules.map(\.id)

        #expect(ids.contains(.dashboard))
        #expect(ids.contains(.system))
        #expect(ids.contains(.processes))
        #expect(ids.contains(.network))
        #expect(ids.contains(.ports))
        #expect(ids.contains(.docker))
        #expect(ids.contains(.environment))
        #expect(ids.contains(.envVars))
        #expect(ids.contains(.utilities))
        #expect(ids.contains(.actions))
        #expect(ids.contains(.settings))
        #expect(ids.contains(.about))
        #expect(ids.first == .dashboard)
        #expect(ids.firstIndex(of: .utilities) == 8)
        #expect(ids.firstIndex(of: .actions) == 9)
    }
}
