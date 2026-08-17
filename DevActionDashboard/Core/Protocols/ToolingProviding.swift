import Foundation

/// Discovers installed developer toolchains and their versions.
public protocol ToolingProviding: Sendable {
    func probe() async throws -> ToolingSnapshot
}
