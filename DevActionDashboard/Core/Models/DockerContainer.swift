import Foundation

/// A Docker container as reported by `docker ps`.
public struct DockerContainer: Identifiable, Sendable, Equatable, Hashable {
    public var id: String { containerID }

    public let containerID: String
    public let name: String
    public let image: String
    public let status: String
    public let state: DockerContainerState
    public let ports: String
    public let createdAt: String
    public let cpuUsageRatio: Double?
    public let memoryUsageBytes: UInt64?
    public let memoryLimitBytes: UInt64?
    public let memoryUsageRatio: Double?

    public init(
        containerID: String,
        name: String,
        image: String,
        status: String,
        state: DockerContainerState,
        ports: String,
        createdAt: String,
        cpuUsageRatio: Double? = nil,
        memoryUsageBytes: UInt64? = nil,
        memoryLimitBytes: UInt64? = nil,
        memoryUsageRatio: Double? = nil
    ) {
        self.containerID = containerID
        self.name = name
        self.image = image
        self.status = status
        self.state = state
        self.ports = ports
        self.createdAt = createdAt
        self.cpuUsageRatio = cpuUsageRatio
        self.memoryUsageBytes = memoryUsageBytes
        self.memoryLimitBytes = memoryLimitBytes
        self.memoryUsageRatio = memoryUsageRatio
    }

    public func merging(stats: DockerContainerStats?) -> DockerContainer {
        guard let stats else { return self }
        return DockerContainer(
            containerID: containerID,
            name: name,
            image: image,
            status: status,
            state: state,
            ports: ports,
            createdAt: createdAt,
            cpuUsageRatio: stats.cpuUsageRatio,
            memoryUsageBytes: stats.memoryUsageBytes,
            memoryLimitBytes: stats.memoryLimitBytes,
            memoryUsageRatio: stats.memoryUsageRatio
        )
    }
}

public enum DockerContainerState: String, Sendable, Equatable, Hashable {
    case running
    case exited
    case created
    case paused
    case restarting
    case removing
    case dead
    case unknown

    public var title: String { rawValue.capitalized }

    public init(dockerState: String) {
        self = DockerContainerState(rawValue: dockerState.lowercased()) ?? .unknown
    }
}

public struct DockerContainerStats: Sendable, Equatable, Hashable {
    public let containerID: String
    public let cpuUsageRatio: Double?
    public let memoryUsageBytes: UInt64?
    public let memoryLimitBytes: UInt64?
    public let memoryUsageRatio: Double?

    public init(
        containerID: String,
        cpuUsageRatio: Double?,
        memoryUsageBytes: UInt64?,
        memoryLimitBytes: UInt64?,
        memoryUsageRatio: Double?
    ) {
        self.containerID = containerID
        self.cpuUsageRatio = cpuUsageRatio
        self.memoryUsageBytes = memoryUsageBytes
        self.memoryLimitBytes = memoryLimitBytes
        self.memoryUsageRatio = memoryUsageRatio
    }
}

public enum DockerControlAction: String, Sendable, Equatable {
    case start
    case stop
    case restart

    public var title: String { rawValue.capitalized }
}

public struct DockerSnapshot: Sendable, Equatable {
    public let timestamp: Date
    public let isAvailable: Bool
    public let dockerPath: String
    public let engineVersion: String?
    public let containers: [DockerContainer]
    public let availabilityMessage: String?

    public init(
        timestamp: Date = .now,
        isAvailable: Bool,
        dockerPath: String,
        engineVersion: String?,
        containers: [DockerContainer],
        availabilityMessage: String? = nil
    ) {
        self.timestamp = timestamp
        self.isAvailable = isAvailable
        self.dockerPath = dockerPath
        self.engineVersion = engineVersion
        self.containers = containers
        self.availabilityMessage = availabilityMessage
    }
}
