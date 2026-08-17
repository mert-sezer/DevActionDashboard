import SwiftUI

/// Page-level loading indicator — always centered in the available space.
public struct CenteredLoadingView: View {
    private let message: String?

    public init(_ message: String? = nil) {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ProgressView()
                .controlSize(.regular)

            if let message {
                Text(message)
                    .font(DesignTokens.Typography.secondary)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message ?? "Loading")
    }
}
