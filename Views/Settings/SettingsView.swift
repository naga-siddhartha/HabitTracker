import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var habits: [Habit]
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("defaultReminderHour") private var defaultReminderHour = 9
    @AppStorage("defaultReminderMinute") private var defaultReminderMinute = 0
    @AppStorage("weekStartsOnMonday") private var weekStartsOnMonday = false
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = true
    
    @State private var showingExportSheet = false
    @State private var showingResetAlert = false
    @State private var exportDocument: JSONDocument?
    @State private var csvDocument: CSVDocument?
    @State private var showingJSONExport = false
    @State private var showingCSVExport = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("iCloud Sync") {
                    Toggle("Sync with iCloud", isOn: $iCloudSyncEnabled)
                    
                    if iCloudSyncEnabled {
                        HStack {
                            Image(systemName: "checkmark.icloud.fill")
                                .foregroundStyle(.green)
                            Text("Syncing across devices")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("Notifications") {
                    Toggle("Enable Reminders", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                NotificationService.shared.requestAuthorization()
                            } else {
                                NotificationService.shared.cancelAllNotifications()
                            }
                        }
                    
                    if notificationsEnabled {
                        LabeledContent("Default Reminder Time") {
                            Text(String(format: "%d:%02d", defaultReminderHour, defaultReminderMinute))
                                .foregroundStyle(.secondary)
                        }
                        
                        Stepper("Hour: \(defaultReminderHour)", value: $defaultReminderHour, in: 0...23)
                        Stepper("Minute: \(defaultReminderMinute)", value: $defaultReminderMinute, in: 0...59, step: 5)
                    }
                }
                
                Section("Calendar") {
                    Toggle("Week Starts on Monday", isOn: $weekStartsOnMonday)
                }
                
                Section("Data") {
                    Button {
                        showingExportSheet = true
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        Label("Reset All Data", systemImage: "trash")
                    }
                }
                
                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Habits", value: "\(habits.count)")
                    LabeledContent("Total Entries", value: "\(habits.reduce(0) { $0 + $1.entries.count })")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Export Format", isPresented: $showingExportSheet) {
                Button("JSON (Full Backup)") {
                    if let data = ExportService.exportToJSON(habits: habits) {
                        exportDocument = JSONDocument(data: data)
                        showingJSONExport = true
                    }
                }
                Button("CSV (Entries)") {
                    if let data = ExportService.exportToCSV(habits: habits) {
                        csvDocument = CSVDocument(data: data)
                        showingCSVExport = true
                    }
                }
                Button("CSV (Summary)") {
                    if let data = ExportService.exportSummaryCSV(habits: habits) {
                        csvDocument = CSVDocument(data: data)
                        showingCSVExport = true
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .fileExporter(
                isPresented: $showingJSONExport,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "HabitTracker-\(Date.now.formatted(date: .numeric, time: .omitted)).json"
            ) { _ in }
            .fileExporter(
                isPresented: $showingCSVExport,
                document: csvDocument,
                contentType: .commaSeparatedText,
                defaultFilename: "HabitTracker-\(Date.now.formatted(date: .numeric, time: .omitted)).csv"
            ) { _ in }
            .alert("Reset All Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will delete all habits and entries. This cannot be undone.")
            }
        }
    }
    
    private func resetAllData() {
        for habit in habits {
            HabitStore.shared.deleteHabit(habit)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Habit.self, inMemory: true)
}
