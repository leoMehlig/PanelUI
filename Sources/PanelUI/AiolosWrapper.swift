//
//  SwiftUIView.swift
//  
//
//  Created by Leonard Mehlig on 28.04.21.
//

import SwiftUI
import Combine

struct AiolosWrapper<Content: View, PanelContent: View>: UIViewControllerRepresentable {

    typealias UIViewControllerType = AiolosController<Content, PanelContent>

    var content: Content

    var panelContent: () -> PanelContent

    var headerHeight: CGFloat

    @Binding var state: PanelState

    @Environment(\.panelSafeArea) var safeArea

    var progressPublisher: CurrentValueSubject<Double, Never> = CurrentValueSubject(1)

    init(state: Binding<PanelState>,
         headerHeight: CGFloat,
         progressPublisher: CurrentValueSubject<Double, Never>,
         content: Content,
         @ViewBuilder panelContent: @escaping () -> PanelContent) {
        self.content = content
        self.panelContent = panelContent
        self.progressPublisher = progressPublisher
        self._state = state
        self.headerHeight = headerHeight
    }

    func makeUIViewController(context: Context) -> UIViewControllerType {
        return AiolosController<Content, PanelContent>(rootView: content, state: $state)
    }

    func updateUIViewController(_ controller: UIViewControllerType, context: Context) {
        controller.rootView = content
        controller.panelSafeArea = safeArea
        controller.progressPublisher = progressPublisher
        controller.headerHeight = headerHeight
        controller.apply(state: state, content: state.isPresented ? panelContent() : nil)
    }

}

//struct AiolosWrapper_Previews: PreviewProvider {
//    static var previews: some View {
//        SwiftUIView()
//    }
//}
