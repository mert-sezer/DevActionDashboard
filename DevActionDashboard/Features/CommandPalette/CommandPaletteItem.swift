import Foundation

/// A searchable command exposed in the ⌘K palette.
struct CommandPaletteItem: Identifiable, Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case feature(FeatureID)
        case utility(UtilityTool)
        case action(SystemActionKind)
    }

    let id: String
    let title: String
    let subtitle: String
    let symbolName: String
    let kind: Kind

    @MainActor
    static func features(from registry: FeatureRegistry) -> [CommandPaletteItem] {
        registry.modules.map { module in
            CommandPaletteItem(
                id: "feature.\(module.id.rawValue)",
                title: module.title,
                subtitle: "Open \(module.title)",
                symbolName: module.symbolName,
                kind: .feature(module.id)
            )
        }
    }

    static var utilities: [CommandPaletteItem] {
        UtilityTool.allCases.map { tool in
            CommandPaletteItem(
                id: "utility.\(tool.rawValue)",
                title: tool.title,
                subtitle: "Utilities",
                symbolName: tool.symbolName,
                kind: .utility(tool)
            )
        }
    }

    static var actions: [CommandPaletteItem] {
        SystemActionKind.allCases.map { action in
            CommandPaletteItem(
                id: "action.\(action.rawValue)",
                title: action.title,
                subtitle: "Actions",
                symbolName: action.symbolName,
                kind: .action(action)
            )
        }
    }
}
