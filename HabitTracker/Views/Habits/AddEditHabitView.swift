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
    @State private var selectedCustomColor = Color.blue
    @State private var selectedEmoji: String? = nil
    @State private var showingEmojiPickerSheet = false
    @State private var showingColorPickerSheet = false
    @State private var anyEmojiText = ""  // for "use any emoji" field (system keyboard)
    @State private var frequency: HabitFrequency = .daily
    @State private var selectedDays: Set<Weekday> = []
    @State private var reminders: [Reminder] = []
    
    private var isEditing: Bool { habit != nil }
    private var suggestedEmoji: String { HabitEmoji.suggest(for: name, description: description.isEmpty ? nil : description) }
    
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
        .sheet(isPresented: $showingEmojiPickerSheet) {
            emojiPickerSheet
        }
        .sheet(isPresented: $showingColorPickerSheet) {
            colorPickerSheet
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
        #if os(macOS)
        .padding(.bottom, LayoutConfig.current.formSectionSpacing)
        #endif

        // Appearance (color + emoji)
        Section("Appearance") {
            colorRow
            emojiRow
        }
        #if os(macOS)
        .padding(.bottom, LayoutConfig.current.formSectionSpacing)
        #endif

        #if os(macOS)
        // macOS: Frequency and Reminders side by side
        frequencyAndRemindersMac
        #else
        // iOS: stacked sections
        Section("Frequency") {
            frequencyContent
        }
        Section("Reminders") {
            remindersContent
        }
        #endif
    }

    @ViewBuilder
    private var frequencyContent: some View {
        Picker("Repeat", selection: $frequency) {
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

    @ViewBuilder
    private var remindersContent: some View {
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

    #if os(macOS)
    private var frequencyAndRemindersMac: some View {
        let config = LayoutConfig.current
        return HStack(alignment: .top, spacing: config.spacingXL) {
            VStack(alignment: .leading, spacing: config.spacingM) {
                Text("Frequency")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                frequencyContent
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: config.spacingM) {
                Text("Reminders")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                remindersContent
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, config.formSectionSpacing)
    }
    #endif

    private var presetColors: [HabitColor] {
        HabitColor.allCases.filter { $0 != .custom }
    }

    private var currentDisplayColor: Color {
        selectedColor == .custom ? selectedCustomColor : selectedColor.color
    }

    @ViewBuilder
    private var colorRow: some View {
        Button {
            DispatchQueue.main.async { showingColorPickerSheet = true }
        } label: {
            HStack {
                Text("Color")
                Spacer()
                Circle()
                    .fill(currentDisplayColor)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .strokeBorder(.secondary.opacity(0.5), lineWidth: 1)
                    )
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var colorPickerSheet: some View {
        #if os(macOS)
        let config = LayoutConfig.current
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Choose color")
                    .font(.headline)
                Spacer()
                Button("Done") { showingColorPickerSheet = false }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, config.sheetHeaderPaddingHorizontal)
            .padding(.top, config.sheetHeaderPaddingTop)
            .padding(.bottom, config.sheetHeaderPaddingBottom)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: config.spacingL) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: config.emojiGridSpacing), count: config.colorGridColumns), spacing: config.emojiGridSpacing) {
                        ForEach(presetColors, id: \.rawValue) { color in
                            colorChip(color)
                        }
                        customColorChip
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: config.colorPickerMinWidth, minHeight: config.colorPickerMinHeight)
        #else
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: LayoutConfig.current.spacingL) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: LayoutConfig.current.emojiGridSpacing), count: LayoutConfig.current.colorGridColumns), spacing: LayoutConfig.current.emojiGridSpacing) {
                        ForEach(presetColors, id: \.rawValue) { color in
                            colorChip(color)
                        }
                        customColorChip
                    }
                }
                .padding()
            }
            .navigationTitle("Choose color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showingColorPickerSheet = false }
                }
            }
        }
        .navigationViewStyle(.stack)
        #endif
    }

    private func colorChip(_ color: HabitColor) -> some View {
        let isSelected = selectedColor == color
        return Button {
            selectedColor = color
        } label: {
            ZStack {
                Circle()
                    .fill(color.color)
                    .frame(width: LayoutConfig.current.colorChipSize, height: LayoutConfig.current.colorChipSize)
                if isSelected {
                    Circle()
                        .strokeBorder(.white, lineWidth: 2.5)
                        .frame(width: LayoutConfig.current.colorChipSize, height: LayoutConfig.current.colorChipSize)
                    Circle()
                        .strokeBorder(color.color.opacity(0.6), lineWidth: 1)
                        .frame(width: LayoutConfig.current.colorChipSize + 4, height: LayoutConfig.current.colorChipSize + 4)
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 0, x: 0, y: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var customColorChip: some View {
        let isSelected = selectedColor == .custom
        return ZStack {
            ColorPicker("", selection: Binding(
                get: { selectedCustomColor },
                set: { new in
                    selectedCustomColor = new
                    selectedColor = .custom
                }
            ))
            .labelsHidden()
            .frame(width: LayoutConfig.current.colorChipSize, height: LayoutConfig.current.colorChipSize)
            .opacity(isSelected ? 1 : 0.6)
            if isSelected {
                Circle()
                    .strokeBorder(.white, lineWidth: 2.5)
                    .frame(width: LayoutConfig.current.colorChipSize, height: LayoutConfig.current.colorChipSize)
                Circle()
                    .strokeBorder(selectedCustomColor.opacity(0.8), lineWidth: 1)
                    .frame(width: LayoutConfig.current.colorChipSize + 4, height: LayoutConfig.current.colorChipSize + 4)
            }
        }
    }

    @ViewBuilder
    private var emojiRow: some View {
        Button {
            DispatchQueue.main.async { showingEmojiPickerSheet = true }
        } label: {
            HStack {
                Text("Emoji")
                Spacer()
                Text(resolvedEmoji)
                    .font(.title2)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var emojiPickerSheet: some View {
        #if os(macOS)
        emojiPickerContent
            .frame(minWidth: LayoutConfig.current.emojiPickerMinWidth, minHeight: LayoutConfig.current.emojiPickerMinHeight)
            .onAppear { anyEmojiText = "" }
        #else
        NavigationView {
            emojiPickerContent
                .navigationTitle("Choose emoji")
                .onAppear { anyEmojiText = "" }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingEmojiPickerSheet = false }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        #endif
    }

    @ViewBuilder
    private var emojiPickerContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            #if os(macOS)
            HStack {
                Text("Choose emoji")
                    .font(.headline)
                Spacer()
                Button("Cancel") { showingEmojiPickerSheet = false }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, LayoutConfig.current.sheetHeaderPaddingHorizontal)
            .padding(.top, LayoutConfig.current.sheetHeaderPaddingTop)
            .padding(.bottom, LayoutConfig.current.sheetHeaderPaddingBottom)
            Divider()
            #endif

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 0) {
                        Button {
                            selectedEmoji = nil
                            showingEmojiPickerSheet = false
                        } label: {
                            HStack(spacing: 10) {
                                Text(suggestedEmoji)
                                    .font(.title2)
                                Text("Suggested")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                        .disabled(name.isEmpty)

                        Rectangle()
                            .fill(Color.primary.opacity(0.12))
                            .frame(width: 1)
                            .padding(.vertical, 8)

                        HStack(spacing: 10) {
                            TextField("Any emoji", text: $anyEmojiText)
                                .textFieldStyle(.plain)
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                            Button {
                                if let emoji = HabitEmoji.firstEmoji(from: anyEmojiText) {
                                    selectedEmoji = emoji
                                    showingEmojiPickerSheet = false
                                }
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(HabitEmoji.firstEmoji(from: anyEmojiText) != nil ? Color.accentColor : Color.secondary.opacity(0.4))
                            }
                            .disabled(HabitEmoji.firstEmoji(from: anyEmojiText) == nil)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                    }
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                    )

                    ForEach(HabitEmoji.gridEmojis, id: \.category) { group in
                        VStack(alignment: .leading, spacing: LayoutConfig.current.spacingS) {
                            Text(group.category)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: LayoutConfig.current.emojiGridSpacing), count: LayoutConfig.current.emojiGridColumns), spacing: LayoutConfig.current.emojiGridSpacing) {
                                ForEach(group.emojis, id: \.self) { emoji in
                                    Button {
                                        selectedEmoji = emoji
                                        showingEmojiPickerSheet = false
                                    } label: {
                                        Text(emoji)
                                            .font(.system(size: LayoutConfig.current.emojiCellSize - 16))
                                            .frame(width: LayoutConfig.current.emojiCellSize, height: LayoutConfig.current.emojiCellSize)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Data Operations
    
    private func loadHabit() {
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
            selectedEmoji = nil
        }
    }
    
    private var resolvedEmoji: String {
        if let emoji = selectedEmoji, !emoji.isEmpty { return emoji }
        return suggestedEmoji
    }
    
    private func saveHabit() {
        if let habit {
            habit.name = name
            habit.habitDescription = description.isEmpty ? nil : description
            habit.emoji = resolvedEmoji
            habit.color = selectedColor
            habit.customColorHex = selectedColor == .custom ? selectedCustomColor.toHex() : nil
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
                emoji: resolvedEmoji,
                color: selectedColor,
                frequency: frequency,
                reminderTimes: reminders.map(\.time),
                reminderNames: reminders.map(\.name),
                reminderSounds: reminders.map(\.sound),
                activeDays: frequency == .weekly ? (selectedDays.isEmpty ? Set(Weekday.allCases) : selectedDays) : []
            )
            if selectedColor == .custom {
                newHabit.customColorHex = selectedCustomColor.toHex()
            }
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
