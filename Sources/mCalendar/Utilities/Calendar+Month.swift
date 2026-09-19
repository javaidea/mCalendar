import Foundation

extension Calendar {
    /// Midnight on the 1st of the month holding `date`.
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
    }
}
