import Foundation

/// Loads and holds holiday data for the years on screen, and answers what a
/// given day is. Nothing touches the network unless holidays are switched on
/// in Settings.
@MainActor
final class HolidayStore: ObservableObject {
    static let shared = HolidayStore()

    /// China's official schedule, which also covers make-up workdays. Seeded
    /// with the built-in years so it works offline.
    @Published private var chinaPlans = ChinaHolidaySchedule.builtIn
    /// Other countries: code -> `dayKey` -> names.
    @Published private var publicHolidays: [String: [Int: [HolidayName]]] = [:]

    /// When each country-year was last loaded. The app can stay running for
    /// weeks, so this expires rather than lasting for the whole run: schedules
    /// get revised, and next year's is published partway through this one.
    private var loaded: [String: Date] = [:]
    private static let refreshInterval: TimeInterval = 24 * 3600

    // MARK: - Lookup

    /// What the loaded data says about `date` for the given countries.
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

    // MARK: - Loading

    /// Downloads whatever is missing or more than a day old for these years and
    /// countries. Called each time the popover opens; a failed download is
    /// retried on the next open.
    func load(years: [Int], countries: [String]) async {
        let currentYear = Calendar(identifier: .gregorian).component(.year, from: Date())
        for year in years {
            for code in countries {
                guard !Task.isCancelled else { return }
                let key = "\(code)-\(year)"
                if let last = loaded[key], Date().timeIntervalSince(last) < Self.refreshInterval { continue }
                if code == "CN" {
                    let result = await ChinaHolidaySchedule.fetch(year: year, currentYear: currentYear)
                    if let plan = result.plan { chinaPlans[year] = plan }
                    guard result.current else { continue }
                } else if let days = await NagerHolidayService.fetch(year: year, countryCode: code) {
                    publicHolidays[code, default: [:]].merge(days) { _, new in new }
                } else {
                    continue
                }
                loaded[key] = Date()
            }
        }
    }
}
