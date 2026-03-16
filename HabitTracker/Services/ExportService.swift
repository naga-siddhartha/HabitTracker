import Foundation
import SwiftUI
import UniformTypeIdentifiers

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
    }
    
    struct ExportEntry: Codable {
        let date: Date
        let isCompleted: Bool
        let isSkipped: Bool
        let skipReason: String?
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
                currentStreak: habit.streak?.currentStreak ?? 0,
                longestStreak: habit.streak?.longestStreak ?? 0,
                entries: (habit.entries ?? []).map { entry in
                    ExportEntry(
                        date: entry.date,
                        isCompleted: entry.isCompleted,
                        isSkipped: entry.isSkipped,
                        skipReason: entry.skipReason
                    )
                }.sorted { $0.date < $1.date }
            )
        }
        
        let exportData = ExportData(
            exportDate: .now,
            appVersion: "1.2",
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
                let streak = habit.streak?.currentStreak ?? 0
                
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
            csv += "\(habit.streak?.currentStreak ?? 0),\(habit.streak?.longestStreak ?? 0),"
            csv += "\(completions),\(skips),\(habit.isArchived)\n"
        }
        
        return csv.data(using: .utf8)
    }
}

// MARK: - Transferable Documents

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
