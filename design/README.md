# Handoff: CS2 Nade Guide — iOS App UI

## Overview
Complete UI design for a native iOS (SwiftUI, iOS 17+) personal utility app: a local-first library of CS2 grenade lineups. Each "Throw" pairs a where-to-stand screenshot with a where-to-aim screenshot, cropped and marked with an aim reticle. No social feed. Covers 9 screen states: Library (populated + empty), Throw Detail, Crop/Aim Editor (Crop + Aim modes), Create/Edit form, Import bottom sheet (signed-in + signed-out), and Sign in.

The product/tech context lives in the docs at the repo root: `../SPEC.md` (architecture, data model, build order), `../STRUCTURE.md` (folder skeleton), `../CS2_TERMS.md` (domain vocabulary, callouts), `../DESIGN_BRIEF.md` (original brief). Read SPEC.md first — it is the source of truth for models and stack.

## About the Design Files
`CS2 Nade Guide.dc.html` (+ `ios-frame.jsx`) is a **design reference created in HTML** — a static high-fidelity mockup, not production code. The task is to **recreate these screens in SwiftUI** per SPEC.md/STRUCTURE.md, using native components (NavigationStack, searchable, PhotosPicker, segmented pickers, sheets) styled to the tokens below. Do not port the HTML.

## Fidelity
**High-fidelity.** Colors, spacing, radii, and typography are final. Recreate pixel-close. The diagonal-striped tiles are placeholders for user CS2 screenshots — real imagery is busy and colorful, so the bottom scrims and contrast rules are load-bearing.

## Design Tokens

Colors:
- Background base `#0B0C0E`
- Surface / card `#16181C`
- Surface elevated `#1E2127`
- Hairline / border `#2A2E36` (1px, never heavy dividers)
- Primary text `#F2F4F7`
- Secondary text `#9AA1AC`
- Tertiary/dim text `#5C636E`
- Accent (the only brand color) `#FF7A1A`; pressed `#E86A0E`; selected-fill tint `rgba(255,122,26,.14)`
- Success `#3FB27F` · Warning/locked `#C9A227`
- Side tags: T `#C9A227`, CT `#5B8DEF` — outlined tags only (border at 40% alpha of the color), never fills
- Nade-type dots: smoke `#B8BEC9`, flash `#F2F4F7`, molly `#FF7A1A`, HE `#E8563F`, decoy `#8A8F99`

Typography:
- Screen titles: SF Pro Display Bold 32pt, tracking −0.5
- Detail title: SF Pro Display Bold 24pt
- Body: SF Pro Text 14–16pt
- All metadata (map codes, side tags, coordinates, section labels): SF Mono 9–13pt; section labels 10pt uppercase, letter-spacing 1
- Buttons: 15–16pt semibold

Shape & spacing:
- Radius: 14 cards, 10 controls/fields, 8 small selector cells, 6 meta tags, full-round capsules/reticle/FAB
- 16pt screen margins, 12pt grid gutter, 8pt small gaps
- Card scrim: linear-gradient over bottom ~60–64% of image, transparent → `rgba(11,12,14,.92)`

## Screens / Views

### 1. Library (LibraryView)
- Nav: large title "Library" (32pt bold) + trailing 32pt circular "⋯" button (surface bg, hairline border).
- Search field: 38pt tall, radius 10, surface bg + hairline, placeholder "Search lineups" in secondary.
- Filter chips: horizontal scroll, 30pt tall, radius 10, SF Mono 12pt. Default: surface bg + hairline, secondary text (side chips use their side color as text). Selected: accent bg, near-black text, semibold. Chips: maps (MIRAGE, DUST II…), sides (T/CT), types (dot + name).
- Grid: 2 columns, 12pt gutter, cards 200pt tall, radius 14. Card = stand image full-bleed, bottom scrim, then bottom-left: title (13pt semibold, 1 line, ellipsis) and meta row (SF Mono 9pt): map code (secondary) · side tag (outlined, side color) · 7pt type dot.
- Seeded throws: top-right "TEXTBOOK" badge — SF Mono 8pt secondary, 1px hairline border, radius 4, bg `rgba(11,12,14,.6)`.
- FAB: 56pt accent circle, bottom-right (20pt from edges), near-black plus glyph, shadow `0 8px 24px rgba(255,122,26,.35)`.
- Empty state: centered — 64pt hairline ring containing a 30pt accent reticle mark, "No lineups yet" (17pt semibold), 2-line secondary caption ("Add your first throw… Textbook lineups are already loaded…"), then a 40pt accent "Add a throw" button.

### 2. Throw Detail (ThrowDetailView)
- Top bar: back "‹ Library" (accent) left; "Share" and "Edit" plain text (accent) right. No heavy bar.
- Hero: 300pt image, radius 14, 16pt margins, crop transform applied. Overlaid bottom-center segmented control Stand/Aim/Landing: capsule-ish radius 10, bg `rgba(11,12,14,.72)` + hairline + blur; selected segment accent bg, near-black text.
- On Aim image: reticle at saved NormalizedPoint — 44pt ring, 2px accent stroke, 4 crosshair ticks extending 8pt beyond the ring, 3pt center dot, glow `0 0 12px rgba(255,122,26,.5)`.
- Below: title 24pt bold; meta strip of SF Mono 11pt outlined tags (radius 6): MAP, SIDE (side color), TYPE (dot + name), technique code e.g. "JUMP·L".
- Jump-throw warning row (only when movement is jump/runJump): 14pt warning-color circle-! icon + "Manual jump-throw — binds are banned in comp" 12pt in `#C9A227`.
- Notes card: surface bg, hairline, radius 14, 14pt padding; header row "NOTES" (SF Mono 10pt secondary, spaced) + "Collapse" (accent 12pt); body 14pt/1.55 primary.
- Footer row: SF Mono 10pt dim: "STAND · <callout>" left, "LANDS · <callout>" right.

### 3. Crop + Aim Editor (CropAimEditorView) — build first per SPEC
Full-bleed image on black; all chrome floats. Top: "Cancel" (white, left) / "Done" (accent semibold, right), text-shadowed, no bar.
- Mode switch: bottom-center floating capsule, bg `rgba(22,24,28,.85)` + hairline + blur, two segments "Crop"/"Aim"; selected = accent bg, near-black text.
- **Crop mode**: crop rect with 1.5px accent border; outside dimmed via 55% black overlay; four 14pt round accent corner handles centered on corners; rule-of-thirds lines inside at `rgba(255,122,26,.25)`, visible while dragging. **Snap moment**: when an edge hits center/thirds, that guide brightens to full accent with glow `0 0 8px rgba(255,122,26,.8)` plus a floating SF Mono 10pt label ("CENTER X") above the frame; fire haptic.
- **Aim mode**: crop border fades to `rgba(255,122,26,.35)` 1px; draggable reticle 56pt (2.5px stroke, ticks 15pt, 4pt center dot, stronger glow). Beneath it a live coordinate readout: "X 0.527 · Y 0.348", SF Mono 10pt, dark pill (bg `rgba(11,12,14,.8)`, hairline, radius 5).
- Outputs NormalizedRect + NormalizedPoint only; never mutates the image.

### 4. Create / Edit Throw (form)
- Nav row: "Cancel" (accent) / "New Throw" (16pt semibold) / "Save" (accent semibold).
- Title field: surface bg, hairline, radius 10, 16pt text.
- MAP: 5-column grid of 34pt map-code cells (SF Mono 11pt, radius 8). Default surface+hairline+secondary; selected accent-tint bg + accent border + accent text. Reserve maps (TRN, VRT) in dim text. Codes: ANC ANB D2 INF MIR NUKE OVP TRN VRT.
- SIDE: 2-segment toggle in a surface container (radius 10, 2pt padding); selected T = sand tint bg `rgba(201,162,39,.16)` + 50%-alpha sand border + sand text; CT equivalent in steel blue.
- TYPE: 5 equal cells, 36pt, radius 8, each holding only its 8pt type dot; selected cell accent-tint + accent border.
- IMAGES: 3 square slots (Stand/Aim/Landing), radius 10. Filled: thumbnail + bottom label strip (SF Mono 9pt on `rgba(11,12,14,.75)`). Empty: 1.5px dashed hairline border, centered plus glyph + SF Mono label. Tap opens the editor.
- NOTES: multiline field, min 72pt, placeholder "Lineup details, timing, what it blocks…".
- All section labels: SF Mono 10pt uppercase secondary, letter-spacing 1.

### 5. Import sheet (ImportTacticView)
Bottom sheet over the dimmed library (50% black overlay): sheet bg surface + hairline (top corners radius 20), 36×4pt grabber, centered "SHARED WITH YOU" caption (SF Mono 10pt, letter-spacing 1.5).
- Throw preview card: 190pt, radius 14, stand image + scrim, title 17pt semibold, meta row (map name, side tag, dot + type name).
- Signed-in: primary "Save to Library" 48pt accent button (near-black text) + "Dismiss" 44pt ghost (hairline border, secondary text).
- Signed-out: replace primary with an elevated info row (radius 10, warning circle-! + "Sign in to save shared lineups to your library. Your own library never needs an account.") then a native Sign in with Apple button (white style, 48pt) + Dismiss.

### 6. Sign in (SignInView)
Centered on base bg: 72pt app mark (surface rounded-18 square with hairline, containing 34pt accent reticle) · "Nade Guide" 24pt bold · 2-line secondary caption ("Signing in only enables sharing lineups. Your library stays on this device either way.") · Sign in with Apple (native white, 50pt, radius 10) · "Continue with Google" (surface bg, hairline, primary text, 50pt) · "Not now" plain text button (secondary).

## Interactions & Behavior
- Library: chips filter live and combine (map ∧ side ∧ type); search filters by title/callout. Card tap → Detail. FAB → Create form (sheet).
- Detail: segmented control swaps hero image with a quick crossfade (~150ms); reticle renders only on Aim. Share → generates link (SPEC share flow); Edit → form.
- Editor: pinch/pan zoom; gestures affect crop frame or reticle depending on mode; snap to center + thirds with haptic and guide flash; Done returns values; Cancel discards.
- Form: Save enabled when title + map + side + type + ≥1 image. Image slot tap → PhotosPicker → editor.
- Import sheet: presented from Universal Link `/t/<code>`; Save writes a local Throw then dismisses.
- Transitions otherwise iOS-default; no decorative animation.

## State Management
Per SPEC.md: SwiftData is the source of truth (Throw, ThrowImage with NormalizedRect crop + NormalizedPoint aim, CloudKit rules baked in). Editor is pure value in/out. Auth state gates only Share/Import. Seed data flagged `isSeed` → TEXTBOOK badge.

## Assets
No image assets. Striped tiles in the mock = user screenshot placeholders. Reticle, dots, plus glyphs, app mark are all drawn shapes (SwiftUI paths) — no icon files. Apple/Google sign-in use their official buttons/marks.

## Files
- `CS2 Nade Guide.dc.html` — all 9 screen states, open in a browser (labels 1a–1i).
  Note: it loads a `./support.js` runtime that was not included in the export, so it
  may not render standalone — the tokens and screen specs above are the authority.
- `ios-frame.jsx` — device frame used by the mock (presentation only, ignore)
- `../SPEC.md`, `../STRUCTURE.md`, `../CS2_TERMS.md`, `../DESIGN_BRIEF.md` — product docs (repo root)
