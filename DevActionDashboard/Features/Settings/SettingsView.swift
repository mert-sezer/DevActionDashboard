import SwiftUI

struct SettingsView: View {
    @Bindable private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        FeaturePage(
            title: "Settings",
            subtitle: "Appearance, notifications, menu bar, and Docker CLI."
        ) {
            GlassPanel {
                SectionHeader("Appearance", subtitle: "Theme and accent used across DAD.")

                Picker("Theme", selection: $viewModel.appearance) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Theme")

                Picker("Accent", selection: $viewModel.accentColor) {
                    ForEach(AppAccentColor.allCases) { accent in
                        Text(accent.title).tag(accent)
                    }
                }
                .accessibilityLabel("Accent color")
            }

            GlassPanel {
                SectionHeader("Data refresh", subtitle: "How often live collectors update.")

                Picker("Refresh interval", selection: $viewModel.refreshInterval) {
                    ForEach(RefreshInterval.allCases) { interval in
                        Text(interval.title).tag(interval)
                    }
                }
                .accessibilityLabel("Refresh interval")
            }

            GlassPanel {
                SectionHeader("Notifications", subtitle: "Optional macOS alerts for completed actions.")

                Toggle("Enable notifications", isOn: $viewModel.notificationsEnabled)
                Toggle("Notify when Actions finish", isOn: $viewModel.notifyOnActionCompletion)
                    .disabled(!viewModel.notificationsEnabled)

                MetadataRow(label: "Permission", value: viewModel.authorizationStatusDescription)
            }

            GlassPanel {
                SectionHeader("Menu Bar", subtitle: "Show a compact DAD extra in the menu bar.")

                Toggle("Show menu bar extra", isOn: $viewModel.menuBarEnabled)
            }

            GlassPanel {
                SectionHeader("Docker", subtitle: "CLI used by the Docker feature.")

                TextField("Docker CLI path", text: $viewModel.dockerCLIPath)
                    .textFieldStyle(.roundedBorder)
                    .font(DesignTokens.Typography.mono)
                    .accessibilityLabel("Docker CLI path")

                Text("Examples: docker, /opt/homebrew/bin/docker, /usr/local/bin/docker")
                    .font(DesignTokens.Typography.secondary)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
            }

            GlassPanel {
                SectionHeader("Welcome", subtitle: "Replay the first-launch intro screen.")

                Button("Show welcome screen again") {
                    viewModel.showWelcomeAgain()
                }
            }
        }
        .onAppear { viewModel.onAppear() }
    }
}
