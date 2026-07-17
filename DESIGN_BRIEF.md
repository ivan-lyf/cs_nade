# CS2 Nade Guide — Design Brief

For Claude Design. iPhone app, portrait. Native SwiftUI feel, iOS 17+.
This is a personal utility for CS2 players to store and reference their own
smoke/flash/molly/HE lineups. Local-first, no social feed, no browsing other
people's content. The whole app is: your library, a throw's detail, and the
tool that crops an image and marks where to aim.

## Product in one line

A precise, HUD-like personal notebook of nade lineups. Every entry pairs a
"where to stand" image with a "where to aim" image, cropped and marked.

## Aesthetic direction

Tactical, dark, precise. Think in-game HUD and demo-review UI, not a social
app. Confident use of black, one warm accent, and crisp geometric structure.
The throw imagery is the hero on every screen, so chrome stays quiet and lets
screenshots carry the color.

- Mood words: tactical, exact, calm, engineered.
- Avoid: playful gradients, rounded pill-heavy "friendly app" look, skeuomorphism.
- Numbers and coordinates feel at home in a monospaced face. Lean into that for
  any metadata badges or coordinate readouts.

## Color tokens

- Background base: near-black `#0B0C0E`
- Surface / card: `#16181C`
- Surface elevated: `#1E2127`
- Hairline / border: `#2A2E36`
- Primary text: `#F2F4F7`
- Secondary text: `#9AA1AC`
- Accent (single, warm): CS orange `#FF7A1A`
- Accent pressed: `#E86A0E`
- Success / active-duty: `#3FB27F`
- Warning / locked: `#C9A227`

Side coding (subtle, used as small tags only): T = warm sand `#C9A227`,
CT = cool steel `#5B8DEF`.

Nade-type dots: smoke `#B8BEC9`, flash `#F2F4F7`, molly `#FF7A1A`,
HE `#E8563F`, decoy `#8A8F99`.

## Type

- Headings: SF Pro Rounded or SF Pro Display, semibold, tight tracking.
- Body: SF Pro Text.
- Metadata, coordinates, map codes: SF Mono.
- Big, quiet hierarchy. One clear title per screen, everything else recedes.

## Shape & spacing

- Corner radius: 14 on cards, 10 on controls, full-round only on the aim reticle.
- 1px hairlines, not heavy dividers.
- 16pt screen margins, 12pt gutters in the grid.
- Generous vertical rhythm. Let cards breathe.

## Screens to design

### 1. Library (home, most important)

The map-organized shelf of the user's throws.

- Top: large screen title "Library", a search field, and a compact filter row.
- Filter row: horizontally scrollable chips for Map (Dust II, Mirage, ...),
  Side (T / CT), Type (Smoke/Flash/Molly/HE). Selected chip uses the accent.
- Body: a 2-column card grid. Each card is a throw:
  - The stand image as the card background (cropped), darkened at the bottom.
  - Overlaid bottom-left: throw title (one line), and a small meta row with a
    map code, a side tag, and a nade-type dot.
  - Seeded "textbook" throws get a tiny outlined badge to read as distinct from
    user content.
- Floating action button, bottom-right, accent, "+" to add a throw.
- Empty state: a centered, understated prompt to add the first throw, with a
  secondary line noting textbook placeholders are already loaded.

Design both a populated state and the empty state.

### 2. Throw Detail

Reference view a player opens mid-game. Fast to parse.

- Hero: a segmented image viewer that swaps between Stand / Aim / Landing.
  Show the crop applied. On the Aim image, render the aim reticle marker at its
  saved position (a circle with crosshair, accent colored).
- Under the hero: title, then a meta strip (map, side, type) as monospaced tags.
- Notes block: quiet, readable, collapsible if long.
- Actions: a Share button (generates a link) and an Edit button. Keep these
  secondary so the image stays hero.

### 3. Crop + Aim Editor

The tool. Full-bleed dark. This is where precision matters.

- The image fills the screen on black. Everything else floats over it.
- A crop frame with four round accent handles at the corners. Outside the crop
  is dimmed ~55%. A thin accent border marks the crop edge.
- Faint thirds guide lines inside the crop (rule-of-thirds), appearing while
  dragging.
- When snapping to center/thirds, the relevant guide line flashes brighter.
- An aim reticle: a ring with a crosshair, draggable, accent colored.
- Bottom: a two-item segmented control, "Crop" and "Aim", to switch what the
  gestures affect. Minimal, floating, capsule.
- Top: a Cancel (left) and Done (right), plain text, no heavy bar.

Design the Crop mode state and the Aim mode state.

### 4. Create / Edit Throw

A short form. One screenful.

- Title field at top.
- Map / Side / Type selectors. Map as a menu or a compact grid of map codes,
  Side as a two-option toggle (T / CT), Type as a small segmented row with the
  type dots.
- An "Images" section: three slots labeled Stand, Aim, Landing. Each slot is a
  square that shows a thumbnail once added, or a dashed add-target when empty.
  Tapping a slot opens the editor.
- Notes: a multi-line text area.
- Save in the nav bar.

### 5. Import card ("Save to library")

Appears as a bottom sheet when the user opens a shared link.

- A single throw card, larger than a grid card: stand image, title, meta strip.
- A short "Shared with you" caption.
- Primary button: "Save to Library" (accent). Secondary: "Dismiss".
- If not signed in and sign-in is required to import, show a compact sign-in
  prompt inside the sheet instead of the save button.

### 6. Sign in (optional, minimal)

Only reached from Share or Import when needed.

- Centered lockup: app mark, one line explaining login only enables sharing.
- "Sign in with Apple" (primary, black system button styling on the dark bg).
- "Continue with Google" (secondary).
- A "Not now" text button so the app stays usable logged out.

## Components to define as a set

- Throw card (grid): image-hero variant.
- Meta tag: monospaced small tag for map / side, and the nade-type dot.
- Filter chip: default and selected.
- Reticle: the aim crosshair marker, reused in editor and detail.
- Primary button (accent) and secondary button (ghost on dark).
- Bottom sheet container styling.

## States to show

- Library: populated and empty.
- Editor: Crop mode and Aim mode, including a snap-engaged moment.
- Import sheet: signed-in (save enabled) and signed-out (sign-in prompt).

## Notes for the designer

- The imagery is user screenshots of CS2, so assume busy, colorful photos
  behind cards. Guarantee contrast with bottom scrims and never rely on the
  photo being dark.
- One accent only. Resist a second brand color. Map/side/type coding is the
  only place other hues appear, and only in small doses.
- This should feel like a tool a player trusts at a clutch moment: legible at a
  glance, nothing decorative getting in the way.
