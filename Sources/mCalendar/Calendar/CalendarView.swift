import SwiftUI
import AppKit

/// The popover's content: a title with month navigation, the month grid, a
/// grip to resize it, and a footer with the version and settings button.
struct CalendarView: View {
    @EnvironmentObject var settings: Settings
    @ObservedObject private var holidays = HolidayStore.shared
    /// A date in the first month shown; the arrows move it by a month.
    @State private var anchor = Date()

    private var cal: Calendar { .display(locale: settings.locale) }

    var body: some View {
        VStack(spacing: 0) {
            header
            MonthsGrid(
                firstMonthStart: firstMonthStart,
                monthCount: monthCount,
                showWeeks: settings.showWeekNumbers,
                showLunar: settings.showLunar,
                holidayCountries: holidayCountries,
                metrics: metrics,
                cal: cal
            )
            .padding(.top, 12)
            // Re-runs whenever the years on screen or the countries change.
            .task(id: "\(holidayCountries)|\(displayedYears)") {
                guard !holidayCountries.isEmpty else { return }
                await holidays.load(years: displayedYears, countries: holidayCountries)
            }
            MonthResizeHandle(
                monthCount: $settings.monthCount,
                maxMonths: maxMonths,
                monthHeight: metrics.monthHeight
            )
            footer
        }
        // The grid's left edge is the week-number gutter, which already reads as
        // inset, so the left margin stays tighter than the other three.
        .padding(EdgeInsets(top: 9, leading: 6, bottom: 9, trailing: 9))
        .frame(width: metrics.popoverWidth)
    }

    // MARK: - Header and footer

    private var header: some View {
        HStack(spacing: 0) {
            Text(rangeTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
                // Line the title up with the week-number text, which is centred
                // in the gutter rather than flush with the content edge.
                .padding(.leading, 5)
            Spacer()
            HStack(spacing: 12) {
                Button(action: { shift(by: -1) }) { Image(systemName: "chevron.left") }
                Button(action: { anchor = Date() }) { Image(systemName: "circle") }
                Button(action: { shift(by: 1) }) { Image(systemName: "chevron.right") }
            }
            .buttonStyle(.borderless)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.primary.opacity(0.75))
        }
    }

    private var footer: some View {
        HStack {
            Text("v\(Settings.appVersion)")
                .font(.system(size: 10))
                .foregroundStyle(Color.primary.opacity(0.5))
                // Same inset as the title, so both line up with the week numbers.
                .padding(.leading, 5)
            Spacer()
            Button(action: { (NSApp.delegate as? AppDelegate)?.openSettings() }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.primary.opacity(0.7))
            }
            .buttonStyle(.borderless)
        }
    }

    /// "2026年 7–8月" / "Jul – Aug 2026"; a single month "2026年 7月" / "Jul 2026".
    private var rangeTitle: String {
        let first = firstMonthStart
        let last = lastMonthStart
        let ya = cal.component(.year, from: first), yb = cal.component(.year, from: last)
        let ma = cal.component(.month, from: first), mb = cal.component(.month, from: last)
        if settings.isChinese {
            if monthCount == 1 { return "\(ya)年 \(ma)月" }
            return ya == yb ? "\(ya)年 \(ma)–\(mb)月" : "\(ya)年\(ma)月 – \(yb)年\(mb)月"
        }
        let f = DateFormatter(); f.locale = cal.locale; f.dateFormat = "MMM"
        let sa = f.string(from: first), sb = f.string(from: last)
        if monthCount == 1 { return "\(sa) \(ya)" }
        return ya == yb ? "\(sa) – \(sb) \(ya)" : "\(sa) \(ya) – \(sb) \(yb)"
    }

    // MARK: - What is shown

    private var metrics: GridMetrics {
        GridMetrics(lunar: settings.showLunar, holidays: !holidayCountries.isEmpty)
    }

    /// Countries whose holidays are marked; empty when holidays are off.
    private var holidayCountries: [String] { settings.showHolidays ? settings.holidayCountries : [] }

    /// The months actually shown: the setting, capped so bigger cells can't push
    /// the popover off the bottom of the screen.
    private var monthCount: Int { min(settings.monthCount, maxMonths) }

    /// How many months fit on the screen under the mouse pointer.
    private var maxMonths: Int {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        guard let height = screen?.visibleFrame.height else { return 6 }
        // ~110pt of header, weekday row, grip and footer, plus a spare week row.
        let available = height - 110 - (metrics.cellHeight + GridMetrics.rowSpacing)
        return min(6, max(1, Int(available / metrics.monthHeight)))
    }

    private var firstMonthStart: Date { cal.startOfMonth(for: anchor) }

    private var lastMonthStart: Date {
        cal.date(byAdding: .month, value: monthCount - 1, to: firstMonthStart) ?? firstMonthStart
    }

    /// The years whose holidays are needed. Padding days can reach into the
    /// neighbouring years, so one either side is included.
    private var displayedYears: [Int] {
        Array((cal.component(.year, from: firstMonthStart) - 1)...(cal.component(.year, from: lastMonthStart) + 1))
    }

    private func shift(by months: Int) {
        if let d = cal.date(byAdding: .month, value: months, to: firstMonthStart) {
            anchor = d
        }
    }
}
