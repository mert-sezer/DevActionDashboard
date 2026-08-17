import Foundation
import Network

/// Reads the current `NWPath` via `NWPathMonitor`.
final class NetworkPathSampler: @unchecked Sendable {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.mertsezer.DevActionDashboard.NWPathMonitor")
    private let lock = NSLock()
    private var latestPath: NWPath?

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            self.lock.lock()
            self.latestPath = path
            self.lock.unlock()
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    func currentStatus() -> NetworkPathStatus {
        lock.lock()
        let path = latestPath ?? monitor.currentPath
        lock.unlock()

        let usesWiFi = path.usesInterfaceType(.wifi)
        let usesWired = path.usesInterfaceType(.wiredEthernet)
        let usesCellular = path.usesInterfaceType(.cellular)

        let description: String
        if path.status != .satisfied {
            description = "Offline"
        } else if usesWiFi {
            description = "Online · Wi‑Fi"
        } else if usesWired {
            description = "Online · Ethernet"
        } else if usesCellular {
            description = "Online · Cellular"
        } else {
            description = "Online"
        }

        return NetworkPathStatus(
            isSatisfied: path.status == .satisfied,
            isExpensive: path.isExpensive,
            isConstrained: path.isConstrained,
            usesWiFi: usesWiFi,
            usesWired: usesWired,
            usesCellular: usesCellular,
            statusDescription: description
        )
    }
}
