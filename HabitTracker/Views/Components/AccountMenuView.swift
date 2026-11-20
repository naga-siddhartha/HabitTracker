import Observation
import SwiftUI
import WidgetKit

// MARK: - Account menu state (shared across tabs)

@available(iOS 17.0, macOS 14.0, *)
@Observable
final class AccountMenuState {
    var showingAccountProfile = false
    var authError: String?
    var isSigningIn = false
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
                    signInTapped()
                } label: {
                    if accountMenuState.isSigningIn {
                        Label("Signing in…", systemImage: "person.crop.circle.badge.plus")
                    } else {
                        Label("Sign in with Apple", systemImage: "person.crop.circle.badge.plus")
                    }
                }
                .disabled(accountMenuState.isSigningIn)
            }
        } label: {
            Image(systemName: authService.isSignedIn ? "person.crop.circle.fill" : "person.crop.circle")
                .font(.system(size: 28))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(authService.isSignedIn ? Color.accentColor : Color.gray)
        }
        .accessibilityLabel(authService.isSignedIn ? "Account menu" : "Sign in")
        .accessibilityHint(authService.isSignedIn ? "Open account, sync, or sign out" : "Sign in with Apple to sync across devices")
    }

    private func signInTapped() {
        accountMenuState.isSigningIn = true
        accountMenuState.authError = nil
        Task {
            do {
                try await authService.signIn()
                await MainActor.run { accountMenuState.isSigningIn = false }
            } catch {
                await MainActor.run {
                    accountMenuState.isSigningIn = false
                    accountMenuState.authError = error.localizedDescription
                }
            }
        }
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
                ToolbarItem(placement: toolbarAccountPlacement) {
                    AccountMenuButton(accountMenuState: accountMenuState)
                }
            }
            .sheet(isPresented: $accountMenuState.showingAccountProfile) {
                AccountProfileView()
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
