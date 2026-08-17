import Foundation

/// A localhost listening TCP port with optional stack fingerprint.
public struct LocalPortEntry: Identifiable, Sendable, Equatable, Hashable {
    public var id: String { "\(pid)-\(port)-\(address)" }

    public let port: UInt16
    public let address: String
    public let pid: Int32
    public let processName: String
    public let processPath: String?
    public let detectedStack: DetectedDevStack
    public let httpTitle: String?
    public let serverHeader: String?
    public let detectionConfidence: DetectionConfidence

    public init(
        port: UInt16,
        address: String,
        pid: Int32,
        processName: String,
        processPath: String?,
        detectedStack: DetectedDevStack,
        httpTitle: String?,
        serverHeader: String?,
        detectionConfidence: DetectionConfidence
    ) {
        self.port = port
        self.address = address
        self.pid = pid
        self.processName = processName
        self.processPath = processPath
        self.detectedStack = detectedStack
        self.httpTitle = httpTitle
        self.serverHeader = serverHeader
        self.detectionConfidence = detectionConfidence
    }

    public var browserURL: URL? {
        URL(string: "http://127.0.0.1:\(port)")
    }
}

public enum DetectedDevStack: String, Sendable, Equatable, Hashable, CaseIterable, Identifiable {
    case nextJS
    case react
    case nodeJS
    case laravel
    case springBoot
    case aspNet
    case unknown

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .nextJS: "Next.js"
        case .react: "React"
        case .nodeJS: "Node.js"
        case .laravel: "Laravel"
        case .springBoot: "Spring Boot"
        case .aspNet: "ASP.NET"
        case .unknown: "Unknown"
        }
    }

    public var symbolName: String {
        switch self {
        case .nextJS: "n.square.fill"
        case .react: "circle.hexagongrid.fill"
        case .nodeJS: "server.rack"
        case .laravel: "cup.and.saucer.fill"
        case .springBoot: "leaf.fill"
        case .aspNet: "chevron.left.forwardslash.chevron.right"
        case .unknown: "questionmark.app"
        }
    }
}

public enum DetectionConfidence: String, Sendable, Equatable, Hashable {
    case high
    case medium
    case low
    case none

    public var title: String {
        rawValue.capitalized
    }
}

public struct PortScanSnapshot: Sendable, Equatable {
    public let timestamp: Date
    public let entries: [LocalPortEntry]

    public init(timestamp: Date = .now, entries: [LocalPortEntry]) {
        self.timestamp = timestamp
        self.entries = entries
    }
}

/// Raw listening socket before HTTP fingerprinting.
public struct ListeningSocket: Sendable, Equatable, Hashable {
    public let port: UInt16
    public let address: String
    public let pid: Int32
    public let processName: String
    public let processPath: String?

    public init(
        port: UInt16,
        address: String,
        pid: Int32,
        processName: String,
        processPath: String?
    ) {
        self.port = port
        self.address = address
        self.pid = pid
        self.processName = processName
        self.processPath = processPath
    }
}

public struct HTTPFingerprint: Sendable, Equatable {
    public let stack: DetectedDevStack
    public let confidence: DetectionConfidence
    public let title: String?
    public let serverHeader: String?
    public let bodySnippet: String?

    public init(
        stack: DetectedDevStack,
        confidence: DetectionConfidence,
        title: String?,
        serverHeader: String?,
        bodySnippet: String?
    ) {
        self.stack = stack
        self.confidence = confidence
        self.title = title
        self.serverHeader = serverHeader
        self.bodySnippet = bodySnippet
    }

    public static let empty = HTTPFingerprint(
        stack: .unknown,
        confidence: .none,
        title: nil,
        serverHeader: nil,
        bodySnippet: nil
    )
}
