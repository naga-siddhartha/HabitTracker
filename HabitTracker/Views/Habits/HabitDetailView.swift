import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Bindable var habit: Habit
    @State private var showingEditView = false
    @State private var selectedDate = Date.now
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                if let streak = habit.streak { streakSection(streak) }
                todaySection
                calendarSection
                activitySection
            }
        }
        .navigationTitle(habit.name)
        .inlineNavigationTitle()
        .toolbar { Button("Edit") { showingEditView = true } }
        .sheet(isPresented: $showingEditView) { AddEditHabitView(habit: habit) }
    }
    
    private var headerSection: some View {
        HStack {
            IconCircle(iconName: habit.iconName, color: habit.color.color, size: 60)
            VStack(alignment: .leading) {
                Text(habit.name).font(.largeTitle).bold()
                if let desc = habit.habitDescription {
                    Text(desc).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding()
    }
    
    private func streakSection(_ streak: Streak) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Current").font(.caption).foregroundStyle(.secondary)
                Text("\(streak.currentStreak)").font(.title).bold()
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("Longest").font(.caption).foregroundStyle(.secondary)
                Text("\(streak.longestStreak)").font(.title).bold()
            }
        }
        .padding()
        .background(Color.systemGray6)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today").font(.headline).padding(.horizontal)
            
            let completed = habit.isCompleted(on: .now)
            
            Button {
                withAnimation(.snappy(duration: 0.3)) {
                    HabitStore.shared.toggleCompletion(for: habit, on: .now)
                }
            } label: {
                HStack {
                    Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .contentTransition(.symbolEffect(.replace))
                    Text(completed ? "Completed" : "Mark as Complete").font(.headline)
                    Spacer()
                }
                .padding()
                .background(completed ? habit.color.color.opacity(0.2) : Color.systemGray6)
                .foregroundStyle(completed ? habit.color.color : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .hapticFeedback(.success, trigger: completed)
            .padding(.horizontal)
        }
    }
    
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calendar").font(.headline).padding(.horizontal)
            MonthCalendarView(habit: habit, selectedDate: $selectedDate)
        }
    }
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity").font(.headline).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                ContributionGraphView(habit: habit, weeks: 26).padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

#Preview {
    NavigationStack {
        HabitDetailView(habit: Habit(name: "Morning Run", description: "Run 5km"))
    }
    .modelContainer(for: Habit.self, inMemory: true)
}
