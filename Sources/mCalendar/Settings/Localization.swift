/// The interface strings, in the two languages the app ships.
///
/// Holiday names and lunar dates are data, not interface, and are handled in
/// `HolidayName` and `LunarDate`.
enum Localization {
    /// The string for `key` in `language` ("en" or "zh"), falling back to
    /// English, then to the key itself.
    static func string(_ key: String, language: String) -> String {
        tables[language]?[key] ?? tables["en"]?[key] ?? key
    }

    private static let tables: [String: [String: String]] = [
        "en": [
            // Settings window
            "settings": "Settings", "months": "Months",
            "showDate": "Date in menu bar", "showWeekday": "Weekday in menu bar",
            "showWeekNums": "Week numbers",
            "showLunar": "Lunar dates & solar terms", "showHolidays": "Public holidays",
            "holidayNote": "“班” marks a Chinese make-up workday. Holiday data is downloaded from date.nager.at and holiday-cn (GitHub) only while this is on.",
            "launchAtLogin": "Launch at login",
            "language": "Language", "appearance": "Appearance",
            "system": "System", "light": "Light", "dark": "Dark",
            // Menus and About
            "about": "About Mini Calendar", "quit": "Quit", "author": "Author: Zhou Yang",
            // Day details
            "lunarDate": "Lunar date", "solarTerm": "Solar term",
            "chinaSchedule": "China holiday schedule", "makeupWorkday": "Make-up workday",
            "week": "Week (ISO)"
        ],
        "zh": [
            // Settings window
            "settings": "设置", "months": "显示月数",
            "showDate": "菜单栏显示日期", "showWeekday": "菜单栏显示星期",
            "showWeekNums": "显示周数列",
            "showLunar": "显示农历和节气", "showHolidays": "显示节假日",
            "holidayNote": "“班”表示中国调休上班日。节假日数据仅在开启时从 date.nager.at 和 holiday-cn (GitHub) 下载。",
            "launchAtLogin": "开机自动启动",
            "language": "语言", "appearance": "外观",
            "system": "跟随系统", "light": "浅色", "dark": "深色",
            // Menus and About
            "about": "关于 Mini Calendar", "quit": "退出", "author": "作者：Zhou Yang",
            // Day details
            "lunarDate": "农历", "solarTerm": "节气",
            "chinaSchedule": "中国放假安排", "makeupWorkday": "调休上班",
            "week": "周数 (ISO)"
        ]
    ]
}
