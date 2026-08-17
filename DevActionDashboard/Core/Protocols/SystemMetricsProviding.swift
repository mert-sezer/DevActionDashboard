import Foundation

/// Collects a live system metrics snapshot from the host.
public protocol SystemMetricsProviding: Sendable {
    func sample() async throws -> SystemMetricsSnapshot
}
