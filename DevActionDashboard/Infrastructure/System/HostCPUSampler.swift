import Darwin
import Foundation

/// Samples aggregate CPU load via `host_processor_info`.
/// Requires two samples to compute a utilization ratio.
struct HostCPUSampler: Sendable {
    struct TickSnapshot: Sendable {
        let user: UInt64
        let system: UInt64
        let idle: UInt64
        let nice: UInt64
        let logicalCoreCount: Int

        var total: UInt64 { user &+ system &+ idle &+ nice }
    }

    func sampleTicks() throws -> TickSnapshot {
        var processorCount: natural_t = 0
        var cpuInfoArray: processor_info_array_t?
        var cpuInfoCount: mach_msg_type_number_t = 0

        let kr = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &cpuInfoArray,
            &cpuInfoCount
        )

        guard kr == KERN_SUCCESS, let cpuInfoArray else {
            throw MetricsError.cpuSampleUnavailable
        }

        defer {
            let size = vm_size_t(cpuInfoCount) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfoArray), size)
        }

        let coreCount = Int(processorCount)
        guard coreCount > 0 else {
            throw MetricsError.cpuSampleUnavailable
        }

        var user: UInt64 = 0
        var system: UInt64 = 0
        var idle: UInt64 = 0
        var nice: UInt64 = 0

        for core in 0..<coreCount {
            let base = core * Int(CPU_STATE_MAX)
            user += UInt64(cpuInfoArray[base + Int(CPU_STATE_USER)])
            system += UInt64(cpuInfoArray[base + Int(CPU_STATE_SYSTEM)])
            idle += UInt64(cpuInfoArray[base + Int(CPU_STATE_IDLE)])
            nice += UInt64(cpuInfoArray[base + Int(CPU_STATE_NICE)])
        }

        return TickSnapshot(
            user: user,
            system: system,
            idle: idle,
            nice: nice,
            logicalCoreCount: coreCount
        )
    }

    func usageRatio(previous: TickSnapshot, current: TickSnapshot) -> Double? {
        let userDelta = current.user &- previous.user
        let systemDelta = current.system &- previous.system
        let idleDelta = current.idle &- previous.idle
        let niceDelta = current.nice &- previous.nice
        let totalDelta = userDelta &+ systemDelta &+ idleDelta &+ niceDelta

        guard totalDelta > 0 else { return nil }

        let busy = userDelta &+ systemDelta &+ niceDelta
        return Double(busy) / Double(totalDelta)
    }
}
