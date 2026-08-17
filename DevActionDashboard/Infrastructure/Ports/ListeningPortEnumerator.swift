import Darwin
import Foundation

/// Enumerates TCP sockets in the LISTEN state via `libproc`.
struct ListeningPortEnumerator: Sendable {
    func enumerate() throws -> [ListeningSocket] {
        let pids = try allPIDs()
        var sockets: [ListeningSocket] = []
        sockets.reserveCapacity(64)

        for pid in pids {
            guard let process = processIdentity(for: pid) else { continue }
            let fds = listFileDescriptors(for: pid)
            for fd in fds where fd.proc_fdtype == PROX_FDTYPE_SOCKET {
                guard let listener = listeningSocket(pid: pid, fd: fd.proc_fd, process: process) else {
                    continue
                }
                sockets.append(listener)
            }
        }

        // Deduplicate identical bind addresses/ports (multiple FDs can report the same listen).
        var unique = Set<ListeningSocket>()
        for socket in sockets {
            unique.insert(socket)
        }

        return unique.sorted { lhs, rhs in
            if lhs.port != rhs.port { return lhs.port < rhs.port }
            return lhs.pid < rhs.pid
        }
    }

    private func allPIDs() throws -> [pid_t] {
        let bufferSize = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard bufferSize > 0 else {
            throw PortError.enumerationFailed("proc_listpids size query failed")
        }

        let capacity = Int(bufferSize) / MemoryLayout<pid_t>.stride
        var pids = [pid_t](repeating: 0, count: capacity)
        let written = pids.withUnsafeMutableBufferPointer { pointer in
            proc_listpids(UInt32(PROC_ALL_PIDS), 0, pointer.baseAddress, bufferSize)
        }
        guard written > 0 else {
            throw PortError.enumerationFailed("proc_listpids returned no data")
        }

        let count = Int(written) / MemoryLayout<pid_t>.stride
        return Array(pids.prefix(count)).filter { $0 > 0 }
    }

    private struct ProcessIdentity {
        let name: String
        let path: String?
    }

    private func processIdentity(for pid: pid_t) -> ProcessIdentity? {
        var info = proc_taskallinfo()
        let size = Int32(MemoryLayout<proc_taskallinfo>.stride)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            proc_pidinfo(pid, PROC_PIDTASKALLINFO, 0, pointer, size)
        }
        guard result == size else { return nil }

        let name = withUnsafeBytes(of: info.pbsd.pbi_comm) { rawBuffer in
            String(decoding: rawBuffer.prefix { $0 != 0 }, as: UTF8.self)
        }
        guard !name.isEmpty else { return nil }

        return ProcessIdentity(name: name, path: path(for: pid))
    }

    private func path(for pid: pid_t) -> String? {
        let maxSize = 4 * Int(MAXPATHLEN)
        var buffer = [CChar](repeating: 0, count: maxSize)
        let result = buffer.withUnsafeMutableBufferPointer { pointer in
            proc_pidpath(pid, pointer.baseAddress, UInt32(maxSize))
        }
        guard result > 0 else { return nil }
        return String(cString: buffer)
    }

    private func listFileDescriptors(for pid: pid_t) -> [proc_fdinfo] {
        let bufferSize = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, nil, 0)
        guard bufferSize > 0 else { return [] }

        let count = Int(bufferSize) / MemoryLayout<proc_fdinfo>.stride
        var fds = [proc_fdinfo](repeating: proc_fdinfo(), count: count)
        let written = fds.withUnsafeMutableBufferPointer { pointer in
            proc_pidinfo(pid, PROC_PIDLISTFDS, 0, pointer.baseAddress, bufferSize)
        }
        guard written > 0 else { return [] }
        let actualCount = Int(written) / MemoryLayout<proc_fdinfo>.stride
        return Array(fds.prefix(actualCount))
    }

    private func listeningSocket(pid: pid_t, fd: Int32, process: ProcessIdentity) -> ListeningSocket? {
        var info = socket_fdinfo()
        let size = Int32(MemoryLayout<socket_fdinfo>.stride)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            proc_pidfdinfo(pid, fd, PROC_PIDFDSOCKETINFO, pointer, size)
        }
        guard result == size else { return nil }

        let socket = info.psi
        guard socket.soi_kind == SOCKINFO_TCP else { return nil }

        let tcp = socket.soi_proto.pri_tcp
        guard tcp.tcpsi_state == TSI_S_LISTEN else { return nil }

        let port = UInt16(bigEndian: UInt16(truncatingIfNeeded: tcp.tcpsi_ini.insi_lport))
        guard port > 0 else { return nil }

        let address = formattedAddress(from: tcp.tcpsi_ini)
        return ListeningSocket(
            port: port,
            address: address,
            pid: pid,
            processName: process.name,
            processPath: process.path
        )
    }

    private func formattedAddress(from info: in_sockinfo) -> String {
        if (info.insi_vflag & UInt8(INI_IPV4)) != 0 {
            var addr = info.insi_laddr.ina_46.i46a_addr4
            var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            inet_ntop(AF_INET, &addr, &buffer, socklen_t(INET_ADDRSTRLEN))
            let text = String(cString: buffer)
            return text.isEmpty ? "0.0.0.0" : text
        }

        if (info.insi_vflag & UInt8(INI_IPV6)) != 0 {
            var addr = info.insi_laddr.ina_6
            var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
            inet_ntop(AF_INET6, &addr, &buffer, socklen_t(INET6_ADDRSTRLEN))
            let text = String(cString: buffer)
            return text.isEmpty ? "::" : text
        }

        return "*"
    }
}
