import SwiftUI

struct PanelModifier<Body: View>: ViewModifier {
    @Binding var isPresented: Bool
    let body: () -> Body

    @State private var state: PanelState = .init()

    func body(content: Content) -> some View {
        content
            .accessibility(hidden: self.isPresented && self.state.state == .expanded)
            .overlay(Panel(state: self.binding, content: self.body))
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

extension View {
    public func panel<Content: View>(isPresented: Binding<Bool>,
                                     @ViewBuilder content: @escaping () -> Content) -> some View {
        self.modifier(PanelModifier(isPresented: isPresented, body: content))
    }

    public func panel<Item: Identifiable, Content: View>(item: Binding<Item?>,
                                                         @ViewBuilder content: @escaping (Item) -> Content)
        -> some View {
            let binding = Binding(get: { item.wrappedValue != nil }, set: { if !$0 { item.wrappedValue = nil } })
            return self.modifier(PanelModifier(isPresented: binding,
                                               body: { content(item.wrappedValue!) }))
    }
}
