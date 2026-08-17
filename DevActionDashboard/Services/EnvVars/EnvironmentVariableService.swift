import Foundation
import Observation

/// Facade for viewing and comparing process environment variables.
@MainActor
@Observable
final class EnvironmentVariableService {
    private(set) var latest: EnvironmentVariableSnapshot?
    private(set) var isRefreshing = false

    private let provider: any EnvironmentVariableProviding

    init(provider: any EnvironmentVariableProviding) {
        self.provider = provider
    }

    func refreshNow() async {
        isRefreshing = true
        defer { isRefreshing = false }
        latest = await provider.snapshot()
        AppLog.envVars.debug("Loaded \(self.latest?.variables.count ?? 0) environment variables")
    }

    func compare(leftKey: String, rightKey: String) -> EnvironmentVariableComparison? {
        guard let variables = latest?.variables else { return nil }
        guard
            let left = variables.first(where: { $0.key == leftKey }),
            let right = variables.first(where: { $0.key == rightKey })
        else {
            return nil
        }
        return EnvironmentVariableComparison(
            leftKey: left.key,
            rightKey: right.key,
            leftValue: left.value,
            rightValue: right.value
        )
    }
}
