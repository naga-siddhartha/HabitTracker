import SwiftUI

// MARK: - Haptic Feedback

extension View {
    @ViewBuilder
    func hapticFeedback<T: Equatable>(_ style: HapticStyle, trigger: T) -> some View {
        #if os(iOS)
        switch style {
        case .light: self.sensoryFeedback(.impact(weight: .light), trigger: trigger)
        case .success: self.sensoryFeedback(.success, trigger: trigger)
        case .selection: self.sensoryFeedback(.selection, trigger: trigger)
        }
        #else
        self
        #endif
    }
}

enum HapticStyle { case light, success, selection }

// MARK: - Pill Style

struct PillModifier: ViewModifier {
    var isSelected: Bool
    var selectedColor: Color = .accentColor
    
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? selectedColor : Color.systemGray6)
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
    }
}

extension View {
    func pillStyle(isSelected: Bool, selectedColor: Color = .accentColor) -> some View {
        modifier(PillModifier(isSelected: isSelected, selectedColor: selectedColor))
    }
}

// MARK: - Card border (visible on macOS)

extension View {
    /// Adds a subtle border so cards are visible on macOS where systemGray6/controlBackground can blend with the window.
    func cardBorder(cornerRadius: CGFloat = 12) -> some View {
        #if os(macOS)
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Color.primary.opacity(0.18), lineWidth: 1)
        )
        #else
        self
        #endif
    }
}

// MARK: - Cross-Platform Navigation

extension View {
    @ViewBuilder
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
