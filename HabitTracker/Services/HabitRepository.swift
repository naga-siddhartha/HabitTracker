import Foundation
import SwiftData
import WidgetKit

// MARK: - Repository Protocol

@available(iOS 17.0, macOS 14.0, *)
protocol HabitRepositoryProtocol {
    func fetchAll() -> [Habit]
    func add(_ habit: Habit)
    func delete(_ habit: Habit)
    func deleteAll()
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
    
    func fetchAll() -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
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

    func deleteAll() {
        do {
            try modelContext.delete(model: Habit.self)
        } catch {
            let descriptor = FetchDescriptor<Habit>()
            guard let all = try? modelContext.fetch(descriptor) else { return }
            for habit in all {
                modelContext.delete(habit)
            }
        }
        save()
    }

    func save() {
        guard modelContext.hasChanges else { return }
        try? modelContext.save()
    }
}
