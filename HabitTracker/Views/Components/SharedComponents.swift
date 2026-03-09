import SwiftUI
import SwiftData

// MARK: - Icon Circle

struct IconCircle: View {
    let iconName: String?
    var emoji: String? = nil
    let color: Color
    var size: CGFloat = 48
    var isCompleted: Bool = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(isCompleted ? 1 : 0.15))
                .frame(width: size, height: size)
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.375, weight: .bold))
                    .foregroundStyle(.white)
            } else if let emoji, !emoji.isEmpty {
                Text(emoji).font(.system(size: size * 0.5))
            } else if let iconName {
                Image(systemName: iconName)
                    .font(.system(size: size * 0.42))
                    .foregroundStyle(color)
            }
        }
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double
    let count: Int
    let total: Int
    var size: CGFloat = 56
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.systemGray5, lineWidth: 6)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(progress == 1 ? Color.green : Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.5), value: progress)
            VStack(spacing: 0) {
                Text("\(count)")
                    .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text("/\(total)")
                    .font(.system(size: size * 0.2, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Today's progress")
        .accessibilityValue("\(count) of \(total) habits completed")
    }
}

// MARK: - Habit Details Sheet (read-only, all edit fields)

@available(iOS 17.0, macOS 14.0, *)
struct HabitDetailsSheetView: View {
    @Bindable var habit: Habit
    var onDismiss: () -> Void = {}

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard
                    if habit.habitDescription.flatMap({ !$0.isEmpty }) == true {
                        sectionCard(title: "Description", systemImage: "text.alignleft") {
                            Text(habit.habitDescription ?? "")
                                .font(.body)
                                .lineSpacing(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    sectionCard(title: "Schedule", systemImage: "calendar") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(habit.frequency == .daily ? "Daily" : "Weekly")
                                .font(.body.weight(.medium))
                            if habit.frequency == .weekly && !habit.activeDays.isEmpty {
                                Text(habit.activeDays.sorted(by: { $0.rawValue < $1.rawValue }).map(\.fullName).joined(separator: ", "))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if !habit.reminderTimes.isEmpty {
                        sectionCard(title: "Reminders", systemImage: "bell") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(habit.reminderTimes.enumerated()), id: \.offset) { index, time in
                                    HStack {
                                        Text((index < habit.reminderNames.count && !habit.reminderNames[index].isEmpty) ? habit.reminderNames[index] : "Reminder")
                                            .font(.subheadline.weight(.medium))
                                        Spacer()
                                        Text(time, format: .dateTime.hour().minute())
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.appGroupedBackground)
            .navigationTitle(habit.name)
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onDismiss)
                }
            }
        }
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            if let emoji = habit.emoji, !emoji.isEmpty {
                Text(emoji).font(.system(size: 44))
            } else {
                Circle()
                    .fill(habit.color.color.opacity(0.2))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: habit.iconName ?? "circle.fill")
                            .font(.title2)
                            .foregroundStyle(habit.color.color)
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.title2.weight(.semibold))
                Text(habit.color.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func sectionCard<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Habit Sheet Modifier (details + edit)

extension View {
    @ViewBuilder
    func habitSheets(details: Binding<Habit?>, editing: Binding<Habit?>) -> some View {
        self
            .sheet(item: details) { habit in
                HabitDetailsSheetView(habit: habit) { details.wrappedValue = nil }
            }
            .sheet(item: editing) { habit in
                AddEditHabitView(habit: habit)
            }
    }
}

// MARK: - Calendar Empty State

struct CalendarEmptyState: View {
    let icon: String
    let title: String
    let message: String

    private let config = LayoutConfig.current

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(.secondary.opacity(0.7))
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.vertical, 28)
        .padding(.horizontal, config.horizontalPadding)
    }
}

// MARK: - Skip reason sheet (shared)

struct SkipReasonSheetItem: Identifiable {
    let habit: Habit
    let date: Date
    var id: String { "\(habit.id.uuidString)-\(date.timeIntervalSince1970)" }
}

struct SkipReasonSheetView: View {
    let habit: Habit
    let date: Date
    var onDismiss: () -> Void
    @State private var reasonText = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Reason (optional)", text: $reasonText)
                } footer: {
                    Text("Skipping doesn’t break your streak. Your progress is preserved.")
                        .font(.footnote)
                }
            }
            .navigationTitle("Skip day")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss(); onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Skip") {
                        HabitStore.shared.skipDay(for: habit, on: date, reason: reasonText.isEmpty ? nil : reasonText)
                        dismiss()
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Habit Row Actions (shared Menu / contextMenu content)

struct HabitRowActions: View {
    var onViewDetails: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    /// When true, show Skip / Unskip based on isSkippedOnDate.
    var showSkipUnskip: Bool = false
    var isSkippedOnDate: Bool = false
    var onSkip: (() -> Void)? = nil
    var onUnskip: (() -> Void)? = nil
    var onSkipWithReason: (() -> Void)? = nil

    var body: some View {
        if onViewDetails != nil {
            Button(action: { onViewDetails?() }) { Label("View details", systemImage: "doc.text") }
            Divider()
        }
        if showSkipUnskip {
            if isSkippedOnDate {
                Button(action: { onUnskip?() }) { Label("Unskip day", systemImage: "arrow.uturn.backward") }
                Divider()
            } else {
                Button(action: { onSkip?() }) { Label("Skip day", systemImage: "pause.circle") }
                if onSkipWithReason != nil {
                    Button(action: { onSkipWithReason?() }) { Label("Skip day with reason", systemImage: "pause.circle.badge.questionmark") }
                }
                Divider()
            }
        }
        if onEdit != nil {
            Button(action: { onEdit?() }) { Label("Edit", systemImage: "pencil") }
            Divider()
        }
        if onDelete != nil {
            Button(role: .destructive, action: { onDelete?() }) { Label("Delete", systemImage: "trash") }
        }
    }
}
