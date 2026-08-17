import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class EnvVarsViewModel {
    private let service: EnvironmentVariableService

    var searchText = ""
    var selectedKey: String?
    var compareLeftKey: String?
    var compareRightKey: String?

    var isRefreshing: Bool { service.isRefreshing }
    var variables: [EnvironmentVariable] { service.latest?.variables ?? [] }

    var visibleVariables: [EnvironmentVariable] {
        guard !searchText.isEmpty else { return variables }
        let query = searchText
        return variables.filter {
            $0.key.localizedCaseInsensitiveContains(query)
                || $0.value.localizedCaseInsensitiveContains(query)
        }
    }

    var selectedVariable: EnvironmentVariable? {
        guard let selectedKey else { return nil }
        return variables.first { $0.key == selectedKey }
    }

    var comparison: EnvironmentVariableComparison? {
        guard let compareLeftKey, let compareRightKey else { return nil }
        return service.compare(leftKey: compareLeftKey, rightKey: compareRightKey)
    }

    init(service: EnvironmentVariableService) {
        self.service = service
    }

    func onAppear() {
        Task { await service.refreshNow() }
    }

    func refresh() {
        Task { await service.refreshNow() }
    }

    func copyValue(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    func copySelected() {
        guard let selectedVariable else { return }
        copyValue("\(selectedVariable.key)=\(selectedVariable.value)")
    }
}
