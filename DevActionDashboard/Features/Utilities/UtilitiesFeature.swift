import SwiftUI

@MainActor
final class UtilitiesFeature: FeatureModule {
    let id = FeatureID.utilities
    let title = "Utilities"
    let symbolName = "wrench"
    let sidebarSortOrder = 80

    private let navigation: AppNavigationStore

    init(navigation: AppNavigationStore) {
        self.navigation = navigation
    }

    func makeRootView() -> AnyView {
        AnyView(UtilitiesView(navigation: navigation))
    }
}
