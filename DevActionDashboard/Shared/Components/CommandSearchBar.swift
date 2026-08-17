import SwiftUI

/// Command palette search field with a cycling suggestion phrase.
struct CommandSearchBar: View {
    let phrases: [String]
    let onActivate: () -> Void

    @State private var phraseIndex = 0
    @State private var phraseOpacity = 1.0
    @State private var isHovered = false
    @State private var cycleTask: Task<Void, Never>?

    private var currentPhrase: String {
        guard !phrases.isEmpty else { return "Search…" }
        return phrases[phraseIndex % phrases.count]
    }

    var body: some View {
        Button(action: onActivate) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DesignTokens.Colors.primary)

                ZStack(alignment: .leading) {
                    Text("Search \(currentPhrase)…")
                        .font(DesignTokens.Typography.monoCaption)
                        .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                        .opacity(phraseOpacity)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .animation(.easeInOut(duration: 0.35), value: phraseOpacity)
                        .animation(.easeInOut(duration: 0.35), value: phraseIndex)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 4) {
                    keyCap("⌘")
                    keyCap("K")
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, 8)
            .frame(minWidth: 280, idealWidth: 340, maxWidth: 420)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
                    .fill(DesignTokens.Colors.surfaceLowest.opacity(isHovered ? 1 : 0.92))
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
                            .strokeBorder(
                                isHovered
                                    ? DesignTokens.Colors.primary.opacity(0.55)
                                    : DesignTokens.Colors.outlineVariant.opacity(0.65),
                                lineWidth: 1
                            )
                    }
                    .shadow(
                        color: DesignTokens.Colors.primaryContainer.opacity(isHovered ? 0.18 : 0.06),
                        radius: isHovered ? 10 : 4,
                        y: 2
                    )
            }
        }
        .buttonStyle(.plain)
        .help("Command Palette (⌘K)")
        .accessibilityLabel("Command Palette")
        .accessibilityHint("Cycles suggestions: \(phrases.joined(separator: ", ")). Opens search.")
        .onHover { hovering in
            withAnimation(DesignTokens.Motion.quick) {
                isHovered = hovering
            }
        }
        .onAppear { startCycling() }
        .onDisappear {
            cycleTask?.cancel()
            cycleTask = nil
        }
        .onChange(of: phrases) { _, _ in
            phraseIndex = 0
            startCycling()
        }
    }

    private func keyCap(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(DesignTokens.Colors.surfaceHighest.opacity(0.9))
                    .overlay {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .strokeBorder(DesignTokens.Colors.outlineVariant.opacity(0.5), lineWidth: 1)
                    }
            }
    }

    private func startCycling() {
        cycleTask?.cancel()
        guard phrases.count > 1 else { return }

        cycleTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.4))
                guard !Task.isCancelled else { return }

                withAnimation(.easeInOut(duration: 0.28)) {
                    phraseOpacity = 0
                }

                try? await Task.sleep(for: .milliseconds(280))
                guard !Task.isCancelled else { return }

                phraseIndex = (phraseIndex + 1) % phrases.count

                withAnimation(.easeInOut(duration: 0.35)) {
                    phraseOpacity = 1
                }
            }
        }
    }
}

extension CommandSearchBar {
    /// Default suggestion phrases for the command search field.
    static var defaultPhrases: [String] {
        [
            "Dashboard",
            "System",
            "Processes",
            "Network",
            "Ports",
            "Docker",
            "Environment",
            "Env Vars",
            "Utilities",
            "Actions",
            "Settings",
            "About"
        ]
    }
}
