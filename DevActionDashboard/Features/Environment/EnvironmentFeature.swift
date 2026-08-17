import SwiftUI

@MainActor
final class EnvironmentFeature: FeatureModule {
    let id = FeatureID.environment
    let title = "Environment"
    let symbolName = "wrench.and.screwdriver"
    let sidebarSortOrder = 60

    private let toolingService: EnvironmentToolingService

    init(toolingService: EnvironmentToolingService) {
        self.toolingService = toolingService
    }

    func makeRootView() -> AnyView {
        AnyView(EnvironmentView(viewModel: EnvironmentViewModel(toolingService: toolingService)))
    }
}
