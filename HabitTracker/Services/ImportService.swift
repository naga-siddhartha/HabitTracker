import Foundation
import SwiftData

/// Restore from Ritual Log v1 JSON export (ExportService.ExportData format).
@available(iOS 17.0, macOS 14.0, *)
struct ImportService {

    // MARK: - Errors

    enum ImportError: LocalizedError {
        case invalidData
        case decodingFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidData: return "The file is not a valid backup."
            case .decodingFailed(let detail): return "Could not read backup: \(detail)"
            }
        }
    }

    // MARK: - Parsing

    /// Parse JSON data into export model. Does not touch the model context.
    static func parseExportData(_ data: Data) throws -> ExportService.ExportData {
        guard !data.isEmpty else { throw ImportError.invalidData }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(ExportService.ExportData.self, from: data)
        } catch {
            throw ImportError.decodingFailed(error.localizedDescription)
        }
    }

    // MARK: - Restore

    /// Replace all habits in the given context with the contents of the export. Call from MainActor with main context.
    static func restoreFromExport(_ exportData: ExportService.ExportData, context: ModelContext) throws {
        for exportHabit in exportData.habits {
            _ = try makeHabit(from: exportHabit, context: context)
        }
        try context.save()
    }
    
    /// Delete all existing habits and then restore from export. Use for "Restore from backup" flow.
    static func replaceAllAndRestore(from exportData: ExportService.ExportData, context: ModelContext) throws {
        try deleteAllHabits(context: context)
        try restoreFromExport(exportData, context: context)
    }
    
    static func deleteAllHabits(context: ModelContext) throws {
        let descriptor = FetchDescriptor<Habit>()
        let existing = try context.fetch(descriptor)
        for habit in existing {
            context.delete(habit)
        }
        try context.save()
    }

    // MARK: - Helpers

    private static func makeHabit(from export: ExportService.ExportHabit, context: ModelContext) throws -> Habit {
        let color = HabitColor(rawValue: export.color) ?? .blue
        let frequency = HabitFrequency(rawValue: export.frequency) ?? .daily
        let activeDays = Set(export.activeDays.compactMap { name in
            Weekday.allCases.first { $0.fullName == name }
        })
        
        let habit = Habit(
            name: export.name,
            description: export.description,
            iconName: export.iconName,
            emoji: nil,
            color: color,
            frequency: frequency,
            reminderTimes: [],
            reminderNames: [],
            reminderSounds: [],
            activeDays: activeDays
        )
        habit.isArchived = export.isArchived
        habit.createdAt = export.createdAt
        habit.updatedAt = export.createdAt
        
        let streak = Streak(currentStreak: export.currentStreak, longestStreak: export.longestStreak)
        streak.habit = habit
        habit.streak = streak
        
        for exportEntry in export.entries {
            let entry = HabitEntry(
                date: exportEntry.date,
                isCompleted: exportEntry.isCompleted,
                isSkipped: exportEntry.isSkipped,
                skipReason: exportEntry.skipReason
            )
            entry.habit = habit
            context.insert(entry)
        }
        context.insert(habit)
        context.insert(streak)
        return habit
    }
}
