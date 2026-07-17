# CS2 Nade Guide

A local-first iPhone app for CS2 players to store their own nade lineups. This
file is persistent project memory. The authoritative docs are, in order:
`CLAUDE_CODE_HANDOFF.md` (the brief and build order), `SPEC.md` (architecture),
`STRUCTURE.md` (folder layout), `DESIGN_BRIEF.md` + `design/README.md` (visual
system), `CS2_TERMS.md` (domain data). A companion doc wins over the handoff on
its own subject; `design/README.md` (finalized handoff) wins over `DESIGN_BRIEF.md`.

## Mission

Each throw pairs a "where to stand" image with a "where to aim" image, cropped
and marked with an aim reticle. No social feed, no browsing others' content. The
only networked features are optional login and sharing a single tactic by link.

## Guardrail (do not violate)

The library never touches the backend. It lives in SwiftData on-device and backs
up through CloudKit. Supabase only ever handles auth verification and individual
shared tactics. If you find yourself syncing the user's library through Supabase,
stop: that is the design mistake that killed v1.

## Stack

- SwiftUI, iOS 17+ (SwiftData requires 17). SwiftData is the source of truth.
- SwiftData + CloudKit private database for backup/sync (no server code).
- Supabase (`supabase-swift`) for auth + shared-tactic storage — Milestone 2 only.
- Sign in with Apple primary, Google secondary, Steam deferred to v2.
- Milestone 1 has zero third-party dependencies. Do not add SPM packages until M2.

## Conventions

- Match the existing code style: value types for geometry, protocol-first
  services, feature-grouped views, normalized coordinates everywhere.
- Views stay thin. Query logic in `@Query` or small view models, not in body.
- Never put image `Data` in a view model. Pass the `ThrowImage`, decode lazily.
- Compress/downscale images before saving (long edge ~2000px, JPEG ~0.8) so
  CloudKit assets stay small. Enforce this helper in the capture path.
- SwiftData is the store — no `UserDefaults` for library data.
- Keep CloudKit rules intact on any model edit: every attribute defaulted or
  optional, no `.unique` constraints, optional relationships.
- Commit per task with a short focused message.

## Repo state (pre-Xcode)

The Xcode project does not exist yet — creating it (and toggling capabilities) is
the human's one-time job, per the handoff's "Human does" section. Until then:

- `code/` — the eight pre-written Swift files (models, geometry, persistence,
  the CropAimEditor). Place them per `STRUCTURE.md` once the project exists, then
  delete the empty `code/` folder. Integrate and extend these; do not rewrite them.
- `design/` — the finalized UI handoff: `README.md` (tokens + per-screen specs),
  the `.dc.html` mockup, and the `ios-frame.jsx` device frame.
- Root `.md` files — the product/architecture/domain docs.

## Build order

Milestone 1 is the whole first push: a shippable, fully local app, no backend.
Sub-steps M1.1–M1.6 are detailed in `CLAUDE_CODE_HANDOFF.md`. Start there. Do not
start M2 (backend) until asked.
