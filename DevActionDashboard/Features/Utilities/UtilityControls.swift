import AppKit
import SwiftUI

enum UtilityClipboard {
    static func copy(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }
}

struct UtilityToolChrome<Content: View>: View {
    let tool: UtilityTool
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            HStack(alignment: .center, spacing: DesignTokens.Spacing.md) {
                Image(systemName: tool.symbolName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DesignTokens.Colors.primary)
                    .frame(width: 40, height: 40)
                    .background {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.icon, style: .continuous)
                            .fill(DesignTokens.Colors.primaryContainer.opacity(0.16))
                    }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(tool.title)
                        .font(DesignTokens.Typography.hero)
                        .foregroundStyle(DesignTokens.Colors.onSurface)
                        .tracking(-0.3)
                        .accessibilityAddTraits(.isHeader)
                    Text(tool.subtitle)
                        .font(DesignTokens.Typography.secondary)
                        .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct UtilityCodeEditor: View {
    @Binding var text: String
    var minHeight: CGFloat = 160

    var body: some View {
        TextEditor(text: $text)
            .font(DesignTokens.Typography.mono)
            .foregroundStyle(DesignTokens.Colors.onSurface)
            .scrollContentBackground(.hidden)
            .textEditorStyle(.plain)
            .padding(DesignTokens.Spacing.sm)
            .frame(minHeight: minHeight, alignment: .topLeading)
            .background {
                UtilityEditorChrome()
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous))
    }
}

struct UtilityOutputWell: View {
    let text: String
    var minHeight: CGFloat = 88
    var accessibilityLabel: String = "Output"

    var body: some View {
        Text(text.isEmpty ? " " : text)
            .font(DesignTokens.Typography.mono)
            .foregroundStyle(DesignTokens.Colors.onSurface)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
            .padding(DesignTokens.Spacing.sm)
            .background { UtilityEditorChrome() }
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(text.isEmpty ? "Empty" : text)
    }
}

struct UtilityProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignTokens.Typography.caption.weight(.semibold))
            .foregroundStyle(DesignTokens.Colors.onPrimaryContainer)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
                    .fill(DesignTokens.Colors.primaryContainer)
                    .opacity(configuration.isPressed ? 0.82 : 1)
            }
    }
}

struct UtilitySecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignTokens.Typography.caption.weight(.semibold))
            .foregroundStyle(DesignTokens.Colors.onSurface)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
                    .fill(DesignTokens.Colors.surfaceHighest.opacity(0.55))
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
                            .strokeBorder(DesignTokens.Colors.outlineVariant.opacity(0.7), lineWidth: 1)
                    }
                    .opacity(configuration.isPressed ? 0.82 : 1)
            }
    }
}

private struct UtilityEditorChrome: View {
    var body: some View {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
            .fill(DesignTokens.Colors.surfaceLowest.opacity(0.92))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
                    .strokeBorder(DesignTokens.Colors.outlineVariant.opacity(0.45), lineWidth: 1)
            }
    }
}
