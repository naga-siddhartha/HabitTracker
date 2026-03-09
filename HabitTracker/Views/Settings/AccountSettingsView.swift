import SwiftUI
import WidgetKit

/// Dedicated account screen: sign in, profile, Sync now, sign out. Presented from Settings.
@available(iOS 17.0, macOS 14.0, *)
struct AccountSettingsView: View {
    @ObservedObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showingAccountProfile = false
    @State private var authError: String?
    @State private var showingAuthErrorAlert = false
    @State private var isSigningIn = false

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
                        Button {
                            HabitStore.shared.save()
                            WidgetKit.WidgetCenter.shared.reloadAllTimelines()
                        } label: {
                            SettingsRow(icon: "arrow.triangle.2.circlepath", iconColor: .green, title: "Sync now") {
                                chevronAccessory
                            }
                        }
                        .buttonStyle(.plain)
                        Button {
                            authService.signOut()
                        } label: {
                            SettingsRow(icon: "rectangle.portrait.and.arrow.right", iconColor: .orange, title: "Sign out") {
                                chevronAccessory
                            }
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            signInTapped()
                        } label: {
                            SettingsRow(icon: "person.crop.circle.badge.plus", iconColor: .blue, title: "Sign in with Apple") {
                                if isSigningIn {
                                    ProgressView().scaleEffect(0.8)
                                } else {
                                    chevronAccessory
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(isSigningIn)
                    }
                } footer: {
                    if !authService.isSignedIn {
                        Text("Sign in to back up your habits and sync across your devices.")
                    } else {
                        Text("Sync: Sign in with Apple on both iPhone and Mac. Use the same iCloud account on both. In Xcode, add the iCloud capability with CloudKit for both app targets.")
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

    private func signInTapped() {
        isSigningIn = true
        authError = nil
        Task {
            do {
                try await authService.signIn()
                isSigningIn = false
            } catch {
                await MainActor.run {
                    isSigningIn = false
                    authError = error.localizedDescription
                    showingAuthErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    AccountSettingsView()
}
