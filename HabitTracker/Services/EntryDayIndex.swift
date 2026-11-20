import Foundation
import SwiftData

/// Per-habit index from day to that day's entries, so `Habit.entry(for:)` is a dictionary lookup.
///
/// Rebuilt when a habit's entry count or the time zone changes. Entry dates never change, and
/// other edits mutate the indexed entry objects in place, so they don't need a rebuild.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
final class EntryDayIndex {
    static let shared = EntryDayIndex()

    private final class Slot {
        weak var owner: Habit?
        let count: Int
        let timeZone: TimeZone
        let byDay: [DayKey: [HabitEntry]]
        init(owner: Habit, count: Int, timeZone: TimeZone, byDay: [DayKey: [HabitEntry]]) {
            self.owner = owner
            self.count = count
            self.timeZone = timeZone
            self.byDay = byDay
        }
    }

    private var slots: [ObjectIdentifier: Slot] = [:]

    func entries(of habit: Habit, on key: DayKey) -> [HabitEntry] {
        let all = habit.entriesOrEmpty
        let calendar = Calendar.current
        let id = ObjectIdentifier(habit)
        let slot: Slot
        if let existing = slots[id], existing.owner === habit,
           existing.count == all.count, existing.timeZone == calendar.timeZone {
            slot = existing
        } else {
            let byDay = Dictionary(grouping: all) { calendar.storedDayKey(for: $0.date) }
            slot = Slot(owner: habit, count: all.count, timeZone: calendar.timeZone, byDay: byDay)
            if slots.count > 500 { slots = slots.filter { $0.value.owner != nil } }
            slots[id] = slot
        }
        return (slot.byDay[key] ?? []).filter { !$0.isDeleted }
    }
}
