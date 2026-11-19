import Foundation

// MARK: - Day Key

/// A calendar day (year, month, day) with no time or time zone attached.
/// Habits are tracked per day, so comparing days by key avoids the off-by-one bugs that come
/// from comparing `Date` instants across time zones and daylight-saving transitions.
struct DayKey: Hashable, Comparable, Sendable, CustomStringConvertible {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    static func < (lhs: DayKey, rhs: DayKey) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    var description: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }
}

extension Calendar {
    /// The calendar day containing `date` in this calendar's time zone.
    func dayKey(for date: Date) -> DayKey {
        let c = dateComponents([.year, .month, .day], from: date)
        return DayKey(year: c.year ?? 0, month: c.month ?? 1, day: c.day ?? 1)
    }

    /// Day key for a stored entry date. Entries are saved as local midnight at the time they were
    /// recorded. After a time zone change that midnight can read as, for example, 9 PM the previous
    /// day, so round to the nearest midnight instead of truncating. Correct for time zone shifts
    /// of up to 12 hours either way.
    func storedDayKey(for date: Date) -> DayKey {
        let hour = component(.hour, from: date)
        guard hour >= 12, let next = self.date(byAdding: .day, value: 1, to: date) else {
            return dayKey(for: date)
        }
        return dayKey(for: next)
    }

    /// Noon on the given day. Noon is never skipped or repeated by DST, so it is safe for day arithmetic.
    func noon(of key: DayKey) -> Date {
        let comps = DateComponents(year: key.year, month: key.month, day: key.day, hour: 12)
        return date(from: comps) ?? Date(timeIntervalSince1970: 0)
    }

    /// Local midnight at the start of the given day.
    func startOfDay(of key: DayKey) -> Date {
        startOfDay(for: noon(of: key))
    }

    func dayKey(byAdding days: Int, to key: DayKey) -> DayKey {
        let base = noon(of: key)
        return dayKey(for: date(byAdding: .day, value: days, to: base) ?? base)
    }
}
