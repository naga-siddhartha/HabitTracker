import Foundation

// MARK: - Habit Emoji (keyword → emoji for automatic assignment)

/// Maps habit names to emojis using common activity keywords. Based on habit-tracking and
/// self-improvement emoji conventions (e.g. habit tracker emoji lists, fitness/wellness apps).
enum HabitEmoji {
    /// Keyword (substring) → single emoji. Order matters: first match wins; put more specific terms first.
    static let keywords: [String: String] = [
        // Fitness & movement
        "run": "🏃",
        "running": "🏃",
        "jog": "🏃",
        "walk": "🚶",
        "exercise": "💪",
        "gym": "💪",
        "workout": "💪",
        "lift": "🏋️",
        "yoga": "🧘",
        "meditat": "🧘",
        "stretch": "🤸",
        "cycle": "🚴",
        "bike": "🚴",
        "swim": "🏊",
        "hike": "🥾",
        // Health & body
        "water": "💧",
        "drink": "💧",
        "hydrat": "💧",
        "sleep": "😴",
        "wake": "🌅",
        "bed": "🛏️",
        "vitamin": "💊",
        "pill": "💊",
        "medicin": "💊",
        "health": "❤️",
        "heart": "❤️",
        "breath": "🌬️",
        // Mind & learning
        "read": "📖",
        "book": "📖",
        "study": "📚",
        "learn": "🎓",
        "language": "🗣️",
        "code": "💻",
        "programming": "💻",
        "write": "✍️",
        "journal": "📝",
        "gratitude": "🙏",
        "mindful": "🪷",
        // Work & productivity
        "work": "💼",
        "focus": "🎯",
        "plan": "📋",
        "inbox": "📥",
        "deep work": "🧠",
        "goal": "🎯",
        // Home & lifestyle
        "clean": "✨",
        "cook": "🍳",
        "eat": "🍽️",
        "meal": "🍽️",
        "budget": "💰",
        "money": "💰",
        "call": "📞",
        "family": "👨‍👩‍👧‍👦",
        "home": "🏠",
        "make bed": "🛏️",
        // Social & creativity
        "music": "🎵",
        "instrument": "🎸",
        "paint": "🎨",
        "draw": "✏️",
        "photo": "📷",
        "social": "📱",
        "alcohol": "🍷",
        "no alcohol": "🚫",
        "sober": "🌟",
    ]

    /// Default emojis when no keyword matches (picked by hash for consistency).
    static let defaults = ["✨", "⭐", "🔥", "💡", "🎯", "🌱", "✅", "📌"]

    /// Emojis shown in the Add/Edit habit picker (defaults + common habit emojis).
    static let pickerEmojis = [
        "✨", "⭐", "🔥", "💡", "🎯", "🌱", "✅", "📌",
        "🏃", "🚶", "💪", "🧘", "📖", "📝", "💧", "😴",
        "❤️", "🎵", "🍳", "💰", "📱", "🏠", "💼", "🧠",
    ]

    /// Returns an emoji for the given habit name (and optional description). Uses keyword match first, then a stable default.
    static func suggest(for name: String, description: String? = nil) -> String {
        let combined = "\(name) \(description ?? "")".lowercased()
        for (keyword, emoji) in keywords {
            if combined.contains(keyword) { return emoji }
        }
        let index = abs(name.hashValue) % defaults.count
        return defaults[index]
    }
}
