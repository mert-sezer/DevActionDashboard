import Foundation

/// Point-in-time system resource snapshot collected from the host.
public struct SystemMetricsSnapshot: Sendable, Equatable {
    public let timestamp: Date
    public let cpu: CPUMetrics
    public let memory: MemoryMetrics
    public let storage: StorageMetrics
    public let battery: BatteryMetrics?
    public let thermalState: SystemThermalState
    public let uptime: TimeInterval

    public init(
        timestamp: Date = .now,
        cpu: CPUMetrics,
        memory: MemoryMetrics,
        storage: StorageMetrics,
        battery: BatteryMetrics?,
        thermalState: SystemThermalState,
        uptime: TimeInterval
    ) {
        self.timestamp = timestamp
        self.cpu = cpu
        self.memory = memory
        self.storage = storage
        self.battery = battery
        self.thermalState = thermalState
        self.uptime = uptime
    }
}

/// Aggregate CPU utilization across logical cores.
public struct CPUMetrics: Sendable, Equatable {
    /// Fraction of non-idle time in `0...1`. `nil` until a second sample establishes a delta.
    public let usageRatio: Double?
    public let logicalCoreCount: Int

    public init(usageRatio: Double?, logicalCoreCount: Int) {
        self.usageRatio = usageRatio.map { min(max($0, 0), 1) }
        self.logicalCoreCount = logicalCoreCount
    }
}

/// Physical memory and swap pressure.
public struct MemoryMetrics: Sendable, Equatable {
    public let totalBytes: UInt64
    public let usedBytes: UInt64
    public let wiredBytes: UInt64
    public let compressedBytes: UInt64
    public let freeBytes: UInt64
    public let swapUsedBytes: UInt64
    public let swapTotalBytes: UInt64

    public init(
        totalBytes: UInt64,
        usedBytes: UInt64,
        wiredBytes: UInt64,
        compressedBytes: UInt64,
        freeBytes: UInt64,
        swapUsedBytes: UInt64,
        swapTotalBytes: UInt64
    ) {
        self.totalBytes = totalBytes
        self.usedBytes = usedBytes
        self.wiredBytes = wiredBytes
        self.compressedBytes = compressedBytes
        self.freeBytes = freeBytes
        self.swapUsedBytes = swapUsedBytes
        self.swapTotalBytes = swapTotalBytes
    }

    public var usageRatio: Double {
        guard totalBytes > 0 else { return 0 }
        return min(Double(usedBytes) / Double(totalBytes), 1)
    }

    public var swapUsageRatio: Double {
        guard swapTotalBytes > 0 else { return 0 }
        return min(Double(swapUsedBytes) / Double(swapTotalBytes), 1)
    }
}

/// Boot volume capacity.
public struct StorageMetrics: Sendable, Equatable {
    public let totalBytes: UInt64
    public let freeBytes: UInt64
    public let volumeName: String

    public init(totalBytes: UInt64, freeBytes: UInt64, volumeName: String) {
        self.totalBytes = totalBytes
        self.freeBytes = freeBytes
        self.volumeName = volumeName
    }

    public var usedBytes: UInt64 {
        totalBytes > freeBytes ? totalBytes - freeBytes : 0
    }

    public var usageRatio: Double {
        guard totalBytes > 0 else { return 0 }
        return min(Double(usedBytes) / Double(totalBytes), 1)
    }
}

/// Battery information when a power source reports charge data.
public struct BatteryMetrics: Sendable, Equatable {
    public let chargeRatio: Double?
    public let isCharging: Bool
    public let isACPowered: Bool
    public let healthDescription: String?

    public init(
        chargeRatio: Double?,
        isCharging: Bool,
        isACPowered: Bool,
        healthDescription: String?
    ) {
        self.chargeRatio = chargeRatio.map { min(max($0, 0), 1) }
        self.isCharging = isCharging
        self.isACPowered = isACPowered
        self.healthDescription = healthDescription
    }
}

/// Public thermal pressure from `ProcessInfo` (no private SMC temperature APIs).
public enum SystemThermalState: String, Sendable, Equatable {
    case nominal
    case fair
    case serious
    case critical
    case unknown

    public var title: String {
        switch self {
        case .nominal: "Nominal"
        case .fair: "Fair"
        case .serious: "Serious"
        case .critical: "Critical"
        case .unknown: "Unknown"
        }
    }

    public init(processInfoThermalState state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal: self = .nominal
        case .fair: self = .fair
        case .serious: self = .serious
        case .critical: self = .critical
        @unknown default: self = .unknown
        }
    }
}
