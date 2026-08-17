import Foundation

/// Catalog of supported macOS system actions.
public enum SystemActionKind: String, CaseIterable, Identifiable, Sendable, Hashable {
    case flushDNS
    case restartFinder
    case restartDock
    case clearXcodeDerivedData
    case openTerminal
    case emptyTrash
    case openDownloads
    case openDesktop

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .flushDNS: "Flush DNS"
        case .restartFinder: "Restart Finder"
        case .restartDock: "Restart Dock"
        case .clearXcodeDerivedData: "Clear Xcode DerivedData"
        case .openTerminal: "Open Terminal"
        case .emptyTrash: "Empty Trash"
        case .openDownloads: "Open Downloads"
        case .openDesktop: "Open Desktop"
        }
    }

    public var detail: String {
        switch self {
        case .flushDNS:
            "Runs dscacheutil -flushcache and sends HUP to mDNSResponder."
        case .restartFinder:
            "Quits Finder; launchd relaunches it."
        case .restartDock:
            "Quits Dock; launchd relaunches it."
        case .clearXcodeDerivedData:
            "Deletes ~/Library/Developer/Xcode/DerivedData contents."
        case .openTerminal:
            "Opens Terminal.app."
        case .emptyTrash:
            "Asks Finder to empty the Trash."
        case .openDownloads:
            "Reveals the Downloads folder in Finder."
        case .openDesktop:
            "Reveals the Desktop folder in Finder."
        }
    }

    public var symbolName: String {
        switch self {
        case .flushDNS: "network"
        case .restartFinder: "folder"
        case .restartDock: "dock.rectangle"
        case .clearXcodeDerivedData: "hammer"
        case .openTerminal: "terminal"
        case .emptyTrash: "trash"
        case .openDownloads: "arrow.down.circle"
        case .openDesktop: "desktopcomputer"
        }
    }

    public var category: SystemActionCategory {
        switch self {
        case .flushDNS, .restartFinder, .restartDock, .clearXcodeDerivedData, .emptyTrash:
            .maintenance
        case .openTerminal, .openDownloads, .openDesktop:
            .shortcuts
        }
    }

    public var requiresConfirmation: Bool {
        switch self {
        case .flushDNS, .restartFinder, .restartDock, .clearXcodeDerivedData, .emptyTrash:
            true
        case .openTerminal, .openDownloads, .openDesktop:
            false
        }
    }

    public var isDestructive: Bool {
        switch self {
        case .clearXcodeDerivedData, .emptyTrash:
            true
        default:
            false
        }
    }
}

public enum SystemActionCategory: String, CaseIterable, Identifiable, Sendable {
    case maintenance
    case shortcuts

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .maintenance: "Maintenance"
        case .shortcuts: "Shortcuts"
        }
    }
}

public struct SystemActionResult: Sendable, Equatable {
    public let action: SystemActionKind
    public let message: String

    public init(action: SystemActionKind, message: String) {
        self.action = action
        self.message = message
    }
}
