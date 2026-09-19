import AppKit

/// Entry point. The app is a plain `NSApplication` driven by `AppDelegate`
/// rather than a SwiftUI `App`: it lives in the menu bar and needs precise
/// control over its status item, popover and settings window.
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
