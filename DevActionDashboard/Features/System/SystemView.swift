import SwiftUI

struct SystemView: View {
    @State private var viewModel: SystemViewModel
    @State private var didCopyReport = false

    init(viewModel: SystemViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.snapshot == nil, viewModel.errorMessage == nil {
                CenteredLoadingView("Sampling host…")
                    .background(AppCanvasBackground())
            } else {
                content
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Refresh", systemImage: "arrow.clockwise") {
                    viewModel.refresh()
                }
                .disabled(viewModel.isRefreshing)
                .help("Refresh system metrics now")
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.gutter) {
                header

                if let errorMessage = viewModel.errorMessage, viewModel.snapshot == nil {
                    ContentUnavailableView(
                        "Metrics unavailable",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                }

                if let snapshot = viewModel.snapshot {
                    overviewTiles(snapshot)
                    lowerGrid(snapshot)
                }
            }
            .frame(maxWidth: 1100, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignTokens.Spacing.lg)
        }
        .scrollIndicators(.automatic)
        .background(AppCanvasBackground())
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("System Overview")
                    .font(DesignTokens.Typography.hero)
                    .foregroundStyle(DesignTokens.Colors.onSurface)
                    .tracking(-0.4)
                    .accessibilityAddTraits(.isHeader)

                Text(viewModel.hostName)
                    .font(DesignTokens.Typography.monoCaption)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
            }

            Spacer()

            HStack(spacing: DesignTokens.Spacing.xs) {
                statusChip(
                    "ONLINE",
                    emphasized: viewModel.snapshot != nil
                )
                statusChip(
                    (viewModel.snapshot?.thermalState.title ?? "—").uppercased(),
                    emphasized: false
                )
            }
        }
    }

    private func overviewTiles(_ snapshot: SystemMetricsSnapshot) -> some View {
        let columns = [
            GridItem(.adaptive(minimum: 200), spacing: DesignTokens.Spacing.gutter)
        ]

        return LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.gutter) {
            overviewTile(
                title: "Uptime",
                value: MetricsFormatter.uptime(snapshot.uptime),
                detail: "Since last reboot",
                symbolName: "clock",
                emphasizeValue: true,
                luminous: true
            )
            overviewTile(
                title: "OS Version",
                value: "macOS \(viewModel.operatingSystemVersion)",
                detail: viewModel.kernelVersion,
                symbolName: "laptopcomputer",
                emphasizeValue: false,
                luminous: false
            )
            overviewTile(
                title: "Architecture",
                value: viewModel.architecture,
                detail: viewModel.architectureDetail,
                symbolName: "cpu",
                emphasizeValue: false,
                luminous: false
            )
            overviewTile(
                title: "Local IP",
                value: viewModel.localIP,
                detail: viewModel.primaryInterfaceHint,
                symbolName: "wifi.router",
                emphasizeValue: false,
                luminous: false
            )
        }
    }

    private func lowerGrid(_ snapshot: SystemMetricsSnapshot) -> some View {
        let columns = [
            GridItem(.flexible(minimum: 320), spacing: DesignTokens.Spacing.gutter),
            GridItem(.flexible(minimum: 240, maximum: 360), spacing: DesignTokens.Spacing.gutter)
        ]

        return LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.gutter) {
            eventsPanel
            hardwarePanel(snapshot)
        }
    }

    private var eventsPanel: some View {
        GlassPanel {
            HStack {
                Text("Recent System Events")
                    .font(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.Colors.onSurface)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DesignTokens.Colors.primary)
                    .accessibilityHidden(true)
            }
            .padding(.bottom, 4)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(DesignTokens.Colors.outlineVariant.opacity(0.35))
                    .frame(height: 1)
            }

            if viewModel.statusEvents.isEmpty {
                Text("No live events yet.")
                    .font(DesignTokens.Typography.monoCaption)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                    .padding(.vertical, DesignTokens.Spacing.md)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.statusEvents) { event in
                        eventRow(event)
                    }
                }
                .frame(minHeight: 280, alignment: .top)
            }
        }
    }

    private func hardwarePanel(_ snapshot: SystemMetricsSnapshot) -> some View {
        GlassPanel {
            Text("Hardware Configuration")
                .font(DesignTokens.Typography.title)
                .foregroundStyle(DesignTokens.Colors.onSurface)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(DesignTokens.Colors.outlineVariant.opacity(0.35))
                        .frame(height: 1)
                }

            hardwareField(label: "Processor", value: viewModel.processorSummary)

            hardwareField(
                label: "Memory",
                value: MetricsFormatter.bytes(snapshot.memory.totalBytes)
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("STORAGE (\(snapshot.storage.volumeName.uppercased()))")
                    .font(DesignTokens.Typography.labelCaps)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                    .tracking(0.6)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    HStack {
                        Text("Used: \(MetricsFormatter.bytes(snapshot.storage.usedBytes))")
                        Spacer()
                        Text("Total: \(MetricsFormatter.bytes(snapshot.storage.totalBytes))")
                    }
                    .font(DesignTokens.Typography.monoCaption)
                    .foregroundStyle(DesignTokens.Colors.onSurface)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(DesignTokens.Colors.surfaceHighest)
                            Capsule()
                                .fill(DesignTokens.Colors.primary)
                                .frame(width: max(4, geo.size.width * snapshot.storage.usageRatio))
                        }
                    }
                    .frame(height: 6)
                }
                .padding(9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.selection, style: .continuous)
                        .fill(DesignTokens.Colors.surfaceLowest.opacity(0.85))
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.selection, style: .continuous)
                                .strokeBorder(DesignTokens.Colors.outlineVariant.opacity(0.35), lineWidth: 1)
                        }
                }
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("LIVE PRESSURE")
                    .font(DesignTokens.Typography.labelCaps)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                    .tracking(0.6)

                MetricBar(
                    title: "CPU",
                    ratio: snapshot.cpu.usageRatio ?? 0,
                    detail: MetricsFormatter.percent(snapshot.cpu.usageRatio),
                    symbolName: "cpu"
                )
                MetricBar(
                    title: "Memory",
                    ratio: snapshot.memory.usageRatio,
                    detail: "\(MetricsFormatter.bytes(snapshot.memory.usedBytes)) / \(MetricsFormatter.bytes(snapshot.memory.totalBytes))",
                    symbolName: "memorychip"
                )
            }

            Button {
                viewModel.copyFullReport()
                didCopyReport = true
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    didCopyReport = false
                }
            } label: {
                Text(didCopyReport ? "Copied to Clipboard" : "Generate Full Report")
                    .font(DesignTokens.Typography.monoCaption)
                    .foregroundStyle(DesignTokens.Colors.onSurface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
            }
            .buttonStyle(.plain)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.selection, style: .continuous)
                    .strokeBorder(DesignTokens.Colors.outlineVariant, lineWidth: 1)
            }
            .padding(.top, DesignTokens.Spacing.xs)
            .accessibilityHint("Copies a text system report to the clipboard")
        }
    }

    private func overviewTile(
        title: String,
        value: String,
        detail: String,
        symbolName: String,
        emphasizeValue: Bool,
        luminous: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack {
                Text(title.uppercased())
                    .font(DesignTokens.Typography.labelCaps)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                    .tracking(0.6)
                Spacer()
                Image(systemName: symbolName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(emphasizeValue ? DesignTokens.Colors.primary : DesignTokens.Colors.onSurfaceVariant)
            }

            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundStyle(emphasizeValue ? DesignTokens.Colors.primary : DesignTokens.Colors.onSurface)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())

            Text(detail)
                .font(DesignTokens.Typography.monoCaption)
                .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                .lineLimit(2)
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(DesignTokens.Colors.outlineVariant.opacity(0.35))
                        .frame(height: 1)
                }
        }
        .padding(DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .background {
            ZStack {
                if luminous {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [
                                    DesignTokens.Colors.primaryContainer.opacity(0.18),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 8,
                                endRadius: 140
                            )
                        )
                        .scaleEffect(1.08)
                        .blur(radius: 6)
                }

                RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                    .fill(DesignTokens.Colors.card.opacity(0.9))
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                            .strokeBorder(
                                luminous
                                    ? DesignTokens.Colors.primary.opacity(0.5)
                                    : DesignTokens.Colors.outlineVariant.opacity(0.55),
                                lineWidth: 1
                            )
                    }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value), \(detail)")
    }

    private func eventRow(_ event: SystemStatusEvent) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            Text(event.timestamp.formatted(date: .omitted, time: .standard))
                .font(DesignTokens.Typography.monoCaption)
                .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                .frame(width: 88, alignment: .leading)

            Text("[\(event.level.rawValue)]")
                .font(DesignTokens.Typography.monoCaption)
                .foregroundStyle(event.level == .warn ? DesignTokens.Colors.error : DesignTokens.Colors.primary)
                .frame(width: 56, alignment: .leading)

            Text(event.message)
                .font(DesignTokens.Typography.monoCaption)
                .foregroundStyle(DesignTokens.Colors.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DesignTokens.Colors.outlineVariant.opacity(0.18))
                .frame(height: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private func hardwareField(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(DesignTokens.Typography.labelCaps)
                .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                .tracking(0.6)

            Text(value)
                .font(DesignTokens.Typography.monoCaption)
                .foregroundStyle(DesignTokens.Colors.onSurface)
                .fixedSize(horizontal: false, vertical: true)
                .padding(9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.selection, style: .continuous)
                        .fill(DesignTokens.Colors.surfaceLowest.opacity(0.85))
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.selection, style: .continuous)
                                .strokeBorder(DesignTokens.Colors.outlineVariant.opacity(0.35), lineWidth: 1)
                        }
                }
        }
    }

    private func statusChip(_ title: String, emphasized: Bool) -> some View {
        Text(title)
            .font(DesignTokens.Typography.labelCaps)
            .tracking(0.5)
            .foregroundStyle(emphasized ? DesignTokens.Colors.primary : DesignTokens.Colors.onSurfaceVariant)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.selection, style: .continuous)
                    .fill(emphasized ? DesignTokens.Colors.primaryContainer.opacity(0.12) : DesignTokens.Colors.surfaceHighest)
                    .overlay {
                        if emphasized {
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.selection, style: .continuous)
                                .strokeBorder(DesignTokens.Colors.primary.opacity(0.35), lineWidth: 1)
                        }
                    }
            }
    }
}
