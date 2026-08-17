import SwiftUI

/// Elevated card with a hairline stroke.
public struct GlassPanel<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    private let content: Content
    private let luminous: Bool

    public init(luminous: Bool = false, @ViewBuilder content: () -> Content) {
        self.luminous = luminous
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            content
        }
        .padding(DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                if luminous {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.panel, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [
                                    DesignTokens.Colors.primaryContainer.opacity(colorScheme == .dark ? 0.15 : 0.08),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 180
                            )
                        )
                        .scaleEffect(1.12)
                        .blur(radius: 8)
                }

                RoundedRectangle(cornerRadius: DesignTokens.Radius.panel, style: .continuous)
                    .fill(DesignTokens.Colors.card.opacity(colorScheme == .dark ? 0.92 : 0.88))
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: DesignTokens.Radius.panel, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.panel, style: .continuous)
                            .strokeBorder(
                                DesignTokens.Colors.outlineVariant.opacity(colorScheme == .dark ? 0.55 : 0.70),
                                lineWidth: 1
                            )
                    }
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.04),
                        radius: colorScheme == .dark ? 10 : 4,
                        y: colorScheme == .dark ? 4 : 2
                    )
            }
        }
    }
}

/// Compact metric tile for dashboard grids.
public struct MetricCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let value: String
    let detail: String?
    let symbolName: String
    let ratio: Double?
    let accent: Color

    public init(
        title: String,
        value: String,
        detail: String? = nil,
        symbolName: String,
        ratio: Double? = nil,
        accent: Color = DesignTokens.Colors.primary
    ) {
        self.title = title
        self.value = value
        self.detail = detail
        self.symbolName = symbolName
        self.ratio = ratio
        self.accent = accent
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text(title.uppercased())
                    .font(DesignTokens.Typography.labelCaps)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                    .tracking(0.8)
                Spacer()
                Image(systemName: symbolName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(accent)
            }

            Text(value)
                .font(DesignTokens.Typography.metric)
                .foregroundStyle(DesignTokens.Colors.onSurface)
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let detail {
                Text(detail)
                    .font(DesignTokens.Typography.monoCaption)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                    .lineLimit(1)
            }

            if let ratio {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(DesignTokens.Colors.surfaceHighest)
                        Capsule()
                            .fill(barColor(for: ratio))
                            .frame(width: max(4, geo.size.width * ratio))
                    }
                }
                .frame(height: 6)
                .animation(DesignTokens.Motion.quick, value: ratio)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                .fill(DesignTokens.Colors.card)
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                        .strokeBorder(
                            DesignTokens.Colors.outlineVariant.opacity(colorScheme == .dark ? 0.65 : 0.80),
                            lineWidth: 1
                        )
                }
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.12 : 0.03),
                    radius: colorScheme == .dark ? 8 : 3,
                    y: 2
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value)")
    }

    private func barColor(for ratio: Double) -> Color {
        switch ratio {
        case 0..<0.7: accent
        case 0.7..<0.9: DesignTokens.Colors.tertiary
        default: DesignTokens.Colors.error
        }
    }
}

public struct SectionHeader: View {
    let title: String
    let subtitle: String?

    public init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(DesignTokens.Typography.title)
                .foregroundStyle(DesignTokens.Colors.onSurface)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .font(DesignTokens.Typography.secondary)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
            }
        }
    }
}

/// Filled primary button using the app accent.
public struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignTokens.Typography.body.weight(.semibold))
            .foregroundStyle(colorScheme == .dark
                ? DesignTokens.Colors.onPrimaryContainer
                : Color.white)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
                    .fill(DesignTokens.Colors.primaryContainer)
                    .opacity(configuration.isPressed ? 0.85 : 1)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(DesignTokens.Motion.quick, value: configuration.isPressed)
    }
}
