//
//  File.swift
//  
//
//  Created by Leonard Mehlig on 19.02.21.
//

import SwiftUI

struct PanelOverlayPreferenceKey: PreferenceKey {
    typealias Value = AnyView?

    static var defaultValue: Value = nil

    static func reduce(value: inout Value, nextValue: () -> Value) {
        if let new = nextValue() {
            value = new
        }
    }
}

extension View {
    public func panelOverlay<Content: View>(_ content: Content) -> some View {
        return self.preference(key: PanelOverlayPreferenceKey.self,
                        value: AnyView(content))
    }
}
