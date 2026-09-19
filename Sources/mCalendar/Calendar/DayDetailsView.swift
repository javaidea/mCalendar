import SwiftUI

/// What a click on a day opens: everything its tile abbreviates, spelled out.
/// Full date, lunar date and solar term, each country's holidays in their own
/// language with a translation, make-up workday, and ISO week.
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
                holidaySection(country)
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

    /// "Thursday, 1 October 2026" / "2026年10月1日 星期四".
    private var fullDate: String {
        let f = DateFormatter()
        f.calendar = cal
        f.locale = settings.locale
        f.dateStyle = .full
        return f.string(from: date)
    }

    /// The country with its dot, then each holiday's local name and translation.
    private func holidaySection(_ country: HolidayCountry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                Circle().fill(country.color).frame(width: 6, height: 6)
                Text(country.name(in: settings.locale))
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

    /// A small grey caption over its value.
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
