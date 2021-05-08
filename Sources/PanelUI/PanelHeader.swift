import SwiftUI

public struct PanelHeaderHeightKey: PreferenceKey {
    public static let defaultValue: [CGFloat] = []

    public static func reduce(value: inout [CGFloat], nextValue: () -> [CGFloat]) {
        value += nextValue()
    }
}

