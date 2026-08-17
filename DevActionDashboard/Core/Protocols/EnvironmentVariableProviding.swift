import Foundation

/// Reads the current process environment.
public protocol EnvironmentVariableProviding: Sendable {
    func snapshot() async -> EnvironmentVariableSnapshot
}
