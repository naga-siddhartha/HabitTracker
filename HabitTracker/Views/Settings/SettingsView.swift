import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Query private var habits: [Habit]
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
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
                    SettingsRow(icon: "icloud.fill", iconColor: .blue, title: "iCloud Sync") {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.green)
                    }
                } footer: {
                    Text("Data syncs automatically across your devices")
                }
                
                Section {
                    SettingsRow(icon: "bell.fill", iconColor: .red, title: "Notifications") {
                        Toggle("", isOn: $notificationsEnabled)
                            .labelsHidden()
                            .onChange(of: notificationsEnabled) { _, newValue in
                                if newValue {
                                    NotificationService.shared.requestAuthorization()
                                } else {
                                    NotificationService.shared.cancelAllNotifications()
                                }
                            }
                    }
                } footer: {
                    Text("Each habit has its own reminder times")
                }
                
                Section {
                    SettingsRow(icon: "calendar", iconColor: .orange, title: "Week Starts Monday") {
                        Toggle("", isOn: $weekStartsOnMonday)
                            .labelsHidden()
                    }
                }
                
                Section("Data") {
                    Button { showingExportSheet = true } label: {
                        SettingsRow(icon: "square.and.arrow.up.fill", iconColor: .green, title: "Export Data") {
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button { showingResetAlert = true } label: {
                        SettingsRow(icon: "trash.fill", iconColor: .red, title: "Reset All Data") {
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                Section("About") {
                    SettingsRow(icon: "info.circle.fill", iconColor: .gray, title: "Version") {
                        Text("1.0.0").foregroundStyle(.secondary)
                    }
                    SettingsRow(icon: "checkmark.circle.fill", iconColor: .blue, title: "Habits") {
                        Text("\(habits.count)").foregroundStyle(.secondary)
                    }
                    SettingsRow(icon: "chart.bar.fill", iconColor: .purple, title: "Total Entries") {
                        Text("\(habits.reduce(0) { $0 + $1.entries.count })").foregroundStyle(.secondary)
                    }
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
            .fileExporter(isPresented: $showingJSONExport, document: exportDocument, contentType: .json, defaultFilename: "HabitTracker-\(Date.now.formatted(date: .numeric, time: .omitted)).json") { _ in }
            .fileExporter(isPresented: $showingCSVExport, document: csvDocument, contentType: .commaSeparatedText, defaultFilename: "HabitTracker-\(Date.now.formatted(date: .numeric, time: .omitted)).csv") { _ in }
            .alert("Reset All Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { habits.forEach { HabitStore.shared.deleteHabit($0) } }
            } message: {
                Text("This will delete all habits and entries. This cannot be undone.")
            }
        }
    }
}

struct SettingsRow<Accessory: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder let accessory: () -> Accessory
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Text(title)
            Spacer()
            accessory()
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Habit.self, inMemory: true)
}
