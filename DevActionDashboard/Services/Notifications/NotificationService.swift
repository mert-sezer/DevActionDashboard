import Foundation
import Observation
import UserNotifications

/// Requests notification authorization and posts optional status alerts.
@MainActor
@Observable
final class NotificationService {
    private let settingsStore: SettingsStore
    private let center: UNUserNotificationCenter

    private(set) var authorizationStatusDescription = "Unknown"

    init(
        settingsStore: SettingsStore,
        center: UNUserNotificationCenter = .current()
    ) {
        self.settingsStore = settingsStore
        self.center = center
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            authorizationStatusDescription = "Allowed"
        case .denied:
            authorizationStatusDescription = "Denied"
        case .notDetermined:
            authorizationStatusDescription = "Not determined"
        @unknown default:
            authorizationStatusDescription = "Unknown"
        }
    }

    func requestAuthorizationIfNeeded() async {
        await refreshAuthorizationStatus()
        guard settingsStore.notificationsEnabled else { return }
        guard authorizationStatusDescription == "Not determined" else { return }

        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            AppLog.notifications.error("Notification auth failed: \(error.localizedDescription, privacy: .public)")
        }
        await refreshAuthorizationStatus()
    }

    func postStatus(title: String, body: String) async {
        guard settingsStore.notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        do {
            try await center.add(request)
        } catch {
            AppLog.notifications.error("Failed to post notification: \(error.localizedDescription, privacy: .public)")
        }
    }
}
