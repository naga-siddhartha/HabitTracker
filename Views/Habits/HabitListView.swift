import SwiftUI

struct HabitListView: View {
    @StateObject private var viewModel = HabitListViewModel()
    @State private var showingAddHabit = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.filteredHabits) { habit in
                    NavigationLink(destination: HabitDetailView(habit: habit)) {
                        HabitRowView(habit: habit)
                    }
                }
                .onDelete(perform: deleteHabits)
            }
            .navigationTitle("Habits")
            .searchable(text: $viewModel.searchText)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddHabit = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { viewModel.toggleArchiveFilter() }) {
                        Text(viewModel.showArchived ? "Show Active" : "Show Archived")
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddEditHabitView()
            }
        }
    }
    
    private func deleteHabits(at offsets: IndexSet) {
        for index in offsets {
            let habit = viewModel.filteredHabits[index]
            viewModel.deleteHabit(habit)
        }
    }
}

struct HabitRowView: View {
    let habit: Habit
    @StateObject private var streakService = StreakService.shared
    
    var body: some View {
        HStack {
            // Icon
            if let iconName = habit.iconName {
                Image(systemName: iconName)
                    .foregroundColor(habit.color.color)
                    .font(.title2)
            } else {
                Circle()
                    .fill(habit.color.color)
                    .frame(width: 40, height: 40)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                
                if let description = habit.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Streak info
                if let streak = streakService.getStreak(for: habit.id) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("\(streak.currentStreak) day streak")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HabitListView()
}
