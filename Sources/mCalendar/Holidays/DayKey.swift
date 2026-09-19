/// A calendar day as an integer, e.g. 20261001 for 1 October 2026.
///
/// Holiday data is keyed by the date written in the source, not by a `Date`,
/// so a holiday stays on its day whatever the Mac's time zone.
func dayKey(_ year: Int, _ month: Int, _ day: Int) -> Int {
    year * 10_000 + month * 100 + day
}

/// Parses "2026-10-01" as used by both holiday sources.
func dayKey(isoDate: String) -> Int? {
    let parts = isoDate.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3 else { return nil }
    return dayKey(parts[0], parts[1], parts[2])
}
