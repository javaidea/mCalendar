/// Everything the holiday data says about one day, for the enabled countries.
struct HolidayInfo {
    /// Holiday names per country code; countries with no holiday that day are
    /// absent.
    var names: [String: [HolidayName]] = [:]
    /// A Chinese make-up workday (调休上班), marked "班".
    var isMakeupWorkday = false
}
