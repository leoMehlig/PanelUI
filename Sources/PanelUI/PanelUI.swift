import SwiftUI

enum PanelState: String {
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

struct Panel<Content: View>: View {
    enum Position: String {
        case leading
        case trailing
    }

    struct DragState: CustomStringConvertible {

        enum Direction {
            case vertical, horizontal
        }

        var direction: Direction? = nil
        var offset: CGSize = .zero

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
    let width: CGFloat = 375
    let content: Content

    @Binding var state: PanelState

    @GestureState private var dragState = DragState()

    @Environment(\.horizontalSizeClass) var sizeClass

    @State var position = Position.leading

    @State private var headerHeight: CGFloat = 0

    init(state: Binding<PanelState>, @ViewBuilder content: () -> Content) {
        self._state = state
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
                        .offset(x: position == .leading
                                    ? dragState.x
                                    : proxy.size.width + dragState.x - width)
                    Spacer()
                }
            }
        }
        .padding(sizeClass == .regular ? 20 : 0)
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
        .animation(.spring(), value: state)
        .frame(height: state == .expanded
                ? proxy.size.height - dragState.y
                : headerHeight - dragState.y)
        .frame(maxWidth: sizeClass == .regular ? width : .infinity)
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

    func header(in proxy: GeometryProxy) -> some View {
        HStack {
            Button(action: {
                if self.state == .expanded {
                    self.state = .collapsed
                } else {
                    self.state = .expanded
                }
            }) {
                Image(systemName: self.state == .expanded ? "chevron.down" : "chevron.up")
            }
            .font(.headline)
            Spacer()
            Text("\(dragState.description) - \(state.rawValue) - \(position.rawValue)")
        }
        .padding()
        .padding(.vertical, 20)
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
                    }
                    .onEnded { [dragState] value in
                        if dragState.direction == .vertical {
                            if value.predictedEndLocation.y < proxy.size.height / 2 {
                                self.state = .expanded
                            } else {
                                self.state = .collapsed
                            }
                        } else if dragState.direction == .horizontal {
                            if value.predictedEndLocation.x < proxy.size.width / 2 {
                                self.position = .leading
                            } else {
                                self.position = .trailing
                            }
                        }
                    })
        .offset(x: -dragState.x, y: -dragState.y)
    }
}

public struct PanelUI_Previews: PreviewProvider {
    struct Preview: View {
        @State var state = PanelState.expanded
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
            .overlay(Panel(state: $state) {
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
            })
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
