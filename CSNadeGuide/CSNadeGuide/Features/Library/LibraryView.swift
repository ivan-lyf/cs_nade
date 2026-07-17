import SwiftUI
import SwiftData

/// Screen 1: the map-organized shelf of the user's throws. Filters combine
/// live (map ∧ side ∧ type), search matches title/callouts, the FAB routes to
/// create, and a clean store shows the empty state.
struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthService.self) private var auth
    @Query(sort: \Throw.updatedAt, order: .reverse) private var allThrows: [Throw]
    @State private var pendingDelete: Throw?
    @State private var filter = LibraryFilter()
    @State private var isCreatePresented = false
    #if DEBUG
    @State private var debugDetailItem: Throw?
    @State private var debugSignInPresented = false
    #endif

    private var visibleThrows: [Throw] {
        allThrows.filter(filter.matches)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Theme.bg.ignoresSafeArea()

            if allThrows.isEmpty {
                emptyLayout
            } else {
                populatedLayout
            }

            fab.padding(20)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isCreatePresented) {
            ThrowFormView()
        }
        .confirmationDialog(
            "Delete \"\(pendingDelete?.title ?? "")\"?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let item = pendingDelete {
                    modelContext.delete(item)
                    try? modelContext.save()
                }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        }
        #if DEBUG
        .fullScreenCover(item: $debugDetailItem) { item in
            ThrowDetailView(item: item)
        }
        .sheet(isPresented: $debugSignInPresented) {
            SignInView()
        }
        .onAppear {
            if DebugFlags.openCreate {
                isCreatePresented = true
            } else if DebugFlags.openDetail {
                debugDetailItem = allThrows.first
            } else if DebugFlags.openSignIn {
                debugSignInPresented = true
            }
        }
        #endif
    }

    // MARK: Layouts

    private var emptyLayout: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, Theme.margin)
                .padding(.top, 8)
            Spacer()
            EmptyLibraryView { isCreatePresented = true }
            Spacer()
        }
    }

    private var populatedLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.gutter) {
                header.padding(.horizontal, Theme.margin)
                searchField.padding(.horizontal, Theme.margin)
                FilterChipsRow(filter: $filter)
                if visibleThrows.isEmpty {
                    noMatches
                } else {
                    grid.padding(.horizontal, Theme.margin)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 96) // keep the last row clear of the FAB
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: Pieces

    private var header: some View {
        HStack {
            Text("Library")
                .font(.system(size: 32, weight: .bold))
                .tracking(-0.5)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Menu {
                if auth.isSignedIn {
                    Button("Sign Out", role: .destructive) {
                        Task { try? await auth.signOut() }
                    }
                } else {
                    Button("Not signed in") {}.disabled(true)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(Theme.surface, in: Circle())
                    .overlay(Circle().stroke(Theme.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
            TextField(
                "",
                text: $filter.search,
                prompt: Text("Search lineups").foregroundStyle(Theme.textSecondary)
            )
            .font(.system(size: 15))
            .foregroundStyle(Theme.textPrimary)
            .autocorrectionDisabled()
        }
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radiusControl))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusControl)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private var grid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Theme.gutter),
                GridItem(.flexible(), spacing: Theme.gutter),
            ],
            spacing: Theme.gutter
        ) {
            ForEach(visibleThrows) { item in
                NavigationLink(destination: ThrowDetailView(item: item)) {
                    ThrowCardView(item: item)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Delete Throw", role: .destructive) {
                        pendingDelete = item
                    }
                }
            }
        }
    }

    private var noMatches: some View {
        VStack(spacing: 6) {
            Text("No lineups match")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Adjust the filters or search.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var fab: some View {
        Button { isCreatePresented = true } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Theme.bg)
                .frame(width: 56, height: 56)
                .background(Theme.accent, in: Circle())
                .shadow(color: Theme.accent.opacity(0.35), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add a throw")
    }
}

