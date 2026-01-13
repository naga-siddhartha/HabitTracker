import Foundation
import UIKit
import Combine

/// Service for generating AI icons for habits
class IconGenerationService: ObservableObject {
    static let shared = IconGenerationService()
    
    private let apiKey: String? // Will be set via configuration
    private let baseURL = "https://api.openai.com/v1/images/generations"
    
    private init() {
        // Load API key from environment or configuration
        // For now, this will need to be configured
    }
    
    /// Generate an icon for a habit using AI
    /// - Parameters:
    ///   - habitName: Name of the habit
    ///   - description: Optional description of the habit
    ///   - style: Style of icon (e.g., "minimalist", "cartoon", "realistic")
    /// - Returns: Image data if successful
    func generateIcon(
        for habitName: String,
        description: String? = nil,
        style: String = "minimalist"
    ) async throws -> Data? {
        // TODO: Implement actual API call to OpenAI DALL-E or similar service
        // For now, return nil as placeholder
        
        let prompt = buildPrompt(habitName: habitName, description: description, style: style)
        
        // Placeholder implementation
        // In production, this would make an actual API call
        print("Generating icon with prompt: \(prompt)")
        
        return nil
    }
    
    /// Generate icon using a local fallback (SF Symbols or system icons)
    func generateLocalIcon(for habitName: String) -> String {
        // Map common habit names to SF Symbols
        let iconMap: [String: String] = [
            "exercise": "figure.run",
            "workout": "figure.run",
            "gym": "dumbbell.fill",
            "meditation": "leaf.fill",
            "reading": "book.fill",
            "writing": "pencil",
            "water": "drop.fill",
            "sleep": "bed.double.fill",
            "journal": "book.closed.fill",
            "study": "book.fill",
            "yoga": "figure.flexibility",
            "walk": "figure.walk",
            "run": "figure.run",
            "code": "laptopcomputer",
            "music": "music.note",
            "piano": "pianokeys",
            "guitar": "guitars.fill"
        ]
        
        let lowercased = habitName.lowercased()
        
        // Check for exact match
        if let icon = iconMap[lowercased] {
            return icon
        }
        
        // Check for partial match
        for (key, icon) in iconMap {
            if lowercased.contains(key) {
                return icon
            }
        }
        
        // Default icon
        return "star.fill"
    }
    
    private func buildPrompt(habitName: String, description: String?, style: String) -> String {
        var prompt = "A simple, minimalist icon representing \(habitName)"
        
        if let description = description, !description.isEmpty {
            prompt += ". \(description)"
        }
        
        prompt += ". Style: \(style). Icon should be suitable for a mobile app, clean and recognizable at small sizes."
        
        return prompt
    }
    
    /// Save generated icon to local storage
    func saveIcon(_ imageData: Data, for habitId: UUID) -> String? {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let iconsDirectory = documentsPath.appendingPathComponent(Constants.IconGeneration.cacheDirectory)
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: iconsDirectory, withIntermediateDirectories: true)
        
        let fileName = "\(habitId.uuidString).png"
        let fileURL = iconsDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            return fileName
        } catch {
            print("Error saving icon: \(error)")
            return nil
        }
    }
    
    /// Load icon from local storage
    func loadIcon(fileName: String) -> Data? {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let iconsDirectory = documentsPath.appendingPathComponent(Constants.IconGeneration.cacheDirectory)
        let fileURL = iconsDirectory.appendingPathComponent(fileName)
        
        return try? Data(contentsOf: fileURL)
    }
}
