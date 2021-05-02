import Combine
import SwiftUI

struct AiolosPanel<Content: View, PanelContent: View>: View {
    @Binding var state: PanelState

    let content: Content
    var panelContent: () -> PanelContent
    @State private var headerHeight: CGFloat = 0

    @State var progressPublisher: CurrentValueSubject<Double, Never> = CurrentValueSubject(1)

    @State var progress: Double = 1

    init(state: Binding<PanelState>,
         content: Content,
         @ViewBuilder panelContent: @escaping () -> PanelContent) {
        self._state = state
        self.content = content
        self.panelContent = panelContent
    }

    var body: some View {
        AiolosWrapper(state: $state,
                      headerHeight: headerHeight,
                      progressPublisher: progressPublisher,
                      content: content,
                      panelContent: panelContent)
            .edgesIgnoringSafeArea(.all)
            .environment(\.panelProgress, progress)
            .onReceive(progressPublisher, perform: {
                self.progress = $0
            })
            .onPreferenceChange(PanelHeaderHeightKey.self, perform: { value in
                self.headerHeight = value.first ?? 0
            })
    }
}
