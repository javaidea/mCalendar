import Foundation

/// One holiday's name, as the country itself writes it plus its English name.
///
/// The details popover shows `local` with a translation underneath: the
/// English name in the English interface, a Chinese one in the Chinese
/// interface.
struct HolidayName: Hashable {
    let local: String
    let english: String

    /// The name to show under `local` in the given interface language, or nil
    /// when it would only repeat it (US holidays in English, Chinese in Chinese).
    /// A holiday missing from the Chinese table falls back to English.
    func translation(chinese: Bool) -> String? {
        let t = chinese ? HolidayName.chinese[english] ?? english : english
        return t == local ? nil : t
    }

    /// A name from China's schedule, which arrives in Chinese only.
    static func china(_ name: String) -> HolidayName {
        HolidayName(local: name, english: chinaInEnglish[name] ?? name)
    }

    // MARK: - Translation tables

    /// `Resources/HolidayNames.json`: Chinese names for every national holiday
    /// of the supported countries, keyed by the English name date.nager.at
    /// uses, and English names for the holidays in China's schedule.
    private struct Tables: Decodable {
        let chineseByEnglishName: [String: String]
        let englishByChineseName: [String: String]
    }

    private static let tables = Bundle.resources.decodeJSON(Tables.self, named: "HolidayNames")
        ?? Tables(chineseByEnglishName: [:], englishByChineseName: [:])

    private static var chinese: [String: String] { tables.chineseByEnglishName }
    private static var chinaInEnglish: [String: String] { tables.englishByChineseName }
}
