import Foundation

/// Reads `ProcessInfo.processInfo.environment`.
struct ProcessEnvironmentVariableProvider: EnvironmentVariableProviding {
    func snapshot() async -> EnvironmentVariableSnapshot {
        let variables = ProcessInfo.processInfo.environment
            .map { EnvironmentVariable(key: $0.key, value: $0.value) }
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
        return EnvironmentVariableSnapshot(variables: variables)
    }
}
