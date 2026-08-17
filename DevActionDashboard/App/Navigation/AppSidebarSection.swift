import SwiftUI

/// Sidebar grouping for the app shell.
public enum AppSidebarSection: Int, CaseIterable, Identifiable, Sendable {
    case monitor
    case develop
    case tools
    case app

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .monitor: "Monitor"
        case .develop: "Develop"
        case .tools: "Tools"
        case .app: "App"
        }
    }

    public static func section(for featureID: FeatureID) -> AppSidebarSection {
        if [FeatureID.dashboard, .system, .processes, .network].contains(featureID) {
            return .monitor
        }
        if [FeatureID.ports, .docker, .environment].contains(featureID) {
            return .develop
        }
        if [FeatureID.envVars, .utilities, .actions].contains(featureID) {
            return .tools
        }
        return .app
    }
}
