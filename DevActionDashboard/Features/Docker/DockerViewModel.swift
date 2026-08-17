import Foundation
import Observation

@MainActor
@Observable
final class DockerViewModel {
    private let dockerService: DockerService

    var searchText = ""
    var showOnlyRunning = false

    var isRefreshing: Bool { dockerService.isRefreshing }
    var errorMessage: String? { dockerService.lastErrorMessage }
    var actionMessage: String? { dockerService.actionMessage }
    var snapshot: DockerSnapshot? { dockerService.latest }
    var logText: String { dockerService.logText }
    var logContainerName: String? { dockerService.logContainerName }

    var visibleContainers: [DockerContainer] {
        let source = snapshot?.containers ?? []
        return source.filter { container in
            if showOnlyRunning && container.state != .running {
                return false
            }
            if searchText.isEmpty {
                return true
            }
            let query = searchText
            return container.name.localizedCaseInsensitiveContains(query)
                || container.image.localizedCaseInsensitiveContains(query)
                || container.containerID.localizedCaseInsensitiveContains(query)
                || container.status.localizedCaseInsensitiveContains(query)
                || container.ports.localizedCaseInsensitiveContains(query)
        }
    }

    init(dockerService: DockerService) {
        self.dockerService = dockerService
    }

    func onAppear() {
        dockerService.startMonitoring()
    }

    func onDisappear() {
        dockerService.stopMonitoring()
    }

    func refresh() {
        Task { await dockerService.refreshNow() }
    }

    func start(_ container: DockerContainer) {
        Task { await dockerService.control(container, action: .start) }
    }

    func stop(_ container: DockerContainer) {
        Task { await dockerService.control(container, action: .stop) }
    }

    func restart(_ container: DockerContainer) {
        Task { await dockerService.control(container, action: .restart) }
    }

    func loadLogs(_ container: DockerContainer) {
        Task { await dockerService.loadLogs(for: container) }
    }

    func clearLogs() {
        dockerService.clearLogs()
    }
}
