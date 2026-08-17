import SwiftUI

@MainActor
final class NetworkFeature: FeatureModule {
    let id = FeatureID.network
    let title = "Network"
    let symbolName = "network"
    let sidebarSortOrder = 30

    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func makeRootView() -> AnyView {
        AnyView(NetworkView(viewModel: NetworkViewModel(networkService: networkService)))
    }
}
