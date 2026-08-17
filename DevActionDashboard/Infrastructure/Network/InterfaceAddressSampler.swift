import Darwin
import Foundation

/// Enumerates local IPv4/IPv6 addresses via `getifaddrs`.
struct InterfaceAddressSampler: Sendable {
    func sample() throws -> [NetworkInterfaceAddress] {
        var ifaddrPointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPointer) == 0, let first = ifaddrPointer else {
            throw NetworkError.interfaceEnumerationFailed
        }
        defer { freeifaddrs(ifaddrPointer) }

        var results: [NetworkInterfaceAddress] = []
        var current: UnsafeMutablePointer<ifaddrs>? = first

        while let interface = current {
            defer { current = interface.pointee.ifa_next }

            let flags = Int32(interface.pointee.ifa_flags)
            guard (flags & IFF_UP) == IFF_UP else { continue }
            guard let addr = interface.pointee.ifa_addr else { continue }

            let family = addr.pointee.sa_family
            guard family == UInt8(AF_INET) || family == UInt8(AF_INET6) else { continue }

            let name = String(cString: interface.pointee.ifa_name)
            let isLoopback = (flags & IFF_LOOPBACK) == IFF_LOOPBACK
            var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))

            let result = getnameinfo(
                addr,
                socklen_t(addr.pointee.sa_len),
                &hostBuffer,
                socklen_t(hostBuffer.count),
                nil,
                0,
                NI_NUMERICHOST
            )
            guard result == 0 else { continue }

            let address = String(cString: hostBuffer)
            // Drop IPv6 zone index (`fe80::1%en0` → `fe80::1`).
            let cleaned = address.split(separator: "%").first.map(String.init) ?? address

            results.append(
                NetworkInterfaceAddress(
                    interfaceName: name,
                    address: cleaned,
                    family: family == UInt8(AF_INET) ? .ipv4 : .ipv6,
                    isLoopback: isLoopback
                )
            )
        }

        return results.sorted { lhs, rhs in
            if lhs.isLoopback != rhs.isLoopback { return !lhs.isLoopback && rhs.isLoopback }
            if lhs.interfaceName != rhs.interfaceName {
                return lhs.interfaceName < rhs.interfaceName
            }
            return lhs.address < rhs.address
        }
    }

    func primaryIPv4(from interfaces: [NetworkInterfaceAddress]) -> String? {
        interfaces.first { !$0.isLoopback && $0.family == .ipv4 }?.address
    }

    func primaryIPv6(from interfaces: [NetworkInterfaceAddress]) -> String? {
        interfaces.first {
            !$0.isLoopback
                && $0.family == .ipv6
                && !$0.address.lowercased().hasPrefix("fe80")
        }?.address
    }
}
