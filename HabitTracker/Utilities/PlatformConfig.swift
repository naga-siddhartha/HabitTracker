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
                buttonStyle: .custom
            )
        case .macOS:
            return LayoutConfig(
                contentMaxWidth: .infinity,
                horizontalPadding: 20,
                cardCornerRadius: 12,
                cardPadding: 12,
                sheetWidth: 450,
                sheetHeight: 500,
                iconGridColumns: 7,
                iconSize: 32,
                buttonStyle: .system
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
                buttonStyle: .system
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

// MARK: - Adaptive Sheet

struct AdaptiveSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let sheetContent: () -> SheetContent
    
    func body(content: Content) -> some View {
        let config = LayoutConfig.current
        
        content.sheet(isPresented: $isPresented) {
            if let width = config.sheetWidth, let height = config.sheetHeight {
                sheetContent().frame(width: width, height: height)
            } else {
                sheetContent()
            }
        }
    }
}

extension View {
    func adaptiveSheet<SheetContent: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> SheetContent) -> some View {
        modifier(AdaptiveSheetModifier(isPresented: isPresented, sheetContent: content))
    }
}

// MARK: - Adaptive Card

struct AdaptiveCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        let config = LayoutConfig.current
        content
            .padding(config.cardPadding)
            .background(Color.systemBackground)
            .clipShape(RoundedRectangle(cornerRadius: config.cardCornerRadius))
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
        VStack(spacing: 0) {
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
            .padding()
            
            Divider()
            
            ScrollView {
                content()
                    .padding(20)
            }
        }
        .frame(width: LayoutConfig.current.sheetWidth ?? 450,
               height: LayoutConfig.current.sheetHeight ?? 500)
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
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: config.iconGridColumns), spacing: 8) {
            ForEach(icons, id: \.self) { icon in
                Button { selected = icon } label: {
                    Image(systemName: icon)
                        .font(.system(size: config.iconSize * 0.5))
                        .frame(width: config.iconSize, height: config.iconSize)
                        .background(selected == icon ? accentColor.opacity(0.2) : Color.systemGray6)
                        .foregroundStyle(selected == icon ? accentColor : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
