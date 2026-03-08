import Foundation
import Combine
import AuthenticationServices
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Sign in with Apple only. Stores user identifier and optional display name in Keychain. No custom backend.
@MainActor
final class AuthService: NSObject, ObservableObject {

    // MARK: - Public state

    static let shared = AuthService()
    @Published private(set) var isSignedIn: Bool = false
    @Published private(set) var currentUserId: String? = nil
    /// Display name or email from Sign in with Apple (only provided on first sign-in).
    @Published private(set) var userDisplayName: String? = nil

    // MARK: - Private state

    /// Cached so nonisolated presentationAnchor can return it without touching MainActor.
    private static nonisolated(unsafe) var cachedPresentationAnchor: ASPresentationAnchor?
    private var authContinuation: CheckedContinuation<Void, Error>?
    /// Exposed so nonisolated delegate can resume immediately (no Task delay).
    private static nonisolated(unsafe) var sharedContinuation: CheckedContinuation<Void, Error>?

    // MARK: - Init

    private override init() {
        super.init()
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

    func signOut() {
        _ = KeychainHelper.deleteUserId()
        currentUserId = nil
        userDisplayName = nil
        isSignedIn = false
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
        if KeychainHelper.save(userId: userId, displayName: displayName) {
            cont?.resume()
            Task { @MainActor in
                currentUserId = userId
                userDisplayName = KeychainHelper.loadUserDisplayName()
                isSignedIn = true
            }
        } else {
            cont?.resume(throwing: AuthError.keychainSaveFailed)
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
        if authError?.code == .canceled {
            cont?.resume(throwing: AuthError.canceled)
        } else {
            cont?.resume(throwing: error)
        }
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
