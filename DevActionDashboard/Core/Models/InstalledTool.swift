import Foundation

/// A developer toolchain probed on the local machine.
public struct InstalledTool: Identifiable, Sendable, Equatable, Hashable {
    public var id: String { kind.rawValue }

    public let kind: DeveloperToolKind
    public let isInstalled: Bool
    public let version: String?
    public let path: String?
    public let detail: String?

    public init(
        kind: DeveloperToolKind,
        isInstalled: Bool,
        version: String?,
        path: String?,
        detail: String? = nil
    ) {
        self.kind = kind
        self.isInstalled = isInstalled
        self.version = version
        self.path = path
        self.detail = detail
    }
}

public enum DeveloperToolKind: String, CaseIterable, Identifiable, Sendable, Hashable {
    case node
    case npm
    case pnpm
    case yarn
    case bun
    case python
    case java
    case go
    case rust
    case flutter
    case androidSDK
    case xcode
    case homebrew

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .node: "Node.js"
        case .npm: "npm"
        case .pnpm: "pnpm"
        case .yarn: "Yarn"
        case .bun: "Bun"
        case .python: "Python"
        case .java: "Java"
        case .go: "Go"
        case .rust: "Rust"
        case .flutter: "Flutter"
        case .androidSDK: "Android SDK"
        case .xcode: "Xcode"
        case .homebrew: "Homebrew"
        }
    }

    public var symbolName: String {
        switch self {
        case .node, .npm, .pnpm, .yarn, .bun: "curlybraces"
        case .python: "chevron.left.forwardslash.chevron.right"
        case .java: "cup.and.saucer"
        case .go: "hare"
        case .rust: "gearshape.2"
        case .flutter: "app"
        case .androidSDK: "iphone"
        case .xcode: "hammer"
        case .homebrew: "mug"
        }
    }

    public var category: DeveloperToolCategory {
        switch self {
        case .node, .npm, .pnpm, .yarn, .bun: .javascript
        case .python, .java, .go, .rust: .languages
        case .flutter, .androidSDK, .xcode: .mobile
        case .homebrew: .packageManagers
        }
    }
}

public enum DeveloperToolCategory: String, CaseIterable, Identifiable, Sendable {
    case javascript
    case languages
    case mobile
    case packageManagers

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .javascript: "JavaScript"
        case .languages: "Languages"
        case .mobile: "Mobile & Apple"
        case .packageManagers: "Package Managers"
        }
    }
}

public struct ToolingSnapshot: Sendable, Equatable {
    public let timestamp: Date
    public let tools: [InstalledTool]

    public init(timestamp: Date = .now, tools: [InstalledTool]) {
        self.timestamp = timestamp
        self.tools = tools
    }

    public var installedCount: Int {
        tools.filter(\.isInstalled).count
    }
}
