import SwiftUI

/// A country whose public holidays can be marked on the grid, each with its
/// own dot colour.
struct HolidayCountry: Identifiable {
    /// ISO 3166-1 alpha-2 code, as used by date.nager.at.
    let code: String
    let color: Color

    var id: String { code }

    /// The countries offered in Settings, in the order they are listed and
    /// their dots drawn. China's data comes from its own source
    /// (`ChinaHolidaySchedule`); the rest from `NagerHolidayService`.
    static let all: [HolidayCountry] = [
        .init(code: "CN", color: .red),
        .init(code: "FI", color: .blue),
        .init(code: "EE", color: .teal),
        .init(code: "US", color: .green),
        .init(code: "KZ", color: .orange)
    ]

    /// The country's name in the interface language, e.g. "芬兰" / "Finland".
    func name(in locale: Locale) -> String {
        locale.localizedString(forRegionCode: code) ?? code
    }
}
