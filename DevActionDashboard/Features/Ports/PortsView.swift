import AppKit
import SwiftUI

struct PortsView: View {
    @State private var viewModel: PortsViewModel
    @State private var selectedID: LocalPortEntry.ID?

    init(viewModel: PortsViewModel) {
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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    Text("Ports")
                        .font(DesignTokens.Typography.hero)
                        .accessibilityAddTraits(.isHeader)
                    Text("\(viewModel.totalCount) listening · local development servers")
                        .font(DesignTokens.Typography.secondary)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Refresh", systemImage: "arrow.clockwise") {
                    viewModel.refresh()
                }
                .disabled(viewModel.isRefreshing)
                .help("Rescan listening ports")
            }

            HStack(spacing: DesignTokens.Spacing.sm) {
                TextField("Search port, process, or stack", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 360)

                Picker("Stack", selection: $viewModel.stackFilter) {
                    Text("All stacks").tag(Optional<DetectedDevStack>.none)
                    ForEach(DetectedDevStack.allCases.filter { $0 != .unknown }) { stack in
                        Text(stack.title).tag(Optional(stack))
                    }
                    Text(DetectedDevStack.unknown.title).tag(Optional(DetectedDevStack.unknown))
                }
                .frame(maxWidth: 220)
                .accessibilityLabel("Filter by detected stack")
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
        Table(viewModel.visibleEntries, selection: $selectedID) {
            TableColumn("Port") { entry in
                Text("\(entry.port)")
                    .font(DesignTokens.Typography.mono)
            }
            .width(min: 56, ideal: 72, max: 88)

            TableColumn("Address") { entry in
                Text(entry.address)
                    .font(DesignTokens.Typography.mono)
                    .lineLimit(1)
            }
            .width(min: 90, ideal: 120, max: 160)

            TableColumn("Stack") { entry in
                Label(entry.detectedStack.title, systemImage: entry.detectedStack.symbolName)
            }
            .width(min: 110, ideal: 140)

            TableColumn("Process") { entry in
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.processName)
                    Text("PID \(entry.pid)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(entry.processName), PID \(entry.pid)")
            }
            .width(min: 120, ideal: 180)

            TableColumn("Title") { entry in
                Text(entry.httpTitle ?? "—")
                    .foregroundStyle(entry.httpTitle == nil ? .tertiary : .primary)
                    .lineLimit(1)
            }
            .width(min: 120, ideal: 200)
        }
        .contextMenu(forSelectionType: LocalPortEntry.ID.self) { selection in
            if let entry = entry(for: selection) {
                Button("Open in Browser") {
                    viewModel.openInBrowser(entry)
                }
                Divider()
                Button("Copy URL") {
                    if let url = entry.browserURL?.absoluteString {
                        copyToPasteboard(url)
                    }
                }
                Button("Copy Port") {
                    copyToPasteboard("\(entry.port)")
                }
                if let path = entry.processPath {
                    Button("Copy Process Path") {
                        copyToPasteboard(path)
                    }
                }
            }
        } primaryAction: { selection in
            if let entry = entry(for: selection) {
                viewModel.openInBrowser(entry)
            }
        }
    }

    private func entry(for selection: Set<LocalPortEntry.ID>) -> LocalPortEntry? {
        guard let id = selection.first else { return nil }
        return viewModel.visibleEntries.first { $0.id == id }
    }

    private func copyToPasteboard(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }
}
