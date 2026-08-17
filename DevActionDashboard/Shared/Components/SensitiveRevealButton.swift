import SwiftUI

/// Compact show/hide control for secret-like values such as IP addresses.
public struct SensitiveRevealButton: View {
    @Binding private var isRevealed: Bool
    private let label: String

    public init(isRevealed: Binding<Bool>, label: String) {
        _isRevealed = isRevealed
        self.label = label
    }

    public var body: some View {
        Button {
            isRevealed.toggle()
        } label: {
            Image(systemName: isRevealed ? "eye.slash" : "eye")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                .frame(width: 18, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(isRevealed ? "Hide \(label)" : "Show \(label)")
        .accessibilityLabel(isRevealed ? "Hide \(label)" : "Show \(label)")
        .accessibilityHint("Toggles visibility of sensitive values on this screen")
    }
}
