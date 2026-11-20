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

extension View {
    /// Success haptic when a habit becomes done, a light tap when it's undone.
    @ViewBuilder
    func completionHaptic(isDone: Bool) -> some View {
        #if os(iOS)
        self.sensoryFeedback(trigger: isDone) { wasDone, nowDone in
            nowDone && !wasDone ? .success : .impact(weight: .light)
        }
        #else
        self
        #endif
    }
}

/// Haptic feedback kinds used by controls.
enum HapticStyle { case light, success, selection }

// MARK: - Swipe actions outside List

extension View {
    /// Makes `swipeActions` work on rows inside this scroll view. No-op before iOS/macOS 27.
    @ViewBuilder
    func swipeActionsContainerIfAvailable() -> some View {
        if #available(iOS 27.0, macOS 27.0, *) {
            self.swipeActionsContainer()
        } else {
            self
        }
    }
}

// MARK: - Pill Style

struct PillModifier: ViewModifier {
    var isSelected: Bool
    var selectedColor: Color = .brandPurple

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
    func pillStyle(isSelected: Bool, selectedColor: Color = .brandPurple) -> some View {
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
