import UIKit

extension UIView {
    var isRTL: Bool {
        self.effectiveUserInterfaceLayoutDirection == .rightToLeft
    }
}
