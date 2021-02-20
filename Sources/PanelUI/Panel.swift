import SwiftUI

struct HeaderHeightKey: PreferenceKey {
    static let defaultValue: [CGFloat] = []

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct Panel<Content: View, Header: View>: View {

    let content: () -> Content
    let header: (Double) -> Header

    @Binding var state: PanelState

    @GestureState private var dragState = DragState()

    @Environment(\.horizontalSizeClass) private var sizeClass

    @ScaledMetric private var width: CGFloat = 375

    @State private var headerHeight: CGFloat = 0

    @State private var feedback = UIImpactFeedbackGenerator()

    @State private var endState: PanelState?

    init(state: Binding<PanelState>,
         @ViewBuilder header: @escaping (Double) -> Header,
         @ViewBuilder content: @escaping () -> Content) {
        self._state = state
        self.header = header
        self.content = content
    }

    @ViewBuilder
    var body: some View {
        GeometryReader { proxy in
            if state.isPresented {
                if sizeClass == .compact {
                    panel(in: proxy)
                        .transition(AnyTransition.opacity.animation(.default)
                                        .combined(with: .move(edge: .bottom)))
                } else {
                    HStack(spacing: 0) {
                        panel(in: proxy)
                            .frame(maxWidth: width)
                            .offset(x: horizontalProgress(for: dragState.x, in: proxy) * (proxy.size.width - width))
                        Spacer()
                    }
                    .transition(AnyTransition.opacity.animation(.default)
                                    .combined(with: .move(edge: state.position == .leading
                                                            ? .leading : .trailing)))
                }
            }
        }
        .padding(sizeClass == .compact ? [] : .all, 20)
        .padding(sizeClass == .compact ? .top : [], 12)
        .animation(.spring(), value: currentState)
        .animation(.interactiveSpring())
        .environment(\.panelState, $state)
        .onPreferenceChange(HeaderHeightKey.self, perform: { value in
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
        let progress = self.verticalProgress(for: dragState.y, in: proxy)
        let offset = (proxy.size.height - headerHeight) * (1 - progress)
        let height = (proxy.size.height - headerHeight) * progress
            + headerHeight
            + (sizeClass == .compact ? 1 : 0) // otherwise the overlay will disappear.
        return VStack(spacing: 0) {
            header(in: proxy)
                .accessibilityAddTraits(.isHeader)
                .zIndex(1)

            content()
                .overlayPreferenceValue(PanelOverlayPreferenceKey.self, { value in
                    if sizeClass == .compact,
                       let overlay = value {
                        overlay
                            .opacity(min(max(1 - Double(progress), 0), 1))
                            .ignoresSafeArea(.all, edges: ignoredEdges)
                    }
                })
                .accessibility(hidden: state.state != .expanded)
        }
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black.opacity(0.5), lineWidth: 1 / UIScreen.main.scale)
                    .ignoresSafeArea(.all, edges: ignoredEdges))
        .mask(clip)
        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
        .offset(y: offset)
        .frame(height: max(height, 0))


    }

    var clip: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .ignoresSafeArea(.all, edges: ignoredEdges)
    }

    func header(in proxy: GeometryProxy) -> some View {
        self.header(max(min(Double(self.verticalProgress(for: dragState.y, in: proxy)), 1), 0))
            .layoutPriority(2)
            .background(GeometryReader { proxy in
                Color.clear
                    .preference(key: HeaderHeightKey.self, value: [proxy.size.height])
            })
            .background(Color(.secondarySystemBackground))
            .offset(x: dragState.x, y: dragState.y)
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
                        }
            )
            .offset(x: -dragState.x, y: -dragState.y)
    }

    var currentState: PanelState {
        return dragState.direction == nil ? endState ?? self.state : self.state
    }

    func verticalProgress(for offset: CGFloat, in proxy: GeometryProxy) -> CGFloat {
        let height = currentState.state == .expanded
            ? proxy.size.height - offset
            : headerHeight - offset
        let progress = (height - headerHeight) / (proxy.size.height - headerHeight)
        return progress
    }

    func horizontalProgress(for offset: CGFloat, in proxy: GeometryProxy) -> CGFloat {
        let endWidth = currentState.position == .leading
            ? offset
            : proxy.size.width + offset - width
        return (endWidth) / (proxy.size.width - width)
    }

    var ignoredEdges: Edge.Set {
       sizeClass == .compact ? [.bottom, .horizontal] : []
    }
}

struct Item: Identifiable {
    var id: String
}

public struct PanelUI_Previews: PreviewProvider {

    struct Header: View {
        @Environment(\.panelState) var state

        let progress: Double

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
            .panel(item: $item, header: { _, progress in
                Header(progress: progress)
            }) { item in
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
                    Button(action: {
                    }) {
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
    public static var previews: some View {
        Group {
            Preview()
                .previewDevice("iPhone 12 Pro")
            Preview()
                .previewDevice("iPad Pro (11-inch) (2nd generation)")
        }
    }
}
