import Foundation

/// A single running process sampled from the host.
public struct RunningProcess: Identifiable, Sendable, Equatable, Hashable {
    public var id: Int32 { pid }

    public let pid: Int32
    public let name: String
    public let path: String?
    public let userID: UInt32
    /// Fraction of a single logical core (`1.0` == 100% of one core). `nil` until a second sample.
    public let cpuUsageRatio: Double?
    public let residentMemoryBytes: UInt64
    public let threadCount: Int

    public init(
        pid: Int32,
        name: String,
        path: String?,
        userID: UInt32,
        cpuUsageRatio: Double?,
        residentMemoryBytes: UInt64,
        threadCount: Int
    ) {
        self.pid = pid
        self.name = name
        self.path = path
        self.userID = userID
        self.cpuUsageRatio = cpuUsageRatio.map { max($0, 0) }
        self.residentMemoryBytes = residentMemoryBytes
        self.threadCount = threadCount
    }
}

/// Full process table snapshot.
public struct ProcessListSnapshot: Sendable, Equatable {
    public let timestamp: Date
    public let processes: [RunningProcess]

    public init(timestamp: Date = .now, processes: [RunningProcess]) {
        self.timestamp = timestamp
        self.processes = processes
    }
}

public enum ProcessSortKey: String, CaseIterable, Identifiable, Sendable {
    case cpu
    case memory
    case name
    case pid

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .cpu: "CPU"
        case .memory: "Memory"
        case .name: "Name"
        case .pid: "PID"
        }
    }
}
