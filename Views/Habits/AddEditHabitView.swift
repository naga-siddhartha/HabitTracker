import SwiftUI

struct AddEditHabitView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var habitService = HabitService.shared
    @StateObject private var notificationService = NotificationService.shared
    
    let habit: Habit?
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var selectedColor: HabitColor = .blue
    @State private var frequency: HabitFrequency = .daily
    @State private var selectedDays: Set<Weekday> = []
    @State private var customPattern: String = ""
    @State private var patternMapping: [String: String] = [:]
    @State private var reminderTimes: [Date] = []
    @State private var showingReminderPicker = false
    
    init(habit: Habit? = nil) {
        self.habit = habit
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Habit Name", text: $name)
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Appearance") {
                    Picker("Color", selection: $selectedColor) {
                        ForEach(HabitColor.allCases, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 20, height: 20)
                                Text(color.rawValue.capitalized)
                            }
                            .tag(color)
                        }
                    }
                }
                
                Section("Frequency") {
                    Picker("Frequency", selection: $frequency) {
                        Text("Daily").tag(HabitFrequency.daily)
                        Text("Weekly").tag(HabitFrequency.weekly)
                        Text("Custom Pattern").tag(HabitFrequency.custom)
                    }
                    
                    if frequency == .weekly {
                        ForEach(Weekday.allCases, id: \.self) { day in
                            Toggle(day.fullName, isOn: Binding(
                                get: { selectedDays.contains(day) },
                                set: { isOn in
                                    if isOn {
                                        selectedDays.insert(day)
                                    } else {
                                        selectedDays.remove(day)
                                    }
                                }
                            ))
                        }
                    }
                    
                    if frequency == .custom {
                        TextField("Pattern (e.g., ULRULRR)", text: $customPattern)
                            .textInputAutocapitalization(.never)
                        
                        Text("Enter a pattern where each character represents a day. The pattern repeats weekly.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Pattern mapping editor
                        if !customPattern.isEmpty {
                            Text("Pattern Mapping")
                                .font(.headline)
                                .padding(.top)
                            
                            ForEach(Array(Set(customPattern.map { String($0) })), id: \.self) { char in
                                HStack {
                                    Text(char)
                                        .font(.title2)
                                        .frame(width: 30)
                                    TextField("Description", text: Binding(
                                        get: { patternMapping[char] ?? "" },
                                        set: { patternMapping[char] = $0 }
                                    ))
                                }
                            }
                        }
                    }
                }
                
                Section("Reminders") {
                    ForEach(reminderTimes.indices, id: \.self) { index in
                        DatePicker("Reminder \(index + 1)", selection: Binding(
                            get: { reminderTimes[index] },
                            set: { reminderTimes[index] = $0 }
                        ), displayedComponents: .hourAndMinute)
                    }
                    
                    Button("Add Reminder") {
                        reminderTimes.append(Date())
                    }
                    
                    if !reminderTimes.isEmpty {
                        Button("Remove Last Reminder", role: .destructive) {
                            if !reminderTimes.isEmpty {
                                reminderTimes.removeLast()
                            }
                        }
                    }
                }
            }
            .navigationTitle(habit == nil ? "New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveHabit()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let habit = habit {
                    loadHabit(habit)
                }
            }
        }
    }
    
    private func loadHabit(_ habit: Habit) {
        name = habit.name
        description = habit.description ?? ""
        selectedColor = habit.color
        frequency = habit.frequency
        selectedDays = habit.activeDays ?? []
        customPattern = habit.customPattern ?? ""
        patternMapping = habit.patternMapping ?? [:]
        reminderTimes = habit.reminderTimes.isEmpty ? [Date()] : habit.reminderTimes
    }
    
    private func saveHabit() {
        let activeDays = frequency == .weekly && !selectedDays.isEmpty ? selectedDays : nil
        let pattern = frequency == .custom && !customPattern.isEmpty ? customPattern : nil
        let mapping = frequency == .custom && !patternMapping.isEmpty ? patternMapping : nil
        
        let newHabit = Habit(
            id: habit?.id ?? UUID(),
            name: name,
            description: description.isEmpty ? nil : description,
            color: selectedColor,
            frequency: frequency,
            reminderTimes: reminderTimes,
            activeDays: activeDays,
            customPattern: pattern,
            patternMapping: mapping,
            createdAt: habit?.createdAt ?? Date(),
            updatedAt: Date(),
            isArchived: habit?.isArchived ?? false
        )
        
        if let existingHabit = habit {
            habitService.updateHabit(newHabit)
            notificationService.removeReminders(for: existingHabit.id)
        } else {
            habitService.addHabit(newHabit)
        }
        
        notificationService.scheduleReminders(for: newHabit)
        dismiss()
    }
}

#Preview {
    AddEditHabitView()
}
