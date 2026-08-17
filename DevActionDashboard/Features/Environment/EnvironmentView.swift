import AppKit
import SwiftUI

struct EnvironmentView: View {
    @State private var viewModel: EnvironmentViewModel

    init(viewModel: EnvironmentViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var isInitialLoad: Bool {
        viewModel.isRefreshing && viewModel.snapshot == nil && viewModel.errorMessage == nil
    }

    var body: some View {
        Group {
            if isInitialLoad {
                CenteredLoadingView("Probing toolchains…")
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
                .help("Re-probe developer toolchains")
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                header
                filterBar

                if let errorMessage = viewModel.errorMessage, viewModel.snapshot == nil {
                    emptyState(
                        title: "Probe failed",
                        systemImage: "wrench.and.screwdriver",
                        description: errorMessage
                    )
                } else if viewModel.groupedTools.isEmpty {
                    emptyState(
                        title: "No tools match",
                        systemImage: "line.3.horizontal.decrease",
                        description: "Adjust filters or refresh the probe."
                    )
                } else {
                    if let snapshot = viewModel.snapshot {
                        metaLine(snapshot)
                    }

                    ForEach(viewModel.groupedTools, id: \.category) { group in
                        categorySection(group.category, tools: group.tools)
                    }
                }
            }
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.md)
        }
        .scrollIndicators(.automatic)
        .background(AppCanvasBackground())
        .overlay {
            if viewModel.isRefreshing, viewModel.snapshot != nil {
                CenteredLoadingView()
                    .background(Color.black.opacity(0.08))
                    .transition(.opacity)
            }
        }
        .animation(DesignTokens.Motion.quick, value: viewModel.isRefreshing)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("ENVIRONMENT")
                .font(DesignTokens.Typography.brand)
                .foregroundStyle(.secondary)
                .tracking(1.6)

            Text("Toolchains")
                .font(DesignTokens.Typography.hero)
                .accessibilityAddTraits(.isHeader)

            Text("What’s installed on this Mac.")
                .font(DesignTokens.Typography.secondary)
                .foregroundStyle(.secondary)
        }
    }

    private var filterBar: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                TextField("Filter", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
                    .fill(.thinMaterial)
            }

            Toggle(isOn: $viewModel.showInstalledOnly) {
                Text("Installed")
                    .font(DesignTokens.Typography.secondary)
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .labelsHidden()
            .accessibilityLabel("Installed only")

            Text("Installed")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func metaLine(_ snapshot: ToolingSnapshot) -> some View {
        Text("\(snapshot.installedCount) of \(snapshot.tools.count) found · \(snapshot.timestamp.formatted(date: .omitted, time: .shortened))")
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(.tertiary)
    }

    private func categorySection(_ category: DeveloperToolCategory, tools: [InstalledTool]) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(category.title.uppercased())
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(.tertiary)
                .tracking(1.2)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                ForEach(Array(tools.enumerated()), id: \.element.id) { index, tool in
                    toolRow(tool)
                    if index < tools.count - 1 {
                        Divider()
                            .opacity(0.45)
                            .padding(.leading, 36)
                    }
                }
            }
        }
    }

    private func toolRow(_ tool: InstalledTool) -> some View {
        HStack(alignment: .center, spacing: DesignTokens.Spacing.sm) {
            Image(systemName: tool.kind.symbolName)
                .font(.body.weight(.medium))
                .foregroundStyle(tool.isInstalled ? Color.accentColor : Color.secondary.opacity(0.55))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(tool.kind.title)
                    .font(DesignTokens.Typography.body.weight(.medium))
                    .foregroundStyle(tool.isInstalled ? .primary : .secondary)

                if let path = tool.path {
                    Text(path)
                        .font(DesignTokens.Typography.monoCaption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                } else if let detail = tool.detail, !tool.isInstalled {
                    Text(detail)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: DesignTokens.Spacing.sm)

            Text(tool.isInstalled ? (tool.version ?? "Installed") : "—")
                .font(DesignTokens.Typography.monoCaption)
                .foregroundStyle(tool.isInstalled ? .secondary : .tertiary)
                .monospacedDigit()
        }
        .padding(.vertical, 11)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: tool))
        .contextMenu {
            if let path = tool.path {
                Button("Copy Path") { copy(path) }
            }
            if let version = tool.version {
                Button("Copy Version") { copy(version) }
            }
        }
    }

    private func emptyState(title: String, systemImage: String, description: String) -> some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(DesignTokens.Typography.title)
            Text(description)
                .font(DesignTokens.Typography.secondary)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.xxl)
    }

    private func accessibilityLabel(for tool: InstalledTool) -> String {
        if tool.isInstalled {
            let version = tool.version ?? "version unknown"
            return "\(tool.kind.title), installed, \(version)"
        }
        return "\(tool.kind.title), not found"
    }

    private func copy(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }
}
