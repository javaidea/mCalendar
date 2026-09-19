import AppKit

/// The standard macOS About panel, with the app's name, version and author.
@MainActor
enum AboutPanel {
    static func show(settings: Settings) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Mini Calendar",
            .applicationVersion: Settings.appVersion,
            .version: "",
            .credits: NSAttributedString(
                string: settings.t(.author),
                attributes: [.font: NSFont.systemFont(ofSize: 11)]
            ),
        ])
    }
}
