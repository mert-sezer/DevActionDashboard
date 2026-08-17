import SwiftUI

/// Labeled key/value row used for system and environment metadata.
public struct MetadataRow: View {
    private let label: String
    private let value: String
    private let monospaced: Bool
    private let emphasizeValue: Bool
    private let isSensitive: Bool
    @Binding private var isRevealed: Bool

    public init(
        label: String,
        value: String,
        monospaced: Bool = false,
        emphasizeValue: Bool = false,
        isSensitive: Bool = false,
        isRevealed: Binding<Bool> = .constant(false)
    ) {
        self.label = label
        self.value = value
        self.monospaced = monospaced
        self.emphasizeValue = emphasizeValue
        self.isSensitive = isSensitive
        _isRevealed = isRevealed
    }

    public var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.Spacing.xs) {
            Text(label)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                .frame(width: 140, alignment: .leading)

            Text(displayedValue)
                .font(monospaced ? DesignTokens.Typography.monoCaption : DesignTokens.Typography.body)
                .foregroundStyle(emphasizeValue ? DesignTokens.Colors.primary : DesignTokens.Colors.onSurface)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .modifier(SensitiveTextSelection(isEnabled: showsPlainValue))
                .accessibilityLabel(showsPlainValue ? value : "Hidden")

            if showsRevealControl {
                SensitiveRevealButton(isRevealed: $isRevealed, label: label)
            }
        }
        .padding(.vertical, 6)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DesignTokens.Colors.outlineVariant.opacity(0.25))
                .frame(height: 1)
        }
        .accessibilityElement(children: showsRevealControl ? .contain : .combine)
    }

    private var showsPlainValue: Bool {
        !isSensitive || isRevealed || !SensitiveDisplay.isMaskable(value)
    }

    private var displayedValue: String {
        SensitiveDisplay.display(value, isRevealed: showsPlainValue)
    }

    private var showsRevealControl: Bool {
        isSensitive && SensitiveDisplay.isMaskable(value)
    }
}

private struct SensitiveTextSelection: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content.textSelection(.enabled)
        } else {
            content.textSelection(.disabled)
        }
    }
}
