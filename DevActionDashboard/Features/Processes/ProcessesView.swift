import AppKit
import SwiftUI

struct ProcessesView: View {
    @State private var viewModel: ProcessesViewModel
    @State private var selectedProcessID: RunningProcess.ID?

    init(viewModel: ProcessesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            table
        }
        .background(AppCanvasBackground())
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .alert(
            confirmationTitle,
            isPresented: Binding(
                get: { viewModel.processPendingTermination != nil },
                set: { if !$0 { viewModel.cancelTermination() } }
            )
        ) {
            Button(viewModel.confirmForceQuit ? "Force Quit" : "Quit", role: .destructive) {
                viewModel.confirmTermination()
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelTermination()
            }
        } message: {
            if let process = viewModel.processPendingTermination {
                Text("PID \(process.pid) · \(process.name)")
            }
        }
    }

    private var confirmationTitle: String {
        viewModel.confirmForceQuit ? "Force Quit Process?" : "Quit Process?"
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    Text("Processes")
                        .font(DesignTokens.Typography.hero)
                        .accessibilityAddTraits(.isHeader)
                    Text("\(viewModel.processCount) running · sorted by \(viewModel.sortKey.title)")
                        .font(DesignTokens.Typography.secondary)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Activity Monitor", systemImage: "chart.bar.doc.horizontal") {
                    viewModel.openActivityMonitor()
                }
                .help("Open Activity Monitor")

                Button("Refresh", systemImage: "arrow.clockwise") {
                    viewModel.refresh()
                }
                .disabled(viewModel.isRefreshing)
            }

            HStack(spacing: DesignTokens.Spacing.sm) {
                TextField("Search name, PID, or path", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 360)

                Picker("Sort", selection: $viewModel.sortKey) {
                    ForEach(ProcessSortKey.allCases) { key in
                        Text(key.title).tag(key)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 360)
                .accessibilityLabel("Sort processes")
            }

            if let actionMessage = viewModel.actionMessage {
                Text(actionMessage)
                    .font(DesignTokens.Typography.secondary)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(DesignTokens.Typography.secondary)
                    .foregroundStyle(.orange)
            }
        }
        .padding(DesignTokens.Spacing.lg)
    }

    private var table: some View {
        Table(viewModel.visibleProcesses, selection: $selectedProcessID) {
            TableColumn("PID") { process in
                Text("\(process.pid)")
                    .font(DesignTokens.Typography.mono)
            }
            .width(min: 56, ideal: 72, max: 88)

            TableColumn("Name") { process in
                VStack(alignment: .leading, spacing: 2) {
                    Text(process.name)
                    if let path = process.path {
                        Text(path)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(processAccessibilityLabel(process))
            }
            .width(min: 160, ideal: 260)

            TableColumn("CPU") { process in
                Text(MetricsFormatter.percent(process.cpuUsageRatio))
                    .font(DesignTokens.Typography.mono)
                    .foregroundStyle(cpuColor(process.cpuUsageRatio))
            }
            .width(min: 64, ideal: 80, max: 96)

            TableColumn("Memory") { process in
                Text(MetricsFormatter.bytes(process.residentMemoryBytes))
                    .font(DesignTokens.Typography.mono)
            }
            .width(min: 88, ideal: 110, max: 140)

            TableColumn("Threads") { process in
                Text("\(process.threadCount)")
                    .font(DesignTokens.Typography.mono)
            }
            .width(min: 64, ideal: 80, max: 96)
        }
        .contextMenu(forSelectionType: RunningProcess.ID.self) { selection in
            if let process = process(for: selection) {
                Button("Quit…") {
                    viewModel.requestQuit(process, force: false)
                }
                Button("Force Quit…", role: .destructive) {
                    viewModel.requestQuit(process, force: true)
                }
                Divider()
                if let path = process.path {
                    Button("Copy Path") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(path, forType: .string)
                    }
                }
                Button("Copy PID") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("\(process.pid)", forType: .string)
                }
            }
        } primaryAction: { selection in
            selectedProcessID = selection.first
        }
    }

    private func process(for selection: Set<RunningProcess.ID>) -> RunningProcess? {
        guard let id = selection.first else { return nil }
        return viewModel.visibleProcesses.first { $0.id == id }
    }

    private func processAccessibilityLabel(_ process: RunningProcess) -> String {
        let cpu = MetricsFormatter.percent(process.cpuUsageRatio)
        let memory = MetricsFormatter.bytes(process.residentMemoryBytes)
        return "\(process.name), PID \(process.pid), CPU \(cpu), Memory \(memory)"
    }

    private func cpuColor(_ ratio: Double?) -> Color {
        guard let ratio else { return .secondary }
        switch ratio {
        case 0..<0.5: return .primary
        case 0.5..<1.0: return .orange
        default: return .red
        }
    }
}
