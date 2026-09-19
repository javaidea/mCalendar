import SwiftUI

/// One day in the grid: the day number, optionally the lunar date or solar
/// term under it, holiday dots above it and "班" in the corner on a Chinese
/// make-up workday. Clicking it opens `DayDetailsView`.
struct DayCell: View {
    let date: Date
    /// 0-based index of the displayed month this day belongs to, nil for the
    /// padding days that fall outside the range.
    let monthIndex: Int?
    /// True when the day's month sits on the darker band, so a boundary that
    /// falls in the middle of a week row still reads as a break.
    let banded: Bool
    let showLunar: Bool
    /// Reserve the dot band even on days without a holiday, so every row keeps
    /// the same height.
    let showHolidays: Bool
    let holiday: HolidayInfo
    let metrics: GridMetrics
    let cal: Calendar

    @EnvironmentObject private var settings: Settings
    @State private var hovered = false
    @State private var showDetails = false

    var body: some View {
        let isToday = cal.isDateInToday(date)
        let weekday = cal.component(.weekday, from: date)
        let isWeekend = weekday == 7 || weekday == 1
        let term = showLunar ? SolarTerm.name(for: date, cal: cal) : nil
        let plain = !showLunar && !showHolidays

        VStack(spacing: 1) {
            Text("\(cal.component(.day, from: date))")
                .font(.system(size: plain ? 11.5 : 12.5, weight: isToday ? .bold : .regular))
                .foregroundStyle(isToday ? Color.white : color(isWeekend: isWeekend))
            if showLunar {
                // A solar term replaces the lunar date on its day, in the accent colour.
                Text(term ?? LunarDate.string(from: date))
                    .font(.system(size: 8.5))
                    .foregroundStyle(isToday ? Color.white : term != nil ? Color.accentColor : color(isWeekend: isWeekend))
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        // The text stays centred; the dots sit in the top margin, and the cell
        // is tall enough that the same margin is left free below.
        .frame(width: metrics.cellWidth, height: metrics.cellHeight)
        .overlay(alignment: .top) {
            if showHolidays {
                holidayDots(isToday: isToday)
            }
        }
        .overlay(alignment: .topTrailing) {
            if holiday.isMakeupWorkday {
                Text("班")
                    .font(.system(size: 7.5, weight: .bold))
                    .foregroundStyle(isToday ? Color.white : Color.orange)
                    .padding(.top, 1)
                    .padding(.trailing, 1)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isToday ? Color.accentColor
                      : hovered || showDetails ? Color.primary.opacity(0.12)
                      : .clear)
        )
        .frame(maxWidth: .infinity)
        .background(
            Rectangle()
                .fill(banded ? Color.primary.opacity(0.10) : .clear)
                // Bleed into the gap between week rows so the band of a month
                // is one continuous block rather than stripes.
                .padding(.vertical, -GridMetrics.rowSpacing / 2)
        )
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
        .animation(.easeOut(duration: 0.12), value: hovered)
        .onTapGesture { showDetails = true }
        .popover(isPresented: $showDetails, arrowEdge: .bottom) {
            DayDetailsView(date: date, showLunar: showLunar, holiday: holiday, cal: cal)
                .environmentObject(settings)
        }
    }

    /// One dot per country with a holiday that day, in `HolidayCountry.all` order.
    private func holidayDots(isToday: Bool) -> some View {
        HStack(spacing: 2) {
            ForEach(HolidayCountry.all.filter { holiday.names[$0.code] != nil }) { country in
                Circle()
                    .fill(isToday ? Color.white : country.color)
                    .frame(width: 4, height: 4)
            }
        }
        .padding(.top, 2)
    }

    // Tiers: first month bright, other months mid-gray, padding days faint.
    //
    // The opacities come from contrast measured on screen rather than picked by
    // eye, against the panel this draws on. In light mode every tier below the
    // brightest used to fall under 3:1 and the padding days all but vanished.
    // In-range days now clear 4.5:1; padding days sit near 3:1 on purpose, so
    // they stay legible without competing with the month you asked for.
    private func color(isWeekend: Bool) -> Color {
        if monthIndex == 0 { return .primary.opacity(isWeekend ? 0.78 : 1) }
        if monthIndex != nil { return .primary.opacity(0.76) }
        return .primary.opacity(0.6)
    }
}
