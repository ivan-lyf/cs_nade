import SwiftUI

/// Screen 2: the reference view a player opens mid-game. Hero image with a
/// Stand/Aim/Landing segmented switcher, meta strip, jump-throw warning,
/// notes, and the stand/lands footer. Fast to parse; the image stays hero.
struct ThrowDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var auth
    @Environment(ShareService.self) private var shareService
    let item: Throw

    @State private var selectedRole: ImageRole = .stand
    @State private var isEditPresented = false
    @State private var isShareInfoPresented = false
    @State private var isSignInPresented = false
    @State private var isSharing = false
    @State private var shareURL: URL?
    @State private var shareErrorMessage: String?
    /// Long notes default to fully expanded with a "Collapse" affordance,
    /// matching the design's depicted state.
    @State private var isNotesExpanded = true

    private var availableRoles: [ImageRole] {
        ImageRole.allCases.filter { item.image(for: $0) != nil }
    }

    private var isNotesLong: Bool { item.notes.count > 160 }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    topBar
                    hero
                    Text(item.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    metaStrip
                    if item.needsManualJumpthrow {
                        jumpWarning
                    }
                    if !item.notes.isEmpty {
                        notesCard
                    }
                    footer
                }
                .padding(.horizontal, Theme.margin)
                .padding(.bottom, 32)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isEditPresented) {
            ThrowFormView(existing: item)
        }
        .sheet(isPresented: $isSignInPresented) {
            SignInView()
        }
        .sheet(isPresented: Binding(
            get: { shareURL != nil },
            set: { if !$0 { shareURL = nil } }
        )) {
            if let shareURL {
                ActivityShareSheet(items: [shareURL])
                    .presentationDetents([.medium])
            }
        }
        .alert("Sharing isn't set up yet", isPresented: $isShareInfoPresented) {
            Button("OK") {}
        } message: {
            Text("Add the Supabase configuration to enable share links. Your library itself never needs an account.")
        }
        .alert("Couldn't share", isPresented: Binding(
            get: { shareErrorMessage != nil },
            set: { if !$0 { shareErrorMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(shareErrorMessage ?? "")
        }
        .onAppear {
            selectedRole = availableRoles.first ?? .stand
        }
        // The edit sheet can add or remove images while this view stays in the
        // hierarchy; onAppear won't re-fire, so reconcile here.
        .onChange(of: availableRoles) { _, roles in
            if !roles.contains(selectedRole) {
                selectedRole = roles.first ?? .stand
            }
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 16) {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Library")
                        .font(.system(size: 15))
                }
                .foregroundStyle(Theme.accent)
            }
            Spacer()
            Button {
                handleShare()
            } label: {
                if isSharing {
                    ProgressView()
                        .tint(Theme.accent)
                } else {
                    Text("Share")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.accent)
                }
            }
            .disabled(isSharing)
            Button("Edit") { isEditPresented = true }
                .font(.system(size: 15))
                .foregroundStyle(Theme.accent)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 8)
    }

    // MARK: Hero

    private var hero: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let image = item.image(for: selectedRole) {
                    // .fit for the aim image: the reticle must never be
                    // clipped away by a fill overflow.
                    CroppedThrowImageView(
                        throwImage: image,
                        showsReticle: selectedRole == .aim,
                        contentMode: selectedRole == .aim ? .fit : .fill
                    )
                } else {
                    StripedPlaceholder()
                }
            }
            .id(selectedRole)
            .transition(.opacity)
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusCard))

            if availableRoles.count > 1 {
                segmentedControl
                    .padding(.bottom, 10)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: selectedRole)
    }

    private var segmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(availableRoles) { role in
                let selected = selectedRole == role
                Button {
                    selectedRole = role
                } label: {
                    Text(role.displayName)
                        .font(.system(size: 12, weight: selected ? .semibold : .medium))
                        .foregroundStyle(selected ? Theme.bg : Theme.textSecondary)
                        .padding(.horizontal, 14)
                        .frame(height: 24)
                        .background(
                            selected ? Theme.accent : .clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.radiusControl))
        .background(
            Theme.bg.opacity(0.72),
            in: RoundedRectangle(cornerRadius: Theme.radiusControl)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusControl)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    // MARK: Meta

    private var metaStrip: some View {
        HStack(spacing: 8) {
            metaTag { Text(item.map.displayName.uppercased()) }
            metaTag(
                textColor: Theme.sideColor(item.side),
                borderColor: Theme.sideColor(item.side).opacity(0.4)
            ) {
                Text(item.side.rawValue + " SIDE")
            }
            metaTag(textColor: Theme.textPrimary) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Theme.typeDotColor(item.type))
                        .frame(width: 7, height: 7)
                    Text(item.type.displayName.uppercased())
                }
            }
            metaTag { Text(item.techniqueCode + (item.isBounce ? "·BANK" : "")) }
        }
    }

    /// Outlined mono tag. Only the side tag colors its border (40% alpha of
    /// the side color); everything else keeps the plain hairline.
    private func metaTag(
        textColor: Color = Theme.textSecondary,
        borderColor: Color = Theme.hairline,
        @ViewBuilder content: () -> some View
    ) -> some View {
        content()
            .font(Theme.mono(11))
            .foregroundStyle(textColor)
            .padding(.horizontal, 8)
            .frame(height: 22)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusTag)
                    .stroke(borderColor, lineWidth: 1)
            )
    }

    /// Share routing: unconfigured build → explainer; signed out → sign-in
    /// sheet; signed in → upload and hand the link to the system share sheet.
    private func handleShare() {
        guard SupabaseConfig.isConfigured else {
            isShareInfoPresented = true
            return
        }
        guard auth.isSignedIn, let userID = auth.userID else {
            isSignInPresented = true
            return
        }
        isSharing = true
        Task {
            defer { isSharing = false }
            do {
                shareURL = try await shareService.share(item, userID: userID)
            } catch {
                shareErrorMessage = error.localizedDescription
            }
        }
    }

    private var jumpWarning: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 14))
            Text("Manual jump-throw — binds are banned in comp")
                .font(.system(size: 12))
        }
        .foregroundStyle(Theme.warning)
    }

    // MARK: Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("NOTES")
                    .font(Theme.mono(10))
                    .tracking(1)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                if isNotesLong {
                    Button(isNotesExpanded ? "Collapse" : "Expand") {
                        isNotesExpanded.toggle()
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.accent)
                    .buttonStyle(.plain)
                }
            }
            Text(item.notes)
                .font(.system(size: 14))
                .lineSpacing(6)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(isNotesLong && !isNotesExpanded ? 4 : nil)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusCard)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    // MARK: Footer

    @ViewBuilder
    private var footer: some View {
        if !item.standCallout.isEmpty || !item.targetCallout.isEmpty {
            HStack {
                if !item.standCallout.isEmpty {
                    Text("STAND · \(item.standCallout.uppercased())")
                }
                Spacer()
                if !item.targetCallout.isEmpty {
                    Text("LANDS · \(item.targetCallout.uppercased())")
                }
            }
            .font(Theme.mono(10))
            .foregroundStyle(Theme.textTertiary)
            .padding(.top, 2)
        }
    }
}
