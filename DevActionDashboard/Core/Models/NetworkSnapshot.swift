import Foundation

/// Point-in-time network observability snapshot.
public struct NetworkSnapshot: Sendable, Equatable {
    public let timestamp: Date
    public let path: NetworkPathStatus
    public let interfaces: [NetworkInterfaceAddress]
    public let primaryIPv4: String?
    public let primaryIPv6: String?
    public let publicIP: String?
    public let dnsServers: [String]
    public let throughput: NetworkThroughput
    public let httpsLatency: NetworkLatencySample?
    public let tcpProbeLatency: NetworkLatencySample?

    public init(
        timestamp: Date = .now,
        path: NetworkPathStatus,
        interfaces: [NetworkInterfaceAddress],
        primaryIPv4: String?,
        primaryIPv6: String?,
        publicIP: String?,
        dnsServers: [String],
        throughput: NetworkThroughput,
        httpsLatency: NetworkLatencySample?,
        tcpProbeLatency: NetworkLatencySample?
    ) {
        self.timestamp = timestamp
        self.path = path
        self.interfaces = interfaces
        self.primaryIPv4 = primaryIPv4
        self.primaryIPv6 = primaryIPv6
        self.publicIP = publicIP
        self.dnsServers = dnsServers
        self.throughput = throughput
        self.httpsLatency = httpsLatency
        self.tcpProbeLatency = tcpProbeLatency
    }
}

public struct NetworkPathStatus: Sendable, Equatable {
    public let isSatisfied: Bool
    public let isExpensive: Bool
    public let isConstrained: Bool
    public let usesWiFi: Bool
    public let usesWired: Bool
    public let usesCellular: Bool
    public let statusDescription: String

    public init(
        isSatisfied: Bool,
        isExpensive: Bool,
        isConstrained: Bool,
        usesWiFi: Bool,
        usesWired: Bool,
        usesCellular: Bool,
        statusDescription: String
    ) {
        self.isSatisfied = isSatisfied
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
        self.usesWiFi = usesWiFi
        self.usesWired = usesWired
        self.usesCellular = usesCellular
        self.statusDescription = statusDescription
    }
}

public struct NetworkInterfaceAddress: Identifiable, Sendable, Equatable, Hashable {
    public var id: String { "\(interfaceName)-\(family.rawValue)-\(address)" }

    public let interfaceName: String
    public let address: String
    public let family: AddressFamily
    public let isLoopback: Bool

    public enum AddressFamily: String, Sendable, Equatable, Hashable {
        case ipv4
        case ipv6
    }

    public init(interfaceName: String, address: String, family: AddressFamily, isLoopback: Bool) {
        self.interfaceName = interfaceName
        self.address = address
        self.family = family
        self.isLoopback = isLoopback
    }
}

public struct NetworkThroughput: Sendable, Equatable {
    /// Bytes/sec received across non-loopback interfaces. `nil` until second sample.
    public let downloadBytesPerSecond: Double?
    /// Bytes/sec sent across non-loopback interfaces. `nil` until second sample.
    public let uploadBytesPerSecond: Double?

    public init(downloadBytesPerSecond: Double?, uploadBytesPerSecond: Double?) {
        self.downloadBytesPerSecond = downloadBytesPerSecond.map { max($0, 0) }
        self.uploadBytesPerSecond = uploadBytesPerSecond.map { max($0, 0) }
    }

    public static let unknown = NetworkThroughput(downloadBytesPerSecond: nil, uploadBytesPerSecond: nil)
}

public struct NetworkLatencySample: Sendable, Equatable {
    public let destination: String
    public let milliseconds: Double
    public let didSucceed: Bool
    public let detail: String?

    public init(destination: String, milliseconds: Double, didSucceed: Bool, detail: String? = nil) {
        self.destination = destination
        self.milliseconds = max(milliseconds, 0)
        self.didSucceed = didSucceed
        self.detail = detail
    }
}
