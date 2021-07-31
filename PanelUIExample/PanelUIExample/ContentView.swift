import PanelUI
import SwiftUI

struct ContentView: View {
    @State var isPresented = true

    @State var item: Item? = nil // Item(id: "Test")

    public init() {}

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
        .background(Color.gray.edgesIgnoringSafeArea(.all))
        .panel(item: $item) { _ in
            VStack(spacing: 0) {
                Header()
                    .background(GeometryReader { proxy in
                        Color.clear
                            .preference(key: PanelHeaderHeightKey.self, value: [proxy.size.height])
                    })
                ListScrollView()
                Text("end")
            }
        }
    }
}

struct Item: Identifiable {
    var id: String
}

struct SlowView: View {
    var body: some View {
        for _ in 0 ..< 10000 {
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
                TextField("trst", text: .constant("Test"))
                Duration(x: $x, foo: {})
                    .transition(AnyTransition.opacity.animation(.default)
                        .combined(with: AnyTransition.move(edge: .bottom)))
                ForEach(0 ..< 20) { _ in
//                    SlowView()
                    Color.blue
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

            Button(action: {
                switch self.state.wrappedValue.position {
                case .leading:
                    self.state.position.wrappedValue = .trailing
                case .trailing:
                    self.state.position.wrappedValue = .leading
                case .center:
                    self.state.position.wrappedValue = .center
                }
            }) {
                Image(systemName: "chevron.down")
                    .rotationEffect(.radians(-Double.pi * (1 - progress)))
            }
        }
        .padding()
        .background(Color.green.opacity(1 - progress))
        .background(Color.white)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
