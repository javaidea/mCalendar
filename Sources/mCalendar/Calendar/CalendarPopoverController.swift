import AppKit
import SwiftUI

/// Shows `CalendarView` in a popover under the menu bar item.
///
/// The popover's own transient behaviour is not used: it is closed explicitly,
/// by a second click on the item or by a click anywhere outside the app.
@MainActor
final class CalendarPopoverController {
    private let settings: Settings
    private var popover: NSPopover?
    private var outsideClickMonitor: Any?

    init(settings: Settings) {
        self.settings = settings
    }

    /// The popover's appearance; nil follows the system. Applied to the open
    /// popover straight away, and to every one opened later.
    var appearance: NSAppearance? {
        didSet { popover?.appearance = appearance }
    }

    func toggle(relativeTo button: NSStatusBarButton) {
        if popover != nil {
            close()
        } else {
            show(relativeTo: button)
        }
    }

    func show(relativeTo button: NSStatusBarButton) {
        let popover = NSPopover()
        popover.behavior = .applicationDefined
        popover.appearance = appearance
        let hosting = NSHostingController(rootView: CalendarView().environmentObject(settings))
        // Size the popover to its content, which also avoids clipping at the top.
        hosting.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hosting

        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        // The vibrant material renders as flat grey when the popover's window
        // isn't focused (e.g. on quick re-opens). Making it key keeps the look.
        popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
        self.popover = popover

        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            self?.close()
        }
    }

    func close() {
        popover?.performClose(nil)
        popover = nil
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickMonitor = nil
        }
    }
}
