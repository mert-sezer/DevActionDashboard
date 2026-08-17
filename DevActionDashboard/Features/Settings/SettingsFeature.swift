import SwiftUI

@MainActor
final class SettingsFeature: FeatureModule {
    let id = FeatureID.settings
    let title = "Settings"
    let symbolName = "gearshape"
    let sidebarSortOrder = 900

    private let store: SettingsStore
    private let notificationService: NotificationService

    init(store: SettingsStore, notificationService: NotificationService) {
        self.store = store
        self.notificationService = notificationService
    }

    func makeRootView() -> AnyView {
        AnyView(
            SettingsView(
                viewModel: SettingsViewModel(
                    store: store,
                    notificationService: notificationService
                )
            )
        )
    }
}
