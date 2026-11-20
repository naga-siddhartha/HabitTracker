#if DEBUG
import Foundation

// MARK: - Marketing Demo Seeder
//
// Activated by the -marketingDemo launch argument. Seeds six sample habits with
// two weeks of completions so the app looks polished in App Store screenshots.
// Stripped entirely from release builds by the #if DEBUG guard.

@MainActor
enum MarketingDemoSeeder {

    static let isActive: Bool = CommandLine.arguments.contains("-marketingDemo")

    private static let seededKey = "marketing.demo.seeded.v1"

    /// Call once at launch. No-ops when demo is not active or already seeded.
    static func seedIfNeeded(store: HabitStore) {
        guard isActive else { return }
        // Always suppress onboarding and notifications in demo mode.
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        guard store.fetchHabits().isEmpty else { return }   // idempotent
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        seed(store: store)
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    // MARK: - Private

    private static func seed(store: HabitStore) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        func ago(_ n: Int) -> Date { cal.date(byAdding: .day, value: -n, to: today)! }

        // 1. Drink Water — repeating 7x/day (8 AM–10 PM, every 140 min), today at 3 of 7
        //    expectedCompletions = (22*60 - 8*60) / 140 + 1 = 840/140 + 1 = 7
        let water = Habit(name: "Drink Water", emoji: "💧", color: .teal,
                          reminderIntervalMinutes: 140)
        water.createdAt = ago(20)
        store.addHabit(water)
        for d in 1...12 { addFull(water, ago(d)) }         // 12-day streak
        addPartial(water, today, count: 3)                  // 3 of 7 today

        // 2. Exercise — 10-day streak, not yet done today
        let exercise = Habit(name: "Exercise", emoji: "🏃", color: .orange)
        exercise.createdAt = ago(20)
        store.addHabit(exercise)
        for d in 1...10 { addFull(exercise, ago(d)) }

        // 3. Journal — 7-day streak including today
        let journal = Habit(name: "Journal", emoji: "📓", color: .green)
        journal.createdAt = ago(20)
        store.addHabit(journal)
        for d in 0...6 { addFull(journal, ago(d)) }

        // 4. Plan Tomorrow — 4-day streak, not yet today
        let plan = Habit(name: "Plan Tomorrow", emoji: "📋", color: .blue)
        plan.createdAt = ago(20)
        store.addHabit(plan)
        for d in 1...4 { addFull(plan, ago(d)) }

        // 5. Practice Instrument — 6-day streak including today
        let instrument = Habit(name: "Practice Instrument", emoji: "🎸", color: .orange)
        instrument.createdAt = ago(20)
        store.addHabit(instrument)
        for d in 0...5 { addFull(instrument, ago(d)) }

        // 6. Read a Book — 8-day streak, not yet today
        let reading = Habit(name: "Read a Book", emoji: "📚", color: .red)
        reading.createdAt = ago(20)
        store.addHabit(reading)
        for d in 1...8 { addFull(reading, ago(d)) }

        store.save()
    }

    private static func addFull(_ habit: Habit, _ date: Date) {
        let entry = HabitEntry(date: date, isCompleted: true)
        if habit.reminderIntervalMinutes > 0 {
            // expectedCompletions(on:) is MainActor, call synchronously here
            let cal = Calendar.current
            let startMins = 8 * 60   // 8 AM default
            let endMins   = 22 * 60  // 10 PM default
            let count = max(1, (endMins - startMins) / habit.reminderIntervalMinutes + 1)
            entry.completionCount = count
        }
        habit.entries = (habit.entries ?? []) + [entry]
    }

    private static func addPartial(_ habit: Habit, _ date: Date, count: Int) {
        let entry = HabitEntry(date: date, isCompleted: false)
        entry.completionCount = count
        habit.entries = (habit.entries ?? []) + [entry]
    }
}
#endif
