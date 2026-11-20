import Foundation
import Observation
import AuthenticationServices
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Sign in with Apple only. Stores user identifier and optional display name in Keychain. No custom backend.
@MainActor
@Observable
final class AuthService: NSObject {

    // MARK: - Public state

    static let shared = AuthService()
    private(set) var isSignedIn: Bool = false
    private(set) var currentUserId: String? = nil
    /// Display name or email from Sign in with Apple (only provided on first sign-in).
    private(set) var userDisplayName: String? = nil

    // MARK: - Private state

    /// Cached so nonisolated presentationAnchor can return it without touching MainActor.
    private static nonisolated(unsafe) var cachedPresentationAnchor: ASPresentationAnchor?
    /// Set in init so nonisolated delegate can obtain the instance without touching MainActor-isolated `shared`.
    private static nonisolated(unsafe) var _sharedRef: AuthService?
    private var authContinuation: CheckedContinuation<Void, Error>?
    /// Exposed so nonisolated delegate can resume immediately (no Task delay).
    private static nonisolated(unsafe) var sharedContinuation: CheckedContinuation<Void, Error>?

    // MARK: - Init

    private override init() {
        super.init()
        Self._sharedRef = self
        currentUserId = KeychainHelper.loadUserId()
        userDisplayName = KeychainHelper.loadUserDisplayName()
        isSignedIn = currentUserId != nil
    }

    // MARK: - Sign in / Sign out

    func signIn() async throws {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        Self.cachedPresentationAnchor = currentPresentationAnchor()
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        
        defer {
            authContinuation = nil
            Self.sharedContinuation = nil
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            authContinuation = continuation
            Self.sharedContinuation = continuation
            controller.performRequests()
        }
    }

    /// Completes sign-in from SwiftUI's `SignInWithAppleButton`.
    func completeSignIn(with result: Result<ASAuthorization, Error>) throws {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
            guard KeychainHelper.save(userId: credential.user, displayName: Self.formatDisplayName(from: credential)) else {
                throw AuthError.keychainSaveFailed
            }
            currentUserId = credential.user
            userDisplayName = KeychainHelper.loadUserDisplayName()
            isSignedIn = true
            NotificationCenter.default.post(name: .userDidSignIn, object: nil)
            Analytics.track(.signedIn)
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            throw error
        }
    }

    private func currentPresentationAnchor() -> ASPresentationAnchor {
        #if os(iOS)
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
        return scene?.keyWindow ?? (scene?.windows.first { $0.isKeyWindow } ?? UIWindow())
        #elseif os(macOS)
        return NSApplication.shared.keyWindow ?? NSWindow()
        #else
        return ASPresentationAnchor()
        #endif
    }

    /// Signs out and stops iCloud sync. Habits stay on this device.
    func signOut() {
        _ = KeychainHelper.deleteUserId()
        currentUserId = nil
        userDisplayName = nil
        isSignedIn = false
        NotificationCenter.default.post(name: .userDidSignOut, object: nil)
    }

    /// Deletes the account (App Store Guideline 5.1.1(v)): removes the copy of the user's habits
    /// stored in iCloud, then the sign-in. Habits stay on this device.
    ///
    /// Sync is switched off first so nothing re-uploads while the iCloud data is being deleted. If
    /// the deletion fails (offline, iCloud unavailable) sync is switched back on and the user stays
    /// signed in, so they can try again.
    func deleteAccount() async throws {
        let provider = ModelContainerProvider.shared
        provider.setCloudSync(enabled: false)
        do {
            try await CloudDataEraser.deleteSyncedData()
        } catch {
            provider.setCloudSync(enabled: true)
            throw error
        }
        signOut()
        Analytics.track(.accountDeleted)
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        let userId = credential.user
        let displayName = Self.formatDisplayName(from: credential)
        let cont = AuthService.sharedContinuation
        AuthService.sharedContinuation = nil
        guard let service = Self._sharedRef else { return }
        Task { @MainActor in
            // A single small Keychain write; fine on the main actor.
            let success = KeychainHelper.save(userId: userId, displayName: displayName)
            if success {
                cont?.resume()
                service.currentUserId = userId
                service.userDisplayName = KeychainHelper.loadUserDisplayName()
                service.isSignedIn = true
                NotificationCenter.default.post(name: .userDidSignIn, object: nil)
                Analytics.track(.signedIn)
            } else {
                cont?.resume(throwing: AuthError.keychainSaveFailed)
            }
        }
    }
    
    nonisolated private static func formatDisplayName(from credential: ASAuthorizationAppleIDCredential) -> String? {
        if let fullName = credential.fullName {
            let formatter = PersonNameComponentsFormatter()
            formatter.style = .default
            let name = formatter.string(from: fullName)
            if !name.isEmpty { return name }
        }
        if let email = credential.email, !email.isEmpty { return email }
        return nil
    }
    
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let cont = AuthService.sharedContinuation
        AuthService.sharedContinuation = nil
        let authError = error as? ASAuthorizationError
        let toThrow = authError?.code == .canceled ? AuthError.canceled : error
        cont?.resume(throwing: toThrow)
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let anchor = AuthService.cachedPresentationAnchor {
            return anchor
        }
        return MainActor.assumeIsolated {
            #if os(iOS)
            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first
            return scene?.keyWindow ?? (scene?.windows.first { $0.isKeyWindow } ?? UIWindow())
            #elseif os(macOS)
            return NSApplication.shared.keyWindow ?? NSWindow()
            #else
            return ASPresentationAnchor()
            #endif
        }
    }
}

// MARK: - AuthError

/// Errors from Sign in with Apple.
enum AuthError: LocalizedError {
    case canceled
    case keychainSaveFailed
    
    var errorDescription: String? {
        switch self {
        case .canceled: return "Sign in was canceled."
        case .keychainSaveFailed: return "Could not save sign-in data."
        }
    }
}
