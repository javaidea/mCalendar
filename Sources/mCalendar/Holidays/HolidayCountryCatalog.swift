import Foundation

/// The countries whose holidays can be chosen, from date.nager.at's list.
///
/// Downloaded only when the country picker in Settings is opened, then kept
/// for the rest of the run. China is always offered, since its data comes
/// from its own source.
@MainActor
final class HolidayCountryCatalog: ObservableObject {
    static let shared = HolidayCountryCatalog()

    enum State {
        case idle, loading, failed
        case loaded([CountryCode])
    }

    @Published private(set) var state = State.idle

    private struct Item: Decodable {
        let countryCode: String
    }

    /// Downloads the list unless it is already here or on its way.
    func load() async {
        switch state {
        case .loading, .loaded: return
        case .idle, .failed: break
        }
        state = .loading
        guard let url = URL(string: "https://date.nager.at/api/v3/AvailableCountries"),
              let data = await holidaySession.fetchData(from: url),
              let items = try? JSONDecoder().decode([Item].self, from: data) else {
            state = .failed
            return
        }
        let codes = Set(items.compactMap { CountryCode(validating: $0.countryCode) }).union([.china])
        state = .loaded(codes.sorted())
    }
}
