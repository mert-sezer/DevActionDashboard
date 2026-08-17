import SwiftUI

struct ActionsView: View {
    @State private var viewModel: ActionsViewModel

    init(viewModel: ActionsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        FeaturePage(
            title: "Actions",
            subtitle: "System maintenance and Finder shortcuts."
        ) {
            if let resultMessage = viewModel.resultMessage {
                Label(resultMessage, systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)
            }

            if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }

            ForEach(viewModel.groupedActions, id: \.category) { group in
                GlassPanel {
                    Text(group.category.title)
                        .font(DesignTokens.Typography.title)
                        .accessibilityAddTraits(.isHeader)

                    ForEach(group.actions) { action in
                        actionRow(action)
                    }
                }
            }
        }
        .disabled(viewModel.isPerforming)
        .overlay {
            if viewModel.isPerforming {
                CenteredLoadingView("Running…")
                    .background(.ultraThinMaterial.opacity(0.55))
            }
        }
        .alert(
            viewModel.pendingAction?.title ?? "Confirm",
            isPresented: Binding(
                get: { viewModel.pendingAction != nil },
                set: { if !$0 { viewModel.cancelPending() } }
            )
        ) {
            Button(
                viewModel.pendingAction?.isDestructive == true ? "Continue" : "Run",
                role: viewModel.pendingAction?.isDestructive == true ? .destructive : nil
            ) {
                viewModel.confirmPending()
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelPending()
            }
        } message: {
            Text(viewModel.pendingAction?.detail ?? "")
        }
    }

    private func actionRow(_ action: SystemActionKind) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.sm) {
            Image(systemName: action.symbolName)
                .frame(width: 22)
                .foregroundStyle(action.isDestructive ? Color.orange : Color.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(action.title)
                    .font(DesignTokens.Typography.body.weight(.semibold))
                Text(action.detail)
                    .font(DesignTokens.Typography.secondary)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button(action.requiresConfirmation ? "Run…" : "Run") {
                viewModel.request(action)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("\(action.title)")
            .accessibilityHint(action.detail)
        }
        .padding(.vertical, 6)
    }
}
