import AppKit
import Foundation

/// Launches Apple Activity Monitor via `NSWorkspace`.
struct ActivityMonitorLauncher: ActivityMonitorLaunching {
    private static let activityMonitorURL = URL(
        fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"
    )

    func openActivityMonitor() async throws {
        let configuration = NSWorkspace.OpenConfiguration()
        do {
            _ = try await NSWorkspace.shared.openApplication(
                at: Self.activityMonitorURL,
                configuration: configuration
            )
            AppLog.processes.info("Opened Activity Monitor")
        } catch {
            AppLog.processes.error("Failed to open Activity Monitor: \(error.localizedDescription, privacy: .public)")
            throw ProcessError.activityMonitorUnavailable
        }
    }
}
