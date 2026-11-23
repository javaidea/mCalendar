import SwiftUI

/// The popover behind the "+" under holidays: a search field over every
/// country with holiday data, each ticked on or off in place. Once
/// `HolidayCountry.maxSelected` are ticked, the others are greyed out until
/// one is unticked.
struct CountryPickerView: View {
    @EnvironmentObject private var settings: Settings
    @ObservedObject private var catalog = HolidayCountryCatalog.shared
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(settings.t(.searchCountries), text: $query)
                .textFieldStyle(.roundedBorder)
                .focused($searchFocused)

            content
                .frame(height: 260)

            if !settings.canAddHolidayCountry {
                Text(settings.t(.countryLimitReached))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .font(.system(size: 12))
        .padding(12)
        .frame(width: 240)
        .task { await catalog.load() }
        .onAppear { searchFocused = true }
    }

    @ViewBuilder
    private var content: some View {
        switch catalog.state {
        case .idle, .loading:
            ProgressView()
                .controlSize(.small)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed:
            VStack(spacing: 8) {
                Text(settings.t(.countryListFailed))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button(settings.t(.retry)) {
                    Task { await catalog.load() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let codes):
            let rows = matching(codes)
            if rows.isEmpty {
                Text(settings.t(.noMatches))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(rows, id: \.code) { row in
                            countryRow(row.code, name: row.name)
                        }
                    }
                }
            }
        }
    }

    /// Countries whose name in the interface language, English name or code
    /// contains the query, ignoring case and accents, sorted by name.
    private func matching(_ codes: [CountryCode]) -> [(code: CountryCode, name: String)] {
        let english = Locale(identifier: "en")
        let needle = query.trimmingCharacters(in: .whitespaces)
        return codes
            .map { (code: $0, name: $0.name(in: settings.locale)) }
            .filter { row in
                needle.isEmpty || [row.name, row.code.name(in: english), row.code.rawValue].contains {
                    $0.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive]) != nil
                }
            }
            .sorted { $0.name.compare($1.name, locale: settings.locale) == .orderedAscending }
    }

    private func countryRow(_ code: CountryCode, name: String) -> some View {
        let isSelected = settings.holidayCountries.contains(code)
        let isFull = !isSelected && !settings.canAddHolidayCountry
        let color = HolidayCountry.selected(settings.holidayCountries).first { $0.code == code }?.color
        return Button {
            if isSelected {
                settings.removeHolidayCountry(code)
            } else {
                settings.addHolidayCountry(code)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                Text(name)
                Spacer()
                if let color {
                    Circle().fill(color).frame(width: 7, height: 7)
                }
            }
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isFull)
        .opacity(isFull ? 0.4 : 1)
    }
}
