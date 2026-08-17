import Foundation
import Testing
@testable import DevActionDashboard

@Suite("EnvironmentVariableComparison")
struct EnvironmentVariableComparisonTests {
    @Test("Detects equality and line differences")
    func comparesValues() {
        let comparison = EnvironmentVariableComparison(
            leftKey: "PATH",
            rightKey: "PATH_BACKUP",
            leftValue: "a\nb\nc",
            rightValue: "b\nc\nd"
        )
        #expect(comparison.areEqual == false)
        #expect(comparison.leftOnlyLines == ["a"])
        #expect(comparison.rightOnlyLines == ["d"])
        #expect(comparison.sharedLines == ["b", "c"])
    }
}

@Suite("EnvironmentVariableService")
@MainActor
struct EnvironmentVariableServiceTests {
    @Test("Loads variables from provider")
    func loadsVariables() async {
        let snapshot = EnvironmentVariableSnapshot(variables: [
            EnvironmentVariable(key: "HOME", value: "/Users/demo"),
            EnvironmentVariable(key: "PATH", value: "/usr/bin")
        ])
        let service = EnvironmentVariableService(provider: StubEnvProvider(snapshot: snapshot))
        await service.refreshNow()
        #expect(service.latest?.variables.count == 2)
        #expect(service.compare(leftKey: "HOME", rightKey: "PATH")?.areEqual == false)
    }
}

private struct StubEnvProvider: EnvironmentVariableProviding {
    let snapshot: EnvironmentVariableSnapshot
    func snapshot() async -> EnvironmentVariableSnapshot { snapshot }
}
