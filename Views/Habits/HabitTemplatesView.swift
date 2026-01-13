import SwiftUI

struct HabitTemplatesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: HabitTemplate.Category?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Category pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryPill(title: "All", isSelected: selectedCategory == nil) {
                                withAnimation { selectedCategory = nil }
                            }
                            
                            ForEach(HabitTemplate.Category.allCases, id: \.self) { category in
                                CategoryPill(
                                    title: category.rawValue,
                                    icon: category.icon,
                                    isSelected: selectedCategory == category
                                ) {
                                    withAnimation { selectedCategory = category }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Templates grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(filteredTemplates) { template in
                            TemplateCard(template: template) {
                                addHabit(from: template)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Add from Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private var filteredTemplates: [HabitTemplate] {
        guard let category = selectedCategory else {
            return HabitTemplate.all
        }
        return HabitTemplate.templates(for: category)
    }
    
    private func addHabit(from template: HabitTemplate) {
        let habit = Habit(
            name: template.name,
            description: template.description,
            iconName: template.iconName,
            color: template.color
        )
        HabitStore.shared.addHabit(habit)
        dismiss()
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
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color.systemGray6)
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

struct TemplateCard: View {
    let template: HabitTemplate
    let onAdd: () -> Void
    
    var body: some View {
        Button(action: onAdd) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: template.iconName)
                        .font(.title2)
                        .foregroundStyle(template.color.color)
                    
                    Spacer()
                    
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.secondary)
                }
                
                Text(template.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let description = template.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.systemGray6)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: UUID()) // Triggers on tap
    }
}

#Preview {
    HabitTemplatesView()
}
