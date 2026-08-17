import Foundation
import Observation

/// Application facade for system maintenance actions and Finder shortcuts.
@MainActor
@Observable
final class SystemActionService {
    private(set) var lastResultMessage: String?
    private(set) var lastErrorMessage: String?
    private(set) var isPerforming = false
    private(set) var lastAction: SystemActionKind?

    private let runner: any SystemActionRunning
    private let settingsStore: SettingsStore
    private let notificationService: NotificationService?

    init(
        runner: any SystemActionRunning,
        settingsStore: SettingsStore,
        notificationService: NotificationService? = nil
    ) {
        self.runner = runner
        self.settingsStore = settingsStore
        self.notificationService = notificationService
    }

    func perform(_ action: SystemActionKind) async {
        isPerforming = true
        lastAction = action
        defer { isPerforming = false }

        do {
            let result = try await runner.perform(action)
            lastResultMessage = result.message
            lastErrorMessage = nil
            AppLog.actions.info("Action \(action.rawValue, privacy: .public): \(result.message, privacy: .public)")
            if settingsStore.notificationsEnabled && settingsStore.notifyOnActionCompletion {
                await notificationService?.postStatus(title: action.title, body: result.message)
            }
        } catch {
            lastResultMessage = nil
            lastErrorMessage = error.localizedDescription
            AppLog.actions.error("Action \(action.rawValue, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            if settingsStore.notificationsEnabled && settingsStore.notifyOnActionCompletion {
                await notificationService?.postStatus(title: "\(action.title) failed", body: error.localizedDescription)
            }
        }
    }
}
