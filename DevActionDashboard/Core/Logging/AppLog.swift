import Foundation
import OSLog

/// Central OSLog categories for consistent, filterable diagnostics.
public enum AppLog {
    public static let subsystem = Bundle.main.bundleIdentifier ?? "com.mertsezer.DevActionDashboard"

    public static let app = Logger(subsystem: subsystem, category: "App")
    public static let ui = Logger(subsystem: subsystem, category: "UI")
    public static let settings = Logger(subsystem: subsystem, category: "Settings")
    public static let features = Logger(subsystem: subsystem, category: "Features")
    public static let system = Logger(subsystem: subsystem, category: "System")
    public static let processes = Logger(subsystem: subsystem, category: "Processes")
    public static let network = Logger(subsystem: subsystem, category: "Network")
    public static let ports = Logger(subsystem: subsystem, category: "Ports")
    public static let docker = Logger(subsystem: subsystem, category: "Docker")
    public static let environment = Logger(subsystem: subsystem, category: "Environment")
    public static let envVars = Logger(subsystem: subsystem, category: "EnvVars")
    public static let utilities = Logger(subsystem: subsystem, category: "Utilities")
    public static let actions = Logger(subsystem: subsystem, category: "Actions")
    public static let notifications = Logger(subsystem: subsystem, category: "Notifications")
}
