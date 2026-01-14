import SwiftUI

struct HabitTemplatesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: HabitTemplate.Category?
    
    private var filteredTemplates: [HabitTemplate] {
        selectedCategory.map { HabitTemplate.byCategory[$0] ?? [] } ?? HabitTemplate.all
    }
    
    var body: some View {
        NavigationStack {
            List {
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
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                
                ForEach(filteredTemplates) { template in
                    Button { addHabit(from: template) } label: {
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
                            Image(systemName: "plus.circle.fill").foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func addHabit(from template: HabitTemplate) {
        HabitStore.shared.addHabit(Habit(
            name: template.name,
            description: template.description,
            iconName: template.iconName,
            color: template.color
        ))
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
                if let icon { Image(systemName: icon).font(.caption) }
                Text(title).font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HabitTemplatesView()
}
