import Foundation

// MARK: - Habit Emoji (keyword → emoji for automatic assignment)

/// Maps habit names to emojis using common activity keywords. Matches whole words and stems
/// so "dancing" matches "dance", "running" matches "run", etc.
enum HabitEmoji {
    /// Keyword (substring) → single emoji. Order matters: first match wins; put more specific terms first.
    static let keywords: [String: String] = [
        // Movement & dance (specific first)
        "dancing": "💃",
        "dance": "💃",
        "party": "🎉",
        "celebrate": "🎉",
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
        "climb": "🧗",
        "skate": "🛼",
        "ski": "⛷️",
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
        "teeth": "🦷",
        "floss": "🦷",
        "skin": "✨",
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
        "pray": "🙏",
        // Work & productivity
        "work": "💼",
        "focus": "🎯",
        "plan": "📋",
        "inbox": "📥",
        "deep work": "🧠",
        "goal": "🎯",
        "task": "✅",
        "todo": "📋",
        // Home & lifestyle
        "clean": "🧹",
        "tidy": "🧹",
        "cook": "🍳",
        "eat": "🍽️",
        "meal": "🍽️",
        "budget": "💰",
        "money": "💰",
        "save": "💰",
        "call": "📞",
        "family": "👨‍👩‍👧‍👦",
        "home": "🏠",
        "make bed": "🛏️",
        "laundry": "🧺",
        // Social & creativity
        "music": "🎵",
        "instrument": "🎸",
        "guitar": "🎸",
        "piano": "🎹",
        "sing": "🎤",
        "paint": "🎨",
        "draw": "✏️",
        "photo": "📷",
        "social": "📱",
        "alcohol": "🍷",
        "no alcohol": "🚫",
        "sober": "🌟",
        "coffee": "☕",
        "tea": "🍵",
    ]

    /// Default emojis when no keyword matches (picked by hash for consistency).
    static let defaults = ["✨", "⭐", "🔥", "💡", "🎯", "🌱", "✅", "📌"]

    /// Emojis shown in the Add/Edit habit picker (defaults + common habit emojis).
    static let pickerEmojis = [
        "✨", "⭐", "🔥", "💡", "🎯", "🌱", "✅", "📌",
        "🏃", "🚶", "💪", "🧘", "💃", "📖", "📝", "💧", "😴",
        "❤️", "🎵", "🍳", "💰", "📱", "🏠", "💼", "🧠",
    ]

    /// Full grid for the emoji picker sheet (no text input, tap to choose). Categories for scanability.
    static let gridEmojis: [(category: String, emojis: [String])] = [
        ("Suggested & favorites", ["✨", "⭐", "🔥", "💡", "🎯", "🌱", "✅", "📌", "💃", "🧠"]),
        ("Fitness & movement", ["🏃", "🚶", "💪", "🧘", "🤸", "🚴", "🏊", "🥾", "🧗", "🛼", "⛷️", "🏋️"]),
        ("Health & body", ["💧", "😴", "🌅", "🛏️", "💊", "❤️", "🌬️", "🦷", "🧹"]),
        ("Mind & learning", ["📖", "📚", "🎓", "🗣️", "💻", "✍️", "📝", "🙏", "🪷"]),
        ("Work & productivity", ["💼", "🎯", "📋", "📥"]),
        ("Home & lifestyle", ["🍳", "🍽️", "💰", "📞", "🏠", "🧺", "☕", "🍵"]),
        ("Creative & social", ["🎵", "🎸", "🎹", "🎤", "🎨", "✏️", "📷", "📱", "🎉", "🍷", "🚫"]),
    ]

    /// Returns an emoji for the given habit name (and optional description).
    /// Matches keywords against the combined text; each word is also checked so "dancing" matches "dance".
    static func suggest(for name: String, description: String? = nil) -> String {
        let combined = "\(name) \(description ?? "")".lowercased()
        let words = combined.split(separator: " ").map(String.init)
        for (keyword, emoji) in keywords {
            if combined.contains(keyword) { return emoji }
            for word in words {
                if word.hasPrefix(keyword) || keyword.hasPrefix(word) { return emoji }
            }
        }
        let index = abs(name.hashValue) % defaults.count
        return defaults[index]
    }

    /// Takes the first visible emoji (extended grapheme cluster) from a string. Use for custom emoji input to avoid crashes.
    static func firstEmoji(from string: String) -> String? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return nil }
        return String(first)
    }
}
