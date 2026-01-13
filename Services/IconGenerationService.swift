import Foundation
import Observation

@Observable
final class IconGenerationService {
    static let shared = IconGenerationService()
    
    private let iconMap: [String: String] = [
        "exercise": "figure.run", "workout": "figure.run", "gym": "dumbbell.fill",
        "meditation": "leaf.fill", "reading": "book.fill", "writing": "pencil",
        "water": "drop.fill", "sleep": "bed.double.fill", "journal": "book.closed.fill",
        "study": "book.fill", "yoga": "figure.flexibility", "walk": "figure.walk",
        "run": "figure.run", "code": "laptopcomputer", "music": "music.note"
    ]
    
    private init() {}
    
    func generateLocalIcon(for habitName: String) -> String {
        let lowercased = habitName.lowercased()
        
        if let icon = iconMap[lowercased] { return icon }
        
        for (key, icon) in iconMap where lowercased.contains(key) {
            return icon
        }
        
        return "star.fill"
    }
}
