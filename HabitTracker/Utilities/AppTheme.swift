import SwiftUI

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

    // MARK: - Headings (system font, modern)

    /// Page title: SF Pro, large and sleek.
    static let pageTitleFont = Font.system(size: 38, weight: .semibold)

    /// Subtitle or date line under the page title (e.g. "March 3" on Home).
    static let pageSubtitleFont = Font.system(size: 19, weight: .medium)

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
