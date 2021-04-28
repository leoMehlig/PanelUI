//
//  ViewController.swift
//  Aiolos
//
//  Created by Matthias Tretter on 11/07/2017.
//  Copyright © 2017 Matthias Tretter. All rights reserved.
//
import Aiolos
import UIKit
import SwiftUI


/// The RootViewController of the Demo
public final class AiolosController<Content: View>: UIViewController, UIGestureRecognizerDelegate {

    private lazy var panelController: Aiolos.Panel = self.makePanelController()

    var content: Content?

    // MARK: - UIViewController
    override public func viewDidLoad() {
        super.viewDidLoad()


        self.panelController.add(to: self, transition: .none)
    }

    override public func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.panelController.performWithoutAnimation {
                self.panelController.configuration = self.configuration(for: newCollection)
            }
        }, completion: nil)
    }

    override public var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.bottom]
    }


    func makePanelController() -> Aiolos.Panel {
        let panelController = Aiolos.Panel(configuration: self.configuration(for: self.traitCollection))
        let hosting = UIHostingController(rootView: content)


        panelController.sizeDelegate = self
        panelController.resizeDelegate = self
        panelController.repositionDelegate = self
        panelController.gestureDelegate = self
        panelController.contentViewController = hosting

        return panelController
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let contentNavigationController = self.panelController.contentViewController as? UINavigationController else { return false }
        guard let tableViewController = contentNavigationController.topViewController as? UITableViewController else { return false }

        // Prevent swipes on the table view being triggered as the panel is being dragged horizontally
        // More info: https://github.com/IdeasOnCanvas/Aiolos/issues/23
        return otherGestureRecognizer.view === tableViewController.tableView
    }
}

// MARK: - PanelSizeDelegate
extension AiolosController: PanelSizeDelegate {

    public func panel(_ panel: Aiolos.Panel, sizeForMode mode: Aiolos.Panel.Configuration.Mode) -> CGSize {
        func panelWidth(for position: Aiolos.Panel.Configuration.Position) -> CGFloat {
            if position == .bottom { return 0.0 }

            return self.traitCollection.userInterfaceIdiom == .pad ? 320.0 : 270.0
        }

        let width = panelWidth(for: panel.configuration.position)
        switch mode {
        case .minimal:
            return CGSize(width: width, height: 0.0)
        case .compact:
            return CGSize(width: width, height: 64.0)
        case .expanded:
            let height: CGFloat = self.traitCollection.userInterfaceIdiom == .phone ? 270.0 : 320.0
            return CGSize(width: width, height: height)
        case .fullHeight:
            return CGSize(width: width, height: 0.0)
        }
    }
}

// MARK: - PanelResizeDelegate
extension AiolosController: PanelResizeDelegate {

    public func panelDidStartResizing(_ panel: Aiolos.Panel) {
        print("Panel did start resizing")
    }

    public func panel(_ panel: Aiolos.Panel, willResizeTo size: CGSize) {
        print("Panel will resize to size \(size)")
    }

    public func panel(_ panel: Aiolos.Panel, willTransitionFrom oldMode: Aiolos.Panel.Configuration.Mode?, to newMode: Aiolos.Panel.Configuration.Mode, with coordinator: PanelTransitionCoordinator) {
        print("Panel will transition from \(String(describing: oldMode)) to \(newMode)")

        // we can animate things along the way
        coordinator.animateAlongsideTransition({
            print("Animating alongside of panel transition")
        }, completion: { _ in
            print("Completed panel transition to \(newMode)")
        })
    }
}

// MARK: - PanelRepositionDelegate
extension AiolosController: PanelRepositionDelegate {

    public func panelCanStartMoving(_ panel: Aiolos.Panel) -> Bool {
        return self.traitCollection.userInterfaceIdiom == .pad
    }

    public func panelCanBeDismissed(_ panel: Aiolos.Panel) -> Bool {
        return true
    }

    public func panel(_ panel: Aiolos.Panel, willMoveTo frame: CGRect) -> Bool {
        print("Panel will move to frame \(frame)")

        // we can prevent the panel from begin dragged
        // returning false will result in a rubber-band effect
        return true
    }

    public func panel(_ panel: Aiolos.Panel, didStopMoving endFrame: CGRect, with context: PanelRepositionContext) -> PanelRepositionContext.Instruction {
        print("Panel did move to frame \(endFrame)")

        let panelShouldHide = context.isMovingPastLeadingEdge || context.isMovingPastTrailingEdge
        guard !panelShouldHide else { return .hide }

        return .updatePosition(context.targetPosition)
    }

    public func panel(_ panel: Aiolos.Panel, willTransitionFrom oldPosition: Aiolos.Panel.Configuration.Position, to newPosition: Aiolos.Panel.Configuration.Position, with coordinator: PanelTransitionCoordinator) {
        print("Panel is transitioning from \(String(describing: oldPosition)) to position \(newPosition)")

        // we can animate things along the way
        coordinator.animateAlongsideTransition({
            print("Animating alongside of panel transition")
        }, completion: { _ in
            print("Completed panel transition to \(newPosition)")
        })
    }

    public func panelWillTransitionToHiddenState(_ panel: Aiolos.Panel, with coordinator: PanelTransitionCoordinator) {
        print("Panel is transitioning to hidden state")

        // we can animate things along the way
        coordinator.animateAlongsideTransition({
            print("Animating alongside of panel transition")
        }, completion: { _ in
            print("Completed panel transition to hidden state")
        })
    }
}


// MARK: - Private
private extension AiolosController {

    func configuration(for traitCollection: UITraitCollection) -> Aiolos.Panel.Configuration {
        var configuration = Aiolos.Panel.Configuration.default

        var panelPosition: Aiolos.Panel.Configuration.Position {
            if traitCollection.userInterfaceIdiom == .pad { return .trailingBottom }

            return traitCollection.verticalSizeClass == .compact ? .leadingBottom : .bottom
        }

        var panelMargins: NSDirectionalEdgeInsets {
            if traitCollection.userInterfaceIdiom == .pad || traitCollection.hasNotch { return NSDirectionalEdgeInsets(top: 20.0, leading: 20.0, bottom: 20.0, trailing: 20.0) }

            let horizontalMargin: CGFloat = traitCollection.verticalSizeClass == .compact ? 20.0 : 0.0
            return NSDirectionalEdgeInsets(top: 20.0, leading: horizontalMargin, bottom: 0.0, trailing: horizontalMargin)
        }

        configuration.appearance.separatorColor = .white
        configuration.position = panelPosition
        configuration.margins = panelMargins

        if self.traitCollection.userInterfaceIdiom == .pad {
            configuration.supportedPositions = [.leadingBottom, .trailingBottom]
            configuration.appearance.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            configuration.supportedModes = [.minimal, .compact, .expanded, .fullHeight]
            configuration.supportedPositions = [configuration.position]

            if traitCollection.hasNotch {
                configuration.appearance.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            } else {
                configuration.appearance.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            }
        }

        return configuration
    }
//
//    @objc
//    func handleToggleVisibilityPress() {
//        let transition: Aiolos.Panel.Transition = self.traitCollection.userInterfaceIdiom == .pad ? .slide(direction: .horizontal) : .slide(direction: .vertical)
//
//        if self.panelController.isVisible {
//            self.panelController.removeFromParent(transition: transition)
//        } else {
//            self.panelController.add(to: self, transition: transition)
//        }
//    }
//
//    @objc
//    func handleToggleModePress() {
//        let nextModeMapping: [Aiolos.Panel.Configuration.Mode: Aiolos.Panel.Configuration.Mode] = [ .compact: .expanded,
//                                                                                      .expanded: .fullHeight,
//                                                                                      .fullHeight: .compact ]
//        guard let nextMode = nextModeMapping[self.panelController.configuration.mode] else { return }
//
//        self.panelController.configuration.mode = nextMode
//    }
}

private extension UITraitCollection {

    var hasNotch: Bool {
        return UIApplication.shared.keyWindow!.safeAreaInsets.bottom > 0.0
    }
}
