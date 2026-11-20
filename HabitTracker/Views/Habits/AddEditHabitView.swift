import SwiftUI
import SwiftData

// MARK: - Reminder Model

struct Reminder: Identifiable {
    let id = UUID()
    var name: String
    var time: Date
    var sound: ReminderSound
}

// MARK: - Add/Edit Habit View

/// Form for creating or editing a habit.
///
/// Split across files: schedule and reminders in `AddEditHabitView+Schedule.swift`, color and
/// emoji in `AddEditHabitView+Appearance.swift`. Members are internal (not private) so those
/// extensions can reach the form state.
struct AddEditHabitView: View {
    @Environment(\.dismiss) var dismiss
    var habit: Habit?
    var template: HabitTemplate? = nil
    
    @State var name = ""
    @State var description = ""
    @State var selectedColor: HabitColor = .blue
    @State var selectedCustomColor = Color.blue
    @State var selectedEmoji: String? = nil
    @State var showingEmojiPickerSheet = false
    @State var showingColorPickerSheet = false
    @State var anyEmojiText = ""
    @State var frequency: HabitFrequency = .daily
    @State var selectedDays: Set<Weekday> = []
    @State var reminders: [Reminder] = []
    @State var reminderIntervalMinutes: Int = 0
    @State var reminderEndTime: Date = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    @State var useRepeatingReminders: Bool = false
    // Custom interval state
    @State var intervalHours: Int = 2
    @State var intervalMinutes: Int = 0

    @Query var allHabits: [Habit]

    var isEditing: Bool { habit != nil }
    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    /// Habits are identified by name across devices (duplicates get merged), so block reusing one.
    var nameTaken: Bool {
        !trimmedName.isEmpty && allHabits.contains {
            $0.id != habit?.id && $0.name.trimmingCharacters(in: .whitespacesAndNewlines) == trimmedName
        }
    }
    var suggestedEmoji: String { HabitEmoji.suggest(for: name, description: description.isEmpty ? nil : description) }
    
    var body: some View {
        AdaptiveForm(
            title: isEditing ? "Edit Habit" : "New Habit",
            onCancel: { dismiss() },
            onSave: saveHabit,
            saveDisabled: trimmedName.isEmpty || nameTaken
        ) {
            formContent
        }
        .onAppear { loadHabit() }
        .sheet(isPresented: $showingEmojiPickerSheet) {
            emojiPickerSheet
        }
        .sheet(isPresented: $showingColorPickerSheet) {
            colorPickerSheet
        }
    }
    
    // MARK: - Form Content
    
    @ViewBuilder
    var formContent: some View {
        Section {
            TextField("Habit Name", text: $name)
            TextField("Note (Optional)", text: $description, axis: .vertical)
                .lineLimit(2...4)
        } header: {
            Text("Basic Information")
        } footer: {
            if nameTaken {
                Text("You already have a habit called “\(trimmedName)”.")
                    .foregroundStyle(.red)
            }
        }
        #if os(macOS)
        .padding(.bottom, LayoutConfig.current.formSectionSpacing)
        #endif

        Section("Appearance") {
            colorRow
            emojiRow
        }
        #if os(macOS)
        .padding(.bottom, LayoutConfig.current.formSectionSpacing)
        #endif

        #if os(macOS)
        frequencyAndRemindersMac
        #else
        Section("Schedule") {
            scheduleContent
        }
        #endif
    }

    // MARK: - Data Operations
    
    func loadHabit() {
        if let habit {
            name = habit.name
            description = habit.habitDescription ?? ""
            selectedColor = habit.color
            if habit.color == .custom, let hex = habit.customColorHex {
                selectedCustomColor = Color(hex: hex) ?? .blue
            }
            let suggested = HabitEmoji.suggest(for: habit.name, description: habit.habitDescription)
            if habit.emoji == suggested {
                selectedEmoji = nil
            } else {
                selectedEmoji = habit.emoji
            }
            frequency = habit.frequency
            selectedDays = habit.frequency == .weekly && habit.activeDays.isEmpty
                ? Set(Weekday.allCases)
                : habit.activeDays
            reminders = zip(habit.reminderTimes, zip(habit.reminderNames, habit.sounds)).map {
                Reminder(name: $1.0, time: $0, sound: $1.1)
            }
            reminderIntervalMinutes = habit.reminderIntervalMinutes
            reminderEndTime = habit.reminderEndTime ?? Self.defaultEndTime
            useRepeatingReminders = habit.reminderIntervalMinutes > 0
            syncStateFromInterval()
            if useRepeatingReminders && reminders.isEmpty {
                reminders = [Reminder(
                    name: habit.reminderNames.first ?? "Reminder",
                    time: habit.reminderTimes.first ?? Self.defaultStartTime,
                    sound: habit.sounds.first ?? .default
                )]
            }
        } else if let template {
            name = template.name
            description = template.description ?? ""
            selectedColor = template.color
            selectedEmoji = nil
        }
    }
    
    var resolvedEmoji: String {
        if let emoji = selectedEmoji, !emoji.isEmpty { return emoji }
        return suggestedEmoji
    }
    
    func saveHabit() {
        guard !trimmedName.isEmpty, !nameTaken else { return }
        syncIntervalFromState()
        
        if let habit {
            habit.name = trimmedName
            habit.habitDescription = description.isEmpty ? nil : description
            habit.emoji = resolvedEmoji
            habit.color = selectedColor
            habit.customColorHex = selectedColor == .custom ? selectedCustomColor.toHex() : nil
            habit.frequency = frequency
            habit.activeDays = frequency == .weekly ? (selectedDays.isEmpty ? Set(Weekday.allCases) : selectedDays) : []
            habit.reminderTimes = reminders.map(\.time)
            habit.reminderNames = reminders.map(\.name)
            habit.sounds = reminders.map(\.sound)
            habit.reminderIntervalMinutes = useRepeatingReminders ? reminderIntervalMinutes : 0
            habit.reminderEndTime = useRepeatingReminders ? reminderEndTime : nil
            habit.updatedAt = .now
        } else {
            let newHabit = Habit(
                name: trimmedName,
                description: description.isEmpty ? nil : description,
                iconName: template?.iconName,
                emoji: resolvedEmoji,
                color: selectedColor,
                frequency: frequency,
                reminderTimes: reminders.map(\.time),
                reminderNames: reminders.map(\.name),
                reminderSounds: reminders.map(\.sound),
                activeDays: frequency == .weekly ? (selectedDays.isEmpty ? Set(Weekday.allCases) : selectedDays) : [],
                reminderIntervalMinutes: useRepeatingReminders ? reminderIntervalMinutes : 0,
                reminderEndTime: useRepeatingReminders ? reminderEndTime : nil
            )
            if selectedColor == .custom {
                newHabit.customColorHex = selectedCustomColor.toHex()
            }
            HabitStore.shared.addHabit(newHabit)
            Analytics.track(.habitCreated(
                fromTemplate: template != nil,
                hasReminder: !reminders.isEmpty || useRepeatingReminders,
                isInterval: useRepeatingReminders,
                isWeekly: frequency == .weekly
            ))
        }
        HabitStore.shared.save()
        HabitStore.shared.rescheduleAllReminders()
        dismiss()
    }
}

#Preview {
    AddEditHabitView().modelContainer(for: Habit.self, inMemory: true)
}
