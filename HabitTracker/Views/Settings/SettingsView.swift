import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Query private var habits: [Habit]
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("weekStartsOnMonday") private var weekStartsOnMonday = false
    
    @State private var showingResetAlert = false
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var isExporting = false
    
    var body: some View {
        NavigationStack {
            List {
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
                    Menu {
                        Button("JSON (Full Backup)") { exportData(format: .json) }
                        Button("CSV (Entries)") { exportData(format: .csvEntries) }
                        Button("CSV (Summary)") { exportData(format: .csvSummary) }
                    } label: {
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
                
                Section("Support") {
                    if let privacyURL = AppLinks.privacyPolicyURL {
                        Link(destination: privacyURL) {
                            SettingsRow(icon: "hand.raised.fill", iconColor: .indigo, title: "Privacy Policy") {
                                Image(systemName: "arrow.up.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    if let supportURL = AppLinks.supportURL {
                        Link(destination: supportURL) {
                            SettingsRow(icon: "envelope.fill", iconColor: .blue, title: "Contact & Support") {
                                Image(systemName: "arrow.up.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
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
            .overlay {
                if isExporting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("Preparing export…")
                        .padding(20)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(url: url)
                }
            }
            .alert("Reset All Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { habits.forEach { HabitStore.shared.deleteHabit($0) } }
            } message: {
                Text("This will delete all habits and entries. This cannot be undone.")
            }
        }
    }
    
    private enum ExportFormat {
        case json, csvEntries, csvSummary
    }
    
    private func exportData(format: ExportFormat) {
        isExporting = true

        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let dateStr = Date.now.formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")

        let data: Data?
        let filename: String

        switch format {
        case .json:
            data = ExportService.exportToJSON(habits: habits)
            filename = "HabitTracker-\(dateStr).json"
        case .csvEntries:
            data = ExportService.exportToCSV(habits: habits)
            filename = "HabitTracker-Entries-\(dateStr).csv"
        case .csvSummary:
            data = ExportService.exportSummaryCSV(habits: habits)
            filename = "HabitTracker-Summary-\(dateStr).csv"
        }

        guard let data else {
            isExporting = false
            return
        }

        let fileURL = tempDir.appendingPathComponent(filename)

        Task.detached(priority: .userInitiated) {
            do {
                try data.write(to: fileURL)
                await MainActor.run {
                    exportURL = fileURL
                    isExporting = false
                    showingShareSheet = true
                }
            } catch {
                await MainActor.run { isExporting = false }
                print("Export failed: \(error)")
            }
        }
    }
}

// MARK: - Share Sheet

#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#elseif os(macOS)
struct ShareSheet: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Export Complete").font(.headline)
            Text(url.lastPathComponent).foregroundStyle(.secondary)
            
            HStack {
                Button("Show in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                    dismiss()
                }
                Button("Done") { dismiss() }
            }
        }
        .padding(40)
    }
}
#endif

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
