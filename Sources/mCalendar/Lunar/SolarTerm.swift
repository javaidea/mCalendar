import Foundation

/// The 24 solar terms: the sun's apparent longitude crossing each multiple of
/// 15°, dated in China Standard Time.
///
/// Each term's date is found numerically rather than looked up, so any year
/// works. Results are cached per year.
enum SolarTerm {
    /// In calendar order, two per month from January: the term's name, the
    /// solar longitude that defines it, and the day of the month it usually
    /// falls on, which seeds the search.
    private static let terms: [(name: String, longitude: Double, estimatedDay: Int)] = [
        ("小寒", 285, 6), ("大寒", 300, 20), ("立春", 315, 4), ("雨水", 330, 19),
        ("惊蛰", 345, 6), ("春分", 0, 21), ("清明", 15, 5), ("谷雨", 30, 20),
        ("立夏", 45, 6), ("小满", 60, 21), ("芒种", 75, 6), ("夏至", 90, 21),
        ("小暑", 105, 7), ("大暑", 120, 23), ("立秋", 135, 8), ("处暑", 150, 23),
        ("白露", 165, 8), ("秋分", 180, 23), ("寒露", 195, 8), ("霜降", 210, 23),
        ("立冬", 225, 7), ("小雪", 240, 22), ("大雪", 255, 7), ("冬至", 270, 22)
    ]

    /// Year -> (month * 100 + day) -> term name.
    private static var cache: [Int: [Int: String]] = [:]

    /// The solar term falling on `date`, or nil on the other ~340 days a year.
    static func name(for date: Date, cal: Calendar) -> String? {
        let c = cal.dateComponents([.year, .month, .day], from: date)
        guard let year = c.year, let month = c.month, let day = c.day else { return nil }
        if cache[year] == nil { cache[year] = compute(year) }
        return cache[year]?[month * 100 + day]
    }

    /// Dates all 24 terms of `year` by bisecting for the moment the sun
    /// reaches each longitude, then reading that moment's date in China.
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
