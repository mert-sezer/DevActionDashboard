import Foundation
import Testing
@testable import DevActionDashboard

@Suite("SystemActionService")
@MainActor
struct SystemActionServiceTests {
    @Test("Records successful action results")
    func recordsSuccess() async {
        let runner = StubActionRunner(result: SystemActionResult(action: .openDesktop, message: "Opened Desktop."))
        let service = makeService(runner: runner)
        await service.perform(.openDesktop)
        #expect(service.lastResultMessage == "Opened Desktop.")
        #expect(service.lastErrorMessage == nil)
        #expect(runner.performed == [.openDesktop])
    }

    @Test("Surfaces runner failures")
    func surfacesFailures() async {
        let runner = StubActionRunner(error: .commandFailed("boom"))
        let service = makeService(runner: runner)
        await service.perform(.flushDNS)
        #expect(service.lastResultMessage == nil)
        #expect(service.lastErrorMessage == "boom")
    }

    private func makeService(runner: StubActionRunner) -> SystemActionService {
        let defaults = UserDefaults(suiteName: "SystemActionServiceTests.\(UUID().uuidString)")!
        return SystemActionService(
            runner: runner,
            settingsStore: SettingsStore(defaults: defaults)
        )
    }
}

@Suite("ActionsViewModel confirmation")
@MainActor
struct ActionsViewModelTests {
    @Test("Queues destructive actions for confirmation")
    func queuesConfirmation() {
        let defaults = UserDefaults(suiteName: "ActionsViewModelTests.\(UUID().uuidString)")!
        let service = SystemActionService(
            runner: StubActionRunner(result: SystemActionResult(action: .emptyTrash, message: "ok")),
            settingsStore: SettingsStore(defaults: defaults)
        )
        let viewModel = ActionsViewModel(service: service)
        viewModel.request(.emptyTrash)
        #expect(viewModel.pendingAction == .emptyTrash)
    }

    @Test("Runs non-confirm actions immediately")
    func runsImmediately() async {
        let runner = StubActionRunner(result: SystemActionResult(action: .openDownloads, message: "Opened Downloads."))
        let defaults = UserDefaults(suiteName: "ActionsViewModelTests.run.\(UUID().uuidString)")!
        let service = SystemActionService(
            runner: runner,
            settingsStore: SettingsStore(defaults: defaults)
        )
        let viewModel = ActionsViewModel(service: service)
        viewModel.request(.openDownloads)
        // Allow async task to schedule.
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(20))
        #expect(runner.performed.contains(.openDownloads))
    }
}

private final class StubActionRunner: SystemActionRunning, @unchecked Sendable {
    private let result: SystemActionResult?
    private let error: SystemActionError?
    private(set) var performed: [SystemActionKind] = []

    init(result: SystemActionResult) {
        self.result = result
        self.error = nil
    }

    init(error: SystemActionError) {
        self.result = nil
        self.error = error
    }

    func perform(_ action: SystemActionKind) async throws -> SystemActionResult {
        performed.append(action)
        if let error {
            throw error
        }
        return result ?? SystemActionResult(action: action, message: "ok")
    }
}
