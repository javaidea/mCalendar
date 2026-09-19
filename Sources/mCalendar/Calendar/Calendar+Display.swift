import Foundation

extension Calendar {
    /// The Gregorian calendar the grid is drawn with, localised for month and
    /// weekday names.
    ///
    /// Weeks follow ISO 8601: Monday first, and week 1 is the one holding
    /// 4 January. Both are pinned after the locale, which would otherwise choose
    /// `minimumDaysInFirstWeek` itself -- that shifted the whole week-number
    /// column by one when the interface language changed.
    static func display(locale: Locale) -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.locale = locale
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 4
        return c
    }

    /// Midnight on the 1st of the month holding `date`.
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
    }
}
