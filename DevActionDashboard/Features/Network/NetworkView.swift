import SwiftUI

struct NetworkView: View {
    @State private var viewModel: NetworkViewModel
    @State private var areSensitiveValuesRevealed = false

    init(viewModel: NetworkViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.snapshot == nil, viewModel.errorMessage == nil {
                CenteredLoadingView("Sampling network…")
                    .background(AppCanvasBackground())
            } else {
                FeaturePage(
                    title: "Network",
                    subtitle: "Connectivity, addressing, DNS, throughput, and latency probes."
                ) {
                    if let errorMessage = viewModel.errorMessage, viewModel.snapshot == nil {
                        ContentUnavailableView(
                            "Network unavailable",
                            systemImage: "network.slash",
                            description: Text(errorMessage)
                        )
                    }

                    if let snapshot = viewModel.snapshot {
                        statusPanel(snapshot)
                        addressingPanel(snapshot)
                        throughputPanel(snapshot.throughput)
                        latencyPanel(snapshot)
                        dnsPanel(snapshot.dnsServers)
                        interfacesPanel(viewModel.nonLoopbackInterfaces)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(
                    areSensitiveValuesRevealed ? "Hide addresses" : "Show addresses",
                    systemImage: areSensitiveValuesRevealed ? "eye.slash" : "eye"
                ) {
                    areSensitiveValuesRevealed.toggle()
                }
                .help(
                    areSensitiveValuesRevealed
                        ? "Hide IP addresses and other sensitive network details"
                        : "Show IP addresses and other sensitive network details"
                )
                .accessibilityHint("Toggles visibility of IP addresses")
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Refresh", systemImage: "arrow.clockwise") {
                    viewModel.refresh()
                }
                .disabled(viewModel.isRefreshing)
                .help("Refresh network snapshot")
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    private func statusPanel(_ snapshot: NetworkSnapshot) -> some View {
        GlassPanel {
            Text("Internet")
                .font(DesignTokens.Typography.title)
                .accessibilityAddTraits(.isHeader)

            MetadataRow(label: "Status", value: snapshot.path.statusDescription)
            MetadataRow(label: "Expensive", value: snapshot.path.isExpensive ? "Yes" : "No")
            MetadataRow(label: "Constrained", value: snapshot.path.isConstrained ? "Yes" : "No")
            MetadataRow(
                label: "Sampled",
                value: snapshot.timestamp.formatted(date: .omitted, time: .standard),
                monospaced: true
            )
        }
    }

    private func addressingPanel(_ snapshot: NetworkSnapshot) -> some View {
        GlassPanel {
            Text("Addresses")
                .font(DesignTokens.Typography.title)
                .accessibilityAddTraits(.isHeader)

            MetadataRow(
                label: "Local IPv4",
                value: snapshot.primaryIPv4 ?? "—",
                monospaced: true,
                isSensitive: true,
                isRevealed: $areSensitiveValuesRevealed
            )
            MetadataRow(
                label: "Local IPv6",
                value: snapshot.primaryIPv6 ?? "—",
                monospaced: true,
                isSensitive: true,
                isRevealed: $areSensitiveValuesRevealed
            )
            MetadataRow(
                label: "Public IP",
                value: snapshot.publicIP ?? "—",
                monospaced: true,
                isSensitive: true,
                isRevealed: $areSensitiveValuesRevealed
            )
        }
    }

    private func throughputPanel(_ throughput: NetworkThroughput) -> some View {
        GlassPanel {
            Text("Throughput")
                .font(DesignTokens.Typography.title)
                .accessibilityAddTraits(.isHeader)

            MetadataRow(
                label: "Download",
                value: MetricsFormatter.bytesPerSecond(throughput.downloadBytesPerSecond),
                monospaced: true
            )
            MetadataRow(
                label: "Upload",
                value: MetricsFormatter.bytesPerSecond(throughput.uploadBytesPerSecond),
                monospaced: true
            )
        }
    }

    private func latencyPanel(_ snapshot: NetworkSnapshot) -> some View {
        GlassPanel {
            Text("Latency")
                .font(DesignTokens.Typography.title)
                .accessibilityAddTraits(.isHeader)

            if let https = snapshot.httpsLatency {
                MetadataRow(
                    label: "HTTPS",
                    value: latencyText(https),
                    monospaced: true
                )
            }
            if let tcp = snapshot.tcpProbeLatency {
                MetadataRow(
                    label: "TCP ping",
                    value: latencyText(tcp),
                    monospaced: true
                )
            }
        }
    }

    private func dnsPanel(_ servers: [String]) -> some View {
        GlassPanel {
            Text("DNS")
                .font(DesignTokens.Typography.title)
                .accessibilityAddTraits(.isHeader)

            if servers.isEmpty {
                Text("No DNS servers reported by the system.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(servers.enumerated()), id: \.offset) { index, server in
                    MetadataRow(
                        label: "Server \(index + 1)",
                        value: server,
                        monospaced: true,
                        isSensitive: true,
                        isRevealed: $areSensitiveValuesRevealed
                    )
                }
            }
        }
    }

    private func interfacesPanel(_ interfaces: [NetworkInterfaceAddress]) -> some View {
        GlassPanel {
            Text("Interfaces")
                .font(DesignTokens.Typography.title)
                .accessibilityAddTraits(.isHeader)

            if interfaces.isEmpty {
                Text("No active non-loopback addresses.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(interfaces) { item in
                    MetadataRow(
                        label: "\(item.interfaceName) · \(item.family.rawValue.uppercased())",
                        value: item.address,
                        monospaced: true,
                        isSensitive: true,
                        isRevealed: $areSensitiveValuesRevealed
                    )
                }
            }
        }
    }

    private func latencyText(_ sample: NetworkLatencySample) -> String {
        let value = MetricsFormatter.milliseconds(sample.milliseconds)
        let mark = sample.didSucceed ? "ok" : "fail"
        if let detail = sample.detail {
            return "\(value) (\(mark)) · \(sample.destination) · \(detail)"
        }
        return "\(value) (\(mark)) · \(sample.destination)"
    }
}
