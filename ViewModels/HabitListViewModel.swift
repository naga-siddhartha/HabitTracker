import Foundation
import Combine
import SwiftUI

class HabitListViewModel: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var searchText: String = ""
    @Published var showArchived: Bool = false
    
    private let habitService = HabitService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to habit service updates
        habitService.$habits
            .receive(on: DispatchQueue.main)
            .assign(to: \.habits, on: self)
            .store(in: &cancellables)
        
        loadHabits()
    }
    
    func loadHabits() {
        if showArchived {
            habits = habitService.habits
        } else {
            habits = habitService.getActiveHabits()
        }
    }
    
    var filteredHabits: [Habit] {
        if searchText.isEmpty {
            return habits
        } else {
            return habits.filter { habit in
                habit.name.localizedCaseInsensitiveContains(searchText) ||
                (habit.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    func deleteHabit(_ habit: Habit) {
        habitService.deleteHabit(habit)
        NotificationService.shared.removeReminders(for: habit.id)
    }
    
    func archiveHabit(_ habit: Habit) {
        habitService.archiveHabit(habit)
    }
    
    func toggleArchiveFilter() {
        showArchived.toggle()
        loadHabits()
    }
}
