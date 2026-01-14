import SwiftUI
import SwiftData

struct HabitListView: View {
    @Query(sort: \Habit.createdAt, order: .reverse) private var allHabits: [Habit]
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddHabit = false
    @State private var showingTemplates = false
    @State private var showArchived = false
    @State private var searchText = ""
    
    private var habits: [Habit] {
        allHabits.filter { showArchived || !$0.isArchived }
    }
    
    private var filteredHabits: [Habit] {
        guard !searchText.isEmpty else { return habits }
        return habits.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.habitDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredHabits) { habit in
                    NavigationLink(destination: HabitDetailView(habit: habit)) {
                        HabitRowView(habit: habit)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation {
                                NotificationService.shared.removeReminders(for: habit.id)
                                HabitStore.shared.deleteHabit(habit)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            withAnimation {
                                habit.isArchived.toggle()
                                HabitStore.shared.save()
                            }
                        } label: {
                            Label(habit.isArchived ? "Unarchive" : "Archive", systemImage: "archivebox")
                        }
                        .tint(.orange)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            withAnimation(.snappy(duration: 0.3)) {
                                HabitStore.shared.toggleCompletion(for: habit, on: .now)
                            }
                        } label: {
                            Label(habit.isCompleted(on: .now) ? "Undo" : "Complete", systemImage: habit.isCompleted(on: .now) ? "arrow.uturn.backward" : "checkmark")
                        }
                        .tint(habit.isCompleted(on: .now) ? .gray : .green)
                    }
                }
            }
            .animation(.smooth, value: filteredHabits.count)
            .navigationTitle("Habits")
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { showingAddHabit = true } label: {
                            Label("Create Custom", systemImage: "plus")
                        }
                        Button { showingTemplates = true } label: {
                            Label("From Template", systemImage: "square.grid.2x2")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button(showArchived ? "Hide Archived" : "Show Archived") {
                        withAnimation { showArchived.toggle() }
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button(showArchived ? "Hide Archived" : "Show Archived") {
                        withAnimation { showArchived.toggle() }
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingAddHabit) {
                AddEditHabitView()
            }
            .sheet(isPresented: $showingTemplates) {
                HabitTemplatesView()
            }
            .overlay {
                if filteredHabits.isEmpty {
                    ContentUnavailableView {
                        Label("No Habits", systemImage: "list.bullet")
                    } description: {
                        Text("Add a habit to get started")
                    } actions: {
                        Button("Browse Templates") { showingTemplates = true }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }
}

struct HabitRowView: View {
    let habit: Habit
    
    var body: some View {
        HStack {
            if let iconName = habit.iconName {
                Image(systemName: iconName)
                    .foregroundStyle(habit.color.color)
                    .font(.title2)
            } else {
                Circle()
                    .fill(habit.color.color)
                    .frame(width: 40, height: 40)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                
                if let desc = habit.habitDescription {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let streak = habit.streak, streak.currentStreak > 0 {
                    Label("\(streak.currentStreak) day streak", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HabitListView()
        .modelContainer(for: Habit.self, inMemory: true)
}
