import Foundation
import Observation

@MainActor
@Observable
final class EnvironmentViewModel {
    private let toolingService: EnvironmentToolingService

    var searchText = ""
    var showInstalledOnly = false

    var isRefreshing: Bool { toolingService.isRefreshing }
    var errorMessage: String? { toolingService.lastErrorMessage }
    var snapshot: ToolingSnapshot? { toolingService.latest }

    var visibleTools: [InstalledTool] {
        let source = snapshot?.tools ?? []
        return source.filter { tool in
            if showInstalledOnly && !tool.isInstalled {
                return false
            }
            if searchText.isEmpty {
                return true
            }
            let query = searchText
            return tool.kind.title.localizedCaseInsensitiveContains(query)
                || (tool.version?.localizedCaseInsensitiveContains(query) ?? false)
                || (tool.path?.localizedCaseInsensitiveContains(query) ?? false)
                || (tool.detail?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    var groupedTools: [(category: DeveloperToolCategory, tools: [InstalledTool])] {
        DeveloperToolCategory.allCases.compactMap { category in
            let tools = visibleTools.filter { $0.kind.category == category }
            guard !tools.isEmpty else { return nil }
            return (category, tools)
        }
    }

    init(toolingService: EnvironmentToolingService) {
        self.toolingService = toolingService
    }

    func onAppear() {
        toolingService.startMonitoring()
    }

    func onDisappear() {
        toolingService.stopMonitoring()
    }

    func refresh() {
        Task { await toolingService.refreshNow() }
    }
}
