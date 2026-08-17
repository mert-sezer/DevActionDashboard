import SwiftUI

/// First-launch welcome screen.
struct WelcomeView: View {
    let onGetStarted: () -> Void
    let onSkip: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            AppCanvasBackground()

            VStack(spacing: 0) {
                Spacer(minLength: DesignTokens.Spacing.xl)

                VStack(spacing: DesignTokens.Spacing.lg) {
                    brandMark
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)

                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Text("DAD")
                            .font(.system(size: 36, weight: .semibold, design: .default))
                            .foregroundStyle(DesignTokens.Colors.onSurface)
                            .tracking(-0.5)

                        Text("Dev Action Dashboard")
                            .font(DesignTokens.Typography.title)
                            .foregroundStyle(DesignTokens.Colors.primary)

                        Text("The Ultimate Developer Action Center for macOS.")
                            .font(DesignTokens.Typography.body)
                            .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                            .padding(.top, DesignTokens.Spacing.xs)

                        Text("System, Docker, ports, toolchains, and developer utilities — in one native window.")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.onSurfaceVariant.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 420)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                }

                Spacer(minLength: DesignTokens.Spacing.xl)

                VStack(spacing: DesignTokens.Spacing.sm) {
                    Button(action: onGetStarted) {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Text("Get Started")
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: 320)

                    Button("Continue without intro", action: onSkip)
                        .buttonStyle(.plain)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                Spacer(minLength: DesignTokens.Spacing.lg)

                Text("macOS 14+ · Local-only · No account required")
                    .font(DesignTokens.Typography.monoCaption)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant.opacity(0.45))
                    .padding(.bottom, DesignTokens.Spacing.lg)
                    .opacity(appeared ? 1 : 0)
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .frame(maxWidth: 1180, maxHeight: 740)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(DesignTokens.Motion.welcome) {
                appeared = true
            }
        }
    }

    private var brandMark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(DesignTokens.Colors.card)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(DesignTokens.Colors.outlineVariant.opacity(0.55), lineWidth: 1)
                }
                .shadow(color: DesignTokens.Colors.primaryContainer.opacity(0.22), radius: 28, y: 10)

            LinearGradient(
                colors: [Color.white.opacity(0.35), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(DesignTokens.Colors.primary)
        }
        .frame(width: 128, height: 128)
        .accessibilityHidden(true)
    }
}
