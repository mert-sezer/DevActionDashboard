import Foundation
import Testing
@testable import DevActionDashboard

@Suite("ProcessesViewModel filtering")
@MainActor
struct ProcessesViewModelTests {
    @Test("Filters by name and sorts by memory")
    func filtersAndSorts() async {
        let snapshot = ProcessListSnapshot(processes: [
            RunningProcess(
                pid: 10,
                name: "Xcode",
                path: "/Applications/Xcode.app",
                userID: 501,
                cpuUsageRatio: 0.1,
                residentMemoryBytes: 2_000,
                threadCount: 20
            ),
            RunningProcess(
                pid: 20,
                name: "Safari",
                path: "/Applications/Safari.app",
                userID: 501,
                cpuUsageRatio: 0.5,
                residentMemoryBytes: 4_000,
                threadCount: 12
            ),
            RunningProcess(
                pid: 30,
                name: "node",
                path: "/usr/local/bin/node",
                userID: 501,
                cpuUsageRatio: 0.9,
                residentMemoryBytes: 1_000,
                threadCount: 8
            )
        ])

        let defaults = UserDefaults(suiteName: "ProcessesViewModelTests.\(UUID().uuidString)")!
        let settings = SettingsStore(defaults: defaults)
        let service = ProcessService(
            provider: StubProcessProvider(snapshot: snapshot),
            activityMonitor: StubActivityMonitor(),
            settingsStore: settings
        )
        await service.refreshNow()

        let viewModel = ProcessesViewModel(processService: service)
        viewModel.searchText = "Saf"
        viewModel.sortKey = .memory

        let names = viewModel.visibleProcesses.map(\.name)
        #expect(names == ["Safari"])
    }
}

@Suite("ProcessService termination")
@MainActor
struct ProcessServiceTests {
    @Test("Propagates terminate to provider")
    func terminatesViaProvider() async {
        let provider = StubProcessProvider(
            snapshot: ProcessListSnapshot(processes: [
                RunningProcess(
                    pid: 99,
                    name: "demo",
                    path: nil,
                    userID: 501,
                    cpuUsageRatio: 0.1,
                    residentMemoryBytes: 100,
                    threadCount: 1
                )
            ])
        )
        let defaults = UserDefaults(suiteName: "ProcessServiceTests.\(UUID().uuidString)")!
        let service = ProcessService(
            provider: provider,
            activityMonitor: StubActivityMonitor(),
            settingsStore: SettingsStore(defaults: defaults)
        )

        await service.terminate(pid: 99, force: false)

        #expect(provider.terminatedPIDs == [99])
        #expect(provider.forceFlags == [false])
        #expect(service.actionMessage != nil)
    }

    @Test("Surfaces protected process errors")
    func surfacesProtectedProcess() async {
        let provider = StubProcessProvider(
            snapshot: ProcessListSnapshot(processes: []),
            terminateError: .protectedProcess(1)
        )
        let defaults = UserDefaults(suiteName: "ProcessServiceProtected.\(UUID().uuidString)")!
        let service = ProcessService(
            provider: provider,
            activityMonitor: StubActivityMonitor(),
            settingsStore: SettingsStore(defaults: defaults)
        )

        await service.terminate(pid: 1, force: true)

        #expect(service.lastErrorMessage != nil)
        #expect(service.actionMessage == nil)
    }
}

@Suite("Process CPU ratio math")
struct ProcessCPUMathTests {
    @Test("Computes single-core fraction from nanosecond deltas")
    func cpuFraction() {
        let previousUser: UInt64 = 1_000_000
        let currentUser: UInt64 = 1_000_000 + 50_000_000
        let cpuDelta = Double(currentUser &- previousUser)
        let elapsedNanos = 100_000_000.0
        #expect(cpuDelta / elapsedNanos == 0.5)
    }
}

private final class StubProcessProvider: ProcessProviding, @unchecked Sendable {
    let snapshot: ProcessListSnapshot
    let terminateError: ProcessError?
    private(set) var terminatedPIDs: [Int32] = []
    private(set) var forceFlags: [Bool] = []

    init(snapshot: ProcessListSnapshot, terminateError: ProcessError? = nil) {
        self.snapshot = snapshot
        self.terminateError = terminateError
    }

    func listProcesses() async throws -> ProcessListSnapshot {
        snapshot
    }

    func terminateProcess(pid: Int32, force: Bool) async throws {
        if let terminateError {
            throw terminateError
        }
        terminatedPIDs.append(pid)
        forceFlags.append(force)
    }
}

private struct StubActivityMonitor: ActivityMonitorLaunching {
    func openActivityMonitor() async throws {}
}
