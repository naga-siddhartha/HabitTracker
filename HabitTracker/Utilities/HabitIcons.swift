import Foundation

// MARK: - Habit Icons

enum HabitIcons {
    static let keywords: [String: String] = [
        "run": "figure.run", "walk": "figure.walk", "exercise": "dumbbell.fill", "gym": "dumbbell.fill",
        "water": "drop.fill", "drink": "cup.and.saucer.fill", "sleep": "moon.fill", "wake": "sun.max.fill",
        "meditat": "brain.head.profile", "vitamin": "pills.fill", "health": "heart.fill",
        "read": "book.fill", "study": "book.fill", "write": "pencil", "journal": "pencil",
        "work": "briefcase.fill", "code": "chevron.left.forwardslash.chevron.right", "learn": "graduationcap.fill",
        "clean": "sparkles", "cook": "fork.knife", "eat": "fork.knife", "budget": "creditcard.fill",
        "call": "phone.fill", "email": "envelope.fill", "home": "house.fill",
        "gratitude": "heart.fill", "breath": "wind", "yoga": "figure.yoga", "relax": "leaf.fill"
    ]

    static let defaults = ["star.fill", "heart.fill", "leaf.fill", "flame.fill", "bolt.fill",
        "sparkles", "moon.fill", "sun.max.fill", "drop.fill", "figure.run"]

    static let all = [
        "figure.run", "figure.walk", "dumbbell.fill", "heart.fill", "book.fill",
        "pencil", "drop.fill", "moon.fill", "sun.max.fill", "leaf.fill",
        "brain.head.profile", "cup.and.saucer.fill", "fork.knife", "pills.fill",
        "creditcard.fill", "phone.fill", "envelope.fill", "house.fill",
        "star.fill", "flame.fill", "bolt.fill", "sparkles", "graduationcap.fill",
        "briefcase.fill", "music.note", "gamecontroller.fill", "paintbrush.fill", "camera.fill"
    ]

    static func suggest(for name: String) -> String {
        let lowercased = name.lowercased()
        for (keyword, icon) in keywords {
            if lowercased.contains(keyword) { return icon }
        }
        return defaults[abs(name.hashValue) % defaults.count]
    }
}
