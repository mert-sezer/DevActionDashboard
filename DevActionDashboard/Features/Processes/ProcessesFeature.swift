import SwiftUI

@MainActor
final class ProcessesFeature: FeatureModule {
    let id = FeatureID.processes
    let title = "Processes"
    let symbolName = "list.bullet.rectangle.portrait"
    let sidebarSortOrder = 20

    private let processService: ProcessService

    init(processService: ProcessService) {
        self.processService = processService
    }

    func makeRootView() -> AnyView {
        AnyView(ProcessesView(viewModel: ProcessesViewModel(processService: processService)))
    }
}
