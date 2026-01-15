import SwiftUI
import SwiftData

// MARK: - Icon Data

enum HabitIcons {
    static let keywords: [String: String] = [
        "run": "figure.run", "walk": "figure.walk", "exercise": "dumbbell.fill", "gym": "dumbbell.fill",
        "water": "drop.fill", "drink": "cup.and.saucer.fill", "sleep": "moon.fill", "wake": "sun.max.fill",
        "meditat": "brain.head.profile", "vitamin": "pills.fill", "health": "heart.fill",
        "read": "book.fill", "study": "book.fill", "write": "pencil", "journal": "pencil",
        "work": "briefcase.fill", "code": "chevron.left.forwardslash.chevron.right", "learn": "graduationcap.fill",
        "clean": "sparkles", "cook": "fork.knife", "eat": "fork.knife", "budget": "creditcard.fill",
        "call": "phone.fill", "email": "envelope.fill", "home": "house.fill",
        "gratitude": "heart.fill", "breath": "wind", "yoga": "figure.yoga", "relax": "leaf.fill"
    ]
    
    static let defaults = ["star.fill", "heart.fill", "leaf.fill", "flame.fill", "bolt.fill",
        "sparkles", "moon.fill", "sun.max.fill", "drop.fill", "figure.run"]
    
    static let all = [
        "figure.run", "figure.walk", "dumbbell.fill", "heart.fill", "book.fill",
        "pencil", "drop.fill", "moon.fill", "sun.max.fill", "leaf.fill",
        "brain.head.profile", "cup.and.saucer.fill", "fork.knife", "pills.fill",
        "creditcard.fill", "phone.fill", "envelope.fill", "house.fill",
        "star.fill", "flame.fill", "bolt.fill", "sparkles", "graduationcap.fill",
        "briefcase.fill", "music.note", "gamecontroller.fill", "paintbrush.fill", "camera.fill"
    ]
    
    static func suggest(for name: String) -> String {
        let lowercased = name.lowercased()
        for (keyword, icon) in keywords {
            if lowercased.contains(keyword) { return icon }
        }
        return defaults[abs(name.hashValue) % defaults.count]
    }
}

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
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColor: HabitColor = .blue
    @State private var selectedIcon: String = "star.fill"
    @State private var showIconPicker = false
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
        .onChange(of: name) { _, newName in
            if !isEditing && !showIconPicker {
                selectedIcon = HabitIcons.suggest(for: newName)
            }
        }
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
        
        // Appearance
        Section("Appearance") {
            Picker("Color", selection: $selectedColor) {
                ForEach(HabitColor.allCases, id: \.self) { color in
                    HStack {
                        Circle().fill(color.color).frame(width: 16, height: 16)
                        Text(color.rawValue.capitalized)
                    }.tag(color)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Icon")
                    Spacer()
                    Button {
                        withAnimation { showIconPicker.toggle() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: selectedIcon)
                                .foregroundStyle(selectedColor.color)
                            Image(systemName: showIconPicker ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                if showIconPicker {
                    IconGrid(icons: HabitIcons.all, selected: $selectedIcon, accentColor: selectedColor.color)
                        .padding(.top, 4)
                }
            }
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
        
        // Reminders (iOS only for now)
        #if os(iOS)
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
            
            Button("Add Reminder") {
                reminders.append(Reminder(name: "Reminder", time: .now, sound: .default))
            }
        }
        #endif
    }
    
    // MARK: - Data Operations
    
    private func loadHabit() {
        guard let habit else { return }
        name = habit.name
        description = habit.habitDescription ?? ""
        selectedColor = habit.color
        selectedIcon = habit.iconName ?? "star.fill"
        frequency = habit.frequency
        selectedDays = habit.activeDays
        reminders = zip(habit.reminderTimes, zip(habit.reminderNames, habit.sounds)).map {
            Reminder(name: $1.0, time: $0, sound: $1.1)
        }
    }
    
    private func saveHabit() {
        if let habit {
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
            scheduleNotifications(for: habit)
        } else {
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
