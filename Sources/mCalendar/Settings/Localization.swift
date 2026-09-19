import Foundation

/// The interface strings, from `Resources/Localizable.xcstrings`.
///
/// The app lets you pick its language regardless of the system's, so strings
/// are looked up in the chosen language's `.lproj` directly rather than
/// through `String(localized:)`, which follows the system.
///
/// Holiday names and lunar dates are data, not interface, and are handled in
/// `HolidayName` and `LunarDate`.
enum Localization {
    /// The string for `key` in `language` ("en" or "zh"), falling back to
    /// English, then to the key itself.
    static func string(_ key: StringKey, language: String) -> String {
        let english = bundle(for: "en")?.localizedString(forKey: key.rawValue, value: key.rawValue, table: nil)
            ?? key.rawValue
        guard language != "en", let localized = bundle(for: language) else { return english }
        return localized.localizedString(forKey: key.rawValue, value: english, table: nil)
    }

    /// The app's language codes mapped to their `.lproj` names.
    private static let lprojNames = ["en": "en", "zh": "zh-Hans"]

    private static var bundles: [String: Bundle] = [:]

    private static func bundle(for language: String) -> Bundle? {
        if let cached = bundles[language] { return cached }
        // SwiftPM lowercases the directory name ("zh-hans.lproj"); Xcode keeps it.
        guard let name = lprojNames[language],
              let path = Bundle.resources.path(forResource: name, ofType: "lproj")
                ?? Bundle.resources.path(forResource: name.lowercased(), ofType: "lproj"),
              let bundle = Bundle(path: path) else { return nil }
        bundles[language] = bundle
        return bundle
    }
}

/// Every key in `Resources/Localizable.xcstrings`. Code refers to strings
/// through these, so a mistyped key fails to compile instead of showing up
/// on screen as the key itself.
enum StringKey: String, CaseIterable {
    // Settings window
    case settings, months, showDate, showWeekday, showWeekNums, showLunar, showHolidays
    case holidayNote, launchAtLogin, language, appearance, system, light, dark
    // Menus and About
    case about, quit, author
    // Day details
    case lunarDate, solarTerm, chinaSchedule, makeupWorkday
}
