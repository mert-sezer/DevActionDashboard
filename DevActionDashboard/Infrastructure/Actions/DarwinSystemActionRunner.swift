import AppKit
import Foundation

/// Performs real macOS system actions via shell, FileManager, NSWorkspace, and AppleScript.
struct DarwinSystemActionRunner: SystemActionRunning {
    private let shell: any ShellCommandRunning
    private let fileManager: FileManager

    init(
        shell: any ShellCommandRunning = ProcessShellRunner(),
        fileManager: FileManager = .default
    ) {
        self.shell = shell
        self.fileManager = fileManager
    }

    func perform(_ action: SystemActionKind) async throws -> SystemActionResult {
        switch action {
        case .flushDNS:
            return try await flushDNS()
        case .restartFinder:
            return try await killProcess(named: "Finder", action: action, success: "Finder restarted.")
        case .restartDock:
            return try await killProcess(named: "Dock", action: action, success: "Dock restarted.")
        case .clearXcodeDerivedData:
            return try clearDerivedData()
        case .openTerminal:
            return try openApplication(
                at: "/System/Applications/Utilities/Terminal.app",
                action: action,
                success: "Opened Terminal."
            )
        case .emptyTrash:
            return try emptyTrash()
        case .openDownloads:
            return try openUserDirectory(.downloadsDirectory, action: action, label: "Downloads")
        case .openDesktop:
            return try openUserDirectory(.desktopDirectory, action: action, label: "Desktop")
        }
    }

    // MARK: - Actions

    private func flushDNS() async throws -> SystemActionResult {
        var notes: [String] = []

        // User-level cache flush (does not require root).
        if let dscacheutil = resolveExecutable("dscacheutil", extras: ["/usr/bin/dscacheutil"]) {
            let result = try await shell.run(
                executable: dscacheutil,
                arguments: ["-flushcache"],
                timeoutSeconds: 8
            )
            if result.exitCode == 0 {
                notes.append("dscacheutil flushed")
            } else {
                notes.append("dscacheutil: \(result.stderrString.trimmedOr("exit \(result.exitCode)"))")
            }
        } else {
            notes.append("dscacheutil not found")
        }

        // Best-effort mDNSResponder refresh; may fail without privileges.
        if let killall = resolveExecutable("killall", extras: ["/usr/bin/killall"]) {
            let result = try await shell.run(
                executable: killall,
                arguments: ["-HUP", "mDNSResponder"],
                timeoutSeconds: 8
            )
            if result.exitCode == 0 {
                notes.append("mDNSResponder HUP sent")
            } else {
                notes.append("mDNSResponder HUP failed (may need admin privileges)")
            }
        }

        return SystemActionResult(action: .flushDNS, message: notes.joined(separator: " · "))
    }

    private func killProcess(named name: String, action: SystemActionKind, success: String) async throws -> SystemActionResult {
        guard let killall = resolveExecutable("killall", extras: ["/usr/bin/killall"]) else {
            throw SystemActionError.commandFailed("killall not found")
        }
        let result = try await shell.run(executable: killall, arguments: [name], timeoutSeconds: 8)
        // killall returns 1 if no matching process — still acceptable for restart intent.
        if result.exitCode == 0 || result.stderrString.localizedCaseInsensitiveContains("no matching processes") {
            return SystemActionResult(action: action, message: success)
        }
        let detail = result.stderrString.trimmedOr("exit \(result.exitCode)")
        throw SystemActionError.commandFailed(detail)
    }

    private func clearDerivedData() throws -> SystemActionResult {
        let derivedData = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Developer/Xcode/DerivedData", isDirectory: true)

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: derivedData.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return SystemActionResult(
                action: .clearXcodeDerivedData,
                message: "DerivedData folder not found (nothing to clear)."
            )
        }

        let contents = try fileManager.contentsOfDirectory(
            at: derivedData,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        var removed = 0
        for item in contents {
            let values = try item.resourceValues(forKeys: [.isSymbolicLinkKey])
            if values.isSymbolicLink == true {
                continue
            }
            try fileManager.removeItem(at: item)
            removed += 1
        }

        return SystemActionResult(
            action: .clearXcodeDerivedData,
            message: "Removed \(removed) item(s) from DerivedData."
        )
    }

    private func openApplication(at path: String, action: SystemActionKind, success: String) throws -> SystemActionResult {
        let url = URL(fileURLWithPath: path)
        guard fileManager.fileExists(atPath: path) else {
            throw SystemActionError.pathUnavailable(path)
        }
        let opened = NSWorkspace.shared.open(url)
        guard opened else {
            throw SystemActionError.commandFailed("NSWorkspace failed to open \(path)")
        }
        return SystemActionResult(action: action, message: success)
    }

    private func openUserDirectory(
        _ directory: FileManager.SearchPathDirectory,
        action: SystemActionKind,
        label: String
    ) throws -> SystemActionResult {
        guard let url = fileManager.urls(for: directory, in: .userDomainMask).first else {
            throw SystemActionError.pathUnavailable(label)
        }
        let opened = NSWorkspace.shared.open(url)
        guard opened else {
            throw SystemActionError.commandFailed("Could not open \(label)")
        }
        return SystemActionResult(action: action, message: "Opened \(label).")
    }

    private func emptyTrash() throws -> SystemActionResult {
        let script = "tell application \"Finder\" to empty the trash"
        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else {
            throw SystemActionError.appleScriptFailed("Could not create AppleScript")
        }
        _ = appleScript.executeAndReturnError(&error)
        if let error {
            let message = error[NSAppleScript.errorMessage] as? String ?? String(describing: error)
            throw SystemActionError.appleScriptFailed(message)
        }
        return SystemActionResult(action: .emptyTrash, message: "Trash emptied.")
    }

    // MARK: - Helpers

    private func resolveExecutable(_ name: String, extras: [String]) -> String? {
        ExecutableResolver.resolve(named: name, extraCandidates: extras)
    }
}

private extension String {
    func trimmedOr(_ fallback: String) -> String {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? fallback : value
    }
}
