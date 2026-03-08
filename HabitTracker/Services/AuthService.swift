import Foundation
import AuthenticationServices
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Sign in with Apple only. Stores user identifier in Keychain. No custom backend.
@MainActor
final class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    @Published private(set) var isSignedIn: Bool = false
    @Published private(set) var currentUserId: String? = nil
    
    private override init() {
        super.init()
        currentUserId = KeychainHelper.loadUserId()
        isSignedIn = currentUserId != nil
    }
    
    func signIn() async throws {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            authContinuation = continuation
            controller.performRequests()
        }
    }
    
    func signOut() {
        _ = KeychainHelper.deleteUserId()
        currentUserId = nil
        isSignedIn = false
    }
    
    private var authContinuation: CheckedContinuation<Void, Error>?
    private var authCredential: String?
}

extension AuthService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        let userId = credential.user
        Task { @MainActor in
            if KeychainHelper.save(userId: userId) {
                currentUserId = userId
                isSignedIn = true
                authContinuation?.resume()
            } else {
                authContinuation?.resume(throwing: AuthError.keychainSaveFailed)
            }
            authContinuation = nil
        }
    }
    
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            let authError = error as? ASAuthorizationError
            if authError?.code == .canceled {
                authContinuation?.resume(throwing: AuthError.canceled)
            } else {
                authContinuation?.resume(throwing: error)
            }
            authContinuation = nil
        }
    }
}

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
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
