import SwiftUI

public class PanelSafeArea: ObservableObject {
    @Published public internal(set) var bottomInset: CGFloat = 0

    @Published public internal(set) var position: PanelState.Position = .center

    public init() {}
}

struct PanelSafeAreaKey: EnvironmentKey {
    static let defaultValue: PanelSafeArea = .init()
}

public extension EnvironmentValues {
    var panelSafeArea: PanelSafeArea {
        get { self[PanelSafeAreaKey.self] }
        set { self[PanelSafeAreaKey.self] = newValue }
    }
}
