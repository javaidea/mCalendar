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

/// The 24 solar terms: the sun's apparent longitude crossing each multiple of
/// 15°, dated in China Standard Time.
enum SolarTerm {
    private static let terms: [(name: String, longitude: Double, estimatedDay: Int)] = [
        ("小寒", 285, 6), ("大寒", 300, 20), ("立春", 315, 4), ("雨水", 330, 19),
        ("惊蛰", 345, 6), ("春分", 0, 21), ("清明", 15, 5), ("谷雨", 30, 20),
        ("立夏", 45, 6), ("小满", 60, 21), ("芒种", 75, 6), ("夏至", 90, 21),
        ("小暑", 105, 7), ("大暑", 120, 23), ("立秋", 135, 8), ("处暑", 150, 23),
        ("白露", 165, 8), ("秋分", 180, 23), ("寒露", 195, 8), ("霜降", 210, 23),
        ("立冬", 225, 7), ("小雪", 240, 22), ("大雪", 255, 7), ("冬至", 270, 22)
    ]

    private static var cache: [Int: [Int: String]] = [:]

    static func name(for date: Date, cal: Calendar) -> String? {
        let c = cal.dateComponents([.year, .month, .day], from: date)
        guard let year = c.year, let month = c.month, let day = c.day else { return nil }
        if cache[year] == nil { cache[year] = compute(year) }
        return cache[year]?[month * 100 + day]
    }

    private static func compute(_ year: Int) -> [Int: String] {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        var china = Calendar(identifier: .gregorian)
        china.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!

        var result: [Int: String] = [:]
        for (i, term) in terms.enumerated() {
            guard let estimate = utc.date(from: DateComponents(
                year: year, month: i / 2 + 1, day: term.estimatedDay, hour: 12
            )) else { continue }
            // Bisect within ±5 days of the usual date for the crossing.
            var lower = estimate.addingTimeInterval(-5 * 86_400)
            var upper = estimate.addingTimeInterval(5 * 86_400)
            for _ in 0..<40 {
                let middle = lower.addingTimeInterval(upper.timeIntervalSince(lower) / 2)
                if longitudeDifference(at: middle, target: term.longitude) < 0 {
                    lower = middle
                } else {
                    upper = middle
                }
            }
            let d = china.dateComponents([.month, .day], from: upper)
            if let month = d.month, let day = d.day { result[month * 100 + day] = term.name }
        }
        return result
    }

    /// Signed distance in degrees from `target` to the sun's apparent longitude
    /// (USNO low-precision formula).
    private static func longitudeDifference(at date: Date, target: Double) -> Double {
        let daysSinceJ2000 = date.timeIntervalSince1970 / 86_400 + 2_440_587.5 - 2_451_545.0
        let anomaly = (357.529 + 0.98560028 * daysSinceJ2000) * .pi / 180
        let meanLongitude = 280.459 + 0.98564736 * daysSinceJ2000
        let longitude = meanLongitude + 1.915 * sin(anomaly) + 0.020 * sin(2 * anomaly)
        return (longitude - target + 540).truncatingRemainder(dividingBy: 360) - 180
    }
}
