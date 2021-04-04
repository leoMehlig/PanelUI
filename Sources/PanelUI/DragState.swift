import SwiftUI

extension Panel {
    struct DragState: CustomStringConvertible, Equatable {
        enum Direction: Equatable {
            case vertical, horizontal
        }

        var direction: Direction?
        var offset: CGSize = .zero
        var predictedEnd: CGSize?

        mutating func update(offset: CGSize, with sizeClass: UserInterfaceSizeClass?) {
            self.offset = offset
            if sizeClass == .compact {
                self.direction = .vertical
            } else if self.direction == nil {
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
            if self.direction == .vertical {
                return self.offset.height
            } else {
                return 0
            }
        }

        var x: CGFloat {
            if self.direction == .horizontal {
                return self.offset.width
            } else {
                return 0
            }
        }

        var description: String {
            switch self.direction {
            case .horizontal:
                return "↔ \(Int(self.x))"
            case .vertical:
                return "↕ \(Int(self.y))"
            default:
                return "undecided"
            }
        }
    }
}
