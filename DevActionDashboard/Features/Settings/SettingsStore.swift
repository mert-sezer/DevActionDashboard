import Foundation
import Observation
import SwiftUI

/// User-facing appearance preference persisted across launches.
public enum AppAppearance: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Refresh cadence for live collectors (metrics, Docker, ports).
public enum RefreshInterval: Int, CaseIterable, Identifiable, Sendable {
    case twoSeconds = 2
    case fiveSeconds = 5
    case tenSeconds = 10
    case thirtySeconds = 30

    public var id: Int { rawValue }

    public var title: String {
        "\(rawValue)s"
    }
}

/// Persists app preferences via `UserDefaults`.
@MainActor
@Observable
public final class SettingsStore {
    private enum Keys {
        static let appearance = "settings.appearance"
        static let refreshInterval = "settings.refreshInterval"
        static let dockerCLIPath = "settings.dockerCLIPath"
        static let accentColor = "settings.accentColor"
        static let notificationsEnabled = "settings.notificationsEnabled"
        static let notifyOnActionCompletion = "settings.notifyOnActionCompletion"
        static let menuBarEnabled = "settings.menuBarEnabled"
        static let hasCompletedWelcome = "settings.hasCompletedWelcome"
    }

    private let defaults: UserDefaults

    public var appearance: AppAppearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    public var refreshInterval: RefreshInterval {
        didSet { defaults.set(refreshInterval.rawValue, forKey: Keys.refreshInterval) }
    }

    public var dockerCLIPath: String {
        didSet { defaults.set(dockerCLIPath, forKey: Keys.dockerCLIPath) }
    }

    public var accentColor: AppAccentColor {
        didSet { defaults.set(accentColor.rawValue, forKey: Keys.accentColor) }
    }

    public var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }

    public var notifyOnActionCompletion: Bool {
        didSet { defaults.set(notifyOnActionCompletion, forKey: Keys.notifyOnActionCompletion) }
    }

    public var menuBarEnabled: Bool {
        didSet { defaults.set(menuBarEnabled, forKey: Keys.menuBarEnabled) }
    }

    public var hasCompletedWelcome: Bool {
        didSet { defaults.set(hasCompletedWelcome, forKey: Keys.hasCompletedWelcome) }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let raw = defaults.string(forKey: Keys.appearance),
           let stored = AppAppearance(rawValue: raw) {
            appearance = stored
        } else {
            appearance = .dark
        }

        let intervalRaw = defaults.integer(forKey: Keys.refreshInterval)
        if let stored = RefreshInterval(rawValue: intervalRaw) {
            refreshInterval = stored
        } else {
            refreshInterval = .fiveSeconds
        }

        if let storedPath = defaults.string(forKey: Keys.dockerCLIPath), !storedPath.isEmpty {
            dockerCLIPath = storedPath
        } else {
            dockerCLIPath = "docker"
        }

        if let accentRaw = defaults.string(forKey: Keys.accentColor),
           let stored = AppAccentColor(rawValue: accentRaw) {
            accentColor = stored
        } else {
            accentColor = .teal
        }

        if defaults.object(forKey: Keys.notificationsEnabled) != nil {
            notificationsEnabled = defaults.bool(forKey: Keys.notificationsEnabled)
        } else {
            notificationsEnabled = false
        }

        if defaults.object(forKey: Keys.notifyOnActionCompletion) != nil {
            notifyOnActionCompletion = defaults.bool(forKey: Keys.notifyOnActionCompletion)
        } else {
            notifyOnActionCompletion = true
        }

        if defaults.object(forKey: Keys.menuBarEnabled) != nil {
            menuBarEnabled = defaults.bool(forKey: Keys.menuBarEnabled)
        } else {
            menuBarEnabled = true
        }

        if defaults.object(forKey: Keys.hasCompletedWelcome) != nil {
            hasCompletedWelcome = defaults.bool(forKey: Keys.hasCompletedWelcome)
        } else {
            hasCompletedWelcome = false
        }
    }
}
