import AuthenticationServices
import SwiftUI

/// Native Sign in with Apple button wired to AuthService, owning the nonce
/// round-trip. Reused by the sign-in screen and the import sheet.
struct AppleSignInButton: View {
    @Environment(AuthService.self) private var auth
    var onSignedIn: () -> Void = {}
    var onError: (String) -> Void = { _ in }

    @State private var currentNonce = ""

    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            currentNonce = AuthService.randomNonce()
            request.requestedScopes = []
            request.nonce = AuthService.sha256(currentNonce)
        } onCompletion: { result in
            switch result {
            case .success(let authorization):
                let nonce = currentNonce
                Task {
                    do {
                        try await auth.signInWithApple(authorization, rawNonce: nonce)
                        onSignedIn()
                    } catch {
                        onError(error.localizedDescription)
                    }
                }
            case .failure(let error):
                onError(error.localizedDescription)
            }
        }
        .signInWithAppleButtonStyle(.white)
    }
}
