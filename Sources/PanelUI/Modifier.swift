import SwiftUI

public struct PanelModifier<Body: View>: ViewModifier {
    @Binding var isPresented: Bool
    let body: () -> Body

    @State private var state: PanelState = .init()

    public init(isPresented: Binding<Bool>, body: @escaping () -> Body) {
        self._isPresented = isPresented
        self.body = body
    }

    public init<Item: Identifiable>(item: Binding<Item?>, body: @escaping (Item) -> Body) {
        let binding = Binding(get: { item.wrappedValue != nil }, set: { if !$0 { item.wrappedValue = nil } })
        self.init(isPresented: binding, body: { body(item.wrappedValue!) })
    }

    public func body(content: Content) -> some View {
        AiolosPanel(state: binding,
                    content: content,
                    panelContent: self.body)
            .environment(\.panelState, binding)
//        content
//            .accessibility(hidden: self.isPresented && self.state.state == .expanded)
//            .overlay(Panel(state: self.binding, content: self.body))
    }

    var binding: Binding<PanelState> {
        Binding(get: {
            var state = self.state
            state.isPresented = isPresented
            return state
        }, set: { value in
            self.state = value
            self.isPresented = value.isPresented
        })
    }
}

public extension View {
    func panel<Content: View>(isPresented: Binding<Bool>,
                              @ViewBuilder content: @escaping () -> Content) -> some View {
        self.modifier(PanelModifier(isPresented: isPresented, body: content))
    }

    func panel<Item: Identifiable, Content: View>(item: Binding<Item?>,
                                                  @ViewBuilder content: @escaping (Item) -> Content)
    -> some View {
        self.modifier(PanelModifier(item: item,
                                    body: content))
    }
}
