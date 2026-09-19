import AppKit

/// The menu bar item: its date/weekday label, and what a click on it does.
/// A left click is handed to `onClick`; a right click shows About / Quit.
@MainActor
final class StatusItemController: NSObject {
    /// Called on a left click with the button to anchor the popover to.
    var onClick: ((NSStatusBarButton) -> Void)?

    private let statusItem: NSStatusItem
    private let settings: Settings
    private var timer: Timer?

    var button: NSStatusBarButton? { statusItem.button }

    init(settings: Settings) {
        self.settings = settings
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        updateTitle()

        // Refresh the label periodically so it rolls over at midnight.
        timer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateTitle() }
        }
    }

    /// Sets the label to "Jul 25, Sat" / "7月25日 周六", or whichever parts are
    /// enabled; with neither, falls back to a calendar icon.
    func updateTitle() {
        guard let button = statusItem.button else { return }
        let f = DateFormatter()
        f.locale = settings.locale
        var parts: [String] = []
        if settings.showDate {
            f.dateFormat = settings.isChinese ? "M月d日" : "MMM d"
            parts.append(f.string(from: Date()))
        }
        if settings.showWeekday {
            f.dateFormat = "EEE"
            parts.append(f.string(from: Date()))
        }
        if parts.isEmpty {
            button.title = ""
            button.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Calendar")
        } else {
            button.image = nil
            button.title = parts.joined(separator: settings.isChinese ? " " : ", ")
        }
    }

    // MARK: - Clicks

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu(sender)
        } else {
            onClick?(sender)
        }
    }

    private func showContextMenu(_ sender: NSStatusBarButton) {
        let menu = NSMenu()
        let about = NSMenuItem(title: settings.t("about"), action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: settings.t("quit"), action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        // Assigning the menu makes the system drop it directly under the status
        // item; it is removed again so the next left click opens the popover.
        statusItem.menu = menu
        sender.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func showAbout() { AboutPanel.show(settings: settings) }

    @objc private func quit() { NSApp.terminate(nil) }
}
