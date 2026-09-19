import AppKit
import SwiftUI

/// The standalone settings window hosting `SettingsView`. Created on first use
/// and kept afterwards, so reopening it is instant.
@MainActor
final class SettingsWindowController {
    private let settings: Settings
    private(set) var window: NSWindow?

    init(settings: Settings) {
        self.settings = settings
    }

    /// Opens the window, or brings it forward, centred on the screen under the
    /// mouse pointer.
    func show() {
        let window = self.window ?? makeWindow()
        self.window = window

        window.layoutIfNeeded()
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        if let frame = screen?.visibleFrame {
            let size = window.frame.size
            window.setFrameOrigin(NSPoint(x: frame.midX - size.width / 2, y: frame.midY - size.height / 2))
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Re-reads the title, for when the interface language changes.
    func updateTitle() {
        window?.title = settings.t(.settings)
    }

    private func makeWindow() -> NSWindow {
        let hosting = NSHostingController(rootView: SettingsView().environmentObject(settings))
        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable]
        window.title = settings.t(.settings)
        window.isReleasedWhenClosed = false
        return window
    }
}
