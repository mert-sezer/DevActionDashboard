import Darwin
import Foundation

/// Derives upload/download byte rates from `if_data` counters.
struct InterfaceThroughputSampler: Sendable {
    struct Counters: Sendable {
        let inbound: UInt64
        let outbound: UInt64
        let sampledAt: ContinuousClock.Instant
    }

    func sampleCounters() throws -> Counters {
        var ifaddrPointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPointer) == 0, let first = ifaddrPointer else {
            throw NetworkError.interfaceEnumerationFailed
        }
        defer { freeifaddrs(ifaddrPointer) }

        var inbound: UInt64 = 0
        var outbound: UInt64 = 0
        var current: UnsafeMutablePointer<ifaddrs>? = first

        while let interface = current {
            defer { current = interface.pointee.ifa_next }

            let flags = Int32(interface.pointee.ifa_flags)
            guard (flags & IFF_UP) == IFF_UP else { continue }
            guard (flags & IFF_LOOPBACK) != IFF_LOOPBACK else { continue }
            guard let addr = interface.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK) else {
                continue
            }
            guard let data = interface.pointee.ifa_data else { continue }

            let ifData = data.assumingMemoryBound(to: if_data.self).pointee
            inbound += UInt64(ifData.ifi_ibytes)
            outbound += UInt64(ifData.ifi_obytes)
        }

        return Counters(inbound: inbound, outbound: outbound, sampledAt: .now)
    }

    func throughput(previous: Counters, current: Counters) -> NetworkThroughput {
        let duration = current.sampledAt - previous.sampledAt
        let seconds = Double(duration.components.seconds)
            + Double(duration.components.attoseconds) / 1_000_000_000_000_000_000
        guard seconds > 0 else { return .unknown }

        let download = Double(current.inbound &- previous.inbound) / seconds
        let upload = Double(current.outbound &- previous.outbound) / seconds
        return NetworkThroughput(downloadBytesPerSecond: download, uploadBytesPerSecond: upload)
    }
}
