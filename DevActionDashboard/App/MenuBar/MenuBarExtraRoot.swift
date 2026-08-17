import AppKit
import SwiftUI

/// Menu bar extra with live metrics and window control.
struct MenuBarExtraRoot: View {
    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Dev Action Dashboard")
                .font(DesignTokens.Typography.title)

            if let metrics = environment.systemMetricsService.latest {
                labeledRow("CPU", MetricsFormatter.percent(metrics.cpu.usageRatio))
                labeledRow("Memory", MetricsFormatter.percent(metrics.memory.usageRatio))
                labeledRow("Storage", MetricsFormatter.percent(metrics.storage.usageRatio))
            } else {
                Text("Sampling…")
                    .font(DesignTokens.Typography.secondary)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button("Open DAD") {
                openMainWindow()
            }
            .keyboardShortcut("o")

            Button("Command Palette") {
                openMainWindow()
                environment.navigationStore.openCommandPalette()
            }
            .keyboardShortcut("k")

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(DesignTokens.Spacing.sm)
        .frame(width: 240)
        .onAppear {
            environment.systemMetricsService.startMonitoring()
        }
    }

    private func labeledRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(DesignTokens.Typography.monoCaption)
                .monospacedDigit()
        }
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }
}
