import SwiftUI

@MainActor
final class EnvVarsFeature: FeatureModule {
    let id = FeatureID.envVars
    let title = "Env Vars"
    let symbolName = "key"
    let sidebarSortOrder = 70

    private let service: EnvironmentVariableService

    init(service: EnvironmentVariableService) {
        self.service = service
    }

    func makeRootView() -> AnyView {
        AnyView(EnvVarsView(viewModel: EnvVarsViewModel(service: service)))
    }
}
