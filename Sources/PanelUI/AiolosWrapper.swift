#if canImport(Aiolos)
import Combine
import SwiftUI

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
        AiolosController<Content, PanelContent>(rootView: self.content, state: $state)
    }

    func updateUIViewController(_ controller: UIViewControllerType, context: Context) {
        controller.rootView = self.content
        controller.panelSafeArea = self.safeArea
        controller.progressPublisher = self.progressPublisher
        controller.headerHeight = self.headerHeight
        controller.apply(state: self.state, content: self.state.isPresented ? self.panelContent() : nil)
    }
}

#endif
