import SwiftUI
import SwiftData

// Frequency, active days and reminder editing for AddEditHabitView.
extension AddEditHabitView {
    // MARK: - Schedule Section

    @ViewBuilder
    var scheduleContent: some View {
        // Frequency pills
        HStack(spacing: 0) {
            Text("Repeats")
                .foregroundStyle(.primary)
            Spacer()
            HStack(spacing: 8) {
                pill("Daily", isOn: frequency == .daily) {
                    withAnimation(.spring(duration: 0.25)) { frequency = .daily }
                }
                pill("Weekly", isOn: frequency == .weekly) {
                    withAnimation(.spring(duration: 0.25)) { frequency = .weekly }
                }
            }
        }

        if frequency == .weekly {
            HStack(spacing: 6) {
                ForEach(Array(Weekday.allCases), id: \.self) { day in
                    let isOn = selectedDays.contains(day)
                    Button {
                        if isOn { selectedDays.remove(day) } else { selectedDays.insert(day) }
                    } label: {
                        Text(String(day.shortName.prefix(1)))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .frame(width: 36, height: 36)
                            .background(isOn ? Color.brandPurple : Color.secondary.opacity(0.15), in: Circle())
                            .foregroundStyle(isOn ? .white : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }

        // Reminder mode pills
        HStack(spacing: 0) {
            Text("Remind me")
                .foregroundStyle(.primary)
            Spacer()
            HStack(spacing: 8) {
                pill("At times", isOn: !useRepeatingReminders) {
                    withAnimation(.spring(duration: 0.25)) {
                        useRepeatingReminders = false
                        reminderIntervalMinutes = 0
                        if reminders.isEmpty {
                            reminders.append(Reminder(name: "Reminder", time: Self.defaultStartTime, sound: .default))
                        }
                    }
                }
                pill("Repeating", isOn: useRepeatingReminders) {
                    withAnimation(.spring(duration: 0.25)) {
                        useRepeatingReminders = true
                        if reminders.isEmpty {
                            reminders.append(Reminder(name: "Reminder", time: Self.defaultStartTime, sound: .default))
                        } else {
                            reminders = [reminders[0]]
                        }
                        // Default to 1 hour if no interval was previously set
                        if intervalHours == 0 && intervalMinutes == 0 {
                            intervalHours = 1
                        }
                        syncIntervalFromState()
                    }
                }
            }
        }

        if useRepeatingReminders {
            repeatingReminderRows
        } else {
            specificTimesRows
        }
    }

    func pill(_ label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isOn ? Color.brandPurple : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background {
                    Capsule()
                        .fill(isOn ? Color.brandPurple.opacity(0.12) : Color.secondary.opacity(0.12))
                        .overlay {
                            Capsule()
                                .strokeBorder(
                                    isOn ? Color.brandPurple.opacity(0.5) : Color.clear,
                                    lineWidth: 1
                                )
                        }
                }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isOn)
    }

    // MARK: - Repeating Reminders

    @ViewBuilder
    var repeatingReminderRows: some View {
        HStack {
            Text("Every")
                .foregroundStyle(.primary)
            Spacer()
            Picker("", selection: $intervalHours) {
                ForEach(0...12, id: \.self) { h in
                    Text(h == 1 ? "1 hr" : "\(h) hrs").tag(h)
                }
            }
            .labelsHidden()
            #if os(iOS)
            .pickerStyle(.wheel)
            .frame(width: 100, height: 120)
            .clipped()
            #else
            .pickerStyle(.menu)
            .frame(width: 90)
            #endif
            .onChange(of: intervalHours) { _, _ in syncIntervalFromState() }

            Picker("", selection: $intervalMinutes) {
                ForEach([0, 5, 10, 15, 20, 30, 45], id: \.self) { m in
                    Text("\(m) min").tag(m)
                }
            }
            .labelsHidden()
            #if os(iOS)
            .pickerStyle(.wheel)
            .frame(width: 100, height: 120)
            .clipped()
            #else
            .pickerStyle(.menu)
            .frame(width: 90)
            #endif
            .onChange(of: intervalMinutes) { _, _ in syncIntervalFromState() }
        }

        HStack {
            Text("Active window")
            Spacer()
            DatePicker("", selection: bindingToReminderTime(at: 0), displayedComponents: .hourAndMinute)
                .labelsHidden()
            Text("–")
                .foregroundStyle(.secondary)
            DatePicker("", selection: $reminderEndTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }

        Picker("Sound", selection: Binding(
            get: { reminders.first?.sound ?? .default },
            set: { s in if !reminders.isEmpty { reminders[0].sound = s } }
        )) {
            ForEach(ReminderSound.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }
    }

    // MARK: - Specific Times

    @ViewBuilder
    var specificTimesRows: some View {
        ForEach(reminders.indices, id: \.self) { idx in
            HStack {
                DatePicker(
                    idx == 0 ? "Time" : "Time \(idx + 1)",
                    selection: bindingToReminderTime(at: idx),
                    displayedComponents: .hourAndMinute
                )
                if reminders.count > 1 {
                    Button(role: .destructive) {
                        withAnimation { _ = reminders.remove(at: idx) }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }

        Button {
            withAnimation {
                reminders.append(Reminder(name: "Reminder", time: Self.defaultStartTime, sound: .default))
            }
        } label: {
            Label("Add another time", systemImage: "plus.circle.fill")
        }

        Picker("Sound", selection: Binding(
            get: { reminders.first?.sound ?? .default },
            set: { s in for i in reminders.indices { reminders[i].sound = s } }
        )) {
            ForEach(ReminderSound.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }
    }

    // MARK: - Helpers

    static var defaultStartTime: Date {
        Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    }

    static var defaultEndTime: Date {
        Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    }

    func bindingToReminderTime(at index: Int) -> Binding<Date> {
        Binding(
            get: { reminders.indices.contains(index) ? reminders[index].time : Self.defaultStartTime },
            set: { new in
                guard reminders.indices.contains(index) else { return }
                reminders[index].time = new
                reminders = reminders
            }
        )
    }

    func syncIntervalFromState() {
        let total = intervalHours * 60 + intervalMinutes
        reminderIntervalMinutes = max(15, total)
    }

    func syncStateFromInterval() {
        intervalHours = reminderIntervalMinutes / 60
        intervalMinutes = (reminderIntervalMinutes % 60 / 15) * 15
    }

    #if os(macOS)
    var frequencyAndRemindersMac: some View {
        let config = LayoutConfig.current
        return VStack(alignment: .leading, spacing: config.spacingM) {
            Text("Schedule")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            scheduleContent
        }
        .padding(.bottom, config.formSectionSpacing)
    }
    #endif
}
