import Foundation
import SwiftData
import WidgetKit

// MARK: - Repository Protocol

@available(iOS 17.0, macOS 14.0, *)
protocol HabitRepositoryProtocol {
    func fetchAll(includeArchived: Bool) -> [Habit]
    func add(_ habit: Habit)
    func delete(_ habit: Habit)
    func save()
}

// MARK: - Habit Repository

@available(iOS 17.0, macOS 14.0, *)
@MainActor
final class HabitRepository: HabitRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchAll(includeArchived: Bool = false) -> [Habit] {
        var descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        if !includeArchived {
            descriptor.predicate = #Predicate { !$0.isArchived }
        }
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func add(_ habit: Habit) {
        modelContext.insert(habit)
        habit.streak = Streak()
        save()
    }
    
    func delete(_ habit: Habit) {
        modelContext.delete(habit)
        save()
    }
    
    func save() {
        guard modelContext.hasChanges else { return }
        try? modelContext.save()
    }
}
