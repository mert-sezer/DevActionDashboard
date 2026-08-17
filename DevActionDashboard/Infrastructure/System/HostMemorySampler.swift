import Darwin
import Foundation

/// Samples physical memory and swap via Mach VM statistics and `vm.swapusage`.
struct HostMemorySampler: Sendable {
    func sample() throws -> MemoryMetrics {
        let pageSize = UInt64(sysconf(_SC_PAGESIZE))
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
        )

        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, rebound, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            throw MetricsError.hostStatisticsUnavailable("HOST_VM_INFO64 (\(result))")
        }

        let totalBytes = ProcessInfo.processInfo.physicalMemory
        let freeBytes = UInt64(stats.free_count) * pageSize
        let wiredBytes = UInt64(stats.wire_count) * pageSize
        let compressedBytes = UInt64(stats.compressor_page_count) * pageSize
        let activeBytes = UInt64(stats.active_count) * pageSize

        // Activity Monitor–style “used”: active + wired + compressed.
        let usedBytes = min(activeBytes &+ wiredBytes &+ compressedBytes, totalBytes)

        let swap = swapUsage()

        return MemoryMetrics(
            totalBytes: totalBytes,
            usedBytes: usedBytes,
            wiredBytes: wiredBytes,
            compressedBytes: compressedBytes,
            freeBytes: freeBytes,
            swapUsedBytes: swap.used,
            swapTotalBytes: swap.total
        )
    }

    private func swapUsage() -> (used: UInt64, total: UInt64) {
        var usage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        let status = sysctlbyname("vm.swapusage", &usage, &size, nil, 0)
        guard status == 0 else {
            return (0, 0)
        }
        return (UInt64(usage.xsu_used), UInt64(usage.xsu_total))
    }
}
