import Foundation

/// China's holiday and make-up workday schedule (放假调休安排), announced by the
/// State Council each year. Years not announced yet get no guesses.
///
/// Downloaded from the holiday-cn project and cached on disk; two years are
/// also built in so they show offline.
enum ChinaHolidaySchedule {
    struct DayStatus {
        let holidays: [String]
        let isMakeupWorkday: Bool
    }

    /// `dayKey` -> status, for the days of one year's schedule. Days not in it
    /// are ordinary.
    typealias YearPlan = [Int: DayStatus]

    // MARK: - Built-in years

    /// Offline fallback. Ranges and dates are written month * 100 + day.
    static let builtIn: [Int: YearPlan] = [
        2025: plan(
            2025,
            holidays: [
                (["元旦"], 101, 101), (["春节"], 128, 204), (["清明节"], 404, 406),
                (["劳动节"], 501, 505), (["端午节"], 531, 602), (["国庆节", "中秋节"], 1001, 1008)
            ],
            makeupWorkdays: [126, 208, 427, 928, 1011]
        ),
        2026: plan(
            2026,
            holidays: [
                (["元旦"], 101, 103), (["春节"], 215, 223), (["清明节"], 404, 406),
                (["劳动节"], 501, 505), (["端午节"], 619, 621), (["中秋节"], 925, 927),
                (["国庆节"], 1001, 1007)
            ],
            makeupWorkdays: [104, 214, 228, 509, 920, 1010]
        )
    ]

    private static func plan(_ year: Int, holidays: [([String], Int, Int)], makeupWorkdays: [Int]) -> YearPlan {
        var days: YearPlan = [:]
        for (names, first, last) in holidays {
            // A range such as 128...204 crosses a month end; skip the non-dates.
            for monthDay in first...last where (1...31).contains(monthDay % 100) {
                days[year * 10_000 + monthDay] = DayStatus(holidays: names, isMakeupWorkday: false)
            }
        }
        for monthDay in makeupWorkdays {
            days[year * 10_000 + monthDay] = DayStatus(holidays: [], isMakeupWorkday: true)
        }
        return days
    }

    // MARK: - Download

    /// Published per year by https://github.com/NateScarlet/holiday-cn, which
    /// scrapes the State Council notices. The CDN mirror is tried second.
    private static let sources = [
        "https://raw.githubusercontent.com/NateScarlet/holiday-cn/master/%d.json",
        "https://cdn.jsdelivr.net/gh/NateScarlet/holiday-cn@master/%d.json"
    ]

    private struct Payload: Decodable {
        struct Day: Decodable { let name: String; let date: String; let isOffDay: Bool }
        let year: Int
        let days: [Day]
    }

    /// A schedule is occasionally revised within its year, so the current and
    /// later years are re-downloaded at most once a day; past years never change.
    private static let refreshInterval: TimeInterval = 24 * 3600

    /// The year's schedule, or nil when unpublished or unreachable (the caller
    /// then keeps the built-in one, if any). `current` is false when the
    /// download failed and this is an old copy, so the caller retries soon.
    static func fetch(year: Int, currentYear: Int) async -> (plan: YearPlan?, current: Bool) {
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("me.mynaturefriends.mcalendar/ChinaHolidays/\(year).json")
        let cached = cacheURL.flatMap { try? Data(contentsOf: $0) }.flatMap { decode($0, year: year) }
        let cacheDate = cacheURL.flatMap {
            try? FileManager.default.attributesOfItem(atPath: $0.path)[.modificationDate] as? Date
        }
        if let cached, !cached.isEmpty, year < currentYear { return (cached, true) }
        if cached != nil, let cacheDate, Date().timeIntervalSince(cacheDate) < refreshInterval {
            return (nonEmpty(cached), true)
        }

        for source in sources {
            guard !Task.isCancelled, let url = URL(string: String(format: source, year)) else { break }
            guard let data = await holidaySession.fetchData(from: url),
                  let plan = decode(data, year: year) else { continue }
            if let cacheURL {
                try? FileManager.default.createDirectory(
                    at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true
                )
                try? data.write(to: cacheURL, options: .atomic)
            }
            return (nonEmpty(plan), true)
        }
        return (nonEmpty(cached), false)
    }

    /// holiday-cn publishes an empty list for a year not yet announced.
    private static func nonEmpty(_ plan: YearPlan?) -> YearPlan? {
        guard let plan, !plan.isEmpty else { return nil }
        return plan
    }

    private static func decode(_ data: Data, year: Int) -> YearPlan? {
        guard let payload = try? JSONDecoder().decode(Payload.self, from: data),
              payload.year == year else { return nil }
        var days: YearPlan = [:]
        for day in payload.days {
            // Entries may spill into the neighbouring year (e.g. a 元旦 break
            // starting 31 Dec), so keep whatever date they name.
            guard let key = dayKey(isoDate: day.date) else { return nil }
            days[key] = day.isOffDay
                ? DayStatus(holidays: day.name.components(separatedBy: "、"), isMakeupWorkday: false)
                : DayStatus(holidays: [], isMakeupWorkday: true)
        }
        return days
    }
}
