import SwiftUI

public struct PanelSafeArea: Equatable {
    public var bottomInset: CGFloat = 0

    public var position: PanelState.Position = .center

    public init() {}
}

struct PanelSafeAreaKey: EnvironmentKey {
    static let defaultValue: PanelSafeArea = .init()
}

struct EditPanelSafeAreaKey: EnvironmentKey {
    static let defaultValue: Binding<PanelSafeArea> = .constant(.init())
}

public extension EnvironmentValues {
    var panelSafeArea: PanelSafeArea {
        get { self[PanelSafeAreaKey.self] }
        set { self[PanelSafeAreaKey.self] = newValue }
    }

    var editPanelSafeArea: Binding<PanelSafeArea> {
        get { self[EditPanelSafeAreaKey.self] }
        set { self[EditPanelSafeAreaKey.self] = newValue }
    }
}
