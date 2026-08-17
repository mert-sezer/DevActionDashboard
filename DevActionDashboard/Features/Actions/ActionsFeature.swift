import SwiftUI

@MainActor
final class ActionsFeature: FeatureModule {
    let id = FeatureID.actions
    let title = "Actions"
    let symbolName = "bolt.horizontal.circle"
    let sidebarSortOrder = 85

    private let service: SystemActionService

    init(service: SystemActionService) {
        self.service = service
    }

    func makeRootView() -> AnyView {
        AnyView(ActionsView(viewModel: ActionsViewModel(service: service)))
    }
}
