import Foundation
import Observation

@MainActor
@Observable
final class PortsViewModel {
    private let portScanService: PortScanService

    var searchText = ""
    var stackFilter: DetectedDevStack?

    var isRefreshing: Bool { portScanService.isRefreshing }
    var errorMessage: String? { portScanService.lastErrorMessage }
    var actionMessage: String? { portScanService.actionMessage }
    var totalCount: Int { portScanService.latest?.entries.count ?? 0 }

    var visibleEntries: [LocalPortEntry] {
        let source = portScanService.latest?.entries ?? []
        return source.filter { entry in
            if let stackFilter, entry.detectedStack != stackFilter {
                return false
            }
            if searchText.isEmpty {
                return true
            }
            let query = searchText
            return "\(entry.port)".contains(query)
                || entry.processName.localizedCaseInsensitiveContains(query)
                || entry.detectedStack.title.localizedCaseInsensitiveContains(query)
                || entry.address.localizedCaseInsensitiveContains(query)
                || (entry.httpTitle?.localizedCaseInsensitiveContains(query) ?? false)
                || (entry.processPath?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    init(portScanService: PortScanService) {
        self.portScanService = portScanService
    }

    func onAppear() {
        portScanService.startMonitoring()
    }

    func onDisappear() {
        portScanService.stopMonitoring()
    }

    func refresh() {
        Task { await portScanService.refreshNow() }
    }

    func openInBrowser(_ entry: LocalPortEntry) {
        Task { await portScanService.openInBrowser(entry) }
    }
}
