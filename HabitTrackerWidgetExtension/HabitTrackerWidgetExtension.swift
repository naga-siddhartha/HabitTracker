import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct WidgetEntry: TimelineEntry {
    let date: Date
    let completedCount: Int
    let totalCount: Int
}

// MARK: - Timeline Provider

struct HabitTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: .now, completedCount: 2, totalCount: 5)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        completion(WidgetEntry(date: .now, completedCount: 2, totalCount: 5))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        // Simple placeholder - actual data requires App Groups setup
        let entry = WidgetEntry(date: .now, completedCount: 0, totalCount: 0)
        let midnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(86400)
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}

// MARK: - Widget View

struct SmallWidgetView: View {
    let entry: WidgetEntry
    
    private var progress: Double {
        entry.totalCount > 0 ? Double(entry.completedCount) / Double(entry.totalCount) : 0
    }
    
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
            ProgressView(value: progress)
                .tint(.green)
            Text("habits done")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget

struct HabitTrackerWidgetExtension: Widget {
    let kind = "HabitTrackerWidgetExtension"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitTimelineProvider()) { entry in
            SmallWidgetView(entry: entry)
        }
        .configurationDisplayName("Habit Tracker")
        .description("Track your daily habits.")
        .supportedFamilies([.systemSmall])
    }
}
