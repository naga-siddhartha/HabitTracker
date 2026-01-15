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

// MARK: - Card Style

struct CardModifier: ViewModifier {
    var padding: CGFloat = 14
    var cornerRadius: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.systemBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

extension View {
    func cardStyle(padding: CGFloat = 14, cornerRadius: CGFloat = 16) -> some View {
        modifier(CardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}

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

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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
