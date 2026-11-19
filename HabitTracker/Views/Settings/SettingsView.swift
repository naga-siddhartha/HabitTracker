import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import WidgetKit

@available(iOS 17.0, macOS 14.0, *)
struct SettingsView: View {
    @Query private var habits: [Habit]
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system
    @AppStorage(Analytics.enabledKey) private var analyticsEnabled = true
    @ObservedObject private var purchases = PurchaseManager.shared

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
            #if os(iOS)
            removeAdsSection
            #endif
            notificationsSection
            appearanceSection
            dataSection
            privacySection
            supportSection
            aboutSection
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .alert("App Store", isPresented: Binding(
            get: { purchases.message != nil },
            set: { if !$0 { purchases.message = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchases.message ?? "")
        }
    }

    #if os(iOS)
    @ViewBuilder
    private var removeAdsSection: some View {
        Section {
            if purchases.isAdFree {
                SettingsRow(icon: "checkmark.seal.fill", iconColor: .green, title: "Ads removed") {
                    Text("Thank you!").foregroundStyle(.secondary)
                }
            } else {
                Button {
                    Task { await purchases.purchaseRemoveAds() }
                } label: {
                    SettingsRow(icon: "sparkles", iconColor: .purple, title: "Remove Ads") {
                        if purchases.isWorking {
                            ProgressView()
                        } else if let price = purchases.removeAdsProduct?.displayPrice {
                            Text(price).foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(purchases.isWorking)

                Button {
                    Task { await purchases.restore() }
                } label: {
                    SettingsRow(icon: "arrow.clockwise", iconColor: .gray, title: "Restore Purchases") {
                        EmptyView()
                    }
                }
                .buttonStyle(.plain)
                .disabled(purchases.isWorking)
            }
        } footer: {
            if !purchases.isAdFree {
                Text("One-time purchase. Also removes ads on your other devices signed in to the same Apple Account.")
            }
        }
    }
    #endif

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
                            // Turning reminders back on must restore them, not just ask permission.
                            HabitStore.shared.rescheduleAllReminders()
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

    private var privacySection: some View {
        Section {
            Toggle("Share anonymous usage stats", isOn: $analyticsEnabled)
        } header: {
            Text("Privacy")
        } footer: {
            Text("Sends one anonymous daily summary, like how many habits you have and whether reminders are on. Never your habit names, notes or history. Turning this off stops it right away.")
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
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.3").foregroundStyle(.secondary)
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
                        // Recompute streaks from the restored history instead of trusting the backup's numbers,
                        // and drop reminders for habits that no longer exist.
                        HabitStore.shared.updateAllStreaks()
                        HabitStore.shared.rescheduleAllReminders()
                        HabitStore.shared.writeWidgetData()
                        WidgetKit.WidgetCenter.shared.reloadAllTimelines()
                        importSuccess = true
                        Analytics.track(.backupRestored)
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

        if data != nil {
            Analytics.track(.backupExported(format: "\(format)"))
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
