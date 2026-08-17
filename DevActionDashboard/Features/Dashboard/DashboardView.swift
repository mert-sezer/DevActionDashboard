import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @State private var areSensitiveValuesRevealed = false

    init(viewModel: DashboardViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        FeaturePage(
            title: "Overview",
            subtitle: "Host overview and live system pressure."
        ) {
            if let snapshot = viewModel.snapshot {
                metricsGrid(snapshot)
            } else if let metricsError = viewModel.metricsError {
                GlassPanel {
                    Label(metricsError, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(DesignTokens.Colors.tertiary)
                }
            } else {
                CenteredLoadingView("Sampling host…")
                    .frame(minHeight: 160)
            }

            bentoRow

            GlassPanel {
                SectionHeader("Application")
                MetadataRow(label: "Version", value: viewModel.appVersion, monospaced: true)
                MetadataRow(label: "Build", value: viewModel.buildNumber, monospaced: true)
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
                .accessibilityHint("Toggles visibility of IP addresses on the dashboard")
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Refresh", systemImage: "arrow.clockwise") {
                    viewModel.refresh()
                }
                .disabled(viewModel.isRefreshing)
                .help("Refresh host metadata and metrics")
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    private var bentoRow: some View {
        let columns = [
            GridItem(.flexible(minimum: 220), spacing: DesignTokens.Spacing.gutter),
            GridItem(.flexible(minimum: 320), spacing: DesignTokens.Spacing.gutter)
        ]

        return LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.gutter) {
            GlassPanel(luminous: true) {
                SectionHeader("System Info")
                MetadataRow(label: "macOS", value: viewModel.operatingSystemVersion)
                MetadataRow(label: "Architecture", value: viewModel.architecture, monospaced: true)
                if let snapshot = viewModel.snapshot {
                    MetadataRow(label: "Uptime", value: MetricsFormatter.uptime(snapshot.uptime), monospaced: true)
                    MetadataRow(label: "Thermal", value: snapshot.thermalState.title)
                }
                if let ip = viewModel.networkSnapshot?.primaryIPv4 {
                    MetadataRow(
                        label: "Local IP",
                        value: ip,
                        monospaced: true,
                        emphasizeValue: true,
                        isSensitive: true,
                        isRevealed: $areSensitiveValuesRevealed
                    )
                }
            }

            if let network = viewModel.networkSnapshot {
                GlassPanel {
                    HStack {
                        SectionHeader("Network Activity")
                        Spacer()
                        throughputChip(
                            symbol: "arrow.down",
                            value: MetricsFormatter.bytesPerSecond(network.throughput.downloadBytesPerSecond),
                            color: DesignTokens.Colors.primary
                        )
                        throughputChip(
                            symbol: "arrow.up",
                            value: MetricsFormatter.bytesPerSecond(network.throughput.uploadBytesPerSecond),
                            color: DesignTokens.Colors.tertiary
                        )
                    }

                    MetadataRow(label: "Status", value: network.path.statusDescription)
                    MetadataRow(
                        label: "Public IP",
                        value: network.publicIP ?? "—",
                        monospaced: true,
                        isSensitive: true,
                        isRevealed: $areSensitiveValuesRevealed
                    )
                    if let latency = network.httpsLatency {
                        MetadataRow(
                            label: "Latency",
                            value: MetricsFormatter.milliseconds(latency.milliseconds),
                            monospaced: true,
                            emphasizeValue: true
                        )
                    }
                    let dns = network.dnsServers.prefix(2).joined(separator: ", ")
                    MetadataRow(
                        label: "DNS",
                        value: dns.isEmpty ? "—" : dns,
                        monospaced: true,
                        isSensitive: true,
                        isRevealed: $areSensitiveValuesRevealed
                    )
                }
            }
        }
    }

    private func metricsGrid(_ snapshot: SystemMetricsSnapshot) -> some View {
        let columns = [GridItem(.adaptive(minimum: 168), spacing: DesignTokens.Spacing.gutter)]

        return LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.gutter) {
            MetricCard(
                title: "CPU Usage",
                value: MetricsFormatter.percent(snapshot.cpu.usageRatio),
                detail: "Live sample",
                symbolName: "cpu",
                ratio: snapshot.cpu.usageRatio,
                accent: DesignTokens.Colors.primary
            )
            MetricCard(
                title: "Memory Pressure",
                value: MetricsFormatter.bytes(snapshot.memory.usedBytes),
                detail: "/ \(MetricsFormatter.bytes(snapshot.memory.totalBytes))",
                symbolName: "memorychip",
                ratio: snapshot.memory.usageRatio,
                accent: DesignTokens.Colors.tertiary
            )
            MetricCard(
                title: "Storage",
                value: MetricsFormatter.bytes(snapshot.storage.usedBytes),
                detail: "/ \(MetricsFormatter.bytes(snapshot.storage.totalBytes))",
                symbolName: "internaldrive",
                ratio: snapshot.storage.usageRatio,
                accent: DesignTokens.Colors.primary
            )
            if let battery = snapshot.battery {
                MetricCard(
                    title: "Power Status",
                    value: MetricsFormatter.percent(battery.chargeRatio),
                    detail: battery.isCharging ? "AC Power" : "On battery",
                    symbolName: battery.isCharging ? "battery.100.bolt" : "battery.100",
                    ratio: battery.chargeRatio,
                    accent: DesignTokens.Colors.primary
                )
            }
        }
    }

    private func throughputChip(symbol: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
            Text(value)
                .font(DesignTokens.Typography.monoCaption)
                .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.selection, style: .continuous)
                .fill(DesignTokens.Colors.surfaceHighest.opacity(0.8))
        }
    }
}
