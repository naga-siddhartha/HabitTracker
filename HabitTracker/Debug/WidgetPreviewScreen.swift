#if DEBUG
import SwiftUI

// MARK: - Widget preview screen for marketing screenshots
//
// Renders a faithful iOS home-screen mockup with the small and medium
// widgets side by side. Activated by `-demoWidgetPreview` launch arg.
// Stripped entirely from release builds by #if DEBUG.

struct WidgetPreviewScreen: View {
    private let gold = Color(red: 0.969, green: 0.776, blue: 0.173)

    // Hardcoded demo data matching MarketingDemoSeeder: Journal + Practice Instrument done today.
    private var entry: PreviewEntry {
        let habits: [WidgetHabit] = [
            WidgetHabit(id: "1", name: "Drink Water", emoji: "💧", colorName: "teal",
                        isCompleted: false, isSkipped: false, completionCount: 3, expectedCount: 7),
            WidgetHabit(id: "2", name: "Exercise", emoji: "🏃", colorName: "orange",
                        isCompleted: false, isSkipped: false, completionCount: 0, expectedCount: 1),
            WidgetHabit(id: "3", name: "Journal", emoji: "📓", colorName: "green",
                        isCompleted: true,  isSkipped: false, completionCount: 1, expectedCount: 1),
            WidgetHabit(id: "4", name: "Plan Tomorrow", emoji: "📋", colorName: "blue",
                        isCompleted: false, isSkipped: false, completionCount: 0, expectedCount: 1),
            WidgetHabit(id: "5", name: "Practice Instrument", emoji: "🎸", colorName: "orange",
                        isCompleted: true,  isSkipped: false, completionCount: 1, expectedCount: 1),
            WidgetHabit(id: "6", name: "Read a Book", emoji: "📚", colorName: "red",
                        isCompleted: false, isSkipped: false, completionCount: 0, expectedCount: 1),
        ]
        return PreviewEntry(completedCount: 2, totalCount: 6, habits: habits)
    }

    var body: some View {
        ZStack {
            // iOS-style wallpaper gradient
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.25),
                         Color(red: 0.12, green: 0.08, blue: 0.40)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Status bar spacer
                Spacer().frame(height: 56)

                // Fake top icon row
                AppIconRow(icons: [
                    ("camera.fill", .gray),
                    ("envelope.fill", .blue),
                    ("phone.fill", .green),
                    ("safari.fill", Color(red: 0.0, green: 0.5, blue: 1.0))
                ])
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                // Widget row
                HStack(alignment: .top, spacing: 16) {
                    PreviewSmallWidget(entry: entry)
                        .frame(width: 160, height: 160)
                    PreviewSmallWidgetDone(entry: entry)
                        .frame(width: 160, height: 160)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                // Medium widget
                PreviewMediumWidget(entry: entry)
                    .frame(height: 160)
                    .padding(.horizontal, 24)

                Spacer()

                // Dock
                HStack(spacing: 28) {
                    DockIcon(systemName: "house.fill", color: .purple)
                    DockIcon(systemName: "calendar", color: .red)
                    DockIcon(systemName: "message.fill", color: .green)
                    DockIcon(systemName: "music.note", color: .orange)
                }
                .padding(.horizontal, 36)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
        .statusBarHidden()
    }
}

// MARK: - Preview Entry (mirrors WidgetEntry without WidgetKit)

private struct PreviewEntry {
    let completedCount: Int
    let totalCount: Int
    let habits: [WidgetHabit]
    var progress: Double { totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0 }
    var isPerfect: Bool { totalCount > 0 && completedCount >= totalCount }
}

// MARK: - Small widget — in progress

private struct PreviewSmallWidget: View {
    let entry: PreviewEntry
    private let gold = Color(red: 0.969, green: 0.776, blue: 0.173)
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "circle.dotted")
                    .foregroundStyle(Color.purple)
                    .font(.system(size: 14, weight: .semibold))
                Text("Today")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            (Text("\(entry.completedCount)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
             + Text("/\(entry.totalCount)")
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary))
            ProgressView(value: entry.progress)
                .tint(Color.purple)
            Text("\(entry.totalCount - entry.completedCount) left")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Small widget — all done variant

private struct PreviewSmallWidgetDone: View {
    let entry: PreviewEntry
    private let gold = Color(red: 0.969, green: 0.776, blue: 0.173)
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(gold)
                    .font(.system(size: 14, weight: .semibold))
                Text("Today")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            (Text("\(entry.totalCount)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(gold)
             + Text("/\(entry.totalCount)")
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary))
            ProgressView(value: 1.0)
                .tint(gold)
            Text("All done!")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Medium widget

private struct PreviewMediumWidget: View {
    let entry: PreviewEntry
    private let gold = Color(red: 0.969, green: 0.776, blue: 0.173)
    private var visibleHabits: [WidgetHabit] { Array(entry.habits.prefix(4)) }
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                (Text("\(entry.completedCount)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                 + Text("/\(entry.totalCount)")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary))
                ProgressView(value: entry.progress)
                    .tint(Color.purple)
                    .frame(maxWidth: 80)
            }
            .frame(maxWidth: 80)
            Divider()
            VStack(alignment: .leading, spacing: 0) {
                ForEach(visibleHabits, id: \.id) { habit in
                    HStack(spacing: 8) {
                        Circle()
                            .stroke(habitColor(habit.colorName).opacity(0.6), lineWidth: 1.5)
                            .frame(width: 18, height: 18)
                            .overlay(
                                habit.isCompleted ?
                                    Image(systemName: "checkmark").font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(habitColor(habit.colorName)) : nil
                            )
                        Text(habit.name)
                            .font(.caption.weight(habit.isCompleted ? .regular : .medium))
                            .foregroundStyle(habit.isCompleted ? .secondary : .primary)
                            .strikethrough(habit.isCompleted)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 5)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    private func habitColor(_ name: String) -> Color {
        switch name {
        case "red": return .red; case "orange": return .orange; case "yellow": return .yellow
        case "green": return .green; case "teal": return .teal; case "blue": return .blue
        case "purple": return .purple; case "pink": return .pink; case "indigo": return .indigo
        default: return .accentColor
        }
    }
}

// MARK: - Home screen chrome helpers

private struct AppIconRow: View {
    let icons: [(String, Color)]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(icons.indices, id: \.self) { i in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(icons[i].1.opacity(0.85))
                        .frame(width: 60, height: 60)
                        .overlay(Image(systemName: icons[i].0)
                            .font(.system(size: 26)).foregroundStyle(.white))
                    Rectangle().fill(Color.clear).frame(height: 10)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct DockIcon: View {
    let systemName: String
    let color: Color
    var body: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(color.opacity(0.85))
            .frame(width: 56, height: 56)
            .overlay(Image(systemName: systemName)
                .font(.system(size: 24)).foregroundStyle(.white))
    }
}
#endif
