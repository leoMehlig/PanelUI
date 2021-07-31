import SwiftUI

public struct EmbeddedPanel: View {
    @Environment(\.embeddedPanel) var embeeded

    @ViewBuilder
    public var body: some View {
        if embeeded.0.wrappedValue {
            embeeded.1
                .frame(minWidth: 320)
                .transition(.opacity)
                .animation(.spring(), value: embeeded.0.wrappedValue)
        }
    }

    public init() {}
}

struct EmbeddedPanelKey: EnvironmentKey {
    static var defaultValue: (Binding<Bool>, AnyView) = (.constant(false), AnyView(EmptyView()))
}

extension EnvironmentValues {
    var embeddedPanel: (Binding<Bool>, AnyView) {
        get { self[EmbeddedPanelKey.self] }
        set { self[EmbeddedPanelKey.self] = newValue }
    }
}
