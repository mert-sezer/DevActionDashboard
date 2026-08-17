import SwiftUI

/// A sidebar-navigable feature, registered at the composition root.
@MainActor
public protocol FeatureModule: AnyObject, Identifiable where ID == FeatureID {
    var id: FeatureID { get }
    var title: String { get }
    var symbolName: String { get }
    var sidebarSortOrder: Int { get }

    func makeRootView() -> AnyView
}
