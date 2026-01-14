import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: - Timeline Entry

struct WidgetEntry: TimelineEntry {
    let date: Date
    let habits: [HabitSnapshot]
    let completedCount: Int
    let totalCount: Int
}

struct HabitSnapshot: Identifiable {
    let id: UUID
    let name: String
    let iconName: String?
    let colorName: String
    let isCompleted: Bool
    let currentStreak: Int
    
    var color: Color {
        HabitColor(rawValue: colorName)?.color ?? .blue
    }
}

// MARK: - Timeline Provider

struct HabitTimelineProvider: TimelineProvider {
    let modelContainer: ModelContainer
    
    init() {
        modelContainer = try! AppConfig.createModelContainer()
    }
    
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: .now, habits: [], completedCount: 2, totalCount: 5)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        Task { @MainActor in
            let entry = fetchEntry()
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        Task { @MainActor in
            let entry = fetchEntry()
            // Refresh at midnight or in 15 minutes
            let midnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(86400)
            let refresh = min(midnight, Date.now.addingTimeInterval(900))
            let timeline = Timeline(entries: [entry], policy: .after(refresh))
            completion(timeline)
        }
    }
    
    @MainActor
    private func fetchEntry() -> WidgetEntry {
        let context = modelContainer.mainContext
        let today = Date.now
        
        var descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdAt)])
        descriptor.predicate = #Predicate { !$0.isArchived }
        
        guard let habits = try? context.fetch(descriptor) else {
            return WidgetEntry(date: today, habits: [], completedCount: 0, totalCount: 0)
        }
        
        let activeHabits = habits.filter { $0.isActive(on: today) }
        let snapshots = activeHabits.prefix(6).map { habit in
            HabitSnapshot(
                id: habit.id,
                name: habit.name,
                iconName: habit.iconName,
                colorName: habit.colorName,
                isCompleted: habit.isCompleted(on: today),
                currentStreak: habit.streak?.currentStreak ?? 0
            )
        }
        
        let completed = activeHabits.filter { $0.isCompleted(on: today) }.count
        
        return WidgetEntry(
            date: today,
            habits: snapshots,
            completedCount: completed,
            totalCount: activeHabits.count
        )
    }
}

// MARK: - Widget Views

struct SmallWidgetView: View {
    let entry: WidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Today")
                    .font(.headline)
            }
            
            Spacer()
            
            Text("\(entry.completedCount)/\(entry.totalCount)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
            
            ProgressView(value: Double(entry.completedCount), total: max(1, Double(entry.totalCount)))
                .tint(.green)
            
            Text("habits done")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumWidgetView: View {
    let entry: WidgetEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Progress circle
            VStack {
                ZStack {
                    Circle()
                        .stroke(.quaternary, lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: entry.totalCount > 0 ? Double(entry.completedCount) / Double(entry.totalCount) : 0)
                        .stroke(.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(entry.completedCount)")
                            .font(.title.bold())
                        Text("of \(entry.totalCount)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 70, height: 70)
                
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Habit list with interactive buttons
            VStack(alignment: .leading, spacing: 6) {
                ForEach(entry.habits.prefix(4)) { habit in
                    Button(intent: ToggleHabitIntent(habitId: habit.id)) {
                        HStack(spacing: 8) {
                            Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(habit.isCompleted ? habit.color : .secondary)
                                .font(.caption)
                            
                            Text(habit.name)
                                .font(.caption)
                                .lineLimit(1)
                                .strikethrough(habit.isCompleted)
                            
                            Spacer()
                            
                            if habit.currentStreak > 0 {
                                Label("\(habit.currentStreak)", systemImage: "flame.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                if entry.habits.count > 4 {
                    Text("+\(entry.habits.count - 4) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct LargeWidgetView: View {
    let entry: WidgetEntry
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Today's Habits")
                        .font(.headline)
                    Text(entry.date, format: .dateTime.weekday(.wide).month().day())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("\(entry.completedCount)/\(entry.totalCount)")
                    .font(.title2.bold())
                    .foregroundStyle(.green)
            }
            
            ProgressView(value: Double(entry.completedCount), total: max(1, Double(entry.totalCount)))
                .tint(.green)
            
            // Habits grid with interactive buttons
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(entry.habits) { habit in
                    Button(intent: ToggleHabitIntent(habitId: habit.id)) {
                        HStack(spacing: 6) {
                            Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(habit.isCompleted ? habit.color : .secondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(habit.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .strikethrough(habit.isCompleted)
                                
                                if habit.currentStreak > 0 {
                                    Label("\(habit.currentStreak)d", systemImage: "flame.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(8)
                        .background(habit.isCompleted ? habit.color.opacity(0.15) : Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Configuration

struct HabitTrackerWidget: Widget {
    let kind = "HabitTrackerWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitTimelineProvider()) { entry in
            HabitWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Habit Tracker")
        .description("Track your daily habits at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct HabitWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WidgetEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct HabitTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitTrackerWidget()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    HabitTrackerWidget()
} timeline: {
    WidgetEntry(date: .now, habits: [], completedCount: 3, totalCount: 5)
}

#Preview("Medium", as: .systemMedium) {
    HabitTrackerWidget()
} timeline: {
    WidgetEntry(date: .now, habits: [
        HabitSnapshot(id: UUID(), name: "Exercise", iconName: "figure.run", colorName: "green", isCompleted: true, currentStreak: 7),
        HabitSnapshot(id: UUID(), name: "Read", iconName: "book.fill", colorName: "blue", isCompleted: true, currentStreak: 3),
        HabitSnapshot(id: UUID(), name: "Meditate", iconName: "leaf.fill", colorName: "purple", isCompleted: false, currentStreak: 0),
        HabitSnapshot(id: UUID(), name: "Water", iconName: "drop.fill", colorName: "teal", isCompleted: false, currentStreak: 12),
    ], completedCount: 2, totalCount: 4)
}

#Preview("Large", as: .systemLarge) {
    HabitTrackerWidget()
} timeline: {
    WidgetEntry(date: .now, habits: [
        HabitSnapshot(id: UUID(), name: "Exercise", iconName: "figure.run", colorName: "green", isCompleted: true, currentStreak: 7),
        HabitSnapshot(id: UUID(), name: "Read", iconName: "book.fill", colorName: "blue", isCompleted: true, currentStreak: 3),
        HabitSnapshot(id: UUID(), name: "Meditate", iconName: "leaf.fill", colorName: "purple", isCompleted: false, currentStreak: 0),
        HabitSnapshot(id: UUID(), name: "Water", iconName: "drop.fill", colorName: "teal", isCompleted: false, currentStreak: 12),
        HabitSnapshot(id: UUID(), name: "Journal", iconName: "book.closed.fill", colorName: "orange", isCompleted: true, currentStreak: 5),
        HabitSnapshot(id: UUID(), name: "Sleep 8h", iconName: "bed.double.fill", colorName: "indigo", isCompleted: false, currentStreak: 2),
    ], completedCount: 3, totalCount: 6)
}
