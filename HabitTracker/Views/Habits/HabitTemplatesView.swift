import SwiftUI
import SwiftData

struct HabitTemplatesView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @State private var selectedCategory: HabitTemplate.Category?
    @State private var editingHabit: Habit?
    
    private var filteredTemplates: [HabitTemplate] {
        selectedCategory.map { HabitTemplate.byCategory[$0] ?? [] } ?? HabitTemplate.all
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Your habits") {
                    if habits.isEmpty {
                        Text("No habits yet. Add one from a template below.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(habits) { habit in
                            HabitEditRow(habit: habit) {
                                editingHabit = habit
                            }
                        }
                    }
                }
                
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryPill(title: "All", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            ForEach(HabitTemplate.Category.allCases, id: \.self) { category in
                                CategoryPill(title: category.rawValue, icon: category.icon, isSelected: selectedCategory == category) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Templates")
                }
                
                Section {
                    ForEach(filteredTemplates) { template in
                        TemplateRow(template: template) {
                            addHabit(from: template)
                        }
                    }
                }
            }
            .navigationTitle("Templates")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $editingHabit) { habit in
                AddEditHabitView(habit: habit)
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
    
    private func addHabit(from template: HabitTemplate) {
        HabitStore.shared.addHabit(Habit(
            name: template.name,
            description: template.description,
            iconName: template.iconName,
            emoji: HabitEmoji.suggest(for: template.name, description: template.description),
            color: template.color
        ))
        dismiss()
    }
}

struct HabitEditRow: View {
    let habit: Habit
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                if let emoji = habit.emoji, !emoji.isEmpty {
                    Text(emoji).font(.body)
                } else {
                    Image(systemName: habit.iconName ?? "circle.fill")
                        .font(.body)
                        .foregroundStyle(habit.color.color)
                        .frame(width: 28)
                }
                Text(habit.name).foregroundStyle(.primary)
                Spacer()
                Image(systemName: "pencil")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct TemplateRow: View {
    let template: HabitTemplate
    let onAdd: () -> Void
    
    var body: some View {
        Button(action: onAdd) {
            HStack(spacing: 12) {
                Image(systemName: template.iconName)
                    .font(.title3)
                    .foregroundStyle(template.color.color)
                    .frame(width: 32)
                VStack(alignment: .leading) {
                    Text(template.name).font(.headline)
                    if let desc = template.description {
                        Text(desc).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .buttonStyle(.plain)
    }
}

struct CategoryPill: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon { Image(systemName: icon).font(.caption) }
                Text(title)
            }
            .pillStyle(isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HabitTemplatesView()
}
