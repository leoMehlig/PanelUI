import SwiftUI

public enum PanelState: String {
    case hidden
    case collapsed
    case expanded
}

struct HeaderHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct Panel<Content: View, Header: View>: View {
    enum Position: String {
        case leading
        case trailing
    }

    struct DragState: CustomStringConvertible, Equatable {

        enum Direction: Equatable {
            case vertical, horizontal
        }

        var direction: Direction? = nil
        var offset: CGSize = .zero
        var predictedEnd: CGPoint?

        mutating func update(offset: CGSize, with sizeClass: UserInterfaceSizeClass?) {
            self.offset = offset
            if sizeClass == .compact {
                self.direction = .vertical
            } else if direction == nil {
                if abs(offset.width) > 10 || abs(offset.height) > 10 {
                    if abs(offset.width) > abs(offset.height) {
                        self.direction = .horizontal
                    } else {
                        self.direction = .vertical
                    }
                }
            }
        }

        var y: CGFloat {
            if direction == .vertical {
                return offset.height
            } else {
                return 0
            }
        }
        var x: CGFloat {
            if direction == .horizontal {
                return offset.width
            } else {
                return 0
            }
        }

        var description: String {
            switch direction {
            case .horizontal:
                return "↔ \(Int(self.x))"
            case .vertical:
                return "↕ \(Int(self.y))"
            default:
                return "undecided"
            }
        }

    }

    let content: Content
    let header: (Double) -> Header

    @Binding var state: PanelState

    @GestureState private var dragState = DragState()

    @Environment(\.horizontalSizeClass) private var sizeClass

    @ScaledMetric private var width: CGFloat = 325

    @State private var position = Position.leading

    @State private var headerHeight: CGFloat = 0

    init(state: Binding<PanelState>,
         @ViewBuilder header: @escaping (Double) -> Header,
         @ViewBuilder content: () -> Content) {
        self._state = state
        self.header = header
        self.content = content()
    }

    @ViewBuilder
    var body: some View {
        GeometryReader { proxy in
            if sizeClass == .compact {
                panel(in: proxy)
            } else {
                HStack(spacing: 0) {
                    panel(in: proxy)
                        .frame(maxWidth: width)
                        .offset(x: position == .leading
                                    ? dragState.x
                                    : proxy.size.width + dragState.x - width)
                    Spacer()
                }
            }
        }
        .padding(sizeClass == .regular ? 20 : 0)
        .animation(.spring(), value: state)
        .animation(.spring(), value: position)
        .animation(.interactiveSpring())
        .onPreferenceChange(HeaderHeightKey.self, perform: { value in
            self.headerHeight = value
        })

    }

    func panel(in proxy: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            header(in: proxy)

            content
                .ignoresSafeArea(.container, edges: sizeClass == .compact ? .bottom : [])
        }
        .background(self.background)
        .mask(clip)
        .offset(y: state == .expanded
                    ? dragState.y
                    : proxy.size.height - headerHeight + dragState.y)

        .frame(height: state == .expanded
                ? proxy.size.height - dragState.y
                : headerHeight - dragState.y)
    }

    var clip: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .ignoresSafeArea(.container, edges: sizeClass == .compact ? .bottom : [])
    }

    var background: some View {
        Color(.systemBackground)
            .ignoresSafeArea(.container, edges: sizeClass == .compact ? .bottom : [])
            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: -5)

    }

    func progress(in proxy: GeometryProxy) -> Double {
        let height = state == .expanded
            ? proxy.size.height - dragState.y
            : headerHeight - dragState.y
        let progress = Double((height - headerHeight) / (proxy.size.height - headerHeight))
        return max(min(progress, 1), 0)
    }

    func header(in proxy: GeometryProxy) -> some View {
        self.header(self.progress(in: proxy))
        .background(GeometryReader {
            Color.clear
                .preference(key: HeaderHeightKey.self, value: $0.size.height)
        })
        .background(Color(.secondarySystemBackground))
        .frame(height: headerHeight)
            .offset(x: dragState.x, y: dragState.y)
            .gesture(DragGesture()
                        .updating($dragState) { value, state, _ in
                            state.update(offset: value.translation, with: sizeClass)
                            state.predictedEnd = value.predictedEndLocation
                        })
            .offset(x: -dragState.x, y: -dragState.y)
            .onChange(of: self.dragState) { [dragState] (value: DragState) in
                if value.direction == nil,
                   let predictedEnd = dragState.predictedEnd {
                    if dragState.direction == .vertical {
                        if predictedEnd.y < proxy.size.height / 2 {
                            self.state = .expanded
                        } else {
                            self.state = .collapsed
                        }
                    } else if dragState.direction == .horizontal {
                        if predictedEnd.x < proxy.size.width / 2 {
                            self.position = .leading
                        } else {
                            self.position = .trailing
                        }
                    }
                }
            }
    }
}

struct PanelModifier<Body: View, Header: View>: ViewModifier {

    @Binding var state: PanelState
    let header: (Double) -> Header
    let body: Body


    func body(content: Content) -> some View {
        content
            .overlay(Panel(state: $state, header: header, content: { body }))
    }
}

struct PresentedPanelModifier<Body: View, Header: View>: ViewModifier {

    @State var state: PanelState

    @Binding var isPresented: Bool
    let header: (Double) -> Header
    let body: () -> Body

    init(isPresented: Binding<Bool>, header: @escaping (Double) -> Header, body: @escaping () -> Body) {
        self._isPresented = isPresented
        self._state = State(initialValue: isPresented.wrappedValue ? .expanded : .hidden)
        self.header = header
        self.body = body
    }


    func body(content: Content) -> some View {
        Group {
            if isPresented {
                content
                    .overlay(Panel(state: $state, header: header, content: body))
            } else {
                content
            }
        }
        .onChange(of: isPresented, perform: { value in
            if value && state == .hidden {
                self.state = .expanded
            } else if !value && state != .hidden  {
                self.state = .hidden
            }
        })
        .onChange(of: state, perform: { value in
            if self.isPresented && value == .hidden {
                self.isPresented = false
            } else if !self.isPresented && value != .hidden  {
                self.isPresented = true
            }
        })
    }
}

extension View {
    public func panel<Content: View, Header: View>(state: Binding<PanelState>,
                                                   @ViewBuilder header: @escaping (Double) -> Header,
                                                   @ViewBuilder content: () -> Content) -> some View {
        self.modifier(PanelModifier(state: state, header: header, body: content()))
    }

    public func panel<Content: View, Header: View>(isPresented: Binding<Bool>,
                                                   @ViewBuilder header: @escaping (Double) -> Header,
                                                   @ViewBuilder content: @escaping () -> Content) -> some View {
        self.modifier(PresentedPanelModifier(isPresented: isPresented, header: header, body: content))
    }
    public func panel<Item: Identifiable, Content: View, Header: View>(item: Binding<Item?>,
                                                                       @ViewBuilder header: @escaping (Double) -> Header,
                                                                       @ViewBuilder content: @escaping (Item) -> Content) -> some View {
        let binding = Binding(get: { item.wrappedValue != nil }, set: { if !$0 { item.wrappedValue = nil } })
        return self.modifier(PresentedPanelModifier(isPresented: binding,
                                                    header: header,
                                                    body: { content(item.wrappedValue!) }))

    }
}

public struct PanelUI_Previews: PreviewProvider {
    struct Preview: View {
        @State var state = PanelState.expanded
        @State var isPresented = false
        var body: some View {
            VStack {
                Text("Top")
                Spacer()
                Button("Toggle Panel") {
                    if self.state == .hidden {
                        self.state = .expanded
                    } else {
                        self.state = .hidden
                    }
                }
                Spacer()
                Text("Buttom")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .panel(isPresented: $isPresented, header: { progress in
                HStack {
                    Button(action: {
                        if self.state == .expanded {
                            self.state = .collapsed
                        } else {
                            self.state = .expanded
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .rotationEffect(.radians(-Double.pi * (1 - progress)))
                    }
                    .font(.headline)
                    Spacer()
                    Text("\(progress) - \(state.rawValue)")
                }
                .padding()
                .background(Color.green.opacity(1 - progress))
            }) {
                ScrollView {
                    VStack {
                        HStack {
                            Text("Cool Panel")
                            Spacer()
                            Text("Hoho")
                        }
                        Spacer()
                        Button("Done") {
                            self.state = .hidden
                        }
                    }
                    .padding()
                }
                .background(Color.red)
            }
        }
    }
    public  static var previews: some View {
        Group {
            Preview()
                .previewDevice("iPhone 12 Pro")
            Preview()
                .previewDevice("iPad Pro (11-inch) (2nd generation)")
        }
    }
}
