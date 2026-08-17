import AppKit
import Foundation
import Observation

/// A live status line derived from host metrics and network state.
struct SystemStatusEvent: Identifiable, Equatable, Sendable {
    enum Level: String, Sendable {
        case info = "INFO"
        case warn = "WARN"
    }

    let id: String
    let timestamp: Date
    let level: Level
    let message: String
}

@MainActor
@Observable
final class SystemViewModel {
    private let metricsService: SystemMetricsService
    private let networkService: NetworkService
    private let processInfo: ProcessInfo

    private(set) var hostName: String
    private(set) var operatingSystemVersion: String
    private(set) var architecture: String
    private(set) var kernelVersion: String
    private(set) var processorSummary: String
    private(set) var architectureDetail: String

    var snapshot: SystemMetricsSnapshot? { metricsService.latest }
    var networkSnapshot: NetworkSnapshot? { networkService.latest }
    var errorMessage: String? { metricsService.lastErrorMessage }
    var isRefreshing: Bool { metricsService.isRefreshing || networkService.isRefreshing }

    var localIP: String {
        networkSnapshot?.primaryIPv4 ?? "—"
    }

    var primaryInterfaceHint: String {
        guard let iface = networkSnapshot?.interfaces.first(where: {
            !$0.isLoopback && $0.family == .ipv4
        }) else {
            return "No active IPv4"
        }
        return "\(iface.interfaceName) interface"
    }

    var statusEvents: [SystemStatusEvent] {
        Self.makeStatusEvents(
            snapshot: snapshot,
            network: networkSnapshot,
            hostName: hostName
        )
    }

    init(
        metricsService: SystemMetricsService,
        networkService: NetworkService,
        processInfo: ProcessInfo = .processInfo
    ) {
        self.metricsService = metricsService
        self.networkService = networkService
        self.processInfo = processInfo

        hostName = processInfo.hostName
        operatingSystemVersion = Self.formatOSVersion(processInfo.operatingSystemVersion)
        architecture = Self.currentArchitecture()
        architectureDetail = Self.architectureDetail()
        kernelVersion = Self.readKernelVersion()
        processorSummary = Self.readProcessorSummary(logicalCores: ProcessInfo.processInfo.activeProcessorCount)
    }

    func onAppear() {
        metricsService.startMonitoring()
        networkService.startMonitoring()
        refreshIdentity()
    }

    func onDisappear() {
        metricsService.stopMonitoring()
        networkService.stopMonitoring()
    }

    func refresh() {
        refreshIdentity()
        Task {
            await metricsService.refreshNow()
            await networkService.refreshNow()
        }
    }

    func copyFullReport() {
        let report = buildFullReport()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
        AppLog.system.info("System full report copied to clipboard")
    }

    private func refreshIdentity() {
        hostName = processInfo.hostName
        operatingSystemVersion = Self.formatOSVersion(processInfo.operatingSystemVersion)
        architecture = Self.currentArchitecture()
        architectureDetail = Self.architectureDetail()
        kernelVersion = Self.readKernelVersion()
        let cores = snapshot?.cpu.logicalCoreCount ?? processInfo.activeProcessorCount
        processorSummary = Self.readProcessorSummary(logicalCores: cores)
    }

    private func buildFullReport() -> String {
        var lines: [String] = [
            "Dev Action Dashboard — System Report",
            "Generated: \(Date().formatted(date: .abbreviated, time: .standard))",
            "",
            "Host: \(hostName)",
            "OS: macOS \(operatingSystemVersion)",
            "Kernel: \(kernelVersion)",
            "Architecture: \(architecture) (\(architectureDetail))",
            "Processor: \(processorSummary)",
            "Local IP: \(localIP) (\(primaryInterfaceHint))"
        ]

        if let snapshot {
            lines += [
                "Uptime: \(MetricsFormatter.uptime(snapshot.uptime))",
                "Thermal: \(snapshot.thermalState.title)",
                "CPU: \(MetricsFormatter.percent(snapshot.cpu.usageRatio)) · \(snapshot.cpu.logicalCoreCount) logical cores",
                "Memory: \(MetricsFormatter.bytes(snapshot.memory.usedBytes)) / \(MetricsFormatter.bytes(snapshot.memory.totalBytes))",
                "Storage (\(snapshot.storage.volumeName)): \(MetricsFormatter.bytes(snapshot.storage.usedBytes)) / \(MetricsFormatter.bytes(snapshot.storage.totalBytes))"
            ]
            if let battery = snapshot.battery {
                lines.append(
                    "Battery: \(MetricsFormatter.percent(battery.chargeRatio)) · \(battery.isACPowered ? "AC" : "Battery") · charging=\(battery.isCharging)"
                )
            }
        }

        lines.append("")
        lines.append("Status events:")
        for event in statusEvents {
            let time = event.timestamp.formatted(date: .omitted, time: .standard)
            lines.append("\(time) [\(event.level.rawValue)] \(event.message)")
        }

        return lines.joined(separator: "\n")
    }

    private static func makeStatusEvents(
        snapshot: SystemMetricsSnapshot?,
        network: NetworkSnapshot?,
        hostName: String
    ) -> [SystemStatusEvent] {
        guard let snapshot else { return [] }

        var events: [SystemStatusEvent] = []

        events.append(
            SystemStatusEvent(
                id: "sample",
                timestamp: snapshot.timestamp,
                level: .info,
                message: "Metrics sample · host \(hostName)"
            )
        )

        if let ratio = snapshot.cpu.usageRatio {
            events.append(
                SystemStatusEvent(
                    id: "cpu",
                    timestamp: snapshot.timestamp.addingTimeInterval(-1),
                    level: ratio >= 0.85 ? .warn : .info,
                    message: "CPU utilization \(MetricsFormatter.percent(ratio)) across \(snapshot.cpu.logicalCoreCount) logical cores"
                )
            )
        }

        let memRatio = snapshot.memory.usageRatio
        events.append(
            SystemStatusEvent(
                id: "memory",
                timestamp: snapshot.timestamp.addingTimeInterval(-2),
                level: memRatio >= 0.85 ? .warn : .info,
                message: memRatio >= 0.85
                    ? "Memory pressure elevated · \(MetricsFormatter.percent(memRatio)) used (\(MetricsFormatter.bytes(snapshot.memory.usedBytes)))"
                    : "Memory \(MetricsFormatter.bytes(snapshot.memory.usedBytes)) / \(MetricsFormatter.bytes(snapshot.memory.totalBytes))"
            )
        )

        if snapshot.thermalState != .nominal {
            events.append(
                SystemStatusEvent(
                    id: "thermal",
                    timestamp: snapshot.timestamp.addingTimeInterval(-3),
                    level: .warn,
                    message: "Thermal state \(snapshot.thermalState.title.lowercased())"
                )
            )
        }

        if let ip = network?.primaryIPv4 {
            events.append(
                SystemStatusEvent(
                    id: "network",
                    timestamp: snapshot.timestamp.addingTimeInterval(-4),
                    level: .info,
                    message: "Primary IPv4 \(ip) · \(network?.path.statusDescription ?? "path ok")"
                )
            )
        }

        events.append(
            SystemStatusEvent(
                id: "storage",
                timestamp: snapshot.timestamp.addingTimeInterval(-5),
                level: snapshot.storage.usageRatio >= 0.9 ? .warn : .info,
                message: "Volume \(snapshot.storage.volumeName) · \(MetricsFormatter.bytes(snapshot.storage.usedBytes)) used of \(MetricsFormatter.bytes(snapshot.storage.totalBytes))"
            )
        )

        return events.sorted { $0.timestamp > $1.timestamp }
    }

    private static func formatOSVersion(_ version: OperatingSystemVersion) -> String {
        "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    private static func currentArchitecture() -> String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "unknown"
        #endif
    }

    private static func architectureDetail() -> String {
        #if arch(arm64)
        return "Apple Silicon"
        #elseif arch(x86_64)
        return "Intel"
        #else
        return "Unknown"
        #endif
    }

    private static func readKernelVersion() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let release = withUnsafePointer(to: &systemInfo.release) {
            $0.withMemoryRebound(to: CChar.self, capacity: 256) {
                String(cString: $0)
            }
        }
        return release.isEmpty ? "—" : "Darwin \(release)"
    }

    private static func readProcessorSummary(logicalCores: Int) -> String {
        if let brand = sysctlString("machdep.cpu.brand_string"), !brand.isEmpty {
            return brand
        }
        if let model = sysctlString("hw.model"), !model.isEmpty {
            return "\(model) · \(logicalCores)-core"
        }
        return "\(logicalCores) logical cores · \(currentArchitecture())"
    }

    private static func sysctlString(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
        return String(cString: buffer)
    }
}
