import SwiftUI

@MainActor
final class SystemFeature: FeatureModule {
    let id = FeatureID.system
    let title = "System"
    let symbolName = "gauge.with.dots.needle.67percent"
    let sidebarSortOrder = 10

    private let metricsService: SystemMetricsService
    private let networkService: NetworkService

    init(metricsService: SystemMetricsService, networkService: NetworkService) {
        self.metricsService = metricsService
        self.networkService = networkService
    }

    func makeRootView() -> AnyView {
        AnyView(
            SystemView(
                viewModel: SystemViewModel(
                    metricsService: metricsService,
                    networkService: networkService
                )
            )
        )
    }
}
