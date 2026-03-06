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

struct AddEditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    var habit: Habit?
    var template: HabitTemplate? = nil
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColor: HabitColor = .blue
    @State private var frequency: HabitFrequency = .daily
    @State private var selectedDays: Set<Weekday> = []
    @State private var reminders: [Reminder] = []
    
    private var isEditing: Bool { habit != nil }
    
    var body: some View {
        AdaptiveForm(
            title: isEditing ? "Edit Habit" : "New Habit",
            onCancel: { dismiss() },
            onSave: saveHabit,
            saveDisabled: name.isEmpty
        ) {
            formContent
        }
        .onAppear { loadHabit() }
    }
    
    // MARK: - Form Content
    
    @ViewBuilder
    private var formContent: some View {
        // Basic Info
        Section("Basic Information") {
            TextField("Habit Name", text: $name)
            TextField("Description (Optional)", text: $description, axis: .vertical)
                .lineLimit(2...4)
        }
        
        // Frequency
        Section("Frequency") {
            Picker("Frequency", selection: $frequency) {
                Text("Daily").tag(HabitFrequency.daily)
                Text("Weekly").tag(HabitFrequency.weekly)
            }
            
            if frequency == .weekly {
                ForEach(Weekday.allCases, id: \.self) { day in
                    Toggle(day.fullName, isOn: Binding(
                        get: { selectedDays.contains(day) },
                        set: { if $0 { selectedDays.insert(day) } else { selectedDays.remove(day) } }
                    ))
                }
            }
        }
        
        // Reminders (name, time, sound; supports multiple per habit)
        Section("Reminders") {
            ForEach($reminders) { $reminder in
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Reminder Name", text: $reminder.name)
                    DatePicker("Time", selection: $reminder.time, displayedComponents: [.hourAndMinute])
                    Picker("Sound", selection: $reminder.sound) {
                        ForEach(ReminderSound.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                }
            }
            .onDelete { reminders.remove(atOffsets: $0) }
            
            if reminders.isEmpty {
                Button("Add Reminder") {
                    reminders.append(Reminder(name: "Reminder", time: .now, sound: .default))
                }
            }
        }
    }
    
    // MARK: - Data Operations
    
    private func loadHabit() {
        if let habit {
            name = habit.name
            description = habit.habitDescription ?? ""
            selectedColor = habit.color
            frequency = habit.frequency
            // Weekly with no days = show all days selected so the habit stays visible until user picks days
            selectedDays = habit.frequency == .weekly && habit.activeDays.isEmpty
                ? Set(Weekday.allCases)
                : habit.activeDays
            reminders = zip(habit.reminderTimes, zip(habit.reminderNames, habit.sounds)).map {
                Reminder(name: $1.0, time: $0, sound: $1.1)
            }
        } else if let template {
            name = template.name
            description = template.description ?? ""
            selectedColor = template.color
        }
    }
    
    private func saveHabit() {
        if let habit {
            habit.name = name
            habit.habitDescription = description.isEmpty ? nil : description
            habit.emoji = HabitEmoji.suggest(for: name, description: description.isEmpty ? nil : description)
            habit.color = selectedColor
            habit.frequency = frequency
            // Weekly with no days selected = show every day so the habit doesn’t disappear from Home
            habit.activeDays = frequency == .weekly ? (selectedDays.isEmpty ? Set(Weekday.allCases) : selectedDays) : []
            habit.reminderTimes = reminders.map(\.time)
            habit.reminderNames = reminders.map(\.name)
            habit.sounds = reminders.map(\.sound)
            habit.updatedAt = .now
            NotificationService.shared.removeReminders(for: habit.id)
            scheduleNotifications(for: habit)
        } else {
            let newHabit = Habit(
                name: name,
                description: description.isEmpty ? nil : description,
                iconName: template?.iconName,
                emoji: HabitEmoji.suggest(for: name, description: description.isEmpty ? nil : description),
                color: selectedColor,
                frequency: frequency,
                reminderTimes: reminders.map(\.time),
                reminderNames: reminders.map(\.name),
                reminderSounds: reminders.map(\.sound),
                activeDays: frequency == .weekly ? (selectedDays.isEmpty ? Set(Weekday.allCases) : selectedDays) : []
            )
            HabitStore.shared.addHabit(newHabit)
            scheduleNotifications(for: newHabit)
        }
        HabitStore.shared.save()
        dismiss()
    }
    
    private func scheduleNotifications(for habit: Habit) {
        NotificationService.shared.scheduleReminders(for: NotificationHabit(
            id: habit.id, name: habit.name, frequency: habit.frequency,
            reminderTimes: habit.reminderTimes, reminderNames: habit.reminderNames,
            reminderSounds: habit.sounds, activeDays: habit.activeDays
        ))
    }
}

#Preview {
    AddEditHabitView().modelContainer(for: Habit.self, inMemory: true)
}
