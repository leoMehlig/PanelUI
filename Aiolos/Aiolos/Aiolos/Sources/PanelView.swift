import UIKit

/// The view of the Panel
@objc
public final class PanelView: UIVisualEffectView {
    // MARK: - Lifecycle

    public init(configuration: Panel.Configuration) {
        super.init(effect: configuration.appearance.visualEffect)

        self.clipsToBounds = true
        self.configure(with: configuration)
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - PanelView

    func configure(with configuration: Panel.Configuration) {
        self.effect = configuration.appearance.visualEffect
    }
}
