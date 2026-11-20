import SwiftUI
import AuthenticationServices

/// Dedicated account screen: sign in, profile, Sync now, sign out. Presented from Settings.
@available(iOS 17.0, macOS 14.0, *)
struct AccountSettingsView: View {
    private var authService = AuthService.shared
    private var containerProvider = ModelContainerProvider.shared
    private var syncMonitor = SyncMonitor.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showingAccountProfile = false
    @State private var authError: String?
    @State private var showingAuthErrorAlert = false
    @Environment(\.colorScheme) private var colorScheme

    private var chevronAccessory: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if authService.isSignedIn {
                        Button {
                            showingAccountProfile = true
                        } label: {
                            SettingsRow(
                                icon: "person.crop.circle.fill",
                                iconColor: .blue,
                                title: authService.userDisplayName ?? "Signed in with Apple"
                            ) {
                                chevronAccessory
                            }
                        }
                        .buttonStyle(.plain)
                        // Sync runs automatically; this row reports what it is doing.
                        SettingsRow(icon: "icloud.fill", iconColor: .green, title: "iCloud sync") {
                            Text(SyncStatus.summary(monitor: syncMonitor, provider: containerProvider))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        Button {
                            authService.signOut()
                        } label: {
                            SettingsRow(icon: "rectangle.portrait.and.arrow.right", iconColor: .orange, title: "Sign out") {
                                chevronAccessory
                            }
                        }
                        .buttonStyle(.plain)
                    } else {
                        // Apple's own button (with the logo), as App Review requires (Guideline 4).
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            do {
                                try authService.completeSignIn(with: result)
                            } catch {
                                authError = error.localizedDescription
                                showingAuthErrorAlert = true
                            }
                        }
                        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                        .frame(height: 44)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                } footer: {
                    if !authService.isSignedIn {
                        Text("Sign in to back up your habits and sync across your devices.")
                    } else {
                        Text("Habits sync automatically through iCloud. Sign in on each device with the same Apple ID.")
                            .font(.caption)
                    }
                }
                if let authError {
                    Section {
                        Text(authError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
            .frame(minWidth: 320, minHeight: 260)
            .navigationTitle("Account settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAccountProfile) {
                AccountProfileView()
            }
            .alert("Sign in", isPresented: $showingAuthErrorAlert) {
                Button("OK") { authError = nil }
            } message: {
                if let authError { Text(authError) }
            }
        }
        #if os(macOS)
        .frame(minWidth: 320, minHeight: 280)
        #endif
    }
}

#Preview {
    AccountSettingsView()
}
