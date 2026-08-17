import SwiftUI

@main
struct DevActionDashboardApp: App {
    @State private var environment: AppEnvironment

    init() {
        let environment = AppEnvironment()
        _environment = State(initialValue: environment)
        ReadmeCaptureTour.schedule(environment: environment)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if environment.settingsStore.hasCompletedWelcome {
                    RootView(environment: environment)
                } else {
                    WelcomeView(
                        onGetStarted: completeWelcome,
                        onSkip: completeWelcome
                    )
                }
            }
            .preferredColorScheme(environment.settingsStore.appearance.colorScheme)
            .tint(environment.settingsStore.accentColor.color ?? DesignTokens.Colors.primaryContainer)
            .frame(minWidth: 960, minHeight: 600)
            .animation(DesignTokens.Motion.panel, value: environment.settingsStore.hasCompletedWelcome)
        }
        .defaultSize(width: 1180, height: 740)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Command Palette…") {
                    environment.navigationStore.openCommandPalette()
                }
                .keyboardShortcut("k", modifiers: .command)
            }
        }

        MenuBarExtra(
            "DAD",
            systemImage: "square.grid.2x2.fill",
            isInserted: menuBarInserted
        ) {
            MenuBarExtraRoot(environment: environment)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(
                viewModel: SettingsViewModel(
                    store: environment.settingsStore,
                    notificationService: environment.notificationService
                )
            )
            .preferredColorScheme(environment.settingsStore.appearance.colorScheme)
            .tint(environment.settingsStore.accentColor.color ?? DesignTokens.Colors.primaryContainer)
            .frame(minWidth: 480, minHeight: 520)
        }
    }

    private var menuBarInserted: Binding<Bool> {
        Binding(
            get: { environment.settingsStore.menuBarEnabled },
            set: { environment.settingsStore.menuBarEnabled = $0 }
        )
    }

    private func completeWelcome() {
        environment.settingsStore.hasCompletedWelcome = true
    }
}
