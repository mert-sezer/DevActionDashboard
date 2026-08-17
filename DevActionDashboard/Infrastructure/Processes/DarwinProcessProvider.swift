import Darwin
import Foundation

/// Samples the process table via `libproc` / `proc_pidinfo`.
actor DarwinProcessProvider: ProcessProviding {
    private struct CPUSample {
        let userTime: UInt64
        let systemTime: UInt64
        let sampledAt: ContinuousClock.Instant
    }

    private var previousCPU: [Int32: CPUSample] = [:]

    func listProcesses() async throws -> ProcessListSnapshot {
        let pids = try Self.allPIDs()
        let now = ContinuousClock.now
        var processes: [RunningProcess] = []
        processes.reserveCapacity(pids.count)

        var nextCPU: [Int32: CPUSample] = [:]

        for pid in pids {
            guard let details = Self.details(for: pid) else { continue }

            let cpuSample = CPUSample(
                userTime: details.userTime,
                systemTime: details.systemTime,
                sampledAt: now
            )
            nextCPU[pid] = cpuSample

            let cpuRatio: Double?
            if let previous = previousCPU[pid] {
                cpuRatio = Self.cpuUsageRatio(previous: previous, current: cpuSample)
            } else {
                cpuRatio = nil
            }

            processes.append(
                RunningProcess(
                    pid: pid,
                    name: details.name,
                    path: details.path,
                    userID: details.userID,
                    cpuUsageRatio: cpuRatio,
                    residentMemoryBytes: details.residentMemoryBytes,
                    threadCount: details.threadCount
                )
            )
        }

        previousCPU = nextCPU
        return ProcessListSnapshot(processes: processes)
    }

    func terminateProcess(pid: Int32, force: Bool) async throws {
        guard pid > 1 else {
            throw ProcessError.protectedProcess(pid)
        }
        guard pid != getpid() else {
            throw ProcessError.protectedProcess(pid)
        }

        let signal = force ? SIGKILL : SIGTERM
        let result = kill(pid, signal)
        if result == 0 {
            AppLog.processes.info("Sent \(force ? "SIGKILL" : "SIGTERM", privacy: .public) to pid \(pid)")
            return
        }

        switch errno {
        case ESRCH:
            throw ProcessError.processNotFound(pid)
        case EPERM:
            throw ProcessError.terminationDenied(pid)
        default:
            let message = String(cString: strerror(errno))
            throw ProcessError.terminationFailed(pid, message)
        }
    }

    // MARK: - Private

    private static func allPIDs() throws -> [pid_t] {
        let bufferSize = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard bufferSize > 0 else {
            throw ProcessError.enumerationFailed("proc_listpids size query failed")
        }

        let capacity = Int(bufferSize) / MemoryLayout<pid_t>.stride
        var pids = [pid_t](repeating: 0, count: capacity)
        let written = pids.withUnsafeMutableBufferPointer { pointer in
            proc_listpids(UInt32(PROC_ALL_PIDS), 0, pointer.baseAddress, bufferSize)
        }
        guard written > 0 else {
            throw ProcessError.enumerationFailed("proc_listpids returned no data")
        }

        let count = Int(written) / MemoryLayout<pid_t>.stride
        return Array(pids.prefix(count)).filter { $0 > 0 }
    }

    private struct ProcessDetails {
        let name: String
        let path: String?
        let userID: UInt32
        let residentMemoryBytes: UInt64
        let threadCount: Int
        let userTime: UInt64
        let systemTime: UInt64
    }

    private static func details(for pid: pid_t) -> ProcessDetails? {
        var info = proc_taskallinfo()
        let size = Int32(MemoryLayout<proc_taskallinfo>.stride)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            proc_pidinfo(pid, PROC_PIDTASKALLINFO, 0, pointer, size)
        }
        guard result == size else { return nil }

        let name = withUnsafeBytes(of: info.pbsd.pbi_comm) { rawBuffer in
            let bytes = rawBuffer.prefix { $0 != 0 }
            return String(decoding: bytes, as: UTF8.self)
        }

        guard !name.isEmpty else { return nil }

        return ProcessDetails(
            name: name,
            path: path(for: pid),
            userID: info.pbsd.pbi_uid,
            residentMemoryBytes: info.ptinfo.pti_resident_size,
            threadCount: Int(info.ptinfo.pti_threadnum),
            userTime: info.ptinfo.pti_total_user,
            systemTime: info.ptinfo.pti_total_system
        )
    }

    private static func path(for pid: pid_t) -> String? {
        // libproc.h: PROC_PIDPATHINFO_MAXSIZE == 4 * MAXPATHLEN (not always imported into Swift).
        let maxSize = 4 * Int(MAXPATHLEN)
        var buffer = [CChar](repeating: 0, count: maxSize)
        let result = buffer.withUnsafeMutableBufferPointer { pointer in
            proc_pidpath(pid, pointer.baseAddress, UInt32(maxSize))
        }
        guard result > 0 else { return nil }
        return String(cString: buffer)
    }

    /// `pti_total_user` / `pti_total_system` are nanoseconds of CPU time.
    /// Result is fraction of a single logical core (`1.0` == 100%).
    private static func cpuUsageRatio(previous: CPUSample, current: CPUSample) -> Double? {
        let cpuDeltaNanos = Double(
            (current.userTime &- previous.userTime) &+ (current.systemTime &- previous.systemTime)
        )
        let duration = current.sampledAt - previous.sampledAt
        let elapsedNanos = Double(duration.components.seconds) * 1_000_000_000
            + Double(duration.components.attoseconds) / 1_000_000_000
        guard elapsedNanos > 0 else { return nil }
        return cpuDeltaNanos / elapsedNanos
    }
}
