import Observation
import SwiftUI

@MainActor
@Observable
final class SettingsViewModel {
    private let store: SettingsStore
    private let notificationService: NotificationService?

    var appearance: AppAppearance {
        get { store.appearance }
        set { store.appearance = newValue }
    }

    var refreshInterval: RefreshInterval {
        get { store.refreshInterval }
        set { store.refreshInterval = newValue }
    }

    var dockerCLIPath: String {
        get { store.dockerCLIPath }
        set { store.dockerCLIPath = newValue }
    }

    var accentColor: AppAccentColor {
        get { store.accentColor }
        set { store.accentColor = newValue }
    }

    var notificationsEnabled: Bool {
        get { store.notificationsEnabled }
        set {
            store.notificationsEnabled = newValue
            if newValue {
                Task { await notificationService?.requestAuthorizationIfNeeded() }
            }
        }
    }

    var notifyOnActionCompletion: Bool {
        get { store.notifyOnActionCompletion }
        set { store.notifyOnActionCompletion = newValue }
    }

    var menuBarEnabled: Bool {
        get { store.menuBarEnabled }
        set { store.menuBarEnabled = newValue }
    }

    var authorizationStatusDescription: String {
        notificationService?.authorizationStatusDescription ?? "—"
    }

    init(store: SettingsStore, notificationService: NotificationService? = nil) {
        self.store = store
        self.notificationService = notificationService
    }

    func onAppear() {
        Task { await notificationService?.refreshAuthorizationStatus() }
    }

    func showWelcomeAgain() {
        store.hasCompletedWelcome = false
    }
}
