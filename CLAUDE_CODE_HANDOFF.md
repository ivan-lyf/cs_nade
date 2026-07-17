# Claude Code Handoff — CS2 Nade Guide

You are picking up a fresh iOS app. This doc is your brief. Read it fully before
writing code. Four companion docs sit alongside it and are authoritative on their
topics: `SPEC.md` (architecture and decisions), `STRUCTURE.md` (folder layout),
`DESIGN_BRIEF.md` (visual system), `CS2_TERMS.md` (domain data). When this doc
and a companion disagree, the companion wins on its subject. For UI work,
`design/README.md` is the finalized high-fidelity design handoff (tokens,
per-screen specs) and supersedes `DESIGN_BRIEF.md` where they differ.

A root `CLAUDE.md` carries the "Mission", "Guardrail", and "Conventions"
sections of this file as persistent project memory across sessions.

---

## Mission

A local-first iPhone app for CS2 players to store their own nade lineups. Each
throw pairs a "where to stand" image with a "where to aim" image, cropped and
marked with an aim reticle. No social feed, no browsing others' content. The
only networked features are optional login and sharing a single tactic by link.

## Guardrail (do not violate)

The library never touches the backend. It lives in SwiftData on-device and
backs up through CloudKit. Supabase only ever handles auth verification and
individual shared tactics. If you find yourself syncing the user's library
through Supabase, stop: that is the design mistake that killed v1.

---

## Stack

- SwiftUI, iOS 17+ (SwiftData requires 17).
- SwiftData for local persistence, source of truth.
- SwiftData + CloudKit private database for backup/sync (no server code).
- Supabase (`supabase-swift`) for auth + shared-tactic storage. Backend work is
  Milestone 2, not the first sessions.
- Sign in with Apple (native, AuthenticationServices) primary.
- Google via `GoogleSignIn-iOS`, secondary.
- Steam deferred to v2 behind an Edge Function.

Dependencies to add via Swift Package Manager when their milestone arrives:
- https://github.com/supabase/supabase-swift
- https://github.com/google/GoogleSignIn-iOS
Do not add these until Milestone 2. Milestone 1 has zero third-party deps.

---

## What already exists

These files were written already and live in `code/` until the Xcode project
exists. Place them per `STRUCTURE.md` (then delete the empty `code/` folder).
Do not rewrite them; integrate and extend.

- `Enums.swift` -> `Core/Models/` — GameMap, Side, NadeType, ImageRole.
- `NormalizedRect.swift` -> `Core/Geometry/` — 0..1 crop rect + `rect(in:)`.
- `NormalizedPoint.swift` -> `Core/Geometry/` — 0..1 aim point + `point(in:)`.
- `Throw.swift` -> `Core/Models/` — @Model, CloudKit-safe.
- `ThrowImage.swift` -> `Core/Models/` — @Model, external-storage bytes.
- `AppStore.swift` -> `Core/Persistence/` — ModelContainer with CloudKit.
- `CropAimEditorView.swift` -> `Features/Editor/` — the core editor. Foundation
  quality: integrate it, then tune gestures on device (see Gotchas).

The models are already written to CloudKit's rules (every property defaulted,
optional relationship, no unique constraints). Preserve that when editing them.

---

## Project setup

Split by who does what. The human handles anything requiring Xcode capability
toggles or external dashboards. You handle all Swift and project structure.

### Human does (once, ~10 min)

1. Create the Xcode project: File > New > Project > iOS App, SwiftUI interface,
   name `CSNadeGuide`, and check "Host in CloudKit" / Storage: SwiftData if the
   template offers it (Xcode 16). Set the min deployment to iOS 17.
2. Signing & Capabilities: add iCloud (check CloudKit, create a container),
   and Background Modes > Remote notifications. Set a development team.
3. Later, at Milestone 2: create the Supabase project, configure Apple + Google
   providers in its Auth dashboard, add the GoogleSignIn URL scheme, and add the
   Associated Domains entitlement for share links.

### You (Claude Code) do

1. Create the folder groups from `STRUCTURE.md` and drop the eight existing files
   into place.
2. Wire the app entry to inject the container:
   ```swift
   @main
   struct CSNadeGuideApp: App {
       var body: some Scene {
           WindowGroup { RootView() }
               .modelContainer(AppStore.makeContainer())
       }
   }
   ```
3. Build to green with a placeholder `RootView` before feature work.
4. From then on, work milestone by milestone below.

---

## Conventions

- Match the existing code style: value types for geometry, protocol-first
  services, feature-grouped views, normalized coordinates everywhere.
- Views stay thin. Put query logic in `@Query` or small view models, not in body.
- Never put image `Data` in a view model. Pass the `ThrowImage` and decode lazily.
- Compress and downscale images before saving (cap the long edge around 2000px,
  JPEG ~0.8) so CloudKit assets stay small. Add a helper for this in the capture
  path.
- No browser storage APIs anywhere (irrelevant here, but no `UserDefaults` for
  library data either; SwiftData is the store).
- Keep the CloudKit rules intact on any model edit: defaults, optionals, no
  unique constraints, optional relationships.
- Commit per task with a short message. Keep each task's diff focused.

---

## Build order

Milestone 1 is the whole first push. It yields a shippable, fully local app with
no backend and no third-party dependencies. Do these in order.

### M1.1 — Skeleton compiles

Place the eight files, create groups, wire the container, placeholder RootView.
Done when: app builds and launches to an empty screen on the simulator.

### M1.2 — Data model upgrade from research

Apply the `CS2_TERMS.md` section 5 recommendations before building UI on top of
the model, so you only build once:
- Add `ThrowPower` (left, right, both) and `ThrowMovement` (standing, walk, run,
  jump, runJump, crouch) to `Enums.swift`.
- Add `power`, `movement`, `isBounce` to `Throw` (defaults: `.left`,
  `.standing`, `false`).
- Replace a single location concept with `standCallout: String = ""` and
  `targetCallout: String = ""` on `Throw`.
- Add `Callouts.swift` in `Supporting/`: a `[GameMap: [String]]` lookup built
  from the section 4 callout lists.
Done when: models compile with the new fields and a migration-safe default set.

### M1.3 — Library (home)

Per `DESIGN_BRIEF.md` screen 1. `@Query` throws, 2-column card grid, image-hero
cards with a bottom scrim, map/side/type filter chips, a "+" FAB, and the empty
state. Seeded throws get the distinct badge.
Done when: filters narrow the grid live, empty state shows on a clean store, FAB
routes to create.

### M1.4 — Create / Edit form

Per `DESIGN_BRIEF.md` screen 4. Title, map/side/type selectors, `power` /
`movement` / `isBounce` controls, stand/target callout fields backed by
`Callouts.swift` autocomplete, notes, and three image slots (Stand, Aim,
Landing). Each slot opens `PhotosPicker`, then pushes `CropAimEditorView` bound
to that image's `cropRect` and `aimPoint`. Save writes SwiftData and stamps
`updatedAt`.
Done when: you can create a throw with a cropped stand image and a marked aim
image, and it appears in the Library.

### M1.5 — Throw detail

Per `DESIGN_BRIEF.md` screen 2. Build a reusable `CroppedThrowImageView` that
takes a `ThrowImage` and renders the original with `cropRect` applied and, when
present, the aim reticle at `aimPoint` (reuse the reticle look from the editor).
Segmented Stand / Aim / Landing viewer, meta strip, notes.
Done when: crop and reticle render correctly purely from the stored normalized
values at any view size.

### M1.6 — Seed data

`SeedThrows.swift` with a handful of textbook placeholders (the user will fill
real content). On first launch, if the store is empty, insert them flagged
`isSeed = true`.
Done when: a fresh install shows the seeded throws, visually distinct, and they
don't reinsert on relaunch.

At the end of M1 you have the milestone that proves the scope is survivable: a
complete local app, no network.

### M2 — Backend (later, separate sessions)

Only after M1 ships. Add `supabase-swift` and `GoogleSignIn`, build
`AuthService` (Apple first, then Google) gated so the app stays usable logged
out, then the share-out flow (upload images to Supabase Storage, insert a
`shared_tactics` row, mint a short code, build a Universal Link) and the
import-in flow (deep link -> fetch -> "Save to Library" card). Schema and RLS
are in `SPEC.md`. Do not start M2 until asked.

---

## Known gotchas

- CropAimEditor tuning: it zooms about center, not the pinch focal point, and
  has no double-tap-to-fit or momentum. The `reverseMask` dimming and the
  simultaneous-gesture composition are the two spots most likely to need a
  device pass. The coordinate math (translation / scale, normalized against the
  fitted frame) is correct; refine feel, don't rewrite the math.
- Image size: without downscaling on save, CloudKit assets balloon. Enforce the
  compression helper in the capture path.
- CloudKit + SwiftData: never add a `.unique` attribute or a non-optional
  relationship, or sync silently breaks.
- Jump-throw bind ban (Aug 2024) is a content fact, not a code path. Surface it
  as a small "manual timing" note when `movement` is `.jump` or `.runJump`. Do
  not build any auto-bind feature.
- At M2 only: Apple's Supabase client secret is a JWT that expires every 6
  months (calendar reminder). Google native sign-in via `signInWithIdToken` is
  nonce-sensitive; pass the same nonce you gave Apple/Google. Keep Supabase Auth
  version current (an Apple OIDC issuer bug was fixed in Auth v2.177.0).

---

## Suggested first-session prompt

Paste something like this to start:

> Read CLAUDE_CODE_HANDOFF.md and the four companion docs. Set up the Xcode
> project groups, place the eight existing Swift files per STRUCTURE.md, wire the
> model container in the app entry, and get M1.1 building green with a
> placeholder RootView. Then do M1.2 (the data model upgrade). Stop after M1.2
> and show me the diff before continuing.
