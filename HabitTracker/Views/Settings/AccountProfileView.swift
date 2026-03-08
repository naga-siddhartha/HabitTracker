import SwiftUI

/// Account profile when signed in with Apple: display info, sign out, delete account (Guideline 5.1.1(v)).
struct AccountProfileView: View {
    @ObservedObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAccountConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Signed in with Apple")
                                .font(.headline)
                            if let name = authService.userDisplayName, !name.isEmpty {
                                Text(name)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Account active")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    Button {
                        authService.signOut()
                        dismiss()
                    } label: {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showingDeleteAccountConfirmation = true
                    } label: {
                        Label("Delete account", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Delete account?", isPresented: $showingDeleteAccountConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    authService.deleteAccount()
                    dismiss()
                }
            } message: {
                Text("Sign-in and account data will be removed from this device. Your habits and data will remain on this device unless you use Reset All Data. To revoke this app’s access to your Apple ID, go to Settings → Apple ID → Password & Security → Apps Using Your Apple ID.")
            }
        }
    }
}

#Preview {
    AccountProfileView()
}
