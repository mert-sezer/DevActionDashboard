import Foundation

/// Darwin-backed metrics provider. CPU utilization needs two samples; the first may return `usageRatio == nil`.
actor DarwinSystemMetricsProvider: SystemMetricsProviding {
    private let cpuSampler = HostCPUSampler()
    private let memorySampler = HostMemorySampler()
    private let storageSampler = StorageSampler()
    private let batterySampler = BatterySampler()

    private var previousCPUTicks: HostCPUSampler.TickSnapshot?

    func sample() async throws -> SystemMetricsSnapshot {
        let currentTicks = try cpuSampler.sampleTicks()
        let usageRatio: Double?
        if let previous = previousCPUTicks {
            usageRatio = cpuSampler.usageRatio(previous: previous, current: currentTicks)
        } else {
            usageRatio = nil
        }
        previousCPUTicks = currentTicks

        let memory = try memorySampler.sample()
        let storage = try storageSampler.sample()
        let battery = batterySampler.sample()
        let thermal = SystemThermalState(processInfoThermalState: ProcessInfo.processInfo.thermalState)

        return SystemMetricsSnapshot(
            cpu: CPUMetrics(
                usageRatio: usageRatio,
                logicalCoreCount: currentTicks.logicalCoreCount
            ),
            memory: memory,
            storage: storage,
            battery: battery,
            thermalState: thermal,
            uptime: ProcessInfo.processInfo.systemUptime
        )
    }
}
