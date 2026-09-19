import SwiftUI
import ServiceManagement

/// Every user preference, persisted in UserDefaults and shared app-wide.
///
/// Views observe it as an `EnvironmentObject`. AppKit code, which cannot, is
/// told about changes that affect it through `onChange`.
@MainActor
final class Settings: ObservableObject {
    static let shared = Settings()

    /// Marketing version from the bundle, so About and the footers can't drift
    /// from Info.plist. The fallback only applies to `swift run` builds, which
    /// have no bundle.
    static let appVersion = Bundle.main
        .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"

    /// Called whenever a setting that the menu bar label, the appearance or the
    /// settings window title depends on changes.
    var onChange: (() -> Void)?

    // MARK: - Interface

    /// "system", "en", or "zh-Hans".
    @Published var languageCode: String {
        didSet {
            save(languageCode, .languageCode)
            onChange?()
        }
    }

    @Published var appearance: AppearanceMode {
        didSet {
            save(appearance.rawValue, .appearance)
            onChange?()
        }
    }

    // MARK: - Menu bar label

    /// Whether the label shows the date (e.g. "Jul 25" / "7月25日").
    @Published var showDate: Bool {
        didSet {
            save(showDate, .showDate)
            onChange?()
        }
    }

    /// Whether the label shows the weekday (e.g. "Sat" / "周六").
    @Published var showWeekday: Bool {
        didSet {
            save(showWeekday, .showWeekday)
            onChange?()
        }
    }

    // MARK: - Calendar

    /// How many months the popover shows at once (1...6).
    @Published var monthCount: Int {
        didSet { save(monthCount, .monthCount) }
    }

    /// Whether the week-number gutter is shown on the left.
    @Published var showWeekNumbers: Bool {
        didSet { save(showWeekNumbers, .showWeekNumbers) }
    }

    /// Whether each day shows its Chinese lunar date, or the solar term on the
    /// days one falls.
    @Published var showLunar: Bool {
        didSet { save(showLunar, .showLunar) }
    }

    /// Whether public holidays are marked. Off by default: it is the only thing
    /// in the app that goes to the network.
    @Published var showHolidays: Bool {
        didSet { save(showHolidays, .showHolidays) }
    }

    /// Codes of the countries whose holidays are marked, in `HolidayCountry.all` order.
    @Published var holidayCountries: [CountryCode] {
        didSet {
            save(holidayCountries.map(\.rawValue).joined(separator: ","), .holidayCountries)
        }
    }

    func setHolidayCountry(_ code: CountryCode, enabled: Bool) {
        var selected = Set(holidayCountries)
        if enabled { selected.insert(code) } else { selected.remove(code) }
        holidayCountries = HolidayCountry.all.map(\.code).filter { selected.contains($0) }
    }

    // MARK: - System

    /// Launch at login, backed by SMAppService (the system is the source of truth).
    @Published var launchAtLogin: Bool {
        didSet {
            guard oldValue != launchAtLogin else { return }
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Registration failed (e.g. running outside an app bundle): re-sync.
                DispatchQueue.main.async { [weak self] in
                    self?.launchAtLogin = SMAppService.mainApp.status == .enabled
                }
            }
        }
    }

    // MARK: - Storage

    /// The UserDefaults key of each setting. Launch at login is not stored
    /// here; the system keeps it.
    private enum Key: String {
        case languageCode, appearance, showDate, showWeekday, monthCount
        case showWeekNumbers, showLunar, showHolidays, holidayCountries
    }

    private func save(_ value: Any, _ key: Key) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    // MARK: - Loading

    private init() {
        let defaults = UserDefaults.standard
        languageCode = defaults.string(forKey: Key.languageCode.rawValue) ?? "system"
        appearance = AppearanceMode(rawValue: defaults.string(forKey: Key.appearance.rawValue) ?? "") ?? .system
        let storedMonths = defaults.integer(forKey: Key.monthCount.rawValue)
        monthCount = storedMonths == 0 ? 2 : min(max(storedMonths, 1), 6)
        showDate = defaults.object(forKey: Key.showDate.rawValue) as? Bool ?? true
        showWeekday = defaults.object(forKey: Key.showWeekday.rawValue) as? Bool ?? true
        showWeekNumbers = defaults.object(forKey: Key.showWeekNumbers.rawValue) as? Bool ?? true
        showLunar = defaults.object(forKey: Key.showLunar.rawValue) as? Bool ?? false
        showHolidays = defaults.object(forKey: Key.showHolidays.rawValue) as? Bool ?? false
        // Drops the codes of countries no longer offered.
        let savedCountries = defaults.string(forKey: Key.holidayCountries.rawValue)
            .map { Set($0.split(separator: ",").compactMap { CountryCode(rawValue: String($0)) }) }
            ?? [.china, .finland]
        holidayCountries = HolidayCountry.all.map(\.code).filter { savedCountries.contains($0) }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    // MARK: - Language

    var locale: Locale {
        languageCode == "system" ? .autoupdatingCurrent : Locale(identifier: languageCode)
    }

    /// Resolves "system" or any code to one of the two string tables we ship.
    var effectiveLang: String {
        let code: String
        if languageCode == "system" {
            code = Locale.autoupdatingCurrent.language.languageCode?.identifier ?? "en"
        } else {
            code = languageCode
        }
        return code.hasPrefix("zh") ? "zh" : "en"
    }

    var isChinese: Bool { effectiveLang == "zh" }

    /// The interface string for `key` in the current language.
    func t(_ key: StringKey) -> String {
        Localization.string(key, language: effectiveLang)
    }
}
