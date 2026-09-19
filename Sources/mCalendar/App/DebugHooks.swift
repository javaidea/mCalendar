import AppKit

/// Environment variables that drive the UI without a mouse, so windows can be
/// screenshot-tested from the command line. None has any effect unless set.
///
/// - `ZC_SETTINGS`: open the settings window, pinned near the top-left corner.
/// - `ZC_SHOW`: open the popover; with `ZC_RETOGGLE` also close and reopen it,
///   to exercise the second presentation.
extension AppDelegate {
    func installDebugHooks() {
        let environment = ProcessInfo.processInfo.environment

        if environment["ZC_SETTINGS"] != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.openSettings()
                if let screen = NSScreen.screens.first {
                    self?.settingsWindow.window?.setFrameTopLeftPoint(
                        NSPoint(x: screen.visibleFrame.minX + 50, y: screen.visibleFrame.maxY - 50)
                    )
                }
            }
        }

        if environment["ZC_SHOW"] != nil {
            let toggle = { [weak self] in
                guard let self, let button = self.statusItem.button else { return }
                self.calendarPopover.toggle(relativeTo: button)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { toggle() }
            if environment["ZC_RETOGGLE"] != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { toggle() }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { toggle() }
            }
        }
    }
}
