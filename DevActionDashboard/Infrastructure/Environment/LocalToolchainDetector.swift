import Foundation

/// Probes common developer CLIs for install path and version.
struct LocalToolchainDetector: ToolingProviding {
    private let shell: any ShellCommandRunning

    init(shell: any ShellCommandRunning = ProcessShellRunner()) {
        self.shell = shell
    }

    func probe() async throws -> ToolingSnapshot {
        var tools: [InstalledTool] = []
        tools.reserveCapacity(DeveloperToolKind.allCases.count)

        for kind in DeveloperToolKind.allCases {
            tools.append(await probe(kind))
        }

        return ToolingSnapshot(tools: tools)
    }

    // MARK: - Per tool

    private func probe(_ kind: DeveloperToolKind) async -> InstalledTool {
        switch kind {
        case .node:
            return await probeCLI(kind: kind, executableName: "node", arguments: ["--version"], extra: [
                "/opt/homebrew/bin/node",
                "/usr/local/bin/node"
            ])
        case .npm:
            return await probeCLI(kind: kind, executableName: "npm", arguments: ["--version"], extra: [
                "/opt/homebrew/bin/npm",
                "/usr/local/bin/npm"
            ])
        case .pnpm:
            return await probeCLI(kind: kind, executableName: "pnpm", arguments: ["--version"], extra: [
                "/opt/homebrew/bin/pnpm",
                "/usr/local/bin/pnpm"
            ])
        case .yarn:
            return await probeCLI(kind: kind, executableName: "yarn", arguments: ["--version"], extra: [
                "/opt/homebrew/bin/yarn",
                "/usr/local/bin/yarn"
            ])
        case .bun:
            return await probeCLI(kind: kind, executableName: "bun", arguments: ["--version"], extra: [
                "/opt/homebrew/bin/bun",
                "\(NSHomeDirectory())/.bun/bin/bun"
            ])
        case .python:
            return await probePython()
        case .java:
            return await probeCLI(
                kind: kind,
                executableName: "java",
                arguments: ["-version"],
                extra: ["/usr/bin/java"],
                preferStderr: true
            )
        case .go:
            return await probeCLI(kind: kind, executableName: "go", arguments: ["version"], extra: [
                "/opt/homebrew/bin/go",
                "/usr/local/go/bin/go"
            ])
        case .rust:
            return await probeCLI(kind: kind, executableName: "rustc", arguments: ["--version"], extra: [
                "/opt/homebrew/bin/rustc",
                "\(NSHomeDirectory())/.cargo/bin/rustc"
            ])
        case .flutter:
            return await probeCLI(kind: kind, executableName: "flutter", arguments: ["--version", "--machine"], extra: [
                "/opt/homebrew/bin/flutter",
                "\(NSHomeDirectory())/flutter/bin/flutter",
                "\(NSHomeDirectory())/development/flutter/bin/flutter"
            ], versionParser: parseFlutterMachineVersion)
        case .androidSDK:
            return probeAndroidSDK()
        case .xcode:
            return await probeXcode()
        case .homebrew:
            return await probeCLI(kind: kind, executableName: "brew", arguments: ["--version"], extra: [
                "/opt/homebrew/bin/brew",
                "/usr/local/bin/brew"
            ])
        }
    }

    private func probePython() async -> InstalledTool {
        let python3 = await probeCLI(
            kind: .python,
            executableName: "python3",
            arguments: ["--version"],
            extra: ["/opt/homebrew/bin/python3", "/usr/bin/python3"]
        )
        if python3.isInstalled {
            return python3
        }
        return await probeCLI(
            kind: .python,
            executableName: "python",
            arguments: ["--version"],
            extra: ["/opt/homebrew/bin/python", "/usr/bin/python"]
        )
    }

    private func probeAndroidSDK() -> InstalledTool {
        let env = ProcessInfo.processInfo.environment
        let roots = [env["ANDROID_HOME"], env["ANDROID_SDK_ROOT"]].compactMap { $0 }.filter { !$0.isEmpty }
        let fileManager = FileManager.default

        for root in roots {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: root, isDirectory: &isDirectory), isDirectory.boolValue {
                let adb = URL(fileURLWithPath: root).appendingPathComponent("platform-tools/adb").path
                let detail = fileManager.isExecutableFile(atPath: adb) ? "platform-tools present" : "SDK root found"
                return InstalledTool(
                    kind: .androidSDK,
                    isInstalled: true,
                    version: nil,
                    path: root,
                    detail: detail
                )
            }
        }

        let defaultRoots = [
            "\(NSHomeDirectory())/Library/Android/sdk",
            "/usr/local/share/android-sdk"
        ]
        for root in defaultRoots {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: root, isDirectory: &isDirectory), isDirectory.boolValue {
                return InstalledTool(
                    kind: .androidSDK,
                    isInstalled: true,
                    version: nil,
                    path: root,
                    detail: "Discovered at default location"
                )
            }
        }

        return InstalledTool(kind: .androidSDK, isInstalled: false, version: nil, path: nil, detail: "ANDROID_HOME not set")
    }

    private func probeXcode() async -> InstalledTool {
        let xcodebuild = await probeCLI(
            kind: .xcode,
            executableName: "xcodebuild",
            arguments: ["-version"],
            extra: ["/usr/bin/xcodebuild"]
        )

        let developerDir = await readDeveloperDirectory()
        if xcodebuild.isInstalled {
            return InstalledTool(
                kind: .xcode,
                isInstalled: true,
                version: xcodebuild.version,
                path: developerDir ?? xcodebuild.path,
                detail: developerDir.map { "Developer dir: \($0)" }
            )
        }

        return InstalledTool(
            kind: .xcode,
            isInstalled: false,
            version: nil,
            path: developerDir,
            detail: developerDir == nil ? "xcodebuild not found" : "Xcode tools incomplete"
        )
    }

    private func readDeveloperDirectory() async -> String? {
        guard let select = ExecutableResolver.resolve(named: "xcode-select", extraCandidates: ["/usr/bin/xcode-select"]) else {
            return nil
        }
        do {
            let result = try await shell.run(executable: select, arguments: ["-p"], timeoutSeconds: 3)
            guard result.exitCode == 0 else { return nil }
            let path = result.stdoutString.trimmingCharacters(in: .whitespacesAndNewlines)
            return path.isEmpty ? nil : path
        } catch {
            return nil
        }
    }

    private func probeCLI(
        kind: DeveloperToolKind,
        executableName: String,
        arguments: [String],
        extra: [String],
        preferStderr: Bool = false,
        versionParser: ((String) -> String?)? = nil
    ) async -> InstalledTool {
        guard let path = ExecutableResolver.resolve(named: executableName, extraCandidates: extra) else {
            return InstalledTool(kind: kind, isInstalled: false, version: nil, path: nil)
        }

        do {
            let result = try await shell.run(executable: path, arguments: arguments, timeoutSeconds: 4)
            let combined = preferStderr
                ? (result.stderrString.isEmpty ? result.stdoutString : result.stderrString)
                : (result.stdoutString.isEmpty ? result.stderrString : result.stdoutString)

            // Many CLIs return 0; java -version returns 0 too. Accept output even if non-zero when text exists.
            let raw = combined.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !raw.isEmpty else {
                return InstalledTool(kind: kind, isInstalled: true, version: nil, path: path, detail: "Installed (version unavailable)")
            }

            let version = versionParser?(raw) ?? Self.extractVersion(from: raw)
            return InstalledTool(kind: kind, isInstalled: true, version: version, path: path)
        } catch {
            return InstalledTool(
                kind: kind,
                isInstalled: true,
                version: nil,
                path: path,
                detail: "Found, but version probe failed"
            )
        }
    }

    static func extractVersion(from raw: String) -> String? {
        let firstLine = raw.split(whereSeparator: \.isNewline).first.map(String.init) ?? raw
        let pattern = #"(\d+(?:\.\d+){0,3}(?:[-+][0-9A-Za-z.]+)?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return String(firstLine.prefix(80))
        }
        let range = NSRange(firstLine.startIndex..<firstLine.endIndex, in: firstLine)
        guard let match = regex.firstMatch(in: firstLine, range: range),
              let versionRange = Range(match.range(at: 1), in: firstLine)
        else {
            return String(firstLine.prefix(80))
        }
        return String(firstLine[versionRange])
    }

    private func parseFlutterMachineVersion(_ raw: String) -> String? {
        // flutter --version --machine returns JSON; fall back to text extraction.
        if let data = raw.data(using: .utf8),
           let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let framework = object["frameworkVersion"] as? String {
            return framework
        }
        return Self.extractVersion(from: raw)
    }
}
