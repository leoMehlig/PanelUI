//
//  File.swift
//  
//
//  Created by Leonard Mehlig on 17.02.21.
//

import SwiftUI

struct PanelModifier<Body: View, Header: View>: ViewModifier {

    @Binding var isPresented: Bool
    let header: (Double) -> Header
    let body: () -> Body

    @State private var state: PanelState = .init()

    func body(content: Content) -> some View {
        content
            .accessibility(hidden: isPresented && state.state == .expanded)
            .overlay(Panel(state: binding, header: header, content: body))
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

    public func panel<Content: View, Header: View>(isPresented: Binding<Bool>,
                                                   @ViewBuilder header: @escaping (Double) -> Header,
                                                   @ViewBuilder content: @escaping () -> Content) -> some View {
        self.modifier(PanelModifier(isPresented: isPresented, header: header, body: content))
    }

    public func panel<Item: Identifiable, Content: View, Header: View>(item: Binding<Item?>,
                                                                       @ViewBuilder header: @escaping (Item, Double) -> Header,
                                                                       @ViewBuilder content: @escaping (Item) -> Content) -> some View {
        let binding = Binding(get: { item.wrappedValue != nil }, set: { if !$0 { item.wrappedValue = nil } })
        return self.modifier(PanelModifier(isPresented: binding,
                                           header: { header(item.wrappedValue!, $0) },
                                           body: { content(item.wrappedValue!) }))

    }
}
