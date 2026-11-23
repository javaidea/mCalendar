import SwiftUI

/// A country's ISO 3166-1 alpha-2 code, as used by date.nager.at and stored in
/// settings. Any code the holiday sources know can be chosen; the few the app
/// treats specially have names here.
struct CountryCode: RawRepresentable, Hashable, Comparable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue.uppercased()
    }

    /// Valid only for two ASCII letters, so a corrupt setting can't end up in a URL.
    init?(validating string: String) {
        guard string.count == 2, string.allSatisfy({ $0.isASCII && $0.isLetter }) else { return nil }
        self.init(rawValue: string)
    }

    /// Served by `ChinaHolidaySchedule`, which also knows make-up workdays.
    static let china = CountryCode(rawValue: "CN")
    /// Nager's data is patched by `KazakhstanHolidays`.
    static let kazakhstan = CountryCode(rawValue: "KZ")

    static func < (a: CountryCode, b: CountryCode) -> Bool { a.rawValue < b.rawValue }

    /// The country's name in the interface language, e.g. "芬兰" / "Finland".
    func name(in locale: Locale) -> String {
        locale.localizedString(forRegionCode: rawValue) ?? rawValue
    }
}

/// A selected country whose public holidays are marked on the grid, with the
/// dot colour of its place in the selection.
struct HolidayCountry: Identifiable {
    let code: CountryCode
    let color: Color

    var id: CountryCode { code }

    /// How many countries can be selected at once: a day cell has room for
    /// about this many dots, and each gets a colour of its own.
    static let maxSelected = 5

    /// One colour per selection slot, in the order countries were added.
    private static let palette: [Color] = [.red, .blue, .teal, .green, .orange]

    /// The selected countries with their colours, in selection order -- the
    /// order they are listed in Settings and their dots drawn.
    static func selected(_ codes: [CountryCode]) -> [HolidayCountry] {
        zip(codes, palette).map { HolidayCountry(code: $0, color: $1) }
    }

    func name(in locale: Locale) -> String { code.name(in: locale) }
}
