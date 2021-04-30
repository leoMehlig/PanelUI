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
        case leading, trailing, center
    }

    public var state: State = .expanded {
        didSet {
            self.predictedState = self.state
        }
    }

    public var position: Position = .trailing {
        didSet {
            self.predictedPosition = self.position
        }
    }

    public var predictedState: State = .expanded

    public var predictedPosition: Position = .center

    //Remove did set when using Aiolos
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

public extension EnvironmentValues {
    var panelState: Binding<PanelState> {
        get { self[PanelStateKey.self] }
        set { self[PanelStateKey.self] = newValue }
    }
}

struct PanelProgressKey: EnvironmentKey {
    static var defaultValue: Double = 1
}

public extension EnvironmentValues {
    var panelProgress: Double {
        get { self[PanelProgressKey.self] }
        set { self[PanelProgressKey.self] = newValue }
    }
}
