import Foundation
import Testing
@testable import DevActionDashboard

@Suite("NetworkThroughput")
struct NetworkThroughputTests {
    @Test("Clamps negative rates and preserves values")
    func clampsRates() {
        let throughput = NetworkThroughput(downloadBytesPerSecond: 2_000, uploadBytesPerSecond: 1_000)
        #expect(throughput.downloadBytesPerSecond == 2_000)
        #expect(throughput.uploadBytesPerSecond == 1_000)
    }
}

@Suite("InterfaceAddressSampler helpers")
struct InterfaceAddressSamplerTests {
    @Test("Picks primary non-loopback IPv4 and skips link-local IPv6")
    func primaryAddresses() {
        let sampler = InterfaceAddressSampler()
        let interfaces = [
            NetworkInterfaceAddress(interfaceName: "lo0", address: "127.0.0.1", family: .ipv4, isLoopback: true),
            NetworkInterfaceAddress(interfaceName: "en0", address: "192.168.1.20", family: .ipv4, isLoopback: false),
            NetworkInterfaceAddress(interfaceName: "en0", address: "fe80::1", family: .ipv6, isLoopback: false),
            NetworkInterfaceAddress(interfaceName: "en0", address: "2001:db8::1", family: .ipv6, isLoopback: false)
        ]

        #expect(sampler.primaryIPv4(from: interfaces) == "192.168.1.20")
        #expect(sampler.primaryIPv6(from: interfaces) == "2001:db8::1")
    }
}

@Suite("MetricsFormatter network")
struct MetricsFormatterNetworkTests {
    @Test("Formats bytes/sec and milliseconds")
    func formatting() {
        #expect(MetricsFormatter.bytesPerSecond(nil) == "—")
        #expect(MetricsFormatter.milliseconds(nil) == "—")
        #expect(MetricsFormatter.milliseconds(12) == "12 ms")
        #expect(!MetricsFormatter.bytesPerSecond(2_048).isEmpty)
    }
}

@Suite("NetworkService")
@MainActor
struct NetworkServiceTests {
    @Test("Stores latest snapshot from provider")
    func storesLatest() async {
        let snapshot = NetworkSnapshot(
            path: NetworkPathStatus(
                isSatisfied: true,
                isExpensive: false,
                isConstrained: false,
                usesWiFi: true,
                usesWired: false,
                usesCellular: false,
                statusDescription: "Online · Wi‑Fi"
            ),
            interfaces: [],
            primaryIPv4: "10.0.0.2",
            primaryIPv6: nil,
            publicIP: "1.2.3.4",
            dnsServers: ["1.1.1.1"],
            throughput: NetworkThroughput(downloadBytesPerSecond: 100, uploadBytesPerSecond: 50),
            httpsLatency: NetworkLatencySample(destination: "captive.apple.com", milliseconds: 30, didSucceed: true),
            tcpProbeLatency: NetworkLatencySample(destination: "1.1.1.1:443", milliseconds: 12, didSucceed: true)
        )

        let defaults = UserDefaults(suiteName: "NetworkServiceTests.\(UUID().uuidString)")!
        let service = NetworkService(
            provider: StubNetworkProvider(snapshot: snapshot),
            settingsStore: SettingsStore(defaults: defaults)
        )

        await service.refreshNow()

        #expect(service.latest == snapshot)
        #expect(service.lastErrorMessage == nil)
    }
}

private struct StubNetworkProvider: NetworkProviding {
    let snapshot: NetworkSnapshot

    func sample() async throws -> NetworkSnapshot {
        snapshot
    }
}
