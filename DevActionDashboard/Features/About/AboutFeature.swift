import SwiftUI

@MainActor
final class AboutFeature: FeatureModule {
    let id = FeatureID.about
    let title = "About"
    let symbolName = "info.circle"
    let sidebarSortOrder = 1_000

    func makeRootView() -> AnyView {
        AnyView(AboutView())
    }
}
