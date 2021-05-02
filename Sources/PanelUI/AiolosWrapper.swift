import Combine
import SwiftUI

struct XAiolosWrapper<Content: View, PanelContent: View>: UIViewRepresentable {
    typealias Coordinator = AiolosController<Content, PanelContent>

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

    func makeUIView(context: Context) -> UIView {
        context.coordinator.view
    }

    func updateUIView(_ controller: UIView, context: Context) {
        context.coordinator.rootView = self.content
        context.coordinator.panelSafeArea = self.safeArea
        context.coordinator.progressPublisher = self.progressPublisher
        context.coordinator.headerHeight = self.headerHeight
        context.coordinator.apply(state: self.state, content: self.state.isPresented ? self.panelContent() : nil)
    }

    func makeCoordinator() -> Coordinator {
        AiolosController<Content, PanelContent>(rootView: self.content, state: $state)
    }
}

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

// struct AiolosWrapper_Previews: PreviewProvider {
//    static var previews: some View {
//        SwiftUIView()
//    }
// }
