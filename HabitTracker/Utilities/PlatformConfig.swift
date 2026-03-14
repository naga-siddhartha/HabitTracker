import SwiftUI

// MARK: - Platform Configuration

enum Platform {
    case iOS, macOS, visionOS
    
    static var current: Platform {
        #if os(iOS)
        return .iOS
        #elseif os(macOS)
        return .macOS
        #elseif os(visionOS)
        return .visionOS
        #else
        return .iOS
        #endif
    }
    
    var isCompact: Bool {
        self == .iOS
    }
}

// MARK: - Layout Configuration

struct LayoutConfig {
    let contentMaxWidth: CGFloat
    let horizontalPadding: CGFloat
    let cardCornerRadius: CGFloat
    let cardPadding: CGFloat
    let sheetWidth: CGFloat?
    let sheetHeight: CGFloat?
    let iconGridColumns: Int
    let iconSize: CGFloat
    let buttonStyle: ButtonStyleType
    
    // Spacing (used consistently across the app)
    let spacingXS: CGFloat
    let spacingS: CGFloat
    let spacingM: CGFloat
    let spacingL: CGFloat
    let spacingXL: CGFloat
    let spacingXXL: CGFloat
    
    // Card and section padding
    let cardContentPaddingHorizontal: CGFloat
    let cardRowPaddingVertical: CGFloat
    let sectionHeaderTop: CGFloat
    let sectionHeaderBottom: CGFloat
    let progressHeaderTop: CGFloat
    let progressHeaderBottom: CGFloat
    let listRowLeadingInset: CGFloat
    let progressDividerLeadingInset: CGFloat
    let cardBottomPaddingExtra: CGFloat
    let cardBottomPaddingSmall: CGFloat
    
    // Corner radii
    let cornerRadiusSmall: CGFloat
    let cornerRadiusMedium: CGFloat
    
    // Control and icon sizes
    let checkboxSize: CGFloat
    let iconSizeRow: CGFloat
    let iconSizeButton: CGFloat
    let progressRingSize: CGFloat
    let cardShadowRadius: CGFloat

    // Form and sheet layout (macOS section spacing, picker sheet sizes)
    let formSectionSpacing: CGFloat
    let sheetHeaderPaddingHorizontal: CGFloat
    let sheetHeaderPaddingTop: CGFloat
    let sheetHeaderPaddingBottom: CGFloat
    let emojiPickerMinWidth: CGFloat
    let emojiPickerMinHeight: CGFloat
    let colorPickerMinWidth: CGFloat
    let colorPickerMinHeight: CGFloat
    let emojiGridColumns: Int
    let emojiGridSpacing: CGFloat
    let emojiCellSize: CGFloat
    let colorGridColumns: Int
    let colorChipSize: CGFloat

    enum ButtonStyleType {
        case custom, system
    }
    
    static var current: LayoutConfig {
        switch Platform.current {
        case .iOS:
            return LayoutConfig(
                contentMaxWidth: .infinity,
                horizontalPadding: 20,
                cardCornerRadius: 16,
                cardPadding: 14,
                sheetWidth: nil,
                sheetHeight: nil,
                iconGridColumns: 7,
                iconSize: 36,
                buttonStyle: .custom,
                spacingXS: 4,
                spacingS: 8,
                spacingM: 12,
                spacingL: 16,
                spacingXL: 20,
                spacingXXL: 24,
                cardContentPaddingHorizontal: 20,
                cardRowPaddingVertical: 10,
                sectionHeaderTop: 16,
                sectionHeaderBottom: 12,
                progressHeaderTop: 22,
                progressHeaderBottom: 16,
                listRowLeadingInset: 96,
                progressDividerLeadingInset: 112,
                cardBottomPaddingExtra: 12,
                cardBottomPaddingSmall: 6,
                cornerRadiusSmall: 8,
                cornerRadiusMedium: 12,
                checkboxSize: 34,
                iconSizeRow: 28,
                iconSizeButton: 44,
                progressRingSize: 72,
                cardShadowRadius: 8,
                formSectionSpacing: 20,
                sheetHeaderPaddingHorizontal: 16,
                sheetHeaderPaddingTop: 16,
                sheetHeaderPaddingBottom: 12,
                emojiPickerMinWidth: 0,
                emojiPickerMinHeight: 0,
                colorPickerMinWidth: 0,
                colorPickerMinHeight: 0,
                emojiGridColumns: 6,
                emojiGridSpacing: 10,
                emojiCellSize: 44,
                colorGridColumns: 5,
                colorChipSize: 44
            )
        case .macOS:
            return LayoutConfig(
                contentMaxWidth: .infinity,
                horizontalPadding: 20,
                cardCornerRadius: 12,
                cardPadding: 12,
                sheetWidth: 420,
                sheetHeight: 480,
                iconGridColumns: 7,
                iconSize: 32,
                buttonStyle: .system,
                spacingXS: 4,
                spacingS: 8,
                spacingM: 12,
                spacingL: 16,
                spacingXL: 20,
                spacingXXL: 24,
                cardContentPaddingHorizontal: 20,
                cardRowPaddingVertical: 10,
                sectionHeaderTop: 16,
                sectionHeaderBottom: 12,
                progressHeaderTop: 22,
                progressHeaderBottom: 16,
                listRowLeadingInset: 96,
                progressDividerLeadingInset: 112,
                cardBottomPaddingExtra: 12,
                cardBottomPaddingSmall: 6,
                cornerRadiusSmall: 8,
                cornerRadiusMedium: 12,
                checkboxSize: 34,
                iconSizeRow: 28,
                iconSizeButton: 44,
                progressRingSize: 72,
                cardShadowRadius: 8,
                formSectionSpacing: 10,
                sheetHeaderPaddingHorizontal: 20,
                sheetHeaderPaddingTop: 12,
                sheetHeaderPaddingBottom: 10,
                emojiPickerMinWidth: 400,
                emojiPickerMinHeight: 420,
                colorPickerMinWidth: 280,
                colorPickerMinHeight: 320,
                emojiGridColumns: 6,
                emojiGridSpacing: 12,
                emojiCellSize: 44,
                colorGridColumns: 5,
                colorChipSize: 44
            )
        case .visionOS:
            return LayoutConfig(
                contentMaxWidth: .infinity,
                horizontalPadding: 24,
                cardCornerRadius: 20,
                cardPadding: 16,
                sheetWidth: 500,
                sheetHeight: 600,
                iconGridColumns: 8,
                iconSize: 44,
                buttonStyle: .system,
                spacingXS: 4,
                spacingS: 8,
                spacingM: 12,
                spacingL: 16,
                spacingXL: 20,
                spacingXXL: 24,
                cardContentPaddingHorizontal: 24,
                cardRowPaddingVertical: 10,
                sectionHeaderTop: 16,
                sectionHeaderBottom: 12,
                progressHeaderTop: 22,
                progressHeaderBottom: 16,
                listRowLeadingInset: 96,
                progressDividerLeadingInset: 112,
                cardBottomPaddingExtra: 12,
                cardBottomPaddingSmall: 6,
                cornerRadiusSmall: 8,
                cornerRadiusMedium: 12,
                checkboxSize: 34,
                iconSizeRow: 28,
                iconSizeButton: 44,
                progressRingSize: 72,
                cardShadowRadius: 8,
                formSectionSpacing: 20,
                sheetHeaderPaddingHorizontal: 24,
                sheetHeaderPaddingTop: 16,
                sheetHeaderPaddingBottom: 12,
                emojiPickerMinWidth: 440,
                emojiPickerMinHeight: 460,
                colorPickerMinWidth: 300,
                colorPickerMinHeight: 360,
                emojiGridColumns: 6,
                emojiGridSpacing: 12,
                emojiCellSize: 44,
                colorGridColumns: 5,
                colorChipSize: 44
            )
        }
    }
}

// MARK: - Adaptive Button

struct AdaptiveButton: View {
    let title: String
    let icon: String?
    let role: ButtonRole?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.role = role
        self.action = action
    }
    
    var body: some View {
        Button(role: role, action: action) {
            if let icon {
                Label(title, systemImage: icon)
            } else {
                Text(title)
            }
        }
        .buttonStyle(.borderedProminent)
    }
}

struct AdaptiveSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            if let icon {
                Label(title, systemImage: icon)
            } else {
                Text(title)
            }
        }
        .buttonStyle(.bordered)
    }
}

// MARK: - Adaptive Form

struct AdaptiveForm<Content: View>: View {
    let title: String
    let onCancel: () -> Void
    let onSave: () -> Void
    let saveDisabled: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        #if os(macOS)
        macOSForm
        #else
        iOSForm
        #endif
    }
    
    #if os(macOS)
    private var macOSForm: some View {
        let config = LayoutConfig.current
        return VStack(spacing: 0) {
            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Text(title).font(.headline)
                Spacer()
                Button("Save", action: onSave)
                    .keyboardShortcut(.defaultAction)
                    .disabled(saveDisabled)
            }
            .padding(.horizontal, config.sheetHeaderPaddingHorizontal)
            .padding(.vertical, 10)
            
            Divider()
            
            ScrollView {
                content()
                    .padding(.horizontal, config.sheetHeaderPaddingHorizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
            }
        }
        .frame(width: config.sheetWidth ?? 420,
               height: config.sheetHeight ?? 480)
    }
    #endif
    
    #if os(iOS)
    private var iOSForm: some View {
        NavigationStack {
            Form {
                content()
            }
            .navigationTitle(title)
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .disabled(saveDisabled)
                }
            }
        }
    }
    #endif
}

// MARK: - Icon Grid

struct IconGrid: View {
    let icons: [String]
    @Binding var selected: String
    let accentColor: Color
    
    var body: some View {
        let config = LayoutConfig.current
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: config.iconGridColumns), spacing: config.spacingS) {
            ForEach(icons, id: \.self) { icon in
                Button { selected = icon } label: {
                    Image(systemName: icon)
                        .font(.system(size: config.iconSize * 0.5))
                        .frame(width: config.iconSize, height: config.iconSize)
                        .background(selected == icon ? accentColor.opacity(0.2) : Color.systemGray6)
                        .foregroundStyle(selected == icon ? accentColor : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: config.cornerRadiusSmall))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
