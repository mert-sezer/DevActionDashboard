import Foundation
import Testing
@testable import DevActionDashboard

@Suite("MemoryMetrics")
struct MemoryMetricsTests {
    @Test("Computes usage ratio from used and total bytes")
    func usageRatio() {
        let metrics = MemoryMetrics(
            totalBytes: 1_000,
            usedBytes: 250,
            wiredBytes: 100,
            compressedBytes: 50,
            freeBytes: 700,
            swapUsedBytes: 10,
            swapTotalBytes: 100
        )

        #expect(metrics.usageRatio == 0.25)
        #expect(metrics.swapUsageRatio == 0.1)
    }
}

@Suite("HostCPUSampler")
struct HostCPUSamplerTests {
    @Test("Derives utilization from tick deltas")
    func usageFromDeltas() {
        let sampler = HostCPUSampler()
        let previous = HostCPUSampler.TickSnapshot(user: 100, system: 50, idle: 850, nice: 0, logicalCoreCount: 8)
        let current = HostCPUSampler.TickSnapshot(user: 150, system: 70, idle: 880, nice: 0, logicalCoreCount: 8)

        // busy delta = 70, total delta = 100 → 0.7
        let ratio = sampler.usageRatio(previous: previous, current: current)
        #expect(ratio == 0.7)
    }
}

@Suite("MetricsFormatter")
struct MetricsFormatterTests {
    @Test("Formats percent and missing values")
    func percentFormatting() {
        #expect(MetricsFormatter.percent(0.42) == "42%")
        #expect(MetricsFormatter.percent(nil) == "—")
    }

    @Test("Formats uptime components")
    func uptimeFormatting() {
        let value = MetricsFormatter.uptime(90_061) // 1d 1h 1m
        #expect(value.contains("1d"))
        #expect(value.contains("1h"))
        #expect(value.contains("1m"))
    }
}

private struct StubMetricsProvider: SystemMetricsProviding {
    let snapshot: SystemMetricsSnapshot

    func sample() async throws -> SystemMetricsSnapshot {
        snapshot
    }
}

@Suite("SystemMetricsService")
@MainActor
struct SystemMetricsServiceTests {
    @Test("Stores latest snapshot from provider")
    func storesLatestSnapshot() async {
        let snapshot = SystemMetricsSnapshot(
            cpu: CPUMetrics(usageRatio: 0.2, logicalCoreCount: 8),
            memory: MemoryMetrics(
                totalBytes: 16,
                usedBytes: 8,
                wiredBytes: 2,
                compressedBytes: 1,
                freeBytes: 8,
                swapUsedBytes: 0,
                swapTotalBytes: 0
            ),
            storage: StorageMetrics(totalBytes: 100, freeBytes: 40, volumeName: "Test"),
            battery: nil,
            thermalState: .nominal,
            uptime: 120
        )

        let defaults = UserDefaults(suiteName: "SystemMetricsServiceTests.\(UUID().uuidString)")!
        let store = SettingsStore(defaults: defaults)
        let service = SystemMetricsService(
            provider: StubMetricsProvider(snapshot: snapshot),
            settingsStore: store
        )

        await service.refreshNow()

        #expect(service.latest == snapshot)
        #expect(service.lastErrorMessage == nil)
    }
}
