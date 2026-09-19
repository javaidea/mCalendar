import SwiftUI

/// A country whose public holidays can be offered. The raw value is the
/// ISO 3166-1 alpha-2 code, as used by date.nager.at and stored in settings.
enum CountryCode: String {
    case china = "CN"
    case finland = "FI"
    case estonia = "EE"
    case unitedStates = "US"
    case kazakhstan = "KZ"
}

/// A country whose public holidays can be marked on the grid, each with its
/// own dot colour.
struct HolidayCountry: Identifiable {
    let code: CountryCode
    let color: Color

    var id: CountryCode { code }

    /// The countries offered in Settings, in the order they are listed and
    /// their dots drawn. China's data comes from its own source
    /// (`ChinaHolidaySchedule`); the rest from `NagerHolidayService`.
    static let all: [HolidayCountry] = [
        .init(code: .china, color: .red),
        .init(code: .finland, color: .blue),
        .init(code: .estonia, color: .teal),
        .init(code: .unitedStates, color: .green),
        .init(code: .kazakhstan, color: .orange)
    ]

    /// The country's name in the interface language, e.g. "芬兰" / "Finland".
    func name(in locale: Locale) -> String {
        locale.localizedString(forRegionCode: code.rawValue) ?? code.rawValue
    }
}
