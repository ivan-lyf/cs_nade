# CS2 Nade Guide — v2 Spec

Fresh start. Native SwiftUI, iPhone only. Local-first library, thin backend.

## Guiding rule

The backend does two jobs and nothing else: verify logins, and host tactics you
explicitly share. It never holds your library. Your library lives on-device in
SwiftData and backs up through CloudKit. The day library sync creeps into the
backend is the day you have rebuilt v1. Hold that line.

## Stack

| Layer            | Choice                                                        |
|------------------|---------------------------------------------------------------|
| UI               | SwiftUI, iOS 17+ (SwiftData needs 17)                         |
| Local store      | SwiftData, source of truth                                    |
| Backup / sync    | SwiftData + CloudKit private DB (automatic, no server code)   |
| Auth             | Supabase Auth via `signInWithIdToken` (Apple + Google native) |
| Share backend    | Supabase Postgres (RLS) + Supabase Storage for images         |
| Steam            | Deferred. Edge Function verifies OpenID, mints a session      |

Two separate sync channels on purpose:
- CloudKit carries your whole private library. Free, tied to iCloud, no server.
- Supabase carries only individual shared tactics. Never your library.

## Identity model

- Sign in with Apple is the primary identity and the same account CloudKit
  backup rides on. One clean identity.
- Google is secondary.
- Steam is v2, added behind the same `AuthService` abstraction so it never
  blocks launch.
- App is fully usable logged out. Login only gates share and import.
- Apple guideline 4.8: shipping Google means you must also ship Sign in with
  Apple. Already covered.

## Data model

### Throw (SwiftData @Model, local)

- `id: UUID`
- `map: GameMap` (dust2, mirage, inferno, nuke, overpass, ancient, anubis, train, vertigo)
- `side: Side` (T / CT)
- `type: NadeType` (smoke, flash, molly, he, decoy)
- `title: String`
- `notes: String`
- `createdAt`, `updatedAt`
- `images: [ThrowImage]` (relationship, ordered by sortIndex)

### ThrowImage (SwiftData @Model, local)

- `id: UUID`
- `role: ImageRole` (stand, aim, landing)
- `imageData: Data` with `@Attribute(.externalStorage)` so bytes live on disk
  and CloudKit syncs them, not the DB row
- `cropRect: NormalizedRect` (x, y, w, h in 0..1)
- `aimPoint: NormalizedPoint?` (0..1, the crosshair spot after crop)
- `sortIndex: Int`

Store originals plus a normalized crop transform and aim point, never
pre-cropped bitmaps. Normalized coords survive any screen size: the editor
writes the numbers, display re-applies them. This is the whole trick that
makes the app feel precise.

### CloudKit constraints (bake in from day one)

- Every attribute must be optional or have a default.
- No `.unique` constraints.
- No required inverse-less relationships.
Design the models to these rules now; retrofitting later is painful.

## The core component: CropAimEditor

Build this first and well. Everything leans on it.

- Pinch/pan zoom over the original image.
- Draggable crop frame, output `NormalizedRect`.
- Draggable aim reticle, output `NormalizedPoint`.
- Snap + haptics near center lines and thirds. "Smart" = this UX, no ML in v1.
- Pure value output (rect + point), no image mutation.

## Share flow

Send a tactic (metadata + image) so someone can save it to their library.

1. On share, upload each image to Supabase Storage, insert one row into
   `shared_tactics` with metadata, normalized transforms, and image paths.
   Get back a short code.
2. Build a Universal Link: `https://<yourdomain>/t/<shortcode>`.
3. App installed: deep link resolves, fetches the row, downloads images,
   shows a "Save to library" card. Tap saves a local Throw.
4. App not installed: a tiny static web fallback page renders a preview and
   an App Store link.

Needs: Associated Domains entitlement, an `apple-app-site-association` file on
the domain, and the fallback page. Small but not skippable.

## Supabase schema

```sql
create table shared_tactics (
  id          uuid primary key default gen_random_uuid(),
  short_code  text unique not null,
  owner_id    uuid not null references auth.users(id),
  map         text not null,
  side        text not null,
  type        text not null,
  title       text not null,
  notes       text default '',
  payload     jsonb not null,        -- image paths + normalized transforms
  created_at  timestamptz default now()
);

alter table shared_tactics enable row level security;

-- anyone can read a shared tactic by code (public share)
create policy read_shared on shared_tactics
  for select using (true);

-- only the authenticated owner can create/delete their own
create policy insert_own on shared_tactics
  for insert with check (auth.uid() = owner_id);
create policy delete_own on shared_tactics
  for delete using (auth.uid() = owner_id);
```

Storage: bucket `shared-images`, public read, authenticated write. No Edge
Function needed for v1. Steam adds one later.

## Seed content

Ship a `SeedThrows.swift` with textbook placeholders you fill in. On first
launch, if the store is empty, insert seeds flagged so they are visually
distinct from user throws.

## Build order

1. SwiftData models + ModelContainer with CloudKit.
2. CropAimEditor against a hardcoded image. Nail this before anything else.
3. Library list + Throw detail + create/edit, fully offline. Usable app here.
4. Seed data.
5. Supabase client + Apple sign-in, gated behind an optional login.
6. Share out (upload + short code + Universal Link).
7. Import in (deep link + Save-to-library card) + web fallback page.
8. Google sign-in.
9. Later: Steam via Edge Function, iPad layout.

Steps 1 to 4 give a shippable local-only app with zero backend. That is the
milestone that proves the scope is survivable this time.
