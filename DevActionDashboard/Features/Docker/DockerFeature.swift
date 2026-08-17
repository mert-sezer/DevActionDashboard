import SwiftUI

@MainActor
final class DockerFeature: FeatureModule {
    let id = FeatureID.docker
    let title = "Docker"
    let symbolName = "shippingbox"
    let sidebarSortOrder = 50

    private let dockerService: DockerService

    init(dockerService: DockerService) {
        self.dockerService = dockerService
    }

    func makeRootView() -> AnyView {
        AnyView(DockerView(viewModel: DockerViewModel(dockerService: dockerService)))
    }
}
