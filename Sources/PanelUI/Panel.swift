import SwiftUI

public struct PanelHeaderHeightKey: PreferenceKey {
    public static let defaultValue: [CGFloat] = []

    public static func reduce(value: inout [CGFloat], nextValue: () -> [CGFloat]) {
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

    @Environment(\.panelSafeArea) var safeArea

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
                            .transition(AnyTransition.move(edge: .bottom)
                                .combined(with: .offset(y: 30)))
                } else {
                    HStack(spacing: 0) {
                        panel(in: proxy)
                            .frame(maxWidth: width)

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
            self.updateSafeArea(for: state, height: value.first ?? 0, sizeClass: sizeClass)
        })
        .onChange(of: state, perform: { [state] value in
            self.feedback.impactOccurred()
            if state.state != value.state || value.isPresented != state.isPresented {
                UIAccessibility.post(notification: .screenChanged, argument: nil)
            }
            self.updateSafeArea(for: value, height: headerHeight, sizeClass: sizeClass)
        })
        .onChange(of: sizeClass, perform: { [sizeClass] new in
            if sizeClass != new {
                if sizeClass == .compact {
                    self.state.position = .center
                } else {
                    self.state.position = .trailing
                }
            }
            self.updateSafeArea(for: state, height: headerHeight, sizeClass: new)
        })
        .onAppear {
            if sizeClass == .compact {
                self.state.position = .center
            } else {
                self.state.position = .trailing
            }
        }
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
                .offset(x: horizontalProgress(for: dragState.x, in: proxy) * (proxy.size.width - width))
                .gesture(DragGesture(minimumDistance: 30, coordinateSpace: .local)
                    .updating($dragState) { value, state, _ in
                        state.update(offset: value.translation, with: sizeClass)
                    }
                    .onChanged { value in
                        if dragState.direction == .vertical {
                            if verticalProgress(for: value.predictedEndTranslation.height, in: proxy) > 0.5 {
                                self.state.predictedState = .expanded
                            } else {
                                self.state.predictedState = .collapsed
                            }
                        } else if dragState.direction == .horizontal {
                            if horizontalProgress(for: value.predictedEndTranslation.width, in: proxy) < 0.5 {
                                self.state.predictedPosition = .leading
                            } else {
                                self.state.predictedPosition = .trailing
                            }
                        }
                    }
                    .onEnded { _ in
                        self.state.state = self.state.predictedState
                        self.state.position = self.state.predictedPosition
                    })
                .accessibilityAction(.escape) {
                    self.state.isPresented = false
                }
    }

    func updateSafeArea(for state: PanelState, height: CGFloat, sizeClass: UserInterfaceSizeClass?) {
        if state.isPresented, state.state == .collapsed {
            if sizeClass == .compact {
                self.safeArea.bottomInset = height
            } else {
                self.safeArea.bottomInset = height + 20
            }
        } else {
            self.safeArea.bottomInset = 0
        }
        self.safeArea.position = state.position
    }

    var clip: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .ignoresSafeArea(.all, edges: ignoredEdges)
    }

    var currentState: PanelState.State {
        self.dragState.direction == nil ? self.state.predictedState : self.state.state
    }

    var currentPosition: PanelState.Position {
        self.dragState.direction == nil ? self.state.predictedPosition : self.state.position
    }

    func verticalProgress(for offset: CGFloat, in proxy: GeometryProxy) -> CGFloat {
        let height = self.currentState == .expanded
            ? proxy.size.height - offset
            : self.headerHeight - offset
        let progress = (height - self.headerHeight) / (proxy.size.height - self.headerHeight)
        return progress
    }

    func horizontalProgress(for offset: CGFloat, in proxy: GeometryProxy) -> CGFloat {
        let endWidth = self.currentPosition == .leading
            ? offset
            : proxy.size.width + offset - self.width
        let result =  (endWidth) / (proxy.size.width - self.width)
        print(result, endWidth, proxy.size.width, self.width, offset)
        return result

    }

    var ignoredEdges: Edge.Set {
        self.sizeClass == .compact ? [.bottom, .horizontal] : []
    }
}

struct Item: Identifiable {
    var id: String
}

struct SlowView: View {
    var body: some View {
        for _ in 0..<10000 {
            var i = pow(2, 2)
            i += 1
        }
        return [Color.red, Color.blue, Color.green, Color.yellow].randomElement()!
            .frame(height: 50)
            .cornerRadius(10)
            .padding()
    }
}

public struct Stack<Content: View>: View {
    public enum Orientation {
        case vertical, horizontal
    }

    public let content: Content
    public let orientation: Orientation
    public let spacing: CGFloat?

    @inlinable public init(orientation: Orientation, spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.orientation = orientation
        self.spacing = spacing
    }

    public var body: some View {
        Group {
            switch orientation {
            case .vertical:
                VStack(alignment: .leading, spacing: spacing, content: {
                    content
                })
            case .horizontal:
                HStack(spacing: spacing, content: {
                    content
                })
            }
        }
    }
}

struct Duration: View {
    @Binding var x: Int

    let foo: () -> Void

    @Environment(\.sizeCategory) var sizeCategory

    var body: some View {
        VStack(spacing: 16) {
            Stack(orientation: sizeCategory.isAccessibilityCategory ? .vertical : .horizontal,
                  spacing: 4) {
                Text("How long?")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: self.foo) {
                    Text("More")
                        .font(.headline)
                }
            }
        }
    }

    private static var trackLabelCache = [Int: String]()

}

struct ListScrollView: View {
    @Environment(\.panelProgress) var progress

    @State var x = 0

    var body: some View {
        ScrollView {
            VStack {
                Duration(x: $x, foo: { })
                    .transition(AnyTransition.opacity.animation(.default)
                        .combined(with: AnyTransition.move(edge: .bottom)))
                ForEach(0..<1000) { _ in
//                    SlowView()
                    Color.red
                }
            }
            .padding()
        }
        .background(Color.red.ignoresSafeArea(.all, edges: [.bottom, .horizontal]))
    }

    func foo() {
        print("foo")
    }
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
            .background(Color.white)
        }
    }

    public struct Preview: View {
        @State var isPresented = true

        @State var item: Item? = Item(id: "Test")

        public init() {

        }
        public var body: some View {
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
                        .background(GeometryReader { proxy in
                            Color.clear
                                .preference(key: PanelHeaderHeightKey.self, value: [proxy.size.height])
                        })
                    ListScrollView()

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
