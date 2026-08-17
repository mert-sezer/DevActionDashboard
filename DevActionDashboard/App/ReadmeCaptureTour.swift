import AppKit
import Foundation

/// Walks visible screens so `Scripts/capture-readme-media.sh` can photograph a live window.
/// Activated when `DAD_CAPTURE_README=1` or UserDefaults `capture.readme` is true.
enum ReadmeCaptureTour {
    @MainActor
    static func schedule(environment: AppEnvironment) {
        let defaults = UserDefaults.standard
        let envRequested = ProcessInfo.processInfo.environment["DAD_CAPTURE_README"] == "1"
        let defaultsRequested = defaults.bool(forKey: "capture.readme")
        guard envRequested || defaultsRequested else { return }

        defaults.set(false, forKey: "capture.readme")

        let directory = captureDirectory()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? Data("scheduled".utf8).write(to: directory.appendingPathComponent("boot"), options: .atomic)

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1_400))
            NSApp.activate(ignoringOtherApps: true)
            await run(environment: environment, directory: directory)
        }
    }

    @MainActor
    private static func run(environment: AppEnvironment, directory: URL) async {
        func signal(_ name: String) {
            let url = directory.appendingPathComponent("ready-\(name)")
            try? Data(name.utf8).write(to: url, options: .atomic)
        }

        environment.settingsStore.appearance = .dark
        environment.settingsStore.menuBarEnabled = false

        environment.settingsStore.hasCompletedWelcome = false
        try? await Task.sleep(for: .milliseconds(900))
        signal("welcome")
        try? await Task.sleep(for: .milliseconds(1_100))

        environment.settingsStore.hasCompletedWelcome = true
        try? await Task.sleep(for: .milliseconds(800))

        let pages: [(String, FeatureID)] = [
            ("dashboard", .dashboard),
            ("system", .system),
            ("processes", .processes),
            ("network", .network),
            ("ports", .ports),
            ("docker", .docker),
            ("environment", .environment),
            ("utilities", .utilities),
            ("actions", .actions)
        ]

        for (name, featureID) in pages {
            environment.navigationStore.closeCommandPalette()
            environment.navigationStore.navigate(to: featureID)
            try? await Task.sleep(for: .milliseconds(1_700))
            signal(name)
            try? await Task.sleep(for: .milliseconds(1_000))
        }

        environment.navigationStore.openCommandPalette()
        try? await Task.sleep(for: .milliseconds(800))
        signal("palette")
        try? await Task.sleep(for: .milliseconds(1_100))
        environment.navigationStore.closeCommandPalette()

        signal("done")
    }

    private static func captureDirectory() -> URL {
        let fromEnv = ProcessInfo.processInfo.environment["DAD_CAPTURE_DIR"]
        let fromDefaults = UserDefaults.standard.string(forKey: "capture.dir")
        return URL(
            fileURLWithPath: fromEnv ?? fromDefaults ?? NSTemporaryDirectory() + "dad-readme-capture",
            isDirectory: true
        )
    }
}
