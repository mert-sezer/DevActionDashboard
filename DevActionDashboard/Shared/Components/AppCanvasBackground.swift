import SwiftUI

/// Window canvas with a subtle accent glow.
public struct AppCanvasBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        ZStack {
            DesignTokens.Colors.background

            RadialGradient(
                colors: [
                    DesignTokens.Colors.primaryContainer.opacity(colorScheme == .dark ? 0.18 : 0.10),
                    .clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 560
            )

            RadialGradient(
                colors: [
                    DesignTokens.Colors.primary.opacity(colorScheme == .dark ? 0.08 : 0.05),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 10,
                endRadius: 480
            )
        }
        .ignoresSafeArea()
    }
}
