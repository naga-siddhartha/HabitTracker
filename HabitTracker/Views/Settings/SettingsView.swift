import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import WidgetKit

@available(iOS 17.0, macOS 14.0, *)
struct SettingsView: View {
    @Query private var habits: [Habit]
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system

    var onRequestReset: (() -> Void)? = nil

    @State private var showingResetAlert = false
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var showingAccountSettings = false
    @State private var showingRestoreConfirmation = false
    @State private var restoreURL: URL?
    @State private var isImporting = false
    @State private var importError: String?
    @State private var showingImportErrorAlert = false
    @State private var importSuccess = false
    @State private var showingFileImporter = false
    @State private var exportError: String?
    @State private var showingExportErrorAlert = false
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("")
                .inlineNavigationTitle()
                .sheet(isPresented: $showingAccountSettings) {
                    AccountSettingsView()
                }
                .sheet(isPresented: $showingShareSheet) {
                    if let url = exportURL {
                        ShareSheet(url: url)
                    }
                }
                .alert("Reset All Data?", isPresented: $showingResetAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Reset", role: .destructive) {
                        DispatchQueue.main.async {
                            onRequestReset?()
                        }
                    }
                } message: {
                    Text("This will delete all habits and entries. This cannot be undone.")
                }
                .fileImporter(
                    isPresented: $showingFileImporter,
                    allowedContentTypes: [.json],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        guard let url = urls.first else { return }
                        restoreURL = url
                        showingRestoreConfirmation = true
                    case .failure:
                        importError = "Could not open file."
                    }
                }
                .alert("Restore from backup?", isPresented: $showingRestoreConfirmation) {
                    Button("Cancel", role: .cancel) { restoreURL = nil }
                    Button("Restore", role: .destructive) {
                        performRestore()
                    }
                } message: {
                    Text("This will replace all current habits and entries with the backup. This cannot be undone.")
                }
                .alert("Restore failed", isPresented: $showingImportErrorAlert) {
                    Button("Retry") { retryImport() }
                    Button("OK") { importError = nil }
                } message: {
                    if let importError { Text(importError) }
                }
                .alert("Export failed", isPresented: $showingExportErrorAlert) {
                    Button("OK") { exportError = nil }
                } message: {
                    if let exportError { Text(exportError) }
                }
                .alert("Restore complete", isPresented: $importSuccess) {
                    Button("OK") { importSuccess = false }
                } message: {
                    Text("Your habits have been restored from the backup.")
                }
        }
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            PageHeading(title: "Settings")
                .padding(.bottom, 4)
            settingsList
        }
        .overlay { exportOverlay }
    }

    private var settingsList: some View {
        List {
            accountSection
            notificationsSection
            appearanceSection
            dataSection
            supportSection
            aboutSection
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
    }

    @ViewBuilder
    private var accountSection: some View {
        Section {
            Button {
                showingAccountSettings = true
            } label: {
                SettingsRow(icon: "person.crop.circle.fill", iconColor: .blue, title: "Account settings") {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var chevronAccessory: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
    }

    @ViewBuilder
    private var notificationsSection: some View {
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
    }

    private var appearanceSection: some View {
        Section(header: Text("Appearance")) {
            Picker("Theme", selection: $appearanceMode) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
            .alignmentGuide(.listRowSeparatorTrailing) { d in d[.trailing] }
        }
    }

    private var dataSection: some View {
        Section(header: Text("Data")) {
            Menu {
                Button("JSON (Full Backup)") { exportData(format: .json) }
                Button("CSV (Entries)") { exportData(format: .csvEntries) }
                Button("CSV (Summary)") { exportData(format: .csvSummary) }
            } label: {
                SettingsRow(icon: "square.and.arrow.up.fill", iconColor: .green, title: "Export Data") {
                    chevronAccessory
                }
            }
            .buttonStyle(.plain)

            Button {
                showingFileImporter = true
            } label: {
                SettingsRow(icon: "square.and.arrow.down.fill", iconColor: .indigo, title: "Restore from backup") {
                    if isImporting {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        chevronAccessory
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isImporting)

            Button { showingResetAlert = true } label: {
                SettingsRow(icon: "trash.fill", iconColor: .red, title: "Reset All Data") {
                    chevronAccessory
                }
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var supportSection: some View {
        Section(header: Text("Support")) {
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
    }

    private var aboutSection: some View {
        Section(header: Text("About")) {
            SettingsRow(icon: "info.circle.fill", iconColor: .gray, title: "Version") {
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.2").foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var exportOverlay: some View {
        if isExporting {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            ProgressView("Preparing export…")
                .padding(20)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func performRestore() {
        guard let url = restoreURL else { return }
        restoreURL = nil
        isImporting = true
        importError = nil
        Task {
            do {
                let data: Data
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    data = try Data(contentsOf: url)
                } else {
                    data = try Data(contentsOf: url)
                }
                let exportData = try ImportService.parseExportData(data)
                await MainActor.run {
                    do {
                        try ImportService.replaceAllAndRestore(from: exportData, context: HabitStore.shared.modelContext)
                        HabitStore.shared.writeWidgetData()
                        WidgetKit.WidgetCenter.shared.reloadAllTimelines()
                        importSuccess = true
                    } catch {
                        importError = error.localizedDescription
                        showingImportErrorAlert = true
                    }
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    importError = error.localizedDescription
                    showingImportErrorAlert = true
                    isImporting = false
                }
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
            filename = "HabitGrabIt-\(dateStr).json"
        case .csvEntries:
            data = ExportService.exportToCSV(habits: habits)
            filename = "HabitGrabIt-Entries-\(dateStr).csv"
        case .csvSummary:
            data = ExportService.exportSummaryCSV(habits: habits)
            filename = "HabitGrabIt-Summary-\(dateStr).csv"
        }

        guard let data else {
            isExporting = false
            exportError = "Could not prepare export data."
            showingExportErrorAlert = true
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
                await MainActor.run {
                    isExporting = false
                    exportError = "Export failed: \(error.localizedDescription)"
                    showingExportErrorAlert = true
                }
            }
        }
    }
    
    private func retryImport() {
        showingImportErrorAlert = false
        importError = nil
        showingFileImporter = true
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
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
        .alignmentGuide(.listRowSeparatorTrailing) { d in d[.trailing] }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Habit.self, inMemory: true)
}
