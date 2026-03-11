import SwiftUI
import SwiftData

struct ContributionGraphView: View {
    let habit: Habit?
    let weeks: Int
    
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @Environment(\.colorScheme) private var colorScheme

    private let calendar = Calendar.current
    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 3
    
    // Cached computation
    @State private var levelCache: [Date: Int] = [:]
    
    init(habit: Habit? = nil, weeks: Int = 52) {
        self.habit = habit
        self.weeks = weeks
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Month labels
            HStack(spacing: 0) {
                ForEach(monthLabels, id: \.offset) { label in
                    Text(label.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(
                            width: max(CGFloat(label.weeks) * (cellSize + cellSpacing), 26),
                            alignment: .leading
                        )
                }
            }
            .padding(.leading, 28)
            
            HStack(alignment: .top, spacing: cellSpacing) {
                // Day labels
                VStack(spacing: cellSpacing) {
                    ForEach(Array(["", "Mon", "", "Wed", "", "Fri", ""].enumerated()), id: \.offset) { _, day in
                        Text(day)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 24, height: cellSize, alignment: .trailing)
                    }
                }
                
                // Grid - use LazyHStack for performance
                LazyHStack(spacing: cellSpacing) {
                    ForEach(0..<weeks, id: \.self) { weekOffset in
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<7, id: \.self) { dayOffset in
                                let date = dateFor(week: weekOffset, day: dayOffset)
                                ContributionCell(
                                    date: date,
                                    level: levelCache[date] ?? 0,
                                    size: cellSize
                                )
                            }
                        }
                    }
                }
            }
            
            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                ForEach(0..<5, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorForLevel(level))
                        .frame(width: cellSize, height: cellSize)
                }
                
                Text("More")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 28)
        }
        .onAppear { computeLevels() }
        .onChange(of: habits.count) { computeLevels() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Activity graph, past \(weeks) weeks")
        .accessibilityHint("Each cell is a day; darker green means more habits completed")
    }
    
    private func computeLevels() {
        var cache: [Date: Int] = [:]
        let targetHabits = habit.map { [$0] } ?? Array(habits)
        let today = Date.now
        
        for weekOffset in 0..<weeks {
            for dayOffset in 0..<7 {
                let date = dateFor(week: weekOffset, day: dayOffset)
                guard date <= today else {
                    cache[date] = -1
                    continue
                }
                
                let activeHabits = targetHabits.filter { $0.isActive(on: date) }
                guard !activeHabits.isEmpty else {
                    cache[date] = 0
                    continue
                }
                
                let completed = activeHabits.filter { $0.isCompleted(on: date) }.count
                let ratio = Double(completed) / Double(activeHabits.count)
                
                if ratio == 0 { cache[date] = 0 }
                else if ratio < 0.25 { cache[date] = 1 }
                else if ratio < 0.5 { cache[date] = 2 }
                else if ratio < 0.75 { cache[date] = 3 }
                else { cache[date] = 4 }
            }
        }
        
        levelCache = cache
    }
    
    private var monthLabels: [(name: String, weeks: Int, offset: Int)] {
        var labels: [(String, Int, Int)] = []
        var currentMonth = -1
        var weekCount = 0
        var startOffset = 0
        
        for weekOffset in 0..<weeks {
            let date = dateFor(week: weekOffset, day: 0)
            let month = calendar.component(.month, from: date)
            
            if month != currentMonth {
                if currentMonth != -1 {
                    labels.append((calendar.shortMonthSymbols[currentMonth - 1], weekCount, startOffset))
                }
                currentMonth = month
                weekCount = 1
                startOffset = weekOffset
            } else {
                weekCount += 1
            }
        }
        
        if weekCount > 0 {
            labels.append((calendar.shortMonthSymbols[currentMonth - 1], weekCount, startOffset))
        }
        
        return labels
    }
    
    private func dateFor(week: Int, day: Int) -> Date {
        let today = Date.now.startOfDay
        let startOfWeek = calendar.date(byAdding: .weekOfYear, value: -(weeks - 1 - week), to: today.startOfWeek ?? today)!
        return calendar.date(byAdding: .day, value: day, to: startOfWeek) ?? today
    }

    private func colorForLevel(_ level: Int) -> Color {
        ContributionGraphView.fillForLevel(level, colorScheme: colorScheme)
    }
}

extension ContributionGraphView {
    static func fillForLevel(_ level: Int, colorScheme: ColorScheme) -> Color {
        switch level {
        case -1: return .clear
        case 0:
            return colorScheme == .dark ? Color.systemGray6 : Color(white: 0.88)
        case 1:
            return colorScheme == .dark ? .green.opacity(0.25) : .green.opacity(0.42)
        case 2:
            return colorScheme == .dark ? .green.opacity(0.5) : .green.opacity(0.6)
        case 3:
            return colorScheme == .dark ? .green.opacity(0.75) : .green.opacity(0.82)
        default:
            return .green
        }
    }
}

struct ContributionCell: View {
    let date: Date
    let level: Int
    let size: CGFloat
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var showTooltip = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(ContributionGraphView.fillForLevel(level, colorScheme: colorScheme))
            .frame(width: size, height: size)
            #if os(macOS)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.2), lineWidth: 0.5)
            )
            #endif
            .onTapGesture {
                if level >= 0 {
                    showTooltip = true
                }
            }
            .popover(isPresented: $showTooltip) {
                VStack(spacing: 4) {
                    Text(date, format: .dateTime.weekday(.wide).month().day().year())
                        .font(.caption.bold())
                    Text(levelDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .presentationCompactAdaptation(.popover)
            }
            .accessibilityLabel(date.formatted(date: .abbreviated, time: .omitted))
            .accessibilityValue(level >= 0 ? levelDescription : "Future")
    }
    
    private var levelDescription: String {
        switch level {
        case 0: return "No completions"
        case 1: return "1-24% completed"
        case 2: return "25-49% completed"
        case 3: return "50-74% completed"
        case 4: return "75-100% completed"
        default: return ""
        }
    }
}

#Preview {
    ScrollView {
        VStack {
            ContributionGraphView(weeks: 20)
                .padding()
        }
    }
    .modelContainer(for: Habit.self, inMemory: true)
}
