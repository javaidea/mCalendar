import SwiftUI

/// A country whose public holidays can be marked on the grid, each with its
/// own dot colour.
struct HolidayCountry: Identifiable {
    let code: String
    let color: Color

    var id: String { code }

    static let all: [HolidayCountry] = [
        .init(code: "CN", color: .red),
        .init(code: "FI", color: .blue),
        .init(code: "EE", color: .teal),
        .init(code: "US", color: .green),
        .init(code: "KZ", color: .orange)
    ]
}

/// One holiday's name, as the country itself writes it plus its English name.
struct HolidayName: Hashable {
    let local: String
    let english: String

    /// The name to show under `local` in the given interface language, or nil
    /// when it would only repeat it (US holidays in English, Chinese in Chinese).
    func translation(chinese: Bool) -> String? {
        let t = chinese ? HolidayName.chinese[english] ?? english : english
        return t == local ? nil : t
    }

    /// Chinese names for every holiday the supported countries observe, keyed
    /// by the English name date.nager.at uses.
    private static let chinese: [String: String] = [
        "New Year's Day": "元旦", "Epiphany": "主显节", "Good Friday": "耶稣受难日",
        "Easter Sunday": "复活节", "Easter Monday": "复活节星期一", "Ascension Day": "耶稣升天节",
        "Pentecost": "圣灵降临节", "All Saints' Day": "诸圣节", "Christmas Eve": "平安夜",
        "Christmas Day": "圣诞节", "St. Stephen's Day": "圣诞节次日", "May Day": "五一节",
        "Labour Day": "劳动节", "Midsummer Eve": "仲夏夜", "Midsummer Day": "仲夏节",
        "Independence Day": "独立日", "Spring Day": "春日节", "Victory Day": "胜利日",
        "Day of Restoration of Independence": "恢复独立日",
        "Martin Luther King, Jr. Day": "马丁·路德·金纪念日", "Presidents Day": "总统日",
        "Memorial Day": "阵亡将士纪念日", "Juneteenth National Independence Day": "六月节",
        "Columbus Day": "哥伦布日", "Indigenous Peoples' Day": "原住民日",
        "Veterans Day": "退伍军人节", "Thanksgiving Day": "感恩节",
        "International Women's Day": "国际妇女节", "Nauryz Meyramy": "纳吾肉孜节",
        "Kazakhstan People's Unity Day": "哈萨克斯坦人民团结日",
        "Defender of the Fatherland Day": "祖国保卫者日",
        "Great Patriotic War Against Fascism Victory Day": "卫国战争胜利日",
        "Orthodox Christmas": "东正教圣诞节", "Kurban Ait": "古尔邦节", "Capital City Day": "首都日", "Constitution Day": "宪法日", "Republic Day": "共和国日"
    ]

    /// English names for China's holidays, which arrive in Chinese only.
    static func china(_ name: String) -> HolidayName {
        let english = [
            "元旦": "New Year's Day", "春节": "Spring Festival", "清明节": "Qingming Festival",
            "劳动节": "Labour Day", "端午节": "Dragon Boat Festival", "中秋节": "Mid-Autumn Festival",
            "国庆节": "National Day"
        ][name] ?? name
        return HolidayName(local: name, english: english)
    }
}

/// What the holiday data says about one day.
struct HolidayInfo {
    /// Holiday names per enabled country code.
    var names: [String: [HolidayName]] = [:]
    /// A Chinese make-up workday (调休上班), marked "班".
    var isMakeupWorkday = false
}

/// The session for every holiday download. PRIVACY.md lists exactly what a
/// request carries, so nothing is left to system defaults: no cookies, no
/// cache, and fixed headers instead of the default User-Agent (app build, OS
/// version) and Accept-Language (the user's preferred languages).
private let holidaySession: URLSession = {
    let config = URLSessionConfiguration.ephemeral
    config.httpCookieStorage = nil
    config.httpShouldSetCookies = false
    config.urlCache = nil
    config.httpAdditionalHeaders = ["User-Agent": "MiniCalendar", "Accept-Language": "en"]
    config.timeoutIntervalForRequest = 10
    return URLSession(configuration: config)
}()

/// Day key independent of time zones: 20261001 for 1 Oct 2026.
private func dayKey(_ year: Int, _ month: Int, _ day: Int) -> Int { year * 10_000 + month * 100 + day }

/// Loads and holds holiday data for the years on screen. Nothing touches the
/// network unless holidays are switched on in Settings.
@MainActor
final class HolidayStore: ObservableObject {
    static let shared = HolidayStore()

    /// China's official schedule, which also covers make-up workdays. Seeded
    /// with the built-in years so it works offline.
    @Published private var chinaPlans = ChinaSchedule.builtIn
    /// Other countries: code -> day key -> names.
    @Published private var publicHolidays: [String: [Int: [HolidayName]]] = [:]
    private var fetched: Set<String> = []

    func info(for date: Date, cal: Calendar, countries: [String]) -> HolidayInfo {
        let c = cal.dateComponents([.year, .month, .day], from: date)
        guard let y = c.year, let m = c.month, let d = c.day else { return HolidayInfo() }
        let key = dayKey(y, m, d)
        var info = HolidayInfo()
        for code in countries {
            if code == "CN" {
                // A year's schedule can name days just across New Year.
                guard let status = chinaPlans[y]?[key] ?? chinaPlans[y - 1]?[key] ?? chinaPlans[y + 1]?[key]
                else { continue }
                if status.isMakeupWorkday {
                    info.isMakeupWorkday = true
                } else {
                    info.names["CN"] = status.holidays.map(HolidayName.china)
                }
            } else if let names = publicHolidays[code]?[key] {
                info.names[code] = names
            }
        }
        return info
    }

    func load(years: [Int], countries: [String]) async {
        let currentYear = Calendar(identifier: .gregorian).component(.year, from: Date())
        for year in years {
            for code in countries {
                guard !Task.isCancelled else { return }
                let key = "\(code)-\(year)"
                guard !fetched.contains(key) else { continue }
                if code == "CN" {
                    if let plan = await ChinaSchedule.fetch(year: year, currentYear: currentYear) {
                        chinaPlans[year] = plan
                    }
                } else if let days = await PublicHolidays.fetch(year: year, countryCode: code) {
                    publicHolidays[code, default: [:]].merge(days) { _, new in new }
                } else {
                    continue // failed: try again next time the popover opens
                }
                fetched.insert(key)
            }
        }
    }
}

/// Public holidays from date.nager.at.
private enum PublicHolidays {
    private struct Item: Decodable {
        let date: String
        let localName: String
        let name: String
        /// False for regional holidays, such as a single US state's.
        let global: Bool
    }

    static func fetch(year: Int, countryCode: String) async -> [Int: [HolidayName]]? {
        guard let url = URL(string: "https://date.nager.at/api/v3/PublicHolidays/\(year)/\(countryCode)") else {
            return nil
        }
        guard let (data, response) = try? await holidaySession.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let items = try? JSONDecoder().decode([Item].self, from: data) else { return nil }
        var result: [Int: [HolidayName]] = [:]
        func add(_ key: Int, _ name: HolidayName) {
            if !result[key, default: []].contains(where: { $0.english == name.english }) {
                result[key, default: []].append(name)
            }
        }
        for item in items where item.global {
            let parts = item.date.split(separator: "-").compactMap { Int($0) }
            guard parts.count == 3 else { continue }
            var local = item.localName.isEmpty ? item.name : item.localName
            if let fixed = truncatedNames[local] { local = fixed }
            add(dayKey(parts[0], parts[1], parts[2]), HolidayName(local: local, english: item.name))
        }
        if countryCode == "KZ" {
            for (key, name) in kazakhstanExtras(year) { add(key, name) }
        }
        return result
    }

    /// Local names date.nager.at cuts short.
    private static let truncatedNames = [
        "Қазақстан халқының": "Қазақстан халқының бірлігі мерекесі"
    ]

    /// Kazakhstan's public holidays date.nager.at leaves out.
    private static func kazakhstanExtras(_ year: Int) -> [(Int, HolidayName)] {
        var extras = [(dayKey(year, 1, 7), HolidayName(local: "Православиелік Рождество", english: "Orthodox Christmas"))]
        // Kurban Ait falls on 10 Dhu al-Hijjah. Kazakhstan's Muslim board
        // fixes the date each year; the Umm al-Qura calendar matched it for
        // 2023-2025.
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(identifier: "Asia/Almaty") ?? .current
        var hijri = Calendar(identifier: .islamicUmmAlQura)
        hijri.timeZone = gregorian.timeZone
        if let jan1 = gregorian.date(from: DateComponents(year: year, month: 1, day: 1)) {
            let hijriYear = hijri.component(.year, from: jan1)
            for y in [hijriYear, hijriYear + 1] {
                guard let date = hijri.date(from: DateComponents(year: y, month: 12, day: 10)) else { continue }
                let c = gregorian.dateComponents([.year, .month, .day], from: date)
                if c.year == year, let month = c.month, let day = c.day {
                    extras.append((dayKey(year, month, day), HolidayName(local: "Құрбан айт", english: "Kurban Ait")))
                }
            }
        }
        return extras
    }
}

/// China's holiday and make-up workday schedule (放假调休安排), announced by the
/// State Council each year. Years not announced yet get no guesses.
enum ChinaSchedule {
    struct DayStatus {
        let holidays: [String]
        let isMakeupWorkday: Bool
    }

    /// Day key -> status, for one year.
    typealias YearPlan = [Int: DayStatus]

    private static func plan(_ year: Int, holidays: [([String], Int, Int)], makeupWorkdays: [Int]) -> YearPlan {
        var days: YearPlan = [:]
        for (names, first, last) in holidays {
            for monthDay in first...last where (1...31).contains(monthDay % 100) {
                days[year * 10_000 + monthDay] = DayStatus(holidays: names, isMakeupWorkday: false)
            }
        }
        for monthDay in makeupWorkdays {
            days[year * 10_000 + monthDay] = DayStatus(holidays: [], isMakeupWorkday: true)
        }
        return days
    }

    /// Offline fallback; ranges are month*100+day.
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

    // Published per year by https://github.com/NateScarlet/holiday-cn, which
    // scrapes the State Council notices.
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
    /// then keeps the built-in one, if any).
    static func fetch(year: Int, currentYear: Int) async -> YearPlan? {
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("me.mynaturefriends.mcalendar/ChinaHolidays/\(year).json")
        let cached = cacheURL.flatMap { try? Data(contentsOf: $0) }.flatMap { decode($0, year: year) }
        let cacheDate = cacheURL.flatMap {
            try? FileManager.default.attributesOfItem(atPath: $0.path)[.modificationDate] as? Date
        }
        if let cached, !cached.isEmpty, year < currentYear { return cached }
        if cached != nil, let cacheDate, Date().timeIntervalSince(cacheDate) < refreshInterval {
            return nonEmpty(cached)
        }

        for source in sources {
            guard !Task.isCancelled, let url = URL(string: String(format: source, year)) else { break }
            guard let (data, response) = try? await holidaySession.data(from: url),
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  let plan = decode(data, year: year) else { continue }
            if let cacheURL {
                try? FileManager.default.createDirectory(
                    at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true
                )
                try? data.write(to: cacheURL, options: .atomic)
            }
            return nonEmpty(plan)
        }
        return nonEmpty(cached)
    }

    private static func nonEmpty(_ plan: YearPlan?) -> YearPlan? {
        guard let plan, !plan.isEmpty else { return nil }
        return plan
    }

    private static func decode(_ data: Data, year: Int) -> YearPlan? {
        guard let payload = try? JSONDecoder().decode(Payload.self, from: data),
              payload.year == year else { return nil }
        var days: YearPlan = [:]
        for day in payload.days {
            let parts = day.date.split(separator: "-").compactMap { Int($0) }
            // Entries may spill into the neighbouring year (e.g. a 元旦 break
            // starting 31 Dec), so keep whatever date they name.
            guard parts.count == 3 else { return nil }
            days[dayKey(parts[0], parts[1], parts[2])] = day.isOffDay
                ? DayStatus(holidays: day.name.components(separatedBy: "、"), isMakeupWorkday: false)
                : DayStatus(holidays: [], isMakeupWorkday: true)
        }
        return days
    }
}
