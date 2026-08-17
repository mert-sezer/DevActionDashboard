import Foundation

/// Reads boot volume capacity using Foundation resource values.
struct StorageSampler: Sendable {
    func sample(volumeURL: URL = URL(fileURLWithPath: "/")) throws -> StorageMetrics {
        let values = try volumeURL.resourceValues(forKeys: [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey
        ])

        guard let total = values.volumeTotalCapacity.map(UInt64.init) else {
            throw MetricsError.storageUnavailable
        }

        let free: UInt64
        if let important = values.volumeAvailableCapacityForImportantUsage {
            free = UInt64(important)
        } else if let available = values.volumeAvailableCapacity {
            free = UInt64(available)
        } else {
            throw MetricsError.storageUnavailable
        }

        return StorageMetrics(
            totalBytes: total,
            freeBytes: free,
            volumeName: values.volumeName ?? "Macintosh HD"
        )
    }
}
