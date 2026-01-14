import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Query private var habits: [Habit]
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("defaultReminderHour") private var defaultReminderHour = 9
    @AppStorage("defaultReminderMinute") private var defaultReminderMinute = 0
    @AppStorage("weekStartsOnMonday") private var weekStartsOnMonday = false
    
    @State private var showingExportSheet = false
    @State private var showingResetAlert = false
    @State private var exportDocument: JSONDocument?
    @State private var csvDocument: CSVDocument?
    @State private var showingJSONExport = false
    @State private var showingCSVExport = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "icloud.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                            .frame(width: 50, height: 50)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("iCloud Sync")
                                .font(.headline)
                            Text("Data syncs automatically across all your devices signed into the same iCloud account")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Sync")
                }
                
                Section {
                    Toggle("Enable Reminders", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                NotificationService.shared.requestAuthorization()
                            } else {
                                NotificationService.shared.cancelAllNotifications()
                            }
                        }
                    
                    if notificationsEnabled {
                        HStack {
                            Text("Default Time")
                            Spacer()
                            Text(String(format: "%d:%02d AM", defaultReminderHour > 12 ? defaultReminderHour - 12 : (defaultReminderHour == 0 ? 12 : defaultReminderHour), defaultReminderMinute))
                                .foregroundStyle(.secondary)
                        }
                        
                        Stepper("Hour: \(defaultReminderHour)", value: $defaultReminderHour, in: 0...23)
                        Stepper("Minute: \(defaultReminderMinute)", value: $defaultReminderMinute, in: 0...59, step: 5)
                    }
                } header: {
                    Text("Notifications")
                }
                
                Section {
                    Toggle("Week Starts on Monday", isOn: $weekStartsOnMonday)
                } header: {
                    Text("Calendar")
                }
                
                Section {
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
                } header: {
                    Text("Data")
                }
                
                Section {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Habits", value: "\(habits.count)")
                    LabeledContent("Total Entries", value: "\(habits.reduce(0) { $0 + $1.entries.count })")
                } header: {
                    Text("About")
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
