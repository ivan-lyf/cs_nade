import SwiftData
import SwiftUI
import UIKit

/// Screen 5: the "Save to Library" bottom sheet, presented when a share link
/// opens the app. Signed-in users save directly; signed-out users get the
/// explainer plus Sign in with Apple inline.
struct ImportTacticView: View {
    @Environment(ShareService.self) private var shareService
    @Environment(AuthService.self) private var auth
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let code: String

    private enum LoadState {
        case loading
        case loaded(ShareService.FetchedTactic, UIImage?)
        case failed(String)
    }

    @State private var state: LoadState = .loading
    @State private var errorMessage: String?
    @State private var signInErrorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Theme.hairline)
                .frame(width: 36, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 14)

            Text("SHARED WITH YOU")
                .font(Theme.mono(10))
                .tracking(1.5)
                .foregroundStyle(Theme.textSecondary)
                .padding(.bottom, 14)

            switch state {
            case .loading:
                ProgressView()
                    .tint(Theme.accent)
                    .frame(height: 190)
                    .frame(maxWidth: .infinity)
            case .failed(let message):
                VStack(spacing: 8) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.textSecondary)
                    Text(message)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 190)
                .frame(maxWidth: .infinity)
            case .loaded(let tactic, let standImage):
                previewCard(tactic: tactic, standImage: standImage)
                    .padding(.bottom, 16)
                actions(for: tactic)
            }

            Spacer(minLength: 16)
        }
        .padding(.horizontal, Theme.margin)
        .background(Theme.bg.ignoresSafeArea())
        .task { await load() }
        .alert("Couldn't save", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("Couldn't sign in", isPresented: Binding(
            get: { signInErrorMessage != nil },
            set: { if !$0 { signInErrorMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(signInErrorMessage ?? "")
        }
    }

    private func load() async {
        do {
            let tactic = try await shareService.fetch(code: code)
            let stand = tactic.imageData[ImageRole.stand.rawValue].flatMap(UIImage.init(data:))
            state = .loaded(tactic, stand)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: Preview card

    private func previewCard(tactic: ShareService.FetchedTactic, standImage: UIImage?) -> some View {
        let row = tactic.row
        return ZStack(alignment: .bottomLeading) {
            Group {
                if let standImage {
                    GeometryReader { geo in
                        Image(uiImage: standImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    }
                } else {
                    StripedPlaceholder()
                }
            }
            Theme.cardScrim

            VStack(alignment: .leading, spacing: 5) {
                Text(row.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let map = GameMap(rawValue: row.map) {
                        Text(map.displayName.uppercased())
                            .font(Theme.mono(10))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    if let side = Side(rawValue: row.side) {
                        SideTag(side: side, fontSize: 10)
                    }
                    if let type = NadeType(rawValue: row.type) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Theme.typeDotColor(type))
                                .frame(width: 7, height: 7)
                            Text(type.displayName.uppercased())
                                .font(Theme.mono(10))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
            }
            .padding(12)
        }
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard))
    }

    // MARK: Actions

    @ViewBuilder
    private func actions(for tactic: ShareService.FetchedTactic) -> some View {
        if auth.isSignedIn {
            Button {
                do {
                    try shareService.saveToLibrary(tactic, context: modelContext)
                    dismiss()
                } catch {
                    errorMessage = "Couldn't save to your library. Try again."
                }
            } label: {
                Text("Save to Library")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.bg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.radiusControl))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 8)
        } else {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.warning)
                Text("Sign in to save shared lineups to your library. Your own library never needs an account.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: Theme.radiusControl))
            .padding(.bottom, 10)

            AppleSignInButton {
                // Signed in: stay on the sheet, now showing Save.
            } onError: { message in
                signInErrorMessage = message
            }
            .frame(height: 48)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusControl))
            .padding(.bottom, 8)
        }

        Button {
            dismiss()
        } label: {
            Text("Dismiss")
                .font(.system(size: 15))
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusControl)
                        .stroke(Theme.hairline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
