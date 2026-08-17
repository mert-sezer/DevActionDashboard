import SwiftUI

struct EnvVarsView: View {
    @State private var viewModel: EnvVarsViewModel

    init(viewModel: EnvVarsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            HSplitView {
                variableList
                    .frame(minWidth: 280)
                detailPane
                    .frame(minWidth: 360)
            }
        }
        .background(AppCanvasBackground())
        .onAppear { viewModel.onAppear() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    Text("Env Vars")
                        .font(DesignTokens.Typography.hero)
                        .accessibilityAddTraits(.isHeader)
                    Text("\(viewModel.visibleVariables.count) of \(viewModel.variables.count) variables")
                        .font(DesignTokens.Typography.secondary)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Refresh", systemImage: "arrow.clockwise") {
                    viewModel.refresh()
                }
                .disabled(viewModel.isRefreshing)
            }

            TextField("Search keys or values", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 420)
        }
        .padding(DesignTokens.Spacing.lg)
    }

    private var variableList: some View {
        List(selection: $viewModel.selectedKey) {
            ForEach(viewModel.visibleVariables) { variable in
                VStack(alignment: .leading, spacing: 2) {
                    Text(variable.key)
                        .font(DesignTokens.Typography.mono.weight(.semibold))
                    Text(variable.value)
                        .font(DesignTokens.Typography.secondary)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .tag(variable.key)
                .contextMenu {
                    Button("Copy Value") { viewModel.copyValue(variable.value) }
                    Button("Copy KEY=value") { viewModel.copyValue("\(variable.key)=\(variable.value)") }
                    Button("Use as Compare Left") { viewModel.compareLeftKey = variable.key }
                    Button("Use as Compare Right") { viewModel.compareRightKey = variable.key }
                }
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }

    private var detailPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                if let selected = viewModel.selectedVariable {
                    GlassPanel {
                        Text(selected.key)
                            .font(DesignTokens.Typography.title)
                            .textSelection(.enabled)
                            .accessibilityAddTraits(.isHeader)

                        Text(selected.value)
                            .font(DesignTokens.Typography.mono)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack {
                            Button("Copy Value") { viewModel.copyValue(selected.value) }
                            Button("Copy KEY=value") { viewModel.copySelected() }
                            Button("Compare as Left") { viewModel.compareLeftKey = selected.key }
                            Button("Compare as Right") { viewModel.compareRightKey = selected.key }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Select a variable",
                        systemImage: "key",
                        description: Text("Choose an environment variable to inspect or compare.")
                    )
                }

                comparePanel
            }
            .padding(DesignTokens.Spacing.lg)
        }
    }

    private var comparePanel: some View {
        GlassPanel {
            Text("Compare")
                .font(DesignTokens.Typography.title)
                .accessibilityAddTraits(.isHeader)

            HStack {
                Picker("Left", selection: $viewModel.compareLeftKey) {
                    Text("Select…").tag(Optional<String>.none)
                    ForEach(viewModel.variables) { variable in
                        Text(variable.key).tag(Optional(variable.key))
                    }
                }
                Picker("Right", selection: $viewModel.compareRightKey) {
                    Text("Select…").tag(Optional<String>.none)
                    ForEach(viewModel.variables) { variable in
                        Text(variable.key).tag(Optional(variable.key))
                    }
                }
            }

            if let comparison = viewModel.comparison {
                MetadataRow(label: "Equal", value: comparison.areEqual ? "Yes" : "No")
                if !comparison.areEqual {
                    MetadataRow(label: "Left-only lines", value: "\(comparison.leftOnlyLines.count)")
                    MetadataRow(label: "Right-only lines", value: "\(comparison.rightOnlyLines.count)")
                    MetadataRow(label: "Shared lines", value: "\(comparison.sharedLines.count)")
                }

                HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                    VStack(alignment: .leading) {
                        Text(comparison.leftKey)
                            .font(DesignTokens.Typography.secondary.weight(.semibold))
                        Text(comparison.leftValue)
                            .font(DesignTokens.Typography.mono)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading) {
                        Text(comparison.rightKey)
                            .font(DesignTokens.Typography.secondary.weight(.semibold))
                        Text(comparison.rightValue)
                            .font(DesignTokens.Typography.mono)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text("Pick two variables to compare their values.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
