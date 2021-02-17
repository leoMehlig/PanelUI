import SwiftUI

struct HeaderHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct Panel<Content: View, Header: View>: View {

    let content: () -> Content
    let header: (Double) -> Header

    @Binding var isPresented: Bool

    @Binding var state: PanelState

    @GestureState private var dragState = DragState()

    @Environment(\.horizontalSizeClass) private var sizeClass

    @ScaledMetric private var width: CGFloat = 325

    @State private var headerHeight: CGFloat = 0

    @State private var feedback = UIImpactFeedbackGenerator()

    init(isPresented: Binding<Bool>,
         state: Binding<PanelState>,
         @ViewBuilder header: @escaping (Double) -> Header,
         @ViewBuilder content: @escaping () -> Content) {
        self._isPresented = isPresented
        self._state = state
        self.header = header
        self.content = content
    }

    @ViewBuilder
    var body: some View {
        GeometryReader { proxy in
            if isPresented {
                if sizeClass == .compact {
                    panel(in: proxy)
                        .transition(AnyTransition.opacity.animation(.default)
                                        .combined(with: .move(edge: .bottom)))
                } else {
                    HStack(spacing: 0) {
                        panel(in: proxy)
                            .frame(maxWidth: width)
                            .offset(x: state.position == .leading
                                        ? dragState.x
                                        : proxy.size.width + dragState.x - width)
                        Spacer()
                    }
                    .transition(AnyTransition.opacity.animation(.default)
                                    .combined(with: .move(edge: state.position == .leading
                                                            ? .leading : .trailing)))
                }
            }
        }
        .padding(sizeClass == .regular ? [.all] : .top, 20)
        .animation(.spring(), value: state)
        .animation(.spring(), value: isPresented)
        .animation(.interactiveSpring())
        .animation(.default)
        .environment(\.panelState, $state)
        .onPreferenceChange(HeaderHeightKey.self, perform: { value in
            self.headerHeight = value
        })
        .onChange(of: isPresented, perform: { _ in
            UIAccessibility.post(notification: .screenChanged, argument: nil)
            self.feedback.impactOccurred()
        })
        .onChange(of: state, perform: { [state] value in
            self.feedback.impactOccurred()
            if state.state != value.state {
                UIAccessibility.post(notification: .screenChanged, argument: nil)
            }
        })
    }

    func panel(in proxy: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            header(in: proxy)
                .accessibilityAddTraits(.isHeader)
                .zIndex(1)
            content()
//                .ignoresSafeArea(.container, edges: sizeClass == .compact ? [.bottom, .horizontal] : [])
                .accessibility(hidden: state.state != .expanded)
        }
        .background(self.background)
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black.opacity(0.5), lineWidth: 1 / UIScreen.main.scale)
                    .ignoresSafeArea(.container, edges: sizeClass == .compact ? [.bottom, .horizontal] : []))
        .mask(clip)
        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
        .offset(y: (proxy.size.height - headerHeight) * (1 - self.verticalProgress(for: dragState.y, in: proxy)))
        .frame(height: (proxy.size.height - headerHeight) * self.verticalProgress(for: dragState.y, in: proxy) + headerHeight)
    }

    var clip: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .ignoresSafeArea(.container, edges: sizeClass == .compact ? [.bottom, .horizontal] : [])
    }

    var background: some View {
        Color(.systemBackground)
            .ignoresSafeArea(.container, edges: sizeClass == .compact ? [.bottom, .horizontal] : [])

    }

    func verticalProgress(for offset: CGFloat, in proxy: GeometryProxy) -> CGFloat {
        let height = state.state == .expanded
            ? proxy.size.height - offset
            : headerHeight - offset
        return (height - headerHeight) / (proxy.size.height - headerHeight)
    }

    func horizontalProgress(for offset: CGFloat, in proxy: GeometryProxy) -> CGFloat {
        let endWidth = state.position == .leading
            ? offset
            : proxy.size.width + offset - width
        return (endWidth) / (proxy.size.width - width)
    }

    func header(in proxy: GeometryProxy) -> some View {
        self.header(max(min(Double(self.verticalProgress(for: dragState.y, in: proxy)), 1), 0))
            .background(GeometryReader {
                Color.clear
                    .preference(key: HeaderHeightKey.self, value: $0.size.height)
            })
            .background(Color(.secondarySystemBackground))
            .frame(height: headerHeight)
            .offset(x: dragState.x, y: dragState.y)
            .gesture(DragGesture(minimumDistance: 30, coordinateSpace: .local)
                        .updating($dragState) { value, state, _ in
                            state.update(offset: value.translation, with: sizeClass)
                            state.predictedEnd = value.predictedEndTranslation
                        })
            .offset(x: -dragState.x, y: -dragState.y)
            .onChange(of: self.dragState) { [dragState] (value: DragState) in
                if value.direction == nil,
                   let predictedEnd = dragState.predictedEnd {
                    if dragState.direction == .vertical {
                        let newState: PanelState.State
                        if verticalProgress(for: predictedEnd.height, in: proxy) > 0.5 {
                            newState = .expanded
                        } else {
                            newState = .collapsed
                        }
                        if newState != self.state.state {
                            self.state.state = newState
                        }
                    } else if dragState.direction == .horizontal {
                        let position: PanelState.Position
                        if horizontalProgress(for: predictedEnd.width, in: proxy) < 0.5 {
                            position = .leading
                        } else {
                            position = .trailing
                        }
                        if position != self.state.position {
                            self.state.position = position
                        }
                    }
                }
            }
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
                Text("\(progress) - \(state.state.wrappedValue == .expanded ? "expanded" : "collapsed")")
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
                .background(Color.red.ignoresSafeArea(.container, edges: [.bottom, .horizontal]))

            }
        }
    }
    public static var previews: some View {
        Group {
            Preview()
                .previewDevice("iPhone 12 Pro")
//            Preview()
//                .previewDevice("iPad Pro (11-inch) (2nd generation)")
        }
    }
}
