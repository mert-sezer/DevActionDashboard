import SwiftUI

@MainActor
final class DashboardFeature: FeatureModule {
    let id = FeatureID.dashboard
    let title = "Dashboard"
    let symbolName = "square.grid.2x2"
    let sidebarSortOrder = 0

    private let metricsService: SystemMetricsService
    private let networkService: NetworkService

    init(metricsService: SystemMetricsService, networkService: NetworkService) {
        self.metricsService = metricsService
        self.networkService = networkService
    }

    func makeRootView() -> AnyView {
        AnyView(
            DashboardView(
                viewModel: DashboardViewModel(
                    metricsService: metricsService,
                    networkService: networkService
                )
            )
        )
    }
}
