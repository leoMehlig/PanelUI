import SwiftUI

enum PanelState: String {
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

    let content: () -> Content
    let header: (Double) -> Header

    @Binding var isPresented: Bool

    @State var state: PanelState = .expanded

    @GestureState private var dragState = DragState()

    @Environment(\.horizontalSizeClass) private var sizeClass

    @ScaledMetric private var width: CGFloat = 325

    @State private var position = Position.leading

    @State private var headerHeight: CGFloat = 0

    init(isPresented: Binding<Bool>,
         @ViewBuilder header: @escaping (Double) -> Header,
         @ViewBuilder content: @escaping () -> Content) {
        self._isPresented = isPresented
        self.header = header
        self.content = content
    }

    @ViewBuilder
    var body: some View {
        GeometryReader { proxy in
            if isPresented {
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
                    .transition(AnyTransition.opacity.animation(.default)
                                    .combined(with: .move(edge: self.position == .leading
                                                            ? .leading : .trailing)))
                }
            }
        }
        .padding(sizeClass == .regular ? 20 : 0)
        .animation(.spring(), value: state)
        .animation(.spring(), value: position)
        .animation(.spring(), value: isPresented)
        .animation(.interactiveSpring())
        .animation(.default)
        .onPreferenceChange(HeaderHeightKey.self, perform: { value in
            self.headerHeight = value
        })
    }

    func panel(in proxy: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            header(in: proxy)
            content()
                .ignoresSafeArea(.container, edges: sizeClass == .compact ? .bottom : [])
        }
        .background(self.background)
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black.opacity(0.5), lineWidth: 1 / UIScreen.main.scale)
                    .ignoresSafeArea(.container, edges: sizeClass == .compact ? .bottom : []))
        .mask(clip)
        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
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

    @Binding var isPresented: Bool
    let header: (Double) -> Header
    let body: () -> Body


    func body(content: Content) -> some View {
        content
            .overlay(Panel(isPresented: $isPresented, header: header, content: body))
    }
}

extension View {

    public func panel<Content: View, Header: View>(isPresented: Binding<Bool>,
                                                   @ViewBuilder header: @escaping (Double) -> Header,
                                                   @ViewBuilder content: @escaping () -> Content) -> some View {
        self.modifier(PanelModifier(isPresented: isPresented, header: header, body: content))
    }

    public func panel<Item: Identifiable, Content: View, Header: View>(item: Binding<Item?>,
                                                                       @ViewBuilder header: @escaping (Double) -> Header,
                                                                       @ViewBuilder content: @escaping (Item) -> Content) -> some View {
        let binding = Binding(get: { item.wrappedValue != nil }, set: { if !$0 { item.wrappedValue = nil } })
        return self.modifier(PanelModifier(isPresented: binding,
                                           header: header,
                                           body: { content(item.wrappedValue!) }))

    }
}

struct Item: Identifiable {
    var id: String
}

public struct PanelUI_Previews: PreviewProvider {

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
            .panel(item: $item, header: { progress in
                HStack {
                    Button(action: {

                    }) {
                        Image(systemName: "chevron.down")
                            .rotationEffect(.radians(-Double.pi * (1 - progress)))
                    }
                    .font(.headline)
                    Spacer()
                    Text("\(progress) - \(isPresented.description)")
                }
                .padding()
                .background(Color.green.opacity(1 - progress))
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
                .background(Color.red)
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
