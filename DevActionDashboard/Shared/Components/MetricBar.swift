import SwiftUI

/// Accessible horizontal usage bar for ratio-based metrics.
struct MetricBar: View {
    let title: String
    let ratio: Double?
    let detail: String
    var symbolName: String = "gauge.with.dots.needle.33percent"

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack {
                Label(title, systemImage: symbolName)
                    .font(DesignTokens.Typography.secondary.weight(.semibold))
                Spacer()
                Text(detail)
                    .font(DesignTokens.Typography.mono)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: ratio ?? 0)
                .progressViewStyle(.linear)
                .tint(barColor)
                .animation(.easeInOut(duration: 0.25), value: ratio)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(detail)
    }

    private var barColor: Color {
        guard let ratio else { return .secondary }
        switch ratio {
        case 0..<0.7: return .accentColor
        case 0.7..<0.9: return .orange
        default: return .red
        }
    }
}
