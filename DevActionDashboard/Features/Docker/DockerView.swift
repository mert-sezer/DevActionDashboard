import AppKit
import SwiftUI

struct DockerView: View {
    @State private var viewModel: DockerViewModel
    @State private var selectedID: DockerContainer.ID?
    @State private var isLogSheetPresented = false

    init(viewModel: DockerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var isInitialLoad: Bool {
        viewModel.isRefreshing && viewModel.snapshot == nil && viewModel.errorMessage == nil
    }

    private var isUnavailable: Bool {
        guard let snapshot = viewModel.snapshot else { return false }
        return !snapshot.isAvailable
    }

    var body: some View {
        Group {
            if isInitialLoad {
                CenteredLoadingView("Connecting to Docker…")
                    .background(AppCanvasBackground())
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    Divider()
                    content
                }
                .background(AppCanvasBackground())
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .sheet(isPresented: $isLogSheetPresented) {
            logSheet
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    Text("Docker")
                        .font(DesignTokens.Typography.hero)
                        .accessibilityAddTraits(.isHeader)

                    Text(statusSubtitle)
                        .font(DesignTokens.Typography.secondary)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Refresh", systemImage: "arrow.clockwise") {
                    viewModel.refresh()
                }
                .disabled(viewModel.isRefreshing)
            }

            if !isUnavailable {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    TextField("Search name, image, ID, or ports", text: $viewModel.searchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 360)

                    Toggle("Running only", isOn: $viewModel.showOnlyRunning)
                        .toggleStyle(.checkbox)
                }
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
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DesignTokens.Spacing.lg)
    }

    private var statusSubtitle: String {
        guard let snapshot = viewModel.snapshot else {
            return "Docker CLI"
        }
        if !snapshot.isAvailable {
            return snapshot.dockerPath
        }
        let version = snapshot.engineVersion.map { "Engine \($0)" } ?? "Engine unknown"
        return "\(snapshot.containers.count) containers · \(version) · \(snapshot.dockerPath)"
    }

    @ViewBuilder
    private var content: some View {
        if isUnavailable {
            unavailableState
        } else if viewModel.visibleContainers.isEmpty {
            ContentUnavailableView(
                "No containers",
                systemImage: "shippingbox",
                description: Text(
                    viewModel.searchText.isEmpty
                        ? "No containers were reported by docker ps."
                        : "No containers match the current filter."
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            table
        }
    }

    private var unavailableState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "shippingbox")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.tertiary)

            Text("Docker Engine isn’t running")
                .font(DesignTokens.Typography.title)

            Text(viewModel.snapshot?.availabilityMessage
                  ?? "Start Docker Desktop, then refresh.")
                .font(DesignTokens.Typography.secondary)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            HStack(spacing: DesignTokens.Spacing.sm) {
                if canOpenDockerDesktop {
                    Button("Open Docker Desktop") {
                        openDockerDesktop()
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button("Refresh") {
                    viewModel.refresh()
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, DesignTokens.Spacing.xs)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var canOpenDockerDesktop: Bool {
        FileManager.default.fileExists(atPath: "/Applications/Docker.app")
    }

    private func openDockerDesktop() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Docker.app"))
    }

    private var table: some View {
        Table(viewModel.visibleContainers, selection: $selectedID) {
            TableColumn("Name") { container in
                VStack(alignment: .leading, spacing: 2) {
                    Text(container.name)
                    Text(String(container.containerID.prefix(12)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospaced()
                }
            }
            .width(min: 120, ideal: 180)

            TableColumn("Image") { container in
                Text(container.image)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .width(min: 120, ideal: 180)

            TableColumn("State") { container in
                Text(container.state.title)
                    .foregroundStyle(stateColor(container.state))
            }
            .width(min: 80, ideal: 100, max: 120)

            TableColumn("CPU") { container in
                Text(MetricsFormatter.percent(container.cpuUsageRatio))
                    .font(DesignTokens.Typography.mono)
            }
            .width(min: 64, ideal: 80, max: 96)

            TableColumn("Memory") { container in
                Text(memoryText(container))
                    .font(DesignTokens.Typography.mono)
                    .lineLimit(1)
            }
            .width(min: 100, ideal: 140)

            TableColumn("Status") { container in
                Text(container.status)
                    .lineLimit(1)
            }
            .width(min: 120, ideal: 180)
        }
        .contextMenu(forSelectionType: DockerContainer.ID.self) { selection in
            if let container = container(for: selection) {
                Button("Start") { viewModel.start(container) }
                    .disabled(container.state == .running)
                Button("Stop") { viewModel.stop(container) }
                    .disabled(container.state != .running)
                Button("Restart") { viewModel.restart(container) }
                Divider()
                Button("View Logs") {
                    viewModel.loadLogs(container)
                    isLogSheetPresented = true
                }
            }
        } primaryAction: { selection in
            if let container = container(for: selection) {
                viewModel.loadLogs(container)
                isLogSheetPresented = true
            }
        }
    }

    private var logSheet: some View {
        NavigationStack {
            ScrollView {
                Text(viewModel.logText)
                    .font(DesignTokens.Typography.mono)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle(viewModel.logContainerName.map { "Logs · \($0)" } ?? "Logs")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        isLogSheetPresented = false
                        viewModel.clearLogs()
                    }
                }
            }
        }
        .frame(minWidth: 720, minHeight: 480)
    }

    private func memoryText(_ container: DockerContainer) -> String {
        guard let used = container.memoryUsageBytes else { return "—" }
        if let limit = container.memoryLimitBytes {
            return "\(MetricsFormatter.bytes(used)) / \(MetricsFormatter.bytes(limit))"
        }
        return MetricsFormatter.bytes(used)
    }

    private func stateColor(_ state: DockerContainerState) -> Color {
        switch state {
        case .running: .green
        case .exited, .dead: .secondary
        case .paused: .orange
        case .restarting, .removing: .yellow
        case .created, .unknown: .primary
        }
    }

    private func container(for selection: Set<DockerContainer.ID>) -> DockerContainer? {
        guard let id = selection.first else { return nil }
        return viewModel.visibleContainers.first { $0.id == id }
    }
}
