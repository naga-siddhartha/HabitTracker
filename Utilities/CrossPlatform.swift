import SwiftUI

// MARK: - Cross-Platform Colors
extension Color {
    static var systemBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemBackground)
        #endif
    }
    
    static var secondarySystemBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(uiColor: .secondarySystemBackground)
        #endif
    }
    
    static var tertiarySystemBackground: Color {
        #if os(macOS)
        Color(nsColor: .textBackgroundColor)
        #else
        Color(uiColor: .tertiarySystemBackground)
        #endif
    }
    
    static var systemGray6: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #elseif os(watchOS)
        Color.gray.opacity(0.2)
        #else
        Color(uiColor: .systemGray6)
        #endif
    }
    
    static var systemGray4: Color {
        #if os(macOS)
        Color(nsColor: .systemGray)
        #elseif os(watchOS)
        Color.gray.opacity(0.4)
        #else
        Color(uiColor: .systemGray4)
        #endif
    }
}
