import Foundation
import Observation

@MainActor
@Observable
final class NetworkViewModel {
    private let networkService: NetworkService

    var snapshot: NetworkSnapshot? { networkService.latest }
    var errorMessage: String? { networkService.lastErrorMessage }
    var isRefreshing: Bool { networkService.isRefreshing }

    var nonLoopbackInterfaces: [NetworkInterfaceAddress] {
        snapshot?.interfaces.filter { !$0.isLoopback } ?? []
    }

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func onAppear() {
        networkService.startMonitoring()
    }

    func onDisappear() {
        networkService.stopMonitoring()
    }

    func refresh() {
        Task { await networkService.refreshNow() }
    }
}
