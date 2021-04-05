//
//  File.swift
//  
//
//  Created by Leonard Mehlig on 05.04.21.
//

import SwiftUI

public class PanelSafeArea: ObservableObject {
    @Published public internal(set) var bottomInset: CGFloat = 0

    @Published public internal(set) var position: PanelState.Position = .center

    public init() {

    }
}


struct PanelSafeAreaKey: EnvironmentKey {
    static let defaultValue: PanelSafeArea = .init()
}

extension EnvironmentValues {
    public var panelSafeArea: PanelSafeArea {
        get { self[PanelSafeAreaKey.self] }
        set { self[PanelSafeAreaKey.self] = newValue }
    }
}
