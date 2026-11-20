import Observation
import SwiftUI
import WidgetKit

// MARK: - Account menu state (shared across tabs)

@available(iOS 17.0, macOS 14.0, *)
@Observable
final class AccountMenuState {
    var showingAccountProfile = false
    var authError: String?
}

// MARK: - Profile icon + menu (toolbar)

@available(iOS 17.0, macOS 14.0, *)
struct AccountMenuButton: View {
    private var authService = AuthService.shared
    @Bindable var accountMenuState: AccountMenuState
    @Environment(ModelContainerProvider.self) private var containerProvider
    private var syncMonitor = SyncMonitor.shared

    var body: some View {
        Menu {
            if authService.isSignedIn {
                Button {
                    accountMenuState.showingAccountProfile = true
                } label: {
                    Label("Account", systemImage: "person.crop.circle.fill")
                }
                // Sync runs automatically; show its status instead of a manual button.
                Label(SyncStatus.summary(monitor: syncMonitor, provider: containerProvider), systemImage: "icloud")
                Divider()
                Button(role: .destructive) {
                    authService.signOut()
                } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } else {
                Button {
                    accountMenuState.showingAccountProfile = true
                } label: {
                    Label("Sign in…", systemImage: "person.crop.circle.badge.plus")
                }
            }
        } label: {
            // A solid filled circle: white figure on brand purple (gray when signed out).
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 28))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, authService.isSignedIn ? Color.brandPurple : Color.gray)
        }
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .accessibilityLabel(authService.isSignedIn ? "Account menu" : "Sign in")
        .accessibilityHint(authService.isSignedIn ? "Open account, sync, or sign out" : "Sign in with Apple to sync across devices")
    }
}

// MARK: - Toolbar + sheet + alert modifier (apply to each tab content)

@available(iOS 17.0, macOS 14.0, *)
struct AccountToolbarModifier: ViewModifier {
    @Bindable var accountMenuState: AccountMenuState

    private var toolbarAccountPlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .topBarTrailing
        #else
        return .primaryAction
        #endif
    }

    func body(content: Content) -> some View {
        content
            .toolbar {
                if #available(iOS 26.0, macOS 26.0, *) {
                    // The icon is its own circle; no glass capsule around it.
                    ToolbarItem(placement: toolbarAccountPlacement) {
                        AccountMenuButton(accountMenuState: accountMenuState)
                    }
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: toolbarAccountPlacement) {
                        AccountMenuButton(accountMenuState: accountMenuState)
                    }
                }
            }
            .sheet(isPresented: $accountMenuState.showingAccountProfile) {
                AccountSheet()
            }
            .alert("Sign in", isPresented: Binding(
                get: { accountMenuState.authError != nil },
                set: { if !$0 { accountMenuState.authError = nil } }
            )) {
                Button("OK") { accountMenuState.authError = nil }
            } message: {
                if let error = accountMenuState.authError { Text(error) }
            }
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension View {
    func withAccountToolbar(accountMenuState: AccountMenuState) -> some View {
        modifier(AccountToolbarModifier(accountMenuState: accountMenuState))
    }
}

/// Profile when signed in, otherwise the account screen with the Sign in with Apple button.
struct AccountSheet: View {
    private var authService = AuthService.shared

    var body: some View {
        if authService.isSignedIn {
            AccountProfileView()
        } else {
            AccountSettingsView()
        }
    }
}
