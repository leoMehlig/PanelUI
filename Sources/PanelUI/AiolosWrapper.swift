//
//  SwiftUIView.swift
//  
//
//  Created by Leonard Mehlig on 28.04.21.
//

import SwiftUI

struct AiolosWrapper<Content: View, PanelContent: View>: UIViewControllerRepresentable {

    typealias UIViewControllerType = AiolosController<Content, PanelContent>

    var content: Content

    var panelContent: () -> PanelContent

    var headerHeight: CGFloat

    var isPresented: Bool

    init(isPresented: Bool,
         headerHeight: CGFloat,
         content: Content,
         @ViewBuilder panelContent: @escaping () -> PanelContent) {
        self.content = content
        self.panelContent = panelContent
        self.isPresented = isPresented
        self.headerHeight = headerHeight
    }

    func makeUIViewController(context: Context) -> UIViewControllerType {
        return AiolosController<Content, PanelContent>(rootView: content)
    }

    func updateUIViewController(_ controller: UIViewControllerType, context: Context) {
        controller.rootView = content
        if isPresented {
            controller.panelContent = panelContent()
        } else {
            controller.panelContent = nil
        }
        controller.isPresented = isPresented
        controller.headerHeight = headerHeight

    }

}

//struct AiolosWrapper_Previews: PreviewProvider {
//    static var previews: some View {
//        SwiftUIView()
//    }
//}
