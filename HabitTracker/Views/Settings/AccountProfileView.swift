import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Account profile when signed in with Apple: display info, sign out, delete account (Guideline 5.1.1(v)).
struct AccountProfileView: View {
    @ObservedObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAccountConfirmation = false

    private var appAccent: Color { Color(red: 0.35, green: 0.51, blue: 0.88) }

    var body: some View {
        #if os(macOS)
        macContent
        #else
        iosContent
        #endif
    }

    // MARK: - iOS (list-based)

    private var iosContent: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(appAccent)
                        VStack(alignment: .leading, spacing: 2) {
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
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    .alignmentGuide(.listRowSeparatorTrailing) { d in d[.trailing] }
                }
                Section {
                    Button {
                        authService.signOut()
                        dismiss()
                    } label: {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    .alignmentGuide(.listRowSeparatorTrailing) { d in d[.trailing] }
                    Button(role: .destructive) {
                        showingDeleteAccountConfirmation = true
                    } label: {
                        Label("Delete account", systemImage: "trash")
                    }
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    .alignmentGuide(.listRowSeparatorTrailing) { d in d[.trailing] }
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationTitle("Account")
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

    // MARK: - macOS (compact, native-style)

    private var macContent: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(appAccent)
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
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                Divider()

                VStack(spacing: 0) {
                    Button {
                        authService.signOut()
                        dismiss()
                    } label: {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteAccountConfirmation = true
                    } label: {
                        Label("Delete account", systemImage: "trash")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }

                Spacer(minLength: 0)
            }
            #if os(macOS)
            .background(Color(nsColor: NSColor.windowBackgroundColor))
            #endif
            .navigationTitle("Account")
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
        .frame(minWidth: 320, minHeight: 260)
    }
}

#Preview {
    AccountProfileView()
}
