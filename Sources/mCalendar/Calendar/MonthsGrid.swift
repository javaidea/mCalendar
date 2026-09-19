import SwiftUI

/// A continuous grid spanning `monthCount` months starting at `firstMonthStart`,
/// with a single weekday header and a week-number gutter.
///
/// Months run on without a break; each one sits on an alternating background
/// band so the boundaries stay visible.
struct MonthsGrid: View {
    let firstMonthStart: Date
    let monthCount: Int
    let showWeeks: Bool
    let showLunar: Bool
    /// Countries whose holidays are marked; empty when holidays are off.
    let holidayCountries: [String]
    let metrics: GridMetrics
    let cal: Calendar

    @ObservedObject private var holidays = HolidayStore.shared

    private var gutter: CGFloat { showWeeks ? 24 : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: GridMetrics.rowSpacing) {
            weekdayHeader
            VStack(spacing: GridMetrics.rowSpacing) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    weekRow(week)
                }
            }
            // A panel behind the day grid (week rows only) separates the calendar
            // area from the week-number gutter.
            //
            // It leans towards the content background colour -- white in light
            // mode, near-black in dark -- rather than a wash of `primary`. The
            // popover is translucent, so a wash of primary darkened an already
            // grey light-mode backdrop and left the dimmer day tiers illegible;
            // this pulls the backdrop towards a known lightness instead.
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(nsColor: .textBackgroundColor).opacity(0.6))
                    .padding(.leading, gutter)
                    .padding(.vertical, -3)
            }
            // The month bands are square-edged, so without this the band of the
            // topmost or bottom month would square off the panel's corners. The
            // gutter is left unmasked so the week numbers keep their full width.
            .mask {
                HStack(spacing: 0) {
                    if showWeeks {
                        Color.black.frame(width: gutter)
                    }
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.black)
                }
                .padding(.vertical, -3)
            }
        }
    }

    // MARK: - Rows

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            if showWeeks {
                Color.clear.frame(width: gutter)
            }
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { i, s in
                Text(s)
                    .font(.system(size: 10, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(0.5)
                    // Saturday and Sunday, the last two columns, are dimmer.
                    .foregroundStyle(Color.primary.opacity(i >= 5 ? 0.66 : 0.8))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func weekRow(_ week: [Date]) -> some View {
        HStack(spacing: 0) {
            if showWeeks {
                weekLabel(week)
            }
            ForEach(week, id: \.self) { day in
                DayCell(
                    date: day,
                    monthIndex: monthIndex(of: day),
                    banded: isBanded(day),
                    showLunar: showLunar,
                    showHolidays: !holidayCountries.isEmpty,
                    holiday: holidays.info(for: day, cal: cal, countries: holidayCountries),
                    metrics: metrics,
                    cal: cal
                )
            }
        }
    }

    /// The gutter label: the week number, except in the week a month starts,
    /// which gets the month's name so month boundaries stay readable.
    @ViewBuilder
    private func weekLabel(_ week: [Date]) -> some View {
        if let start = monthStarting(in: week) {
            Text(monthAbbrev(start))
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: gutter)
        } else {
            Text("\(cal.component(.weekOfYear, from: week[0]))")
                .font(.system(size: 9.5))
                .foregroundStyle(Color.primary.opacity(0.78))
                .frame(width: gutter)
        }
    }

    // MARK: - Layout

    /// Full weeks from the one holding the first month's 1st through the end
    /// of the last month.
    private var weeks: [[Date]] {
        let end = cal.startOfDay(for: lastMonthEnd)
        let spanned = (cal.dateComponents([.day], from: gridStart, to: end).day ?? 0) + 1
        let rows = Int(ceil(Double(spanned) / 7.0))
        return (0..<rows).map { r in
            (0..<7).compactMap { c in cal.date(byAdding: .day, value: r * 7 + c, to: gridStart) }
        }
    }

    /// The Monday on or before the first month's 1st.
    private var gridStart: Date {
        let firstWeekday = cal.component(.weekday, from: firstMonthStart)
        let leading = (firstWeekday - cal.firstWeekday + 7) % 7
        return cal.date(byAdding: .day, value: -leading, to: firstMonthStart) ?? firstMonthStart
    }

    private var lastMonthEnd: Date {
        let last = cal.date(byAdding: .month, value: monthCount - 1, to: firstMonthStart) ?? firstMonthStart
        let count = cal.range(of: .day, in: .month, for: last)?.count ?? 30
        return cal.date(byAdding: .day, value: count - 1, to: last) ?? last
    }

    /// Weekday initials starting from the calendar's first weekday (Monday).
    private var weekdaySymbols: [String] {
        let s = cal.veryShortStandaloneWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(s[first...] + s[..<first])
    }

    // MARK: - Months

    /// Signed month distance from the first displayed month: negative for the
    /// padding days before it, >= monthCount for the ones after.
    private func monthOffset(of day: Date) -> Int {
        cal.dateComponents([.month], from: firstMonthStart, to: cal.startOfMonth(for: day)).month ?? 0
    }

    /// 0-based index of the displayed month `day` falls in, or nil if outside.
    private func monthIndex(of day: Date) -> Int? {
        let m = monthOffset(of: day)
        return (0..<monthCount).contains(m) ? m : nil
    }

    /// The band alternates by calendar month, padding days included -- otherwise
    /// the first and last rows lose their background where the range starts or
    /// ends mid-week, leaving a notch in the panel.
    private func isBanded(_ day: Date) -> Bool { monthOffset(of: day) % 2 == 0 }

    /// First day of a displayed month if this week contains one, else nil.
    private func monthStarting(in week: [Date]) -> Date? {
        week.first { cal.component(.day, from: $0) == 1 && monthIndex(of: $0) != nil }
    }

    /// "8月" in Chinese, "Aug" in English.
    private func monthAbbrev(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = cal.locale
        f.calendar = cal
        f.dateFormat = "LLL"
        return f.string(from: date)
    }
}
