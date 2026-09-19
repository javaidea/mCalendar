import SwiftUI
import AppKit

@main
struct mCalendarApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover?
    private var settingsWindow: NSWindow?
    private var timer: Timer?
    private var eventMonitor: Any?
    private let settings = Settings.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menubar-only app: no Dock icon.
        NSApp.setActivationPolicy(.accessory)
        // Use the icon in the bundle rather than the system's cached copy, which
        // can lag behind a new icon when the version number stays the same.
        if let icon = Bundle.main.image(forResource: "AppIcon") {
            NSApp.applicationIconImage = icon
        }
        applyAppearance()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        updateTitle()

        // Refresh the menubar label periodically so it rolls over at midnight.
        timer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateTitle() }
        }

        settings.onChange = { [weak self] in
            self?.updateTitle()
            self?.applyAppearance()
            self?.settingsWindow?.title = self?.settings.t("settings") ?? "Settings"
        }

        // Debug hook: auto-open the settings window for screenshot testing.
        if ProcessInfo.processInfo.environment["ZC_SETTINGS"] != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.openSettings()
                if let screen = NSScreen.screens.first {
                    self?.settingsWindow?.setFrameTopLeftPoint(
                        NSPoint(x: screen.visibleFrame.minX + 50, y: screen.visibleFrame.maxY - 50)
                    )
                }
            }
        }

        // Debug hook: auto show (and optionally re-show, to exercise the second
        // presentation) so the popover can be screenshot-tested from the CLI.
        if ProcessInfo.processInfo.environment["ZC_SHOW"] != nil {
            let toggle = { [weak self] in
                guard let self, let button = self.statusItem.button else { return }
                self.togglePopover(button)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { toggle() }
            if ProcessInfo.processInfo.environment["ZC_RETOGGLE"] != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { toggle() }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { toggle() }
            }
        }
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu(sender)
        } else {
            togglePopover(sender)
        }
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover != nil {
            closePopover()
            return
        }

        let popover = NSPopover()
        popover.behavior = .applicationDefined // we manage dismissal ourselves
        popover.appearance = appearance
        let hosting = NSHostingController(rootView: CalendarView().environmentObject(settings))
        hosting.sizingOptions = [.preferredContentSize] // fit content, avoid top clipping
        popover.contentViewController = hosting

        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        // The vibrant material renders as flat gray when the popover's window isn't
        // focused (e.g. on quick re-opens). Making it key keeps the proper look.
        popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
        self.popover = popover

        // Dismiss when the user clicks anywhere outside the popover.
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func closePopover() {
        popover?.performClose(nil)
        popover = nil
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    /// Opens (or brings forward) the standalone settings window.
    func openSettings() {
        closePopover()
        if settingsWindow == nil {
            let hosting = NSHostingController(rootView: SettingsView().environmentObject(settings))
            let window = NSWindow(contentViewController: hosting)
            window.styleMask = [.titled, .closable]
            window.title = settings.t("settings")
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        // Center on the screen the user is on, every time it opens.
        if let window = settingsWindow {
            window.layoutIfNeeded()
            let mouse = NSEvent.mouseLocation
            let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
            if let frame = screen?.visibleFrame {
                let size = window.frame.size
                window.setFrameOrigin(NSPoint(
                    x: frame.midX - size.width / 2,
                    y: frame.midY - size.height / 2
                ))
            }
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Shows the standard macOS about panel with app name, version and author.
    @objc func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Mini Calendar",
            .applicationVersion: Settings.appVersion,
            .version: "",
            .credits: NSAttributedString(
                string: settings.t("author"),
                attributes: [.font: NSFont.systemFont(ofSize: 11)]
            ),
        ])
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
        // Assigning the menu makes the system drop it directly under the status item.
        statusItem.menu = menu
        sender.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func quit() { NSApp.terminate(nil) }

    private func updateTitle() {
        guard let button = statusItem?.button else { return }
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
            // Nothing selected: fall back to a calendar icon.
            button.title = ""
            button.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Calendar")
        } else {
            button.image = nil
            button.title = parts.joined(separator: settings.isChinese ? " " : ", ")
        }
    }

    /// nil means "follow the system", which is what an unset appearance does.
    private var appearance: NSAppearance? {
        switch settings.appearance {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }

    private func applyAppearance() {
        NSApp.appearance = appearance
        // A popover anchored to a status item inherits the menu bar's appearance
        // rather than the app's, so it has to be told separately.
        popover?.appearance = appearance
    }
}
