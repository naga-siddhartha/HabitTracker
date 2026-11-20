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
        // Find the next Monday on or after today so createdAt guard passes
        let today = calendar.startOfDay(for: Date.now)
        let weekday = calendar.component(.weekday, from: today)
        let daysToMonday = (9 - weekday) % 7
        let monday = calendar.date(byAdding: .day, value: daysToMonday, to: today)!
        let tuesday = calendar.date(byAdding: .day, value: 1, to: monday)!

        let habit = Habit(name: "Weekly", frequency: .weekly, activeDays: [.monday, .wednesday])

        XCTAssertTrue(habit.isActive(on: monday))
        XCTAssertFalse(habit.isActive(on: tuesday))
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
    
    func testPickerOffersNinePresetsWithoutPurple() {
        XCTAssertEqual(HabitColor.pickerColors.count, 9)
        XCTAssertFalse(HabitColor.pickerColors.contains(.purple))
        XCTAssertFalse(HabitColor.pickerColors.contains(.custom))
    }
    
    func testReminderSoundCount() {
        XCTAssertEqual(ReminderSound.allCases.count, 5)
    }
}

