import XCTest
import SwiftData
@testable import HabitTracker

final class HabitModelTests: XCTestCase {
    
    func testHabitInitialization() {
        let habit = Habit(name: "Exercise", description: "Daily workout")
        
        XCTAssertEqual(habit.name, "Exercise")
        XCTAssertEqual(habit.habitDescription, "Daily workout")
        XCTAssertEqual(habit.frequency, .daily)
        XCTAssertEqual(habit.color, .blue)
        XCTAssertFalse(habit.isArchived)
    }
    
    func testHabitWithWeeklyFrequency() {
        let activeDays: Set<Weekday> = [.monday, .wednesday, .friday]
        let habit = Habit(name: "Gym", frequency: .weekly, activeDays: activeDays)
        
        XCTAssertEqual(habit.frequency, .weekly)
        XCTAssertEqual(habit.activeDays, activeDays)
    }
    
    func testHabitIsActiveDaily() {
        let habit = Habit(name: "Daily Habit", frequency: .daily)
        XCTAssertTrue(habit.isActive(on: .now))
    }
    
    func testHabitIsActiveWeekly() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 12 // Monday
        let monday = calendar.date(from: components)!
        let tuesday = calendar.date(byAdding: .day, value: 1, to: monday)!
        
        let habit = Habit(name: "Weekly", frequency: .weekly, activeDays: [.monday, .wednesday])
        
        XCTAssertTrue(habit.isActive(on: monday))
        XCTAssertFalse(habit.isActive(on: tuesday))
    }
    
    func testArchivedHabitNotActive() {
        let habit = Habit(name: "Archived")
        habit.isArchived = true
        XCTAssertFalse(habit.isActive(on: .now))
    }
}

final class HabitEntryModelTests: XCTestCase {
    
    func testEntryDateNormalization() {
        let dateWithTime = Calendar.current.date(bySettingHour: 14, minute: 30, second: 0, of: Date.now)!
        let entry = HabitEntry(date: dateWithTime)
        
        XCTAssertEqual(entry.date, Calendar.current.startOfDay(for: dateWithTime))
    }
    
    func testEntryDefaultsToCompleted() {
        let entry = HabitEntry(date: .now)
        XCTAssertTrue(entry.isCompleted)
    }
}

final class StreakModelTests: XCTestCase {
    
    func testStreakInitialization() {
        let streak = Streak(currentStreak: 5, longestStreak: 10)
        
        XCTAssertEqual(streak.currentStreak, 5)
        XCTAssertEqual(streak.longestStreak, 10)
    }
    
    func testStreakDefaultValues() {
        let streak = Streak()
        
        XCTAssertEqual(streak.currentStreak, 0)
        XCTAssertEqual(streak.longestStreak, 0)
        XCTAssertNil(streak.lastCompletedDate)
    }
}

final class EnumTests: XCTestCase {
    
    func testWeekdayRawValues() {
        XCTAssertEqual(Weekday.sunday.rawValue, 1)
        XCTAssertEqual(Weekday.saturday.rawValue, 7)
    }
    
    func testWeekdayNames() {
        XCTAssertEqual(Weekday.monday.shortName, "Mon")
        XCTAssertEqual(Weekday.monday.fullName, "Monday")
    }
    
    func testHabitColorCount() {
        XCTAssertEqual(HabitColor.allCases.count, 9)
    }
    
    func testReminderSoundCount() {
        XCTAssertEqual(ReminderSound.allCases.count, 5)
    }
}

final class IconGenerationServiceTests: XCTestCase {
    
    func testExactMatch() {
        XCTAssertEqual(IconGenerationService.shared.generateLocalIcon(for: "exercise"), "figure.run")
        XCTAssertEqual(IconGenerationService.shared.generateLocalIcon(for: "meditation"), "leaf.fill")
    }
    
    func testCaseInsensitive() {
        XCTAssertEqual(IconGenerationService.shared.generateLocalIcon(for: "EXERCISE"), "figure.run")
    }
    
    func testPartialMatch() {
        XCTAssertEqual(IconGenerationService.shared.generateLocalIcon(for: "morning exercise"), "figure.run")
    }
    
    func testDefaultIcon() {
        XCTAssertEqual(IconGenerationService.shared.generateLocalIcon(for: "random"), "star.fill")
    }
}
