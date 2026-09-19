import AppKit

/// Owns the app's three pieces of UI -- the menu bar item, the calendar popover
/// and the settings window -- and keeps them in step with `Settings`.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = Settings.shared
    private(set) var statusItem: StatusItemController!
    private(set) lazy var calendarPopover = CalendarPopoverController(settings: settings) { [weak self] in
        self?.openSettings()
    }
    private(set) lazy var settingsWindow = SettingsWindowController(settings: settings)

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar only: no Dock icon.
        NSApp.setActivationPolicy(.accessory)
        // Use the icon in the bundle rather than the system's cached copy, which
        // can lag behind a new icon when the version number stays the same.
        // Read the .icns file directly: `Bundle.image(forResource:)` looks in an
        // asset catalog first, and with none in the app CoreUI logs an error.
        if let url = Bundle.resources.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: url) {
            NSApp.applicationIconImage = icon
        }
        applyAppearance()

        statusItem = StatusItemController(settings: settings)
        statusItem.onClick = { [weak self] button in
            self?.calendarPopover.toggle(relativeTo: button)
        }

        settings.onChange = { [weak self] in
            self?.statusItem.updateTitle()
            self?.applyAppearance()
            self?.settingsWindow.updateTitle()
        }

        installDebugHooks()
    }

    /// Opens the settings window, closing the popover first.
    func openSettings() {
        calendarPopover.close()
        settingsWindow.show()
    }

    private func applyAppearance() {
        let appearance = settings.appearance.nsAppearance
        NSApp.appearance = appearance
        // A popover anchored to a status item inherits the menu bar's appearance
        // rather than the app's, so it has to be told separately.
        calendarPopover.appearance = appearance
    }
}
