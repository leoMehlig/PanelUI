//
//  SwiftUIView.swift
//  
//
//  Created by Leonard Mehlig on 29.04.21.
//

import SwiftUI

struct AiolosPanel<Content: View, PanelContent: View>: View {

    @Binding var state: PanelState

    let content: Content
    var panelContent: () -> PanelContent
    @State private var headerHeight: CGFloat = 0

    init(state: Binding<PanelState>,
         content: Content,
         @ViewBuilder panelContent: @escaping () -> PanelContent) {
        self._state = state
        self.content = content
        self.panelContent = panelContent
    }

    var body: some View {
        AiolosWrapper(isPresented: state.isPresented,
                      headerHeight: headerHeight,
                      content: content,
                      panelContent: panelContent)
            .onPreferenceChange(PanelHeaderHeightKey.self, perform: { value in
                self.headerHeight = value.first ?? 0
            })
    }
}
//
//struct SwiftUIView_Previews: PreviewProvider {
//    static var previews: some View {
//        SwiftUIView()
//    }
//}
