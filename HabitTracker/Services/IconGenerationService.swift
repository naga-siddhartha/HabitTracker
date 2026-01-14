import Foundation

final class IconGenerationService {
    static let shared = IconGenerationService()
    
    private let localIconMap: [String: String] = [
        // Exercise & Fitness
        "exercise": "figure.run", "workout": "figure.run", "gym": "dumbbell.fill",
        "fitness": "figure.run", "cardio": "heart.circle.fill",
        "yoga": "figure.yoga", "walk": "figure.walk", "walking": "figure.walk",
        "run": "figure.run", "running": "figure.run", "jog": "figure.run",
        "stretch": "figure.flexibility", "stretching": "figure.flexibility",
        "swim": "figure.pool.swim", "swimming": "figure.pool.swim",
        "bike": "bicycle", "cycling": "bicycle", "hike": "figure.hiking",
        "weights": "dumbbell.fill", "lift": "dumbbell.fill",
        
        // Mind & Learning
        "meditation": "leaf.fill", "meditate": "leaf.fill", "mindfulness": "brain.head.profile",
        "reading": "book.fill", "read": "book.fill", "books": "books.vertical.fill",
        "study": "graduationcap.fill", "learn": "brain.head.profile",
        "writing": "pencil", "write": "pencil", "journal": "book.closed.fill",
        "language": "character.bubble.fill", "practice": "star.fill",
        
        // Health & Wellness
        "water": "drop.fill", "drink": "drop.fill", "hydrate": "drop.fill",
        "sleep": "bed.double.fill", "rest": "bed.double.fill", "nap": "zzz",
        "vitamins": "pill.fill", "medicine": "pill.fill", "pills": "pill.fill",
        "supplement": "pill.fill", "medication": "pill.fill",
        "floss": "mouth.fill", "teeth": "mouth.fill", "dental": "mouth.fill",
        "skincare": "face.smiling", "skin": "face.smiling",
        "shower": "shower.fill", "hygiene": "hands.sparkles.fill",
        "posture": "figure.stand", "breathe": "wind", "breathing": "wind",
        
        // Food & Nutrition
        "breakfast": "fork.knife", "lunch": "fork.knife", "dinner": "fork.knife",
        "meal": "fork.knife", "eat": "fork.knife", "food": "fork.knife",
        "cook": "frying.pan.fill", "cooking": "frying.pan.fill",
        "healthy": "carrot.fill", "vegetables": "carrot.fill", "fruit": "apple.logo",
        "coffee": "cup.and.saucer.fill", "tea": "mug.fill",
        "no sugar": "xmark.circle.fill", "diet": "scalemass.fill",
        
        // Productivity & Work
        "code": "laptopcomputer", "coding": "laptopcomputer",
        "programming": "chevron.left.forwardslash.chevron.right",
        "work": "briefcase.fill", "task": "checklist", "tasks": "checklist",
        "email": "envelope.fill", "inbox": "tray.fill",
        "meeting": "person.3.fill", "plan": "calendar", "organize": "folder.fill",
        "focus": "scope", "deep work": "brain.head.profile",
        
        // Creative & Hobbies
        "music": "music.note", "piano": "pianokeys", "guitar": "guitars",
        "sing": "music.mic", "singing": "music.mic", "instrument": "music.note.list",
        "art": "paintbrush.fill", "draw": "pencil.tip", "drawing": "pencil.tip",
        "paint": "paintbrush.fill", "craft": "scissors", "photo": "camera.fill",
        "game": "gamecontroller.fill", "gaming": "gamecontroller.fill",
        
        // Social & Relationships
        "call": "phone.fill", "family": "figure.2.and.child.holdinghands",
        "friends": "person.2.fill", "social": "bubble.left.and.bubble.right.fill",
        "date": "heart.fill", "relationship": "heart.fill",
        "volunteer": "hand.raised.fill", "help": "hands.sparkles.fill",
        
        // Spiritual & Mental
        "prayer": "hands.sparkles.fill", "pray": "hands.sparkles.fill",
        "gratitude": "heart.fill", "grateful": "heart.fill", "thankful": "heart.fill",
        "affirmation": "text.quote", "reflect": "sparkles", "reflection": "sparkles",
        
        // Finance
        "budget": "dollarsign.circle.fill", "save": "banknote.fill",
        "money": "dollarsign.circle.fill", "invest": "chart.line.uptrend.xyaxis",
        "expense": "creditcard.fill", "spending": "cart.fill",
        
        // Home & Life
        "clean": "sparkles", "cleaning": "sparkles", "tidy": "sparkles",
        "laundry": "washer.fill", "dishes": "sink.fill",
        "pet": "pawprint.fill", "dog": "dog.fill", "cat": "cat.fill",
        "plant": "leaf.fill", "garden": "leaf.fill", "water plants": "drop.fill",
        "declutter": "trash.fill",
        
        // Habits to break
        "no phone": "iphone.slash", "screen time": "hourglass",
        "no alcohol": "xmark.circle.fill", "quit": "xmark.circle.fill",
        "no smoking": "nosign", "limit": "minus.circle.fill"
    ]
    
    private init() {}
    
    func suggestIcon(for habitName: String) async -> String {
        generateLocalIcon(for: habitName)
    }
    
    func generateLocalIcon(for habitName: String) -> String {
        let lowercased = habitName.lowercased()
        
        // Exact match
        if let icon = localIconMap[lowercased] { return icon }
        
        // Partial match
        for (key, icon) in localIconMap where lowercased.contains(key) {
            return icon
        }
        
        // Word match
        let words = lowercased.split(separator: " ").map(String.init)
        for word in words {
            if let icon = localIconMap[word] { return icon }
        }
        
        return "star.fill"
    }
}
