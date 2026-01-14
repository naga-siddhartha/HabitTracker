import SwiftUI
import SwiftData

struct YearlyView: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived }) private var habits: [Habit]
    @State private var currentYear = Date.now
    @State private var selectedHabit: Habit?
    
    private let calendar = Calendar.current
    
    private var months: [Date] {
        guard let yearStart = currentYear.startOfYear else { return [] }
        return (0..<12).compactMap { calendar.date(byAdding: .month, value: $0, to: yearStart) }
    }
    
    var body: some View {
        VStack {
            // Year navigation
            HStack {
                Button { changeYear(by: -1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(currentYear, format: .dateTime.year()).font(.headline)
                Spacer()
                Button { changeYear(by: 1) } label: { Image(systemName: "chevron.right") }
            }
            .padding()
            
            // Habit picker
            if !habits.isEmpty {
                Picker("Habit", selection: $selectedHabit) {
                    Text("All Habits").tag(nil as Habit?)
                    ForEach(habits) { habit in
                        Text(habit.name).tag(habit as Habit?)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
            }
            
            // Year grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                    ForEach(months, id: \.self) { month in
                        YearMonthCell(month: month, habits: selectedHabit.map { [$0] } ?? habits)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Yearly")
    }
    
    private func changeYear(by value: Int) {
        if let newYear = calendar.date(byAdding: .year, value: value, to: currentYear) {
            currentYear = newYear
        }
    }
}

struct YearMonthCell: View {
    let month: Date
    let habits: [Habit]
    
    private let calendar = Calendar.current
    
    private var completionRatio: Double {
        guard let daysInMonth = calendar.range(of: .day, in: .month, for: month)?.count,
              let monthStart = month.startOfMonth else { return 0 }
        
        var totalPossible = 0
        var totalCompleted = 0
        
        for dayOffset in 0..<daysInMonth {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: monthStart) else { continue }
            let active = habits.filter { $0.isActive(on: date) }
            totalPossible += active.count
            totalCompleted += active.filter { $0.isCompleted(on: date) }.count
        }
        
        return totalPossible > 0 ? Double(totalCompleted) / Double(totalPossible) : 0
    }
    
    var body: some View {
        VStack {
            Text(month, format: .dateTime.month(.abbreviated))
                .font(.caption)
            
            ZStack {
                Circle()
                    .stroke(Color.systemGray4, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: completionRatio)
                    .stroke(Color.green, lineWidth: 4)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(completionRatio * 100))%")
                    .font(.caption2)
            }
            .frame(width: 50, height: 50)
        }
        .padding()
        .background(Color.systemGray6)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack { YearlyView() }
        .modelContainer(for: Habit.self, inMemory: true)
}
