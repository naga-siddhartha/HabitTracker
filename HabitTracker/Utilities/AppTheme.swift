import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Appearance (light / dark / system)

enum AppearanceMode: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }

    /// Use with .preferredColorScheme(); nil = follow system.
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

// MARK: - App Theme (single source of truth for headings and shared UI)

enum AppTheme {

    // MARK: - Headings (cursive, character)

    /// Custom cursive font "Dancing Script" for page titles. Add DancingScript-Regular.ttf to the project (see Fonts/README.md).
    private static let cursiveFontName = "Dancing Script"
    private static let pageTitleSize: CGFloat = 48

    private static var isCursiveFontAvailable: Bool {
        #if os(iOS)
        return UIFont(name: cursiveFontName, size: pageTitleSize) != nil
        #elseif os(macOS)
        return NSFont(name: cursiveFontName, size: pageTitleSize) != nil
        #else
        return false
        #endif
    }

    /// Main page heading: Dancing Script cursive at 48pt. Falls back to system if font not loaded.
    static var pageTitleFont: Font {
        isCursiveFontAvailable
            ? Font.custom(cursiveFontName, size: pageTitleSize)
            : Font.system(size: pageTitleSize, weight: .medium)
    }

    /// Subtitle or date line under the page title (e.g. "March 3" on Home).
    static let pageSubtitleFont = Font.system(size: 17, weight: .medium)

    // MARK: - Heading layout (reused everywhere)

    static let headingTopPadding: CGFloat = 16
    static let headingBottomPadding: CGFloat = 8
    static let headingSpacing: CGFloat = 6
}

// MARK: - Reusable page heading (one module for all views)

struct PageHeading: View {
    let title: String
    var subtitle: String? = nil

    private let config = LayoutConfig.current

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.headingSpacing) {
            Text(title)
                .font(AppTheme.pageTitleFont)
                .foregroundStyle(.primary)
            if let subtitle {
                Text(subtitle)
                    .font(AppTheme.pageSubtitleFont)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, config.horizontalPadding)
        .padding(.top, AppTheme.headingTopPadding)
        .padding(.bottom, AppTheme.headingBottomPadding)
    }
}
