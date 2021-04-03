import SwiftUI

public struct PanelHeaderHeightKey: PreferenceKey {
    public static let defaultValue: [CGFloat] = []

    public static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct Panel<Content: View>: View {
    let content: () -> Content

    @Binding var state: PanelState

    @GestureState private var dragState = DragState()

    @Environment(\.horizontalSizeClass) private var sizeClass

    @ScaledMetric private var width: CGFloat = 325

    @State private var headerHeight: CGFloat = 0

    @State private var feedback = UIImpactFeedbackGenerator()

    @State private var endState: PanelState?

    init(state: Binding<PanelState>,
         @ViewBuilder content: @escaping () -> Content) {
        self._state = state
        self.content = content
    }

    @ViewBuilder
    var body: some View {
        GeometryReader { proxy in
            if state.isPresented {
                if sizeClass == .compact {
                    panel(in: proxy)
                        // Add additional offset to move it really off screen
                            .transition(AnyTransition.move(edge: .bottom).combined(with: .offset(y: 30)))
                } else {
                    HStack(spacing: 0) {
                        panel(in: proxy)
                            .frame(maxWidth: width)
                            .offset(x: horizontalProgress(for: dragState.x, in: proxy) * (proxy.size.width - width))
                        Spacer()
                    }
                    .transition(.move(edge: state.position == .leading
                            ? .leading : .trailing))
                }
            }
        }
        .padding(sizeClass == .compact ? [] : .all, 20)
        .padding(sizeClass == .compact ? .top : [], 12)
        .animation(.spring(), value: currentState)
        .animation(.interactiveSpring())
        .environment(\.panelState, $state)
        .onPreferenceChange(PanelHeaderHeightKey.self, perform: { value in
            self.headerHeight = value.first ?? 0
        })
        .onChange(of: state, perform: { [state] value in
            self.feedback.impactOccurred()
            if state.state != value.state || value.isPresented != state.isPresented {
                UIAccessibility.post(notification: .screenChanged, argument: nil)
            }
        })
    }

    func panel(in proxy: GeometryProxy) -> some View {
        let progress = self.verticalProgress(for: self.dragState.y, in: proxy)
        let offset = (proxy.size.height - self.headerHeight) * (1 - progress)
        let height = (proxy.size.height - self.headerHeight) * progress
            + self.headerHeight
            + (self.sizeClass == .compact ? 1 : 0) // otherwise the overlay will disappear.
        return self.content()
            .environment(\.panelProgress,
                         max(min(Double(progress), 1), 0))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black.opacity(0.5), lineWidth: 1 / UIScreen.main.scale)
                    .ignoresSafeArea(.all, edges: self.ignoredEdges))
                .mask(self.clip)
                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
                .offset(y: offset)
                .frame(height: max(height, 0))
                .gesture(DragGesture(minimumDistance: 30, coordinateSpace: .local)
                    .updating($dragState) { value, state, _ in
                        state.update(offset: value.translation, with: sizeClass)
                    }
                    .onChanged { value in
                        var end = self.state
                        if dragState.direction == .vertical {
                            if verticalProgress(for: value.predictedEndTranslation.height, in: proxy) > 0.5 {
                                end.state = .expanded
                            } else {
                                end.state = .collapsed
                            }
                        } else if dragState.direction == .horizontal {
                            if horizontalProgress(for: value.predictedEndTranslation.width, in: proxy) < 0.5 {
                                end.position = .leading
                            } else {
                                end.position = .trailing
                            }
                        }
                        self.endState = end
                    }
                    .onEnded { _ in
                        if let end = self.endState {
                            self.state = end
                            self.endState = nil
                        }
                    })
                .accessibilityAction(.escape) {
                    self.state.isPresented = false
                }
    }

    var clip: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .ignoresSafeArea(.all, edges: ignoredEdges)
    }

    var currentState: PanelState {
        self.dragState.direction == nil ? self.endState ?? self.state : self.state
    }

    func verticalProgress(for offset: CGFloat, in proxy: GeometryProxy) -> CGFloat {
        let height = self.currentState.state == .expanded
            ? proxy.size.height - offset
            : self.headerHeight - offset
        let progress = (height - self.headerHeight) / (proxy.size.height - self.headerHeight)
        return progress
    }

    func horizontalProgress(for offset: CGFloat, in proxy: GeometryProxy) -> CGFloat {
        let endWidth = self.currentState.position == .leading
            ? offset
            : proxy.size.width + offset - self.width
        return (endWidth) / (proxy.size.width - self.width)
    }

    var ignoredEdges: Edge.Set {
        self.sizeClass == .compact ? [.bottom, .horizontal] : []
    }
}

struct Item: Identifiable {
    var id: String
}

public struct PanelUI_Previews: PreviewProvider {
    struct Header: View {
        @Environment(\.panelState) var state
        @Environment(\.panelProgress) var progress

        var body: some View {
            HStack {
                Button(action: {
                    self.state.state.wrappedValue.toggle()
                }) {
                    Image(systemName: "chevron.down")
                        .rotationEffect(.radians(-Double.pi * (1 - progress)))
                }
                .font(.headline)
                Spacer()
                Text("\(progress)")
            }
            .padding()
            .background(Color.green.opacity(1 - progress))
        }
    }

    struct Preview: View {
        @State var isPresented = true

        @State var item: Item? = Item(id: "Test")

        var body: some View {
            VStack {
                Text("Top")
                Spacer()
                Button("Toggle Panel") {
                    if item == nil {
                        self.item = Item(id: "Test")
                    } else {
                        self.item = nil
                    }
                }
                Spacer()
                Text("Buttom")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .panel(item: $item) { item in
                VStack(spacing: 0) {
                    Header()
                    ScrollView {
                        VStack {
                            HStack {
                                Text(item.id)
                                Spacer()
                                Text("Hoho")
                            }
                            Spacer()
                            Button("Done") {
                                self.item = nil
                            }
                        }
                        .padding()
                    }
                    .overlay(VStack {
                        Spacer()
                        Button(action: {}) {
                            Text("Action")
                                .padding(60)
                                .background(Color.blue)
                        }
                        .padding(40)
                    })
                    .background(Color.red.ignoresSafeArea(.all, edges: [.bottom, .horizontal]))
                }
            }
        }
    }

    public static var previews: some View {
        Group {
            Preview()
                .previewDevice("iPhone 12 Pro")
            Preview()
                .previewDevice("iPad Pro (11-inch) (2nd generation)")
        }
    }
}
