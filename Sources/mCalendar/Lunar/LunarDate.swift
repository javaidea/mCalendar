import Foundation

/// Chinese lunar dates, from Foundation's built-in Chinese calendar.
enum LunarDate {
    private static let months = ["正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "冬月", "腊月"]
    private static let days = [
        "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
    ]

    private static let lunar = Calendar(identifier: .chinese)

    /// The cell label: the day ("初八"), or the month name on the 1st ("八月").
    /// With `includeMonth`, always both ("闰六月初八").
    static func string(from date: Date, includeMonth: Bool = false) -> String {
        // All components, since `.isLeapMonth` alone needs macOS 14.
        let c = lunar.dateComponents(in: .current, from: date)
        guard let month = c.month, months.indices.contains(month - 1),
              let day = c.day, days.indices.contains(day - 1) else { return "" }
        let monthName = (c.isLeapMonth == true ? "闰" : "") + months[month - 1]
        return includeMonth ? monthName + days[day - 1] : (day == 1 ? monthName : days[day - 1])
    }
}
