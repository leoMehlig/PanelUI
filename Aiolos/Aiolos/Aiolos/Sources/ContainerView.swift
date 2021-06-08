#if canImport(UIKit)
import UIKit

/// Internal class that is used as a Container for the Panel
final class ContainerView: UIView {
    // MARK: - Lifecycle

    init(configuration: Panel.Configuration) {
        super.init(frame: .zero)
        self.configure(with: configuration)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - ContainerView

    func configure(with configuration: Panel.Configuration) {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = configuration.appearance.cornerRadius
        self.layer.maskedCorners = configuration.appearance.maskedCorners
    }
}
#endif
