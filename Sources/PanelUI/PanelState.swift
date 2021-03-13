import SwiftUI

public struct PanelState: Hashable {
    public enum State: Hashable {
        case collapsed, expanded

        public mutating func toggle() {
            switch self {
                case .collapsed:
                    self = .expanded
                case .expanded:
                    self = .collapsed
            }
        }
    }

    public enum Position: Hashable {
        case leading, trailing
    }

    public var state: State = .expanded
    public var position: Position = .trailing
    public var isPresented: Bool = false {
        didSet {
            if oldValue != self.isPresented {
                self.state = .expanded
            }
        }
    }
}

struct PanelStateKey: EnvironmentKey {
    static var defaultValue: Binding<PanelState> = .constant(.init())
}

extension EnvironmentValues {
    public var panelState: Binding<PanelState> {
        get { self[PanelStateKey.self] }
        set { self[PanelStateKey.self] = newValue }
    }
}

struct PanelProgressKey: EnvironmentKey {
    static var defaultValue: Double = 1
}

extension EnvironmentValues {
    public var panelProgress: Double {
        get { self[PanelProgressKey.self] }
        set { self[PanelProgressKey.self] = newValue }
    }
}
