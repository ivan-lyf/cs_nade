# ICON_DESIGN — Nade Guide app icon ("Landing gauge")

Final mark chosen from design exploration (canvas option 4d/5a). This doc + the
SVGs in `assets/` are the source of truth for the app icon and in-app mark.

## Concept
A smoke-grenade canister tumbling along a dotted throw arc, about to land on a
ticked "landing gauge" — a nod to CS2's ruler-style grenade helper overlay shown
when holding a nade. One tick (the landing spot) is lit in accent orange. It
encodes the whole product: throw → measured trajectory → exact landing point.

## Files
- `assets/app-icon-1024.svg` — master icon art, full-bleed bg, export 1024×1024 PNG for the AppIcon asset (iOS masks the corners itself — do NOT pre-round).
- `assets/app-icon-small.svg` — simplified variant for rendered sizes ≤ 40pt (Spotlight 40, Settings 29): fewer ticks, heavier strokes, arc dropped.
- `assets/mark.svg` — mark only, transparent bg, for in-app use (sign-in header, share cards, About). At very small in-app sizes (≤ 28pt) mirror the small-variant simplifications.

## Geometry (120-unit master grid; scale linearly)
- Gauge baseline: y 92, x 10→110, steel `#3A3F49`, stroke 2.5
- Ticks at x 22, 41, 60, 98 (alternating heights 10/6 up from baseline)
- Target tick: x 79, y 92→80, accent `#FF7A1A`, stroke 3.5
- Arc: quadratic `M 14 66 Q 40 8 74 36`, `rgba(255,122,26,.5)`, stroke 5, round caps, dash `0.1 12` (dot chain)
- Canister group at arc end `translate(74,36) rotate(64)`, all `#FF7A1A`:
  - body 22×33, rx 3 (slightly squared — never pill-round, it reads as a mug)
  - cap 12×7 rx 1.5, centered, narrower than body
  - lever: flat quad hugging the right edge `M 5 -23 L 16 -19 L 14 14 L 9 13 Z`
  - pin ring: circle r 4.5, stroke 3, at cap's left shoulder (−10, −26)

## Color
- Background: vertical-ish gradient `#16181C` → `#0B0C0E` (160°). Never pure black; matches app surface tokens.
- Steel (gauge): `#3A3F49`
- Accent (canister, target tick): `#FF7A1A`; arc at 50% alpha
- No other colors. Dark-mode icon = same art. For iOS 18 tinted mode, supply grayscale version: canister+tick white, gauge 45% white.

## Rules
- The canister + arc + gauge move together; don't recompose.
- Landing point stays ON the arc path — target tick sits under the arc's end.
- Don't outline the canister, add gloss, or round the body beyond rx 3.
- Wordmark lockup (optional, marketing only): mark in a hairline-bordered rounded square + "Nade Guide" SF Pro Display Bold + "LINEUPS · CS2" SF Mono 9pt, letter-spacing 2, `#9AA1AC` (see canvas 5b).

## Xcode integration
1. Render `app-icon-1024.svg` → 1024 PNG → AppIcon in Assets.xcassets (single-size).
2. Add `mark.svg` as a vector asset ("Preserve Vector Data") for in-app use.
3. Sign-in screen uses the mark at 84pt inside a 19pt-radius surface square with hairline border (see canvas 5c).
