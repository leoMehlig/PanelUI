import UIKit

@objc
public extension UIViewController {
    var aiolosPanel: Panel? {
        var panel = self.parent
        while panel != nil, (panel is Panel) == false {
            panel = panel?.parent
        }

        return panel as? Panel
    }
}
