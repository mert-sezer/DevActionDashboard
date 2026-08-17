import Foundation

/// Collects a live network observability snapshot.
public protocol NetworkProviding: Sendable {
    func sample() async throws -> NetworkSnapshot
}
