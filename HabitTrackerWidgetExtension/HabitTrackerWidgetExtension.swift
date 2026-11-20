import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Toggle intent

struct ToggleHabitIntent: AppIntent {
    static let title: LocalizedStringResource = "Toggle Habit"
    static let description = IntentDescription("Mark a habit complete or incomplete.")

    @Parameter(title: "Habit ID")
    var habitID: String

    init() { habitID = "" }
    init(habitID: String) { self.habitID = habitID }

    func perform() async throws -> some IntentResult {
        WidgetDataStore.appendPendingToggle(habitID: habitID)
        var habits = WidgetDataStore.readHabits()
        if let idx = habits.firstIndex(where: { $0.id == habitID }) {
            let h = habits[idx]
            habits[idx] = WidgetHabit(
                id: h.id, name: h.name, emoji: h.emoji, colorName: h.colorName,
                isCompleted: !h.isCompleted, isSkipped: h.isSkipped,
                completionCount: h.isCompleted ? 0 : 1,
                expectedCount: h.expectedCount
            )
            WidgetDataStore.writeHabits(habits)
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Entry

struct WidgetEntry: TimelineEntry {
    let date: Date
    let completedCount: Int
    let totalCount: Int
    let habits: [WidgetHabit]

    var progress: Double { totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0 }
    var isPerfect: Bool { totalCount > 0 && completedCount >= totalCount }
}

// MARK: - Provider

struct HabitTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        let sample = [
            WidgetHabit(id: "1", name: "Morning run", emoji: "🏃", colorName: "green", isCompleted: true, isSkipped: false, completionCount: 1, expectedCount: 1),
            WidgetHabit(id: "2", name: "Read", emoji: "📚", colorName: "blue", isCompleted: false, isSkipped: false, completionCount: 0, expectedCount: 1),
            WidgetHabit(id: "3", name: "Meditate", emoji: "🧘", colorName: "teal", isCompleted: false, isSkipped: false, completionCount: 0, expectedCount: 1),
        ]
        return WidgetEntry(date: .now, completedCount: 1, totalCount: 3, habits: sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        let (c, t) = WidgetDataStore.read()
        let habits = WidgetDataStore.readHabits()
        completion(WidgetEntry(date: .now, completedCount: c, totalCount: t, habits: habits))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let (c, t) = WidgetDataStore.read()
        let habits = WidgetDataStore.readHabits()
        let entry = WidgetEntry(date: .now, completedCount: c, totalCount: t, habits: habits)
        let midnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(86400)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }
}

// MARK: - Colors

private let goldColor = Color(red: 0.969, green: 0.776, blue: 0.173)

private func habitColor(for colorName: String) -> Color {
    switch colorName {
    case "red": return .red
    case "orange": return .orange
    case "yellow": return .yellow
    case "green": return .green
    case "teal": return .teal
    case "blue": return .blue
    case "purple": return .purple
    case "pink": return .pink
    case "indigo": return .indigo
    case "brown": return .brown
    default: return .accentColor
    }
}

// MARK: - Small widget view

struct SmallWidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: entry.isPerfect ? "checkmark.circle.fill" : "circle.dotted")
                    .foregroundStyle(entry.isPerfect ? goldColor : .accentColor)
                    .font(.system(size: 14, weight: .semibold))
                Text("Today")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if entry.totalCount > 0 {
                (Text("\(entry.completedCount)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.isPerfect ? goldColor : .primary)
                 + Text("/\(entry.totalCount)")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary))
            } else {
                Text("No habits")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: entry.progress)
                .tint(entry.isPerfect ? goldColor : .accentColor)
            Text(entry.isPerfect ? "All done!" : "\(entry.totalCount - entry.completedCount) left")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today: \(entry.completedCount) of \(entry.totalCount) habits done")
    }
}

// MARK: - Medium widget view

struct MediumWidgetView: View {
    let entry: WidgetEntry

    private var visibleHabits: [WidgetHabit] {
        Array(entry.habits.prefix(4))
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                (Text("\(entry.completedCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.isPerfect ? goldColor : .primary)
                 + Text("/\(entry.totalCount)")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary))
                ProgressView(value: entry.progress)
                    .tint(entry.isPerfect ? goldColor : .accentColor)
                    .frame(maxWidth: 80)
            }
            .frame(maxWidth: 90)

            Divider()

            VStack(alignment: .leading, spacing: 0) {
                if visibleHabits.isEmpty {
                    Text("Add habits in the app")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(visibleHabits, id: \.id) { habit in
                        Button(intent: ToggleHabitIntent(habitID: habit.id)) {
                            HabitRowView(habit: habit)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(habit.name), \(habit.isCompleted ? "completed" : "not completed")")
                        .accessibilityHint("Double tap to toggle")
                        if habit.id != visibleHabits.last?.id {
                            Divider().padding(.leading, 28)
                        }
                    }
                }
                if entry.habits.count > 4 {
                    Text("+\(entry.habits.count - 4) more")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct HabitRowView: View {
    let habit: WidgetHabit

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(habit.isCompleted ? habitColor(for: habit.colorName) : Color.secondary.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 20, height: 20)
                if habit.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(habitColor(for: habit.colorName))
                } else if let emoji = habit.emoji, !emoji.isEmpty {
                    Text(emoji).font(.system(size: 11))
                }
            }
            Text(habit.name)
                .font(.caption.weight(habit.isCompleted ? .regular : .medium))
                .foregroundStyle(habit.isCompleted ? .secondary : .primary)
                .strikethrough(habit.isCompleted)
                .lineLimit(1)
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
    }
}

// MARK: - Lock screen views

struct AccessoryCircularView: View {
    let entry: WidgetEntry

    var body: some View {
        ZStack {
            if entry.totalCount > 0 {
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(entry.isPerfect ? goldColor : .accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            if entry.isPerfect {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
            } else {
                VStack(spacing: 0) {
                    Text("\(entry.completedCount)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    if entry.totalCount > 0 {
                        Text("/\(entry.totalCount)")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .containerBackground(.clear, for: .widget)
        .accessibilityLabel("\(entry.completedCount) of \(entry.totalCount) habits done")
    }
}

struct AccessoryRectangularView: View {
    let entry: WidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: entry.isPerfect ? "checkmark.circle.fill" : "chart.bar.fill")
                    .font(.system(size: 11))
                Text(entry.isPerfect ? "All done!" : "\(entry.completedCount)/\(entry.totalCount) habits")
                    .font(.headline)
                    .minimumScaleFactor(0.8)
            }
            ForEach(entry.habits.prefix(2), id: \.id) { habit in
                HStack(spacing: 4) {
                    Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 10))
                        .foregroundStyle(habit.isCompleted ? .primary : .secondary)
                    Text(habit.name)
                        .font(.caption2)
                        .foregroundStyle(habit.isCompleted ? .secondary : .primary)
                        .strikethrough(habit.isCompleted)
                        .lineLimit(1)
                }
            }
        }
        .containerBackground(.clear, for: .widget)
        .accessibilityLabel("\(entry.completedCount) of \(entry.totalCount) habits done today")
    }
}

struct AccessoryInlineView: View {
    let entry: WidgetEntry

    var body: some View {
        if entry.isPerfect {
            Label("All \(entry.totalCount) habits done", systemImage: "checkmark.circle.fill")
        } else if entry.totalCount == 0 {
            Label("No habits today", systemImage: "circle.dotted")
        } else {
            Label("\(entry.completedCount)/\(entry.totalCount) habits done", systemImage: "chart.bar.fill")
        }
    }
}

// MARK: - Widget

struct HabitTrackerWidgetExtension: Widget {
    let kind = "HabitTrackerWidgetExtension"

    @Environment(\.widgetFamily) private var widgetFamily

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitTimelineProvider()) { entry in
            widgetView(for: entry)
        }
        .configurationDisplayName("Habit: Grab It")
        .description("Today's habit progress at a glance.")
        .supportedFamilies([
            .systemSmall, .systemMedium,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
        .contentMarginsDisabled()
    }

    @ViewBuilder
    private func widgetView(for entry: WidgetEntry) -> some View {
        switch widgetFamily {
        case .systemMedium: MediumWidgetView(entry: entry)
        case .accessoryCircular: AccessoryCircularView(entry: entry)
        case .accessoryRectangular: AccessoryRectangularView(entry: entry)
        case .accessoryInline: AccessoryInlineView(entry: entry)
        default: SmallWidgetView(entry: entry)
        }
    }
}
