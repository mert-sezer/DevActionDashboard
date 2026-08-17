import Foundation

/// Failures raised while sampling host system metrics.
public enum MetricsError: Error, LocalizedError, Sendable, Equatable {
    case hostStatisticsUnavailable(String)
    case storageUnavailable
    case cpuSampleUnavailable

    public var errorDescription: String? {
        switch self {
        case .hostStatisticsUnavailable(let detail):
            return "Host statistics unavailable: \(detail)"
        case .storageUnavailable:
            return "Boot volume capacity could not be read."
        case .cpuSampleUnavailable:
            return "CPU load sample could not be read."
        }
    }
}
