import SwiftUI

/// Screen 6: minimal sign-in, reached only from Share/Import. The app stays
/// fully usable logged out — this only unlocks sharing.
struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?
    @State private var isGoogleInfoPresented = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                appMark
                    .padding(.bottom, 20)

                Text("Nade Guide")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.bottom, 8)

                Text("Signing in only enables sharing lineups.\nYour library stays on this device either way.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.bottom, 28)

                AppleSignInButton {
                    dismiss()
                } onError: { message in
                    errorMessage = message
                }
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusControl))
                .padding(.bottom, 10)

                Button {
                    isGoogleInfoPresented = true
                } label: {
                    Text("Continue with Google")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radiusControl))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusControl)
                                .stroke(Theme.hairline, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.bottom, 16)

                Button("Not now") { dismiss() }
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textSecondary)
                    .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .alert("Couldn't sign in", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("Google sign-in isn't ready", isPresented: $isGoogleInfoPresented) {
            Button("OK") {}
        } message: {
            Text("Google arrives once its OAuth client is configured. Sign in with Apple works today.")
        }
    }

    /// The app mark at 84pt inside a 19pt-radius surface square (ICON_DESIGN).
    private var appMark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 19)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 19)
                        .stroke(Theme.hairline, lineWidth: 1)
                )
                .frame(width: 84, height: 84)
            Image("Mark")
                .resizable()
                .scaledToFit()
                .frame(width: 46, height: 46)
        }
    }
}

#Preview {
    SignInView()
        .environment(AuthService())
        .preferredColorScheme(.dark)
}
