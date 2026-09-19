import SwiftUI
import AppKit

/// Day-cell size. The plain grid keeps its compact 24pt tiles; lunar dates and
/// holiday dots each need extra room, so the cells (and the popover) grow only
/// while those are switched on.
struct GridMetrics {
    let cellWidth: CGFloat
    let cellHeight: CGFloat

    init(lunar: Bool, holidays: Bool) {
        cellWidth = lunar ? 34 : holidays ? 28 : 24
        // Holidays add a dot band above the text and an equal one below it.
        cellHeight = lunar ? (holidays ? 43 : 33) : holidays ? 35 : 24
    }

    /// Wide enough for the gutter, the padding and seven columns with a little
    /// air around each tile; 225 for the plain grid.
    var popoverWidth: CGFloat { (39 + 7 * (cellWidth + 2.6)).rounded() }

    /// Roughly how much taller the popover gets per added month: 4–5 week rows
    /// plus the 5pt spacing between them.
    var monthHeight: CGFloat { (cellHeight + 5) * 4.3 }
}

struct CalendarView: View {
    @EnvironmentObject var settings: Settings
    @ObservedObject private var holidays = HolidayStore.shared
    @State private var anchor = Date()
    @State private var dragStartCount: Int?
    @State private var dragStartY: CGFloat?
    @State private var handleHovered = false

    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.locale = settings.locale
        // ISO 8601 weeks: Monday first, week 1 is the one holding Jan 4th. Both
        // are pinned after the locale, which would otherwise choose
        // minimumDaysInFirstWeek itself — that shifted the whole week-number
        // column by one when the interface language changed.
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 4
        return c
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            MonthsGrid(
                firstMonthStart: startOfMonth(anchor),
                monthCount: monthCount,
                showWeeks: settings.showWeekNumbers,
                showLunar: settings.showLunar,
                holidayCountries: holidayCountries,
                metrics: metrics,
                cal: cal
            )
            .padding(.top, 12)
            .task(id: "\(holidayCountries)|\(displayedYears)") {
                guard !holidayCountries.isEmpty else { return }
                await holidays.load(years: displayedYears, countries: holidayCountries)
            }
            dragHandle
            footer
        }
        // The grid's left edge is the week-number gutter, which already reads as
        // inset, so the left margin stays tighter than the other three.
        .padding(EdgeInsets(top: 9, leading: 6, bottom: 9, trailing: 9))
        .frame(width: metrics.popoverWidth)
    }

    private var metrics: GridMetrics {
        GridMetrics(lunar: settings.showLunar, holidays: !holidayCountries.isEmpty)
    }

    private var holidayCountries: [String] { settings.showHolidays ? settings.holidayCountries : [] }

    /// The months actually shown: the setting, capped so bigger cells can't push
    /// the popover off the bottom of the screen.
    private var monthCount: Int { min(settings.monthCount, maxMonths) }

    private var maxMonths: Int {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        guard let height = screen?.visibleFrame.height else { return 6 }
        // ~110pt of header, weekday row, grip and footer, plus a spare week row.
        let available = height - 110 - (metrics.cellHeight + 5)
        return min(6, max(1, Int(available / metrics.monthHeight)))
    }

    private var displayedYears: [Int] {
        let first = startOfMonth(anchor)
        let last = cal.date(byAdding: .month, value: monthCount - 1, to: first) ?? first
        // Padding days can reach into the neighbouring years.
        return Array((cal.component(.year, from: first) - 1)...(cal.component(.year, from: last) + 1))
    }

    /// Drag down/up to open or close months, like pulling the bottom edge of the
    /// grid — the grip on the Notification Center calendar widget.
    private var dragHandle: some View {
        Capsule()
            .fill(Color.primary.opacity(handleHovered ? 0.28 : 0.15))
            .frame(width: 36, height: 5)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onHover { hovering in
                handleHovered = hovering
                if hovering { NSCursor.resizeUpDown.push() } else { NSCursor.pop() }
            }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { _ in
                        // Measure against the screen, not the view: changing the month
                        // count resizes the popover and moves this handle, so a
                        // view-local translation would feed back on itself and run
                        // away to the limits after one small drag.
                        let y = NSEvent.mouseLocation.y
                        guard let startY = dragStartY, let startCount = dragStartCount else {
                            dragStartY = y
                            dragStartCount = settings.monthCount
                            return
                        }
                        // One month per month-height of travel, so the handle stays
                        // under the pointer as the grid grows. Screen y grows upward,
                        // so dragging down opens more months.
                        let months = Int(((startY - y) / metrics.monthHeight).rounded())
                        let newCount = min(maxMonths, max(1, startCount + months))
                        if newCount != settings.monthCount { settings.monthCount = newCount }
                    }
                    .onEnded { _ in
                        dragStartY = nil
                        dragStartCount = nil
                    }
            )
    }

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

    // "2026年 7–8月" / "Jul – Aug 2026"; single month "2026年 7月" / "Jul 2026".
    private var rangeTitle: String {
        let first = startOfMonth(anchor)
        let last = cal.date(byAdding: .month, value: monthCount - 1, to: first) ?? first
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

    private func startOfMonth(_ date: Date) -> Date {
        cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? date
    }

    private func shift(by months: Int) {
        if let d = cal.date(byAdding: .month, value: months, to: startOfMonth(anchor)) {
            anchor = d
        }
    }
}

/// A continuous grid spanning `monthCount` months starting at `firstMonthStart`,
/// with a single weekday header and week-number gutter.
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
        VStack(alignment: .leading, spacing: 5) {
            // Weekday header as its own row, separated from the grid by a hairline.
            HStack(spacing: 0) {
                if showWeeks {
                    Color.clear.frame(width: gutter)
                }
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { i, s in
                    Text(s)
                        .font(.system(size: 10, weight: .semibold))
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .foregroundStyle(Color.primary.opacity(isWeekendColumn(i) ? 0.66 : 0.8))
                        .frame(maxWidth: .infinity)
                }
            }

            VStack(spacing: 5) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 0) {
                        // The week a month starts in gets the month label instead of
                        // the week number, so month boundaries stay readable.
                        if showWeeks {
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

    /// Signed month distance from the first displayed month: negative for the
    /// padding days before it, >= monthCount for the ones after.
    private func monthOffset(of day: Date) -> Int {
        let comps = cal.dateComponents(
            [.month],
            from: firstMonthStart,
            to: cal.date(from: cal.dateComponents([.year, .month], from: day)) ?? day
        )
        return comps.month ?? 0
    }

    /// 0-based index of the displayed month `day` falls in, or nil if outside.
    private func monthIndex(of day: Date) -> Int? {
        let m = monthOffset(of: day)
        return (0..<monthCount).contains(m) ? m : nil
    }

    /// The band alternates by calendar month, padding days included — otherwise
    /// the first and last rows lose their background where the range starts or
    /// ends mid-week, leaving a notch in the panel.
    private func isBanded(_ day: Date) -> Bool { monthOffset(of: day) % 2 == 0 }

    private var weekdaySymbols: [String] {
        let s = cal.veryShortStandaloneWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(s[first...] + s[..<first])
    }

    private func isWeekendColumn(_ index: Int) -> Bool { index >= 5 }

    private var lastMonthEnd: Date {
        let last = cal.date(byAdding: .month, value: monthCount - 1, to: firstMonthStart) ?? firstMonthStart
        let count = cal.range(of: .day, in: .month, for: last)?.count ?? 30
        return cal.date(byAdding: .day, value: count - 1, to: last) ?? last
    }

    private var gridStart: Date {
        let firstWeekday = cal.component(.weekday, from: firstMonthStart)
        let leading = (firstWeekday - cal.firstWeekday + 7) % 7
        return cal.date(byAdding: .day, value: -leading, to: firstMonthStart) ?? firstMonthStart
    }

    // Full weeks from the start gutter through the end of the last month.
    private var weeks: [[Date]] {
        let end = cal.startOfDay(for: lastMonthEnd)
        let spanned = (cal.dateComponents([.day], from: gridStart, to: end).day ?? 0) + 1
        let rows = Int(ceil(Double(spanned) / 7.0))
        return (0..<rows).map { r in
            (0..<7).compactMap { c in cal.date(byAdding: .day, value: r * 7 + c, to: gridStart) }
        }
    }
}

struct DayCell: View {
    let date: Date
    /// 0-based index of the displayed month this day belongs to, nil for the
    /// padding days that fall outside the range.
    let monthIndex: Int?
    /// True when the day's month sits on the darker band, so a boundary that
    /// falls in the middle of a week row still reads as a break.
    let banded: Bool
    let showLunar: Bool
    /// Reserve the dot row, so every row keeps the same height.
    let showHolidays: Bool
    let holiday: HolidayInfo
    let metrics: GridMetrics
    let cal: Calendar

    @EnvironmentObject private var settings: Settings
    @State private var hovered = false
    @State private var showDetails = false

    /// True when the day belongs to the first (topmost) month.
    private var emphasized: Bool { monthIndex == 0 }

    private var countries: [HolidayCountry] {
        HolidayCountry.all.filter { holiday.names[$0.code] != nil }
    }

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
                HStack(spacing: 2) {
                    ForEach(countries) { country in
                        Circle()
                            .fill(isToday ? Color.white : country.color)
                            .frame(width: 4, height: 4)
                    }
                }
                .padding(.top, 2)
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
                // Bleed into the 5pt gap between week rows so the band of a
                // month is one continuous block rather than stripes.
                .padding(.vertical, -2.5)
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

    // Tiers: first month bright, other months mid-gray, padding days faint.
    //
    // The opacities come from contrast measured on screen rather than picked by
    // eye, against the panel this draws on. In light mode every tier below the
    // brightest used to fall under 3:1 and the padding days all but vanished.
    // In-range days now clear 4.5:1; padding days sit near 3:1 on purpose, so
    // they stay legible without competing with the month you asked for.
    private func color(isWeekend: Bool) -> Color {
        if emphasized { return .primary.opacity(isWeekend ? 0.78 : 1) }
        if monthIndex != nil { return .primary.opacity(0.76) }
        return .primary.opacity(0.6)
    }
}

/// What a click on a day opens: everything its tile abbreviates, spelled out.
struct DayDetailsView: View {
    let date: Date
    let showLunar: Bool
    let holiday: HolidayInfo
    let cal: Calendar

    @EnvironmentObject private var settings: Settings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(fullDate)
                .font(.system(size: 13, weight: .semibold))

            if showLunar {
                row(settings.t("lunarDate"), LunarDate.string(from: date, includeMonth: true))
                if let term = SolarTerm.name(for: date, cal: cal) {
                    row(settings.t("solarTerm"), term, color: .accentColor)
                }
            }

            ForEach(HolidayCountry.all.filter { holiday.names[$0.code] != nil }) { country in
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Circle().fill(country.color).frame(width: 6, height: 6)
                        Text(settings.locale.localizedString(forRegionCode: country.code) ?? country.code)
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    ForEach(holiday.names[country.code] ?? [], id: \.self) { name in
                        Text(name.local)
                        if let translation = name.translation(chinese: settings.isChinese) {
                            Text(translation)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if holiday.isMakeupWorkday {
                row(settings.t("chinaSchedule"), settings.t("makeupWorkday"), color: .orange)
            }

            row(settings.t("week"), "\(cal.component(.weekOfYear, from: date))")
        }
        .font(.system(size: 12))
        .textSelection(.enabled)
        .fixedSize()
        .frame(minWidth: 160, alignment: .leading)
        .padding(14)
    }

    private var fullDate: String {
        let f = DateFormatter()
        f.calendar = cal
        f.locale = settings.locale
        f.dateStyle = .full
        return f.string(from: date)
    }

    private func row(_ title: String, _ value: String, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text(value)
                .foregroundStyle(color)
        }
    }
}

/// Content of the standalone settings window.
struct SettingsView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 28, height: 28)
                Text("Mini Calendar")
                    .font(.system(size: 15, weight: .semibold))
            }

            Divider()

            HStack(spacing: 8) {
                Text(settings.t("months"))
                Slider(
                    value: Binding(
                        get: { Double(settings.monthCount) },
                        set: { settings.monthCount = Int($0.rounded()) }
                    ),
                    in: 1...6, step: 1
                )
                Text("\(settings.monthCount)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            toggleRow("showDate", $settings.showDate)
            toggleRow("showWeekday", $settings.showWeekday)
            toggleRow("showWeekNums", $settings.showWeekNumbers)
            toggleRow("showLunar", $settings.showLunar)
            toggleRow("showHolidays", $settings.showHolidays)
            if settings.showHolidays {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(HolidayCountry.all) { country in
                        Toggle(isOn: Binding(
                            get: { settings.holidayCountries.contains(country.code) },
                            set: { settings.setHolidayCountry(country.code, enabled: $0) }
                        )) {
                            HStack(spacing: 6) {
                                Circle().fill(country.color).frame(width: 7, height: 7)
                                Text(settings.locale.localizedString(forRegionCode: country.code) ?? country.code)
                            }
                        }
                        .toggleStyle(.checkbox)
                    }
                    Text(settings.t("holidayNote"))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 12)
            }
            toggleRow("launchAtLogin", $settings.launchAtLogin)

            HStack {
                Text(settings.t("language"))
                Spacer()
                Picker("", selection: $settings.languageCode) {
                    Text(settings.t("system")).tag("system")
                    Text("English").tag("en")
                    Text("中文").tag("zh-Hans")
                }
                .labelsHidden()
                .fixedSize()
            }

            HStack {
                Text(settings.t("appearance"))
                Spacer()
                Picker("", selection: $settings.appearance) {
                    Text(settings.t("system")).tag(AppearanceMode.system)
                    Text(settings.t("light")).tag(AppearanceMode.light)
                    Text(settings.t("dark")).tag(AppearanceMode.dark)
                }
                .labelsHidden()
                .fixedSize()
            }

            Divider()

            HStack {
                Text("v\(Settings.appVersion) · \(settings.t("author"))")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Spacer()
                Button(settings.t("quit")) { NSApp.terminate(nil) }
            }
        }
        .font(.system(size: 12))
        .padding(16)
        .frame(width: 300)
    }

    private func toggleRow(_ key: String, _ binding: Binding<Bool>) -> some View {
        HStack {
            Text(settings.t(key))
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
    }
}
