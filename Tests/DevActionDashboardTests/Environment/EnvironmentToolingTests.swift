import Foundation
import Testing
@testable import DevActionDashboard

@Suite("LocalToolchainDetector version parsing")
struct ToolchainVersionParsingTests {
    @Test("Extracts semver-like tokens")
    func extractsVersions() {
        #expect(LocalToolchainDetector.extractVersion(from: "v20.11.1") == "20.11.1")
        #expect(LocalToolchainDetector.extractVersion(from: "go version go1.22.5 darwin/arm64") == "1.22.5")
        #expect(LocalToolchainDetector.extractVersion(from: "Homebrew 4.3.0") == "4.3.0")
        #expect(LocalToolchainDetector.extractVersion(from: "rustc 1.79.0 (129f3b996 2024-06-10)") == "1.79.0")
    }
}

@Suite("EnvironmentViewModel filtering")
@MainActor
struct EnvironmentViewModelFilteringTests {
    @Test("Filters installed tools and search")
    func filters() async {
        let snapshot = ToolingSnapshot(tools: [
            InstalledTool(kind: .node, isInstalled: true, version: "20.11.1", path: "/opt/homebrew/bin/node"),
            InstalledTool(kind: .rust, isInstalled: false, version: nil, path: nil),
            InstalledTool(kind: .python, isInstalled: true, version: "3.12.0", path: "/usr/bin/python3")
        ])

        let service = EnvironmentToolingService(provider: StubToolingProvider(snapshot: snapshot))
        await service.refreshNow()

        let viewModel = EnvironmentViewModel(toolingService: service)
        viewModel.showInstalledOnly = true
        #expect(viewModel.visibleTools.map(\.kind) == [.node, .python])

        viewModel.searchText = "rust"
        viewModel.showInstalledOnly = false
        #expect(viewModel.visibleTools.map(\.kind) == [.rust])
    }
}

@Suite("EnvironmentToolingService")
@MainActor
struct EnvironmentToolingServiceTests {
    @Test("Stores probe snapshot")
    func storesSnapshot() async {
        let snapshot = ToolingSnapshot(tools: [
            InstalledTool(kind: .homebrew, isInstalled: true, version: "4.3.0", path: "/opt/homebrew/bin/brew")
        ])
        let service = EnvironmentToolingService(provider: StubToolingProvider(snapshot: snapshot))
        await service.refreshNow()
        #expect(service.latest == snapshot)
        #expect(service.latest?.installedCount == 1)
    }
}

private struct StubToolingProvider: ToolingProviding {
    let snapshot: ToolingSnapshot

    func probe() async throws -> ToolingSnapshot {
        snapshot
    }
}
