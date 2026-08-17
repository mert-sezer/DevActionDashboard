import Foundation

/// Composes Darwin / Network / SystemConfiguration samplers into one snapshot.
actor CompositeNetworkProvider: NetworkProviding {
    private let pathSampler = NetworkPathSampler()
    private let addressSampler = InterfaceAddressSampler()
    private let throughputSampler = InterfaceThroughputSampler()
    private let dnsSampler = DNSConfigurationSampler()
    private let publicIPClient = PublicIPClient()
    private let latencyProber = NetworkLatencyProber()

    private var previousCounters: InterfaceThroughputSampler.Counters?
    private var cachedPublicIP: String?

    func sample() async throws -> NetworkSnapshot {
        let path = pathSampler.currentStatus()
        let interfaces = try addressSampler.sample()
        let counters = try throughputSampler.sampleCounters()

        let throughput: NetworkThroughput
        if let previous = previousCounters {
            throughput = throughputSampler.throughput(previous: previous, current: counters)
        } else {
            throughput = .unknown
        }
        previousCounters = counters

        async let httpsLatency = latencyProber.probeHTTPS()
        async let tcpLatency = latencyProber.probeTCP()
        async let publicIP = fetchPublicIPIfNeeded(pathSatisfied: path.isSatisfied)

        return NetworkSnapshot(
            path: path,
            interfaces: interfaces,
            primaryIPv4: addressSampler.primaryIPv4(from: interfaces),
            primaryIPv6: addressSampler.primaryIPv6(from: interfaces),
            publicIP: await publicIP,
            dnsServers: dnsSampler.sample(),
            throughput: throughput,
            httpsLatency: await httpsLatency,
            tcpProbeLatency: await tcpLatency
        )
    }

    private func fetchPublicIPIfNeeded(pathSatisfied: Bool) async -> String? {
        guard pathSatisfied else { return cachedPublicIP }

        do {
            let ip = try await publicIPClient.fetchPublicIP()
            cachedPublicIP = ip
            return ip
        } catch {
            AppLog.network.error("Public IP lookup failed: \(error.localizedDescription, privacy: .public)")
            return cachedPublicIP
        }
    }
}
