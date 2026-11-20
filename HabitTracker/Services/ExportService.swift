import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Builds JSON backups and CSV exports of all habits.
struct ExportService {
    
    // MARK: - Export Data Structures
    
    struct ExportData: Codable {
        let exportDate: Date
        let appVersion: String
        let habits: [ExportHabit]
    }
    
    struct ExportHabit: Codable {
        let id: String
        let name: String
        let description: String?
        let iconName: String?
        let color: String
        let frequency: String
        let activeDays: [String]
        let createdAt: Date
        let isArchived: Bool
        let currentStreak: Int
        let longestStreak: Int
        let entries: [ExportEntry]
        // Added in 1.4. Optional so older backups still restore.
        var emoji: String? = nil
        var customColorHex: String? = nil
        var reminderTimes: [Date]? = nil
        var reminderNames: [String]? = nil
        var reminderSounds: [String]? = nil
        var reminderIntervalMinutes: Int? = nil
        var reminderEndTime: Date? = nil
    }
    
    struct ExportEntry: Codable {
        let date: Date
        let isCompleted: Bool
        let isSkipped: Bool
        let skipReason: String?
        /// Progress for "every few hours" habits. Added in 1.4.
        var completionCount: Int? = nil
    }
    
    // MARK: - Export to JSON
    
    static func exportToJSON(habits: [Habit]) -> Data? {
        let exportHabits = habits.map { habit in
            ExportHabit(
                id: habit.id.uuidString,
                name: habit.name,
                description: habit.habitDescription,
                iconName: habit.iconName,
                color: habit.colorName,
                frequency: habit.frequencyRaw,
                activeDays: habit.activeDays.map { $0.fullName },
                createdAt: habit.createdAt,
                isArchived: habit.isArchived,
                currentStreak: habit.liveStreak.currentStreak,
                longestStreak: habit.liveStreak.longestStreak,
                entries: (habit.entries ?? []).map { entry in
                    ExportEntry(
                        date: entry.date,
                        isCompleted: entry.isCompleted,
                        isSkipped: entry.isSkipped,
                        skipReason: entry.skipReason,
                        completionCount: entry.completionCount
                    )
                }.sorted { $0.date < $1.date },
                emoji: habit.emoji,
                customColorHex: habit.customColorHex,
                reminderTimes: habit.reminderTimes,
                reminderNames: habit.reminderNames,
                reminderSounds: habit.reminderSounds,
                reminderIntervalMinutes: habit.reminderIntervalMinutes,
                reminderEndTime: habit.reminderEndTime
            )
        }
        
        let exportData = ExportData(
            exportDate: .now,
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
            habits: exportHabits
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return try? encoder.encode(exportData)
    }
    
    // MARK: - Export to CSV
    
    static func exportToCSV(habits: [Habit]) -> Data? {
        var csv = "Habit Name,Date,Status,Skip Reason,Streak at Time\n"
        
        for habit in habits {
            let sortedEntries = (habit.entries ?? []).sorted { $0.date < $1.date }
            
            for entry in sortedEntries {
                let status: String
                if entry.isCompleted { status = "Completed" }
                else if entry.isSkipped { status = "Skipped" }
                else { status = "Incomplete" }
                
                let dateStr = entry.date.formatted(date: .numeric, time: .omitted)
                let reason = entry.skipReason ?? ""
                let streak = habit.liveStreak.currentStreak
                
                csv += "\"\(habit.name)\",\(dateStr),\(status),\"\(reason)\",\(streak)\n"
            }
        }
        
        return csv.data(using: .utf8)
    }
    
    // MARK: - Summary CSV
    
    static func exportSummaryCSV(habits: [Habit]) -> Data? {
        var csv = "Habit Name,Color,Frequency,Created,Current Streak,Longest Streak,Total Completions,Total Skips,Archived\n"
        
        for habit in habits {
            let completions = (habit.entries ?? []).filter { $0.isCompleted }.count
            let skips = (habit.entries ?? []).filter { $0.isSkipped }.count
            let created = habit.createdAt.formatted(date: .numeric, time: .omitted)
            
            csv += "\"\(habit.name)\",\(habit.colorName),\(habit.frequencyRaw),\(created),"
            csv += "\(habit.liveStreak.currentStreak),\(habit.liveStreak.longestStreak),"
            csv += "\(completions),\(skips),\(habit.isArchived)\n"
        }
        
        return csv.data(using: .utf8)
    }
}

// MARK: - Transferable Documents

/// File wrapper for exporting a JSON backup.
struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

/// File wrapper for exporting CSV data.
struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
