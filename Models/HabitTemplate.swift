import Foundation

struct HabitTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String?
    let iconName: String
    let color: HabitColor
    let category: Category
    
    enum Category: String, CaseIterable {
        case health = "Health"
        case productivity = "Productivity"
        case mindfulness = "Mindfulness"
        case fitness = "Fitness"
        case learning = "Learning"
        case lifestyle = "Lifestyle"
        
        var icon: String {
            switch self {
            case .health: "heart.fill"
            case .productivity: "briefcase.fill"
            case .mindfulness: "brain.head.profile"
            case .fitness: "figure.run"
            case .learning: "book.fill"
            case .lifestyle: "house.fill"
            }
        }
    }
    
    static let all: [HabitTemplate] = [
        // Health
        HabitTemplate(name: "Drink Water", description: "Stay hydrated with 8 glasses", iconName: "drop.fill", color: .teal, category: .health),
        HabitTemplate(name: "Take Vitamins", description: "Daily supplements", iconName: "pill.fill", color: .orange, category: .health),
        HabitTemplate(name: "Sleep 8 Hours", description: "Get enough rest", iconName: "bed.double.fill", color: .indigo, category: .health),
        HabitTemplate(name: "No Alcohol", description: "Stay sober", iconName: "wineglass", color: .purple, category: .health),
        
        // Fitness
        HabitTemplate(name: "Exercise", description: "30 min workout", iconName: "figure.run", color: .green, category: .fitness),
        HabitTemplate(name: "Walk 10K Steps", description: "Daily step goal", iconName: "figure.walk", color: .green, category: .fitness),
        HabitTemplate(name: "Stretch", description: "Morning stretches", iconName: "figure.flexibility", color: .teal, category: .fitness),
        HabitTemplate(name: "Yoga", description: "Daily yoga practice", iconName: "figure.yoga", color: .purple, category: .fitness),
        
        // Mindfulness
        HabitTemplate(name: "Meditate", description: "10 min mindfulness", iconName: "leaf.fill", color: .purple, category: .mindfulness),
        HabitTemplate(name: "Journal", description: "Write daily thoughts", iconName: "book.closed.fill", color: .orange, category: .mindfulness),
        HabitTemplate(name: "Gratitude", description: "List 3 things grateful for", iconName: "heart.fill", color: .pink, category: .mindfulness),
        HabitTemplate(name: "No Social Media", description: "Digital detox", iconName: "iphone.slash", color: .red, category: .mindfulness),
        
        // Productivity
        HabitTemplate(name: "Plan Tomorrow", description: "Evening planning", iconName: "checklist", color: .blue, category: .productivity),
        HabitTemplate(name: "Inbox Zero", description: "Clear your inbox", iconName: "envelope.fill", color: .blue, category: .productivity),
        HabitTemplate(name: "Deep Work", description: "2 hours focused work", iconName: "brain", color: .indigo, category: .productivity),
        HabitTemplate(name: "Review Goals", description: "Weekly goal review", iconName: "target", color: .red, category: .productivity),
        
        // Learning
        HabitTemplate(name: "Read", description: "Read 30 minutes", iconName: "book.fill", color: .blue, category: .learning),
        HabitTemplate(name: "Learn Language", description: "Practice a language", iconName: "globe", color: .green, category: .learning),
        HabitTemplate(name: "Practice Instrument", description: "Music practice", iconName: "music.note", color: .pink, category: .learning),
        HabitTemplate(name: "Code", description: "Write code daily", iconName: "laptopcomputer", color: .orange, category: .learning),
        
        // Lifestyle
        HabitTemplate(name: "Make Bed", description: "Start day organized", iconName: "bed.double", color: .teal, category: .lifestyle),
        HabitTemplate(name: "Cook at Home", description: "Prepare healthy meals", iconName: "fork.knife", color: .orange, category: .lifestyle),
        HabitTemplate(name: "Call Family", description: "Stay connected", iconName: "phone.fill", color: .green, category: .lifestyle),
        HabitTemplate(name: "Budget Review", description: "Track spending", iconName: "dollarsign.circle.fill", color: .green, category: .lifestyle),
    ]
    
    static func templates(for category: Category) -> [HabitTemplate] {
        all.filter { $0.category == category }
    }
}
