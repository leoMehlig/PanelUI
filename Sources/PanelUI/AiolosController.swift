//
//  ViewController.swift
//  Aiolos
//
//  Created by Matthias Tretter on 11/07/2017.
//  Copyright © 2017 Matthias Tretter. All rights reserved.
//
import Aiolos
import Combine
import SwiftUI
import UIKit

extension PanelState {
    var mode: Aiolos.Panel.Configuration.Mode {
        switch self.state {
        case .expanded:
            return .fullHeight
        case .collapsed:
            return .compact
        }
    }
}

class AiolosController<Content: View, PanelContent: View>: UIHostingController<Content> {
    private lazy var panelController: Aiolos.Panel = self.makePanelController()

    var panelContent: PanelContent? {
        didSet {
            (self.panelController.contentViewController as? UIHostingController<PanelContent?>)?.rootView = self
                .panelContent
        }
    }

    var headerHeight: CGFloat = 64 {
        didSet {
            if oldValue != self.headerHeight {
                self.panelController.reloadSize()
            }
        }
    }

    @Binding var state: PanelState

    var panelSafeArea: PanelSafeArea = .init()

    var progressPublisher: CurrentValueSubject<Double, Never> = CurrentValueSubject(1)

    func apply(state: PanelState, content: PanelContent?) {
        var config = self.panelController.configuration
        config.mode = state.mode

        if self.traitCollection.horizontalSizeClass == .compact {
            config.position = .bottom
        } else {
            switch state.position {
            case .leading, .center:
                config.position = .leadingBottom
            case .trailing:
                config.position = .trailingBottom
            }
        }
        if config.mode != self.panelController.configuration.mode || config.position != self.panelController
            .configuration.position {
            DispatchQueue.main.async {
                self.panelController.configuration = config
            }
        }
        if state.isPresented != self.panelController.isVisible {
            let transition: Aiolos.Panel.Transition = self.traitCollection
                .horizontalSizeClass == .regular ? .slide(direction: .horizontal) : .slide(direction: .vertical)

            if !state.isPresented {
                self.panelController.removeFromParent(transition: transition, completion: {
                    if !self.state.isPresented {
                        DispatchQueue.main.async {
                            self.panelContent = content
                            self.state.state = .expanded
                        }
                    }
                })
            } else {
                self.panelContent = content
                self.panelController.add(to: self, transition: transition, completion: nil)
            }
        } else {
            self.panelContent = content
        }

        DispatchQueue.main.async {
            if state.isPresented, state.state == .collapsed {
                if self.traitCollection.horizontalSizeClass == .compact {
                    self.panelSafeArea.bottomInset = self.headerHeight
                } else {
                    self.panelSafeArea.bottomInset = self.headerHeight + 20
                }
            } else {
                self.panelSafeArea.bottomInset = 0
            }
            self.panelSafeArea.position = state.position
        }
    }

    init(rootView: Content, state: Binding<PanelState>) {
        self._state = state
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    @objc dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
    }

    override func willTransition(to newCollection: UITraitCollection,
                                 with coordinator: UIViewControllerTransitionCoordinator) {
        let changes = newCollection.horizontalSizeClass != traitCollection.horizontalSizeClass
        super.willTransition(to: newCollection, with: coordinator)

        if changes {
            coordinator.animate(alongsideTransition: { _ in
                self.panelController.performWithoutAnimation {
                    self.panelController.configuration = self.configuration(for: newCollection, state: self.state)
                }
            }, completion: nil)
        }
    }

    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        [.bottom]
    }

    func makePanelController() -> Aiolos.Panel {
        let panelController = Aiolos
            .Panel(configuration: self.configuration(for: self.traitCollection, state: self.state))
        let hosting = UIHostingController(rootView: panelContent)

        panelController.sizeDelegate = self
        panelController.resizeDelegate = self
        panelController.repositionDelegate = self
        panelController.contentViewController = hosting

        return panelController
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
            let offset = self.traitCollection.horizontalSizeClass == .compact ? self.view.safeAreaInsets.bottom : 0
            return CGSize(width: width,
                          height: self.headerHeight + offset)
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
        let full = self.panelController.size(for: .fullHeight).height
        let header = self.panelController.size(for: .compact).height
        let progress = (size.height - header) / (full - header)
        print("Current progress", progress)
        if progress != CGFloat(self.progressPublisher.value) {
            self.progressPublisher.send(Double(progress))
        }
    }

    func panel(_ panel: Aiolos.Panel, willTransitionFrom oldMode: Aiolos.Panel.Configuration.Mode?,
               to newMode: Aiolos.Panel.Configuration.Mode, with coordinator: PanelTransitionCoordinator) {
        print("Panel will transition from \(String(describing: oldMode)) to \(newMode)")
        DispatchQueue.main.async {
            // we can animate things along the way
            switch newMode {
            case .fullHeight:
                self.state.state = .expanded
            case .compact:
                self.state.state = .collapsed
            default:
                break
            }
        }
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
        self.traitCollection.horizontalSizeClass == .regular
    }

    func panelCanBeDismissed(_ panel: Aiolos.Panel) -> Bool {
        true
    }

    func panel(_ panel: Aiolos.Panel, willMoveTo frame: CGRect) -> Bool {
        print("Panel will move to frame \(frame)")

        // we can prevent the panel from begin dragged
        // returning false will result in a rubber-band effect
        return true
    }

    func panel(_ panel: Aiolos.Panel, didStopMoving endFrame: CGRect,
               with context: PanelRepositionContext) -> PanelRepositionContext.Instruction {
        print("Panel did move to frame \(endFrame)")

        let panelShouldHide = context.isMovingPastLeadingEdge || context.isMovingPastTrailingEdge
        guard !panelShouldHide else { return .hide }

        return .updatePosition(context.targetPosition)
    }

    func panel(_ panel: Aiolos.Panel, willTransitionFrom oldPosition: Aiolos.Panel.Configuration.Position,
               to newPosition: Aiolos.Panel.Configuration.Position, with coordinator: PanelTransitionCoordinator) {
        print("Panel is transitioning from \(String(describing: oldPosition)) to position \(newPosition)")

        DispatchQueue.main.async {
            switch newPosition {
            case .bottom:
                self.state.position = .center
            case .leadingBottom:
                self.state.position = .leading
            case .trailingBottom:
                self.state.position = .trailing
            }
        }
        // we can animate things along the way
        coordinator.animateAlongsideTransition({
            print("Animating alongside of panel transition")
        }, completion: { _ in
            print("Completed panel transition to \(newPosition)")
        })
    }

    func panelWillTransitionToHiddenState(_ panel: Aiolos.Panel, with coordinator: PanelTransitionCoordinator) {
        print("Panel is transitioning to hidden state")
        DispatchQueue.main.async {
            self.state.isPresented = false
        }
        // we can animate things along the way
        coordinator.animateAlongsideTransition({
            print("Animating alongside of panel transition")
        }, completion: { _ in
            print("Completed panel transition to hidden state")
            self.state.state = .expanded
        })
    }
}

// MARK: - Private

private extension AiolosController {
    func configuration(for traitCollection: UITraitCollection, state: PanelState) -> Aiolos.Panel.Configuration {
        var configuration = Aiolos.Panel.Configuration.default

        var panelMargins: NSDirectionalEdgeInsets {
            if traitCollection.horizontalSizeClass == .regular {
                return NSDirectionalEdgeInsets(top: 20.0, leading: 20.0, bottom: 20.0, trailing: 20.0)
            }

            return NSDirectionalEdgeInsets(top: 20.0, leading: 0.0, bottom: 0.0, trailing: 0.0)
        }
        configuration.appearance.resizeHandle = .hidden
        configuration.appearance.separatorColor = .white

        configuration.margins = panelMargins
        configuration.supportedModes = [.minimal, .compact, .fullHeight]
        switch self.traitCollection.horizontalSizeClass {
        case .regular:
            configuration.supportedPositions = [.leadingBottom, .trailingBottom]
            configuration.appearance.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
                .layerMinXMaxYCorner,
                .layerMaxXMaxYCorner
            ]
        case .compact:
            configuration.supportedPositions = [.bottom]
            configuration.appearance.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            configuration.positionLogic[.bottom] = .ignoreSafeArea
        case .unspecified:
            break
        @unknown default:
            break
        }

        switch self.state.state {
        case .collapsed:
            configuration.mode = .compact
        case .expanded:
            configuration.mode = .fullHeight
        }

        if self.traitCollection.horizontalSizeClass == .compact {
            configuration.position = .bottom
        } else {
            switch state.position {
            case .leading, .center:
                configuration.position = .leadingBottom
            case .trailing:
                configuration.position = .trailingBottom
            }
        }

        return configuration
    }
}

private extension UITraitCollection {
    var hasNotch: Bool {
        UIApplication.shared.windows.contains(where: { $0.safeAreaInsets.bottom > 0 })
    }
}
