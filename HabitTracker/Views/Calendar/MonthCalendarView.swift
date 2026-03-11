import SwiftUI
import SwiftData

struct MonthCalendarView: View {
    @Bindable var habit: Habit
    @Binding var selectedDate: Date
    @State private var currentMonth = Date.now
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button { changeMonth(by: -1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(currentMonth, format: .dateTime.month(.wide).year()).font(.headline)
                Spacer()
                Button { changeMonth(by: 1) } label: { Image(systemName: "chevron.right") }
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, day in
                    Text(day).font(.caption).foregroundStyle(.secondary)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    DayCell(date: date, habit: habit,
                            isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate))
                        .onTapGesture {
                            selectedDate = date
                            if habit.isActive(on: date) {
                                withAnimation(.snappy(duration: 0.3)) {
                                    HabitStore.shared.toggleCompletion(for: habit, on: date)
                                }
                            }
                        }
                        .hapticFeedback(.selection, trigger: selectedDate)
                }
            }
        }
        .padding()
        .background(Color.systemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private var daysInMonth: [Date] {
        guard let monthStart = currentMonth.startOfMonth,
              let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count else { return [] }
        
        let startOffset = calendar.component(.weekday, from: monthStart) - 1
        var dates: [Date] = (0..<startOffset).compactMap {
            calendar.date(byAdding: .day, value: -($0 + 1), to: monthStart)
        }.reversed()
        
        dates += (0..<daysInMonth).compactMap { calendar.date(byAdding: .day, value: $0, to: monthStart) }
        
        let remaining = 42 - dates.count
        if let last = dates.last {
            dates += (1...remaining).compactMap { calendar.date(byAdding: .day, value: $0, to: last) }
        }
        return dates
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

struct DayCell: View {
    let date: Date
    let habit: Habit
    let isCurrentMonth: Bool
    let isSelected: Bool
    
    private var isCompleted: Bool { habit.isCompleted(on: date) }
    private var isSkipped: Bool { habit.isSkipped(on: date) }
    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(fillColor)
                .opacity(isCurrentMonth ? 1 : 0.3)
            
            if isSkipped {
                Image(systemName: "forward.fill").font(.caption2).foregroundStyle(.white)
            } else {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.caption)
                    .foregroundStyle(isCompleted ? .white : (isCurrentMonth ? .primary : .secondary))
            }
        }
        .frame(width: 32, height: 32)
        .overlay { if isToday { Circle().stroke(habit.displayColor, lineWidth: 2) } }
        .background(isSelected ? habit.displayColor.opacity(0.2) : .clear)
        .clipShape(Circle())
        .scaleEffect(isCompleted ? 1.1 : 1.0)
        .animation(.spring(duration: 0.2), value: isCompleted)
    }
    
    private var fillColor: Color {
        if isCompleted { return habit.displayColor }
        if isSkipped { return .orange }
        return Color.systemGray4
    }
}

#Preview {
    MonthCalendarView(habit: Habit(name: "Test"), selectedDate: .constant(.now))
        .modelContainer(for: Habit.self, inMemory: true)
}

