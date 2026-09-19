import SwiftUI
import ServiceManagement

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
}

/// App-wide settings: language + appearance, persisted in UserDefaults.
@MainActor
final class Settings: ObservableObject {
    static let shared = Settings()

    /// Marketing version from the bundle, so About and the settings footer can't
    /// drift from Info.plist. The fallback only applies to `swift run` builds,
    /// which have no bundle.
    static let appVersion = Bundle.main
        .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"

    /// "system", "en", or "zh-Hans".
    @Published var languageCode: String {
        didSet {
            UserDefaults.standard.set(languageCode, forKey: "languageCode")
            onChange?()
        }
    }

    @Published var appearance: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: "appearance")
            onChange?()
        }
    }

    /// How many months the panel shows at once (1...6).
    @Published var monthCount: Int {
        didSet {
            UserDefaults.standard.set(monthCount, forKey: "monthCount")
        }
    }

    /// Whether the menubar label shows the date (e.g. "Jul 25" / "7月25日").
    @Published var showDate: Bool {
        didSet {
            UserDefaults.standard.set(showDate, forKey: "showDate")
            onChange?()
        }
    }

    /// Whether the menubar label shows the weekday (e.g. "Sat" / "周六").
    @Published var showWeekday: Bool {
        didSet {
            UserDefaults.standard.set(showWeekday, forKey: "showWeekday")
            onChange?()
        }
    }

    /// Whether the calendar shows the week-number gutter on the left.
    @Published var showWeekNumbers: Bool {
        didSet { UserDefaults.standard.set(showWeekNumbers, forKey: "showWeekNumbers") }
    }

    /// Whether each day shows its Chinese lunar date, or the solar term on the
    /// days one falls.
    @Published var showLunar: Bool {
        didSet { UserDefaults.standard.set(showLunar, forKey: "showLunar") }
    }

    /// Whether public holidays are marked. Off by default: it is the only thing
    /// in the app that goes to the network.
    @Published var showHolidays: Bool {
        didSet { UserDefaults.standard.set(showHolidays, forKey: "showHolidays") }
    }

    /// Codes of the countries whose holidays are marked, in `HolidayCountry.all` order.
    @Published var holidayCountries: [String] {
        didSet { UserDefaults.standard.set(holidayCountries.joined(separator: ","), forKey: "holidayCountries") }
    }

    func setHolidayCountry(_ code: String, enabled: Bool) {
        var selected = Set(holidayCountries)
        if enabled { selected.insert(code) } else { selected.remove(code) }
        holidayCountries = HolidayCountry.all.map(\.code).filter { selected.contains($0) }
    }

    /// Launch at login, backed by SMAppService (source of truth is the system).
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
                // Registration failed (e.g. running outside an app bundle) — re-sync.
                DispatchQueue.main.async { [weak self] in
                    self?.launchAtLogin = SMAppService.mainApp.status == .enabled
                }
            }
        }
    }


    /// Called (on the main actor) whenever a setting changes, so AppKit bits can refresh.
    var onChange: (() -> Void)?

    private init() {
        languageCode = UserDefaults.standard.string(forKey: "languageCode") ?? "system"
        appearance = AppearanceMode(rawValue: UserDefaults.standard.string(forKey: "appearance") ?? "")
            ?? .system
        let stored = UserDefaults.standard.integer(forKey: "monthCount")
        monthCount = stored == 0 ? 2 : min(max(stored, 1), 6)
        showDate = UserDefaults.standard.object(forKey: "showDate") as? Bool ?? true
        showWeekday = UserDefaults.standard.object(forKey: "showWeekday") as? Bool ?? true
        showWeekNumbers = UserDefaults.standard.object(forKey: "showWeekNumbers") as? Bool ?? true
        showLunar = UserDefaults.standard.object(forKey: "showLunar") as? Bool ?? false
        showHolidays = UserDefaults.standard.object(forKey: "showHolidays") as? Bool ?? false
        // Drops codes of countries no longer offered.
        let savedCountries = Set((UserDefaults.standard.string(forKey: "holidayCountries") ?? "CN,FI")
            .split(separator: ",").map(String.init))
        holidayCountries = HolidayCountry.all.map(\.code).filter { savedCountries.contains($0) }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    var locale: Locale {
        languageCode == "system" ? .autoupdatingCurrent : Locale(identifier: languageCode)
    }

    /// Resolves "system" / any code to one of the two string tables we ship.
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

    /// Localized UI string.
    func t(_ key: String) -> String {
        strings[effectiveLang]?[key] ?? strings["en"]?[key] ?? key
    }

    private let strings: [String: [String: String]] = [
        "en": [
            "today": "Today", "language": "Language", "appearance": "Appearance",
            "system": "System", "light": "Light", "dark": "Dark", "quit": "Quit",
            "months": "Months", "settings": "Settings",
            "showDate": "Date in menu bar", "showWeekday": "Weekday in menu bar",
            "showWeekNums": "Week numbers", "about": "About Mini Calendar",
            "author": "Author: Zhou Yang", "launchAtLogin": "Launch at login",
            "showLunar": "Lunar dates & solar terms", "showHolidays": "Public holidays",
            "holidayNote": "“班” marks a Chinese make-up workday. Holiday data is downloaded from date.nager.at and holiday-cn (GitHub) only while this is on.",
            "lunarDate": "Lunar date", "makeupWorkday": "Make-up workday",
            "solarTerm": "Solar term", "chinaSchedule": "China holiday schedule", "week": "Week (ISO)"
        ],
        "zh": [
            "today": "今天", "language": "语言", "appearance": "外观",
            "system": "跟随系统", "light": "浅色", "dark": "深色", "quit": "退出",
            "months": "显示月数", "settings": "设置",
            "showDate": "菜单栏显示日期", "showWeekday": "菜单栏显示星期",
            "showWeekNums": "显示周数列", "about": "关于 Mini Calendar",
            "author": "作者：Zhou Yang", "launchAtLogin": "开机自动启动",
            "showLunar": "显示农历和节气", "showHolidays": "显示节假日",
            "holidayNote": "“班”表示中国调休上班日。节假日数据仅在开启时从 date.nager.at 和 holiday-cn (GitHub) 下载。",
            "lunarDate": "农历", "makeupWorkday": "调休上班",
            "solarTerm": "节气", "chinaSchedule": "中国放假安排", "week": "周数 (ISO)"
        ]
    ]
}
