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
final class AiolosController<Content: View, PanelContent: View>: UIHostingController<Content> {

    private lazy var panelController: Aiolos.Panel = self.makePanelController()

    var panelContent: PanelContent? {
        didSet {
            (panelController.contentViewController as? UIHostingController<PanelContent?>)?.rootView = self.panelContent
        }
    }

    var headerHeight: CGFloat = 64 {
        didSet {
            panelController.reloadSize()
        }
    }

    var isPresented: Bool = false {
        didSet {
            guard self.panelController.isVisible != isPresented else {
                return
            }
            let transition: Aiolos.Panel.Transition = self.traitCollection.horizontalSizeClass == .regular ? .slide(direction: .horizontal) : .slide(direction: .vertical)

            if !isPresented {
                self.panelController.removeFromParent(transition: transition)
            } else {
                self.panelController.add(to: self, transition: transition)
            }
        }
    }

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
//        self.view.isUserInteractionEnabled = false

    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.panelController.performWithoutAnimation {
                self.panelController.configuration = self.configuration(for: newCollection)
            }
        }, completion: nil)
    }

    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.bottom]
    }


    func makePanelController() -> Aiolos.Panel {
        let panelController = Aiolos.Panel(configuration: self.configuration(for: self.traitCollection))
        let hosting = UIHostingController(rootView: panelContent)


        panelController.sizeDelegate = self
        panelController.resizeDelegate = self
        panelController.repositionDelegate = self
//        panelController.gestureDelegate = self
        panelController.contentViewController = hosting

        return panelController
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let contentNavigationController = self.panelController.contentViewController as? UINavigationController else { return false }
        guard let tableViewController = contentNavigationController.topViewController as? UITableViewController else { return false }

        // Prevent swipes on the table view being triggered as the panel is being dragged horizontally
        // More info: https://github.com/IdeasOnCanvas/Aiolos/issues/23
        return otherGestureRecognizer.view === tableViewController.tableView
    }
}

// MARK: - PanelSizeDelegate
extension AiolosController: PanelSizeDelegate {

    func panel(_ panel: Aiolos.Panel, sizeForMode mode: Aiolos.Panel.Configuration.Mode) -> CGSize {
        func panelWidth(for position: Aiolos.Panel.Configuration.Position) -> CGFloat {
            if position == .bottom { return 0.0 }

            return self.traitCollection.horizontalSizeClass == .regular ? 320.0 : 270.0
        }

        let width = panelWidth(for: panel.configuration.position)
        switch mode {
        case .compact:
            return CGSize(width: width, height: headerHeight)
        case .fullHeight:
            return CGSize(width: width, height: 0.0)
        default:
            return .zero
        }
    }
}

// MARK: - PanelResizeDelegate
extension AiolosController: PanelResizeDelegate {

    func panelDidStartResizing(_ panel: Aiolos.Panel) {
        print("Panel did start resizing")
    }

    func panel(_ panel: Aiolos.Panel, willResizeTo size: CGSize) {
        print("Panel will resize to size \(size)")
    }

    func panel(_ panel: Aiolos.Panel, willTransitionFrom oldMode: Aiolos.Panel.Configuration.Mode?, to newMode: Aiolos.Panel.Configuration.Mode, with coordinator: PanelTransitionCoordinator) {
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

    func panelCanStartMoving(_ panel: Aiolos.Panel) -> Bool {
        return self.traitCollection.userInterfaceIdiom == .pad
    }

    func panelCanBeDismissed(_ panel: Aiolos.Panel) -> Bool {
        return true
    }

    func panel(_ panel: Aiolos.Panel, willMoveTo frame: CGRect) -> Bool {
        print("Panel will move to frame \(frame)")

        // we can prevent the panel from begin dragged
        // returning false will result in a rubber-band effect
        return true
    }

    func panel(_ panel: Aiolos.Panel, didStopMoving endFrame: CGRect, with context: PanelRepositionContext) -> PanelRepositionContext.Instruction {
        print("Panel did move to frame \(endFrame)")

        let panelShouldHide = context.isMovingPastLeadingEdge || context.isMovingPastTrailingEdge
        guard !panelShouldHide else { return .hide }

        return .updatePosition(context.targetPosition)
    }

    func panel(_ panel: Aiolos.Panel, willTransitionFrom oldPosition: Aiolos.Panel.Configuration.Position, to newPosition: Aiolos.Panel.Configuration.Position, with coordinator: PanelTransitionCoordinator) {
        print("Panel is transitioning from \(String(describing: oldPosition)) to position \(newPosition)")

        // we can animate things along the way
        coordinator.animateAlongsideTransition({
            print("Animating alongside of panel transition")
        }, completion: { _ in
            print("Completed panel transition to \(newPosition)")
        })
    }

    func panelWillTransitionToHiddenState(_ panel: Aiolos.Panel, with coordinator: PanelTransitionCoordinator) {
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

        var panelMargins: NSDirectionalEdgeInsets {
            if traitCollection.horizontalSizeClass == .regular {
                return NSDirectionalEdgeInsets(top: 20.0, leading: 20.0, bottom: 20.0, trailing: 20.0)
            }

            return NSDirectionalEdgeInsets(top: 20.0, leading: 0.0, bottom: 0.0, trailing: 0.0)
        }

        configuration.appearance.separatorColor = .white
        configuration.position = traitCollection.horizontalSizeClass == .compact ? .bottom : .trailingBottom
        configuration.margins = panelMargins
        configuration.supportedModes = [.minimal, .compact, .fullHeight]
        switch self.traitCollection.horizontalSizeClass {
        case .regular:
            configuration.supportedPositions = [.leadingBottom, .trailingBottom]
            configuration.appearance.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        case .compact:
            configuration.supportedPositions = [.bottom]
            configuration.appearance.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        case .unspecified:
            break
        @unknown default:
            break
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
