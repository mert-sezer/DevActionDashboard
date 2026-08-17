import Foundation
import Observation

/// Shared navigation / command-palette UI state.
@MainActor
@Observable
final class AppNavigationStore {
    var selectedFeatureID: FeatureID?
    var isCommandPalettePresented = false
    var pendingUtilityTool: UtilityTool?

    init(initialFeatureID: FeatureID?) {
        selectedFeatureID = initialFeatureID
    }

    func openCommandPalette() {
        isCommandPalettePresented = true
    }

    func closeCommandPalette() {
        isCommandPalettePresented = false
    }

    func navigate(to featureID: FeatureID) {
        selectedFeatureID = featureID
        isCommandPalettePresented = false
    }

    func openUtility(_ tool: UtilityTool) {
        pendingUtilityTool = tool
        navigate(to: .utilities)
    }

    func openActions() {
        navigate(to: .actions)
    }
}
