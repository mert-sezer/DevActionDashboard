import SwiftUI

@MainActor
final class PortsFeature: FeatureModule {
    let id = FeatureID.ports
    let title = "Ports"
    let symbolName = "point.3.connected.trianglepath.dotted"
    let sidebarSortOrder = 40

    private let portScanService: PortScanService

    init(portScanService: PortScanService) {
        self.portScanService = portScanService
    }

    func makeRootView() -> AnyView {
        AnyView(PortsView(viewModel: PortsViewModel(portScanService: portScanService)))
    }
}
