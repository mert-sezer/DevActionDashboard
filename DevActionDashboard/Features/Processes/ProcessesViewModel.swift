import Foundation
import Observation

@MainActor
@Observable
final class ProcessesViewModel {
    private let processService: ProcessService

    var searchText = ""
    var sortKey: ProcessSortKey = .cpu
    var processPendingTermination: RunningProcess?
    var confirmForceQuit = false

    var isRefreshing: Bool { processService.isRefreshing }
    var errorMessage: String? { processService.lastErrorMessage }
    var actionMessage: String? { processService.actionMessage }
    var processCount: Int { processService.latest?.processes.count ?? 0 }

    var visibleProcesses: [RunningProcess] {
        let source = processService.latest?.processes ?? []
        let filtered: [RunningProcess]
        if searchText.isEmpty {
            filtered = source
        } else {
            let query = searchText
            filtered = source.filter { process in
                process.name.localizedCaseInsensitiveContains(query)
                    || "\(process.pid)".contains(query)
                    || (process.path?.localizedCaseInsensitiveContains(query) ?? false)
            }
        }

        return filtered.sorted { lhs, rhs in
            switch sortKey {
            case .cpu:
                (lhs.cpuUsageRatio ?? -1) > (rhs.cpuUsageRatio ?? -1)
            case .memory:
                lhs.residentMemoryBytes > rhs.residentMemoryBytes
            case .name:
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .pid:
                lhs.pid < rhs.pid
            }
        }
    }

    init(processService: ProcessService) {
        self.processService = processService
    }

    func onAppear() {
        processService.startMonitoring()
    }

    func onDisappear() {
        processService.stopMonitoring()
    }

    func refresh() {
        Task { await processService.refreshNow() }
    }

    func requestQuit(_ process: RunningProcess, force: Bool) {
        processPendingTermination = process
        confirmForceQuit = force
    }

    func confirmTermination() {
        guard let process = processPendingTermination else { return }
        let force = confirmForceQuit
        processPendingTermination = nil
        Task { await processService.terminate(pid: process.pid, force: force) }
    }

    func cancelTermination() {
        processPendingTermination = nil
        confirmForceQuit = false
    }

    func openActivityMonitor() {
        Task { await processService.openActivityMonitor() }
    }
}
