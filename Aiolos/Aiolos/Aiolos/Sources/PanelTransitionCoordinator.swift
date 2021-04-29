import UIKit

/// This coordinator can be used to animate things alongside the movement of the Panel
public final class PanelTransitionCoordinator {
    private unowned let animator: PanelAnimator

    // MARK: - Properties

    public let direction: Panel.Direction
    public var isAnimated: Bool { self.animator.animateChanges }

    // MARK: - Lifecycle

    init(animator: PanelAnimator, direction: Panel.Direction) {
        self.animator = animator
        self.direction = direction
    }
}

// MARK: - PanelTransitionCoordinator

public extension PanelTransitionCoordinator {
    func animateAlongsideTransition(_ animations: @escaping () -> Void,
                                    completion: ((UIViewAnimatingPosition) -> Void)? = nil) {
        self.animator.transitionCoordinatorQueuedAnimations
            .append(Animation(animations: animations, completion: completion))
    }

    func horizontalOffset(for panel: Panel, at position: Panel.Configuration.Position) -> CGFloat {
        panel.horizontalOffset(at: position)
    }
}

// MARK: - PanelTransitionCoordinator.Animation

extension PanelTransitionCoordinator {
    struct Animation {
        let animations: () -> Void
        let completion: ((UIViewAnimatingPosition) -> Void)?
    }
}
