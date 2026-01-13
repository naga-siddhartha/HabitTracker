import SwiftUI
import SwiftData

struct Reminder: Identifiable {
    let id = UUID()
    var name: String
    var time: Date
    var sound: ReminderSound
}

struct AddEditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var habit: Habit?
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColor: HabitColor = .blue
    @State private var selectedIcon: String?
    @State private var frequency: HabitFrequency = .daily
    @State private var selectedDays: Set<Weekday> = []
    @State private var reminders: [Reminder] = []
    
    private var isEditing: Bool { habit != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Habit Name", text: $name)
                        .onChange(of: name) { _, newValue in
                            if selectedIcon == nil && !newValue.isEmpty {
                                selectedIcon = IconGenerationService.shared.generateLocalIcon(for: newValue)
                            }
                        }
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Appearance") {
                    Picker("Color", selection: $selectedColor) {
                        ForEach(HabitColor.allCases, id: \.self) { color in
                            Label(color.rawValue.capitalized, systemImage: "circle.fill")
                                .foregroundStyle(color.color)
                                .tag(color)
                        }
                    }
                    
                    if let icon = selectedIcon {
                        LabeledContent("Icon") {
                            Image(systemName: icon)
                                .foregroundStyle(selectedColor.color)
                                .font(.title2)
                        }
                    }
                }
                
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
                
                Section("Reminders") {
                    ForEach($reminders) { $reminder in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Reminder Name", text: $reminder.name)
                            DatePicker("Time", selection: $reminder.time, displayedComponents: .hourAndMinute)
                            Picker("Sound", selection: $reminder.sound) {
                                ForEach(ReminderSound.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { reminders.remove(atOffsets: $0) }
                    
                    Button("Add Reminder") {
                        reminders.append(Reminder(name: "Reminder", time: .now, sound: .default))
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveHabit() }
                        .disabled(name.isEmpty)
                }
            }
            .onAppear { loadHabit() }
        }
    }
    
    private func loadHabit() {
        guard let habit else { return }
        name = habit.name
        description = habit.habitDescription ?? ""
        selectedColor = habit.color
        selectedIcon = habit.iconName
        frequency = habit.frequency
        selectedDays = habit.activeDays
        reminders = zip(habit.reminderTimes, zip(habit.reminderNames, habit.sounds)).map { time, pair in
            Reminder(name: pair.0, time: time, sound: pair.1)
        }
    }
    
    private func saveHabit() {
        if let habit {
            // Update existing
            habit.name = name
            habit.habitDescription = description.isEmpty ? nil : description
            habit.iconName = selectedIcon
            habit.color = selectedColor
            habit.frequency = frequency
            habit.activeDays = frequency == .weekly ? selectedDays : []
            habit.reminderTimes = reminders.map(\.time)
            habit.reminderNames = reminders.map(\.name)
            habit.sounds = reminders.map(\.sound)
            habit.updatedAt = .now
            
            NotificationService.shared.removeReminders(for: habit.id)
        } else {
            // Create new
            let newHabit = Habit(
                name: name,
                description: description.isEmpty ? nil : description,
                iconName: selectedIcon,
                color: selectedColor,
                frequency: frequency,
                reminderTimes: reminders.map(\.time),
                reminderNames: reminders.map(\.name),
                reminderSounds: reminders.map(\.sound),
                activeDays: frequency == .weekly ? selectedDays : []
            )
            HabitStore.shared.addHabit(newHabit)
            scheduleNotifications(for: newHabit)
        }
        
        if let habit {
            scheduleNotifications(for: habit)
        }
        
        HabitStore.shared.save()
        dismiss()
    }
    
    private func scheduleNotifications(for habit: Habit) {
        // Convert to notification-compatible format
        let notifHabit = NotificationHabit(
            id: habit.id,
            name: habit.name,
            frequency: habit.frequency,
            reminderTimes: habit.reminderTimes,
            reminderNames: habit.reminderNames,
            reminderSounds: habit.sounds,
            activeDays: habit.activeDays
        )
        NotificationService.shared.scheduleReminders(for: notifHabit)
    }
}

#Preview {
    AddEditHabitView()
        .modelContainer(for: Habit.self, inMemory: true)
}
