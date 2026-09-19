import Foundation

/// Fixes for date.nager.at's Kazakhstan data, which leaves out two public
/// holidays and cuts one name short.
enum KazakhstanHolidays {
    /// The full local name where Nager's is truncated; otherwise `name` as is.
    static func corrected(_ name: String) -> String {
        truncatedNames[name] ?? name
    }

    private static let truncatedNames = [
        "Қазақстан халқының": "Қазақстан халқының бірлігі мерекесі"
    ]

    /// The public holidays Nager omits for `year`: Orthodox Christmas and
    /// Kurban Ait.
    static func missing(in year: Int) -> [(Int, HolidayName)] {
        var holidays = [(dayKey(year, 1, 7), HolidayName(local: "Православиелік Рождество", english: "Orthodox Christmas"))]
        if let kurbanAit = kurbanAit(in: year) {
            holidays.append((kurbanAit, HolidayName(local: "Құрбан айт", english: "Kurban Ait")))
        }
        return holidays
    }

    /// Kurban Ait falls on 10 Dhu al-Hijjah. Kazakhstan's Muslim board fixes the
    /// date each year; the Umm al-Qura calendar matched it for 2023-2025.
    private static func kurbanAit(in year: Int) -> Int? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(identifier: "Asia/Almaty") ?? .current
        var hijri = Calendar(identifier: .islamicUmmAlQura)
        hijri.timeZone = gregorian.timeZone
        guard let jan1 = gregorian.date(from: DateComponents(year: year, month: 1, day: 1)) else { return nil }

        // The Gregorian year spans two Hijri years; the holiday is in one of them.
        let hijriYear = hijri.component(.year, from: jan1)
        for y in [hijriYear, hijriYear + 1] {
            guard let date = hijri.date(from: DateComponents(year: y, month: 12, day: 10)) else { continue }
            let c = gregorian.dateComponents([.year, .month, .day], from: date)
            if c.year == year, let month = c.month, let day = c.day {
                return dayKey(year, month, day)
            }
        }
        return nil
    }
}
