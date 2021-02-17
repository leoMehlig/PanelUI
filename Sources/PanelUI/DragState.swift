//
//  File.swift
//  
//
//  Created by Leonard Mehlig on 17.02.21.
//

import SwiftUI

extension Panel {
    struct DragState: CustomStringConvertible, Equatable {

        enum Direction: Equatable {
            case vertical, horizontal
        }

        var direction: Direction? = nil
        var offset: CGSize = .zero
        var predictedEnd: CGSize?

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
}
