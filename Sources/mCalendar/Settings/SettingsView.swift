import SwiftUI

/// Content of the standalone settings window: the app name, one row per
/// setting, and the version and Quit button at the bottom.
struct SettingsView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()

            monthCountRow
            toggleRow("showDate", $settings.showDate)
            toggleRow("showWeekday", $settings.showWeekday)
            toggleRow("showWeekNums", $settings.showWeekNumbers)
            toggleRow("showLunar", $settings.showLunar)
            toggleRow("showHolidays", $settings.showHolidays)
            if settings.showHolidays {
                holidayCountryList
            }
            toggleRow("launchAtLogin", $settings.launchAtLogin)
            languageRow
            appearanceRow

            Divider()
            footer
        }
        .font(.system(size: 12))
        .padding(16)
        .frame(width: 300)
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 8) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 28, height: 28)
            Text("Mini Calendar")
                .font(.system(size: 15, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
    }

    private var monthCountRow: some View {
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
    }

    /// One checkbox per country, indented under the holidays switch, with a
    /// note on "班" and where the data comes from.
    private var holidayCountryList: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(HolidayCountry.all) { country in
                Toggle(isOn: Binding(
                    get: { settings.holidayCountries.contains(country.code) },
                    set: { settings.setHolidayCountry(country.code, enabled: $0) }
                )) {
                    HStack(spacing: 6) {
                        Circle().fill(country.color).frame(width: 7, height: 7)
                        Text(country.name(in: settings.locale))
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

    private var languageRow: some View {
        pickerRow("language", selection: $settings.languageCode) {
            Text(settings.t("system")).tag("system")
            Text("English").tag("en")
            Text("中文").tag("zh-Hans")
        }
    }

    private var appearanceRow: some View {
        pickerRow("appearance", selection: $settings.appearance) {
            Text(settings.t("system")).tag(AppearanceMode.system)
            Text(settings.t("light")).tag(AppearanceMode.light)
            Text(settings.t("dark")).tag(AppearanceMode.dark)
        }
    }

    private var footer: some View {
        HStack {
            Text("v\(Settings.appVersion) · \(settings.t("author"))")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Spacer()
            Button(settings.t("quit")) { NSApp.terminate(nil) }
        }
    }

    // MARK: - Row builders

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

    private func pickerRow<Value: Hashable, Options: View>(
        _ key: String,
        selection: Binding<Value>,
        @ViewBuilder options: () -> Options
    ) -> some View {
        HStack {
            Text(settings.t(key))
            Spacer()
            Picker("", selection: selection, content: options)
                .labelsHidden()
                .fixedSize()
        }
    }
}
