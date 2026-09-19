import Foundation

/// Public holidays from date.nager.at, for every supported country but China.
enum NagerHolidayService {
    private struct Item: Decodable {
        let date: String
        let localName: String
        let name: String
        /// False for regional holidays, such as a single US state's.
        let global: Bool
    }

    /// One country's national holidays for `year`, keyed by `dayKey`, or nil
    /// when the download fails.
    static func fetch(year: Int, countryCode: String) async -> [Int: [HolidayName]]? {
        guard let url = URL(string: "https://date.nager.at/api/v3/PublicHolidays/\(year)/\(countryCode)"),
              let data = await holidaySession.fetchData(from: url),
              let items = try? JSONDecoder().decode([Item].self, from: data) else { return nil }

        var result: [Int: [HolidayName]] = [:]
        // Nager and the Kazakhstan additions could name the same holiday; keep one.
        func add(_ key: Int, _ name: HolidayName) {
            if !result[key, default: []].contains(where: { $0.english == name.english }) {
                result[key, default: []].append(name)
            }
        }

        for item in items where item.global {
            guard let key = dayKey(isoDate: item.date) else { continue }
            var local = item.localName.isEmpty ? item.name : item.localName
            if countryCode == "KZ" { local = KazakhstanHolidays.corrected(local) }
            add(key, HolidayName(local: local, english: item.name))
        }
        if countryCode == "KZ" {
            for (key, name) in KazakhstanHolidays.missing(in: year) { add(key, name) }
        }
        return result
    }
}
