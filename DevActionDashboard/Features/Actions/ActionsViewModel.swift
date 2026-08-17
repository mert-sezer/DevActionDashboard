import Foundation
import Observation

@MainActor
@Observable
final class ActionsViewModel {
    private let service: SystemActionService

    var pendingAction: SystemActionKind?

    var isPerforming: Bool { service.isPerforming }
    var resultMessage: String? { service.lastResultMessage }
    var errorMessage: String? { service.lastErrorMessage }

    var groupedActions: [(category: SystemActionCategory, actions: [SystemActionKind])] {
        SystemActionCategory.allCases.map { category in
            (category, SystemActionKind.allCases.filter { $0.category == category })
        }
    }

    init(service: SystemActionService) {
        self.service = service
    }

    func request(_ action: SystemActionKind) {
        if action.requiresConfirmation {
            pendingAction = action
        } else {
            Task { await service.perform(action) }
        }
    }

    func confirmPending() {
        guard let action = pendingAction else { return }
        pendingAction = nil
        Task { await service.perform(action) }
    }

    func cancelPending() {
        pendingAction = nil
    }
}
