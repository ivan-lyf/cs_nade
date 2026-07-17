# CS2 Terminology Reference

Compiled July 2026 for the nade guide data model. Two parts: throw techniques
(feeds the technique fields on a Throw) and per-map callouts (feeds the
stand/target location fields).

---

## 1. Throw techniques

A throw is two independent choices: how hard you throw (mouse) and how you move
while throwing. Model them as separate fields, not one flat list. Almost any
power can combine with almost any movement.

### Power (mouse input)

- Left-click — long throw, maximum distance and arc. The default.
- Right-click — short underhand lob, lands close to you. Pop flashes, close smokes.
- Both (left + right together) — medium throw, between the two.

### Movement modifier

- Standing — no movement. Easiest to repeat, best default for lineups.
- Walk-throw — hold Shift while moving forward, then release. Slightly extends
  range and shifts the release point.
- Run-throw — hold W and release mid-run. More distance, less consistent.
- Jump-throw — release at the peak of a jump. Standardizes a high release for
  long smokes. The most common "advanced" lineup requirement.
- Run-jump-throw — sprint, jump, and release together. Maximum distance.
- Crouch / duck-throw — throwing while ducking, sometimes combined with
  duck-walking (jump-throw while duck-walking is a real lineup type).

### Special

- Bounce / bank throw — intentionally bouncing off a wall or ceiling to reach an
  angle a direct throw can't. A flag on top of a power+movement combo.
- One-way smoke — placement that lets you see enemy feet under the smoke while
  they can't see you. A property of the result, not the throw motion.

### Two current facts that matter for the app

- CS2 has a native jump-throw option in settings, and subtick input makes manual
  timing more forgiving than CS:GO was.
- Valve banned multi-input jump-throw binds in competitive play in August 2024.
  Using them can get you kicked. So a lineup that "needs a jumpthrow bind" now
  means a manual jump-throw in comp. Worth a small flag on a throw so the user
  knows a lineup needs precise manual timing.

---

## 2. Grenade types

Five types. Your `NadeType` enum already covers them:

- Smoke — vision block.
- Flash (flashbang) — you can carry two; every other type is one per player.
- Molotov / Incendiary — Molotov is the T version, Incendiary the CT version.
  Mechanically the same fire denial. Your single `molly` case is fine; add a
  side-aware label only if you care about the buy-menu name.
- HE — up to ~98 damage unarmored point-blank, less with armor and distance.
- Decoy — fake fire sound and a false radar blip. Cheapest at $50.

Max four grenades carried, at most two of them flashes.

---

## 3. Map pool (July 2026)

Active Duty (Premier / Majors), the seven that matter most:

- Ancient
- Anubis
- Dust II
- Inferno
- Mirage
- Nuke
- Overpass

Reserve / wider competitive rotation: Train, Vertigo, Office, Italy, and rotating
community maps. Train was moved to reserve and Anubis returned in the Jan 2026
Premier Season 4 update.

Model note: keep all nine in `GameMap` (you already do) and add an
`isActiveDuty` computed flag so the picker can highlight the seven that are
currently competitive. Callouts below cover the seven active-duty maps; add
Train/Vertigo later if you seed lineups for them.

---

## 4. Callouts by map

Grouped by area. These name where you stand and where a nade lands, so they feed
both the stand-callout and target-callout fields on a throw. Some names have
regional variants (noted); NA and EU sometimes differ.

### Dust II

- A site: Long / Long A, Long Doors, Blue (Blue Box), Pit, Side Pit, Car, Goose,
  A Ramp, Barrels, A Plat, A Default (plant), Ninja, A Short, Stairs, Cat / Catwalk.
- Mid: Mid, Mid Doors, Xbox, Catwalk, CT Mid, Top Mid, Palm, Green, Suicide.
- B site: B Doors, B Plat, Back Plat, B Car, Closet, Fence, Window, B Default,
  Big Box, Double Stack, B Back Site, Dog / Close.
- Tunnels & spawns: Upper Tunnels, Lower Tunnels, Outside Tunnels, T Spawn,
  T Plat, Titanic, Outside Long, CT Spawn.

### Mirage

- A site: T Ramp / Ramp, Palace (Pally), Tetris, Firebox, Triple (Triple Box),
  A Default, Ninja, Stairs, Jungle, Ticket / Ticket Booth, Sandwich, Pillars,
  A Balcony, CT.
- Mid: Top Mid, Mid, Mid Boxes / Xbox, Window (Sniper's Nest), Connector,
  Catwalk (Cat / Short), Chair, Underpass, Ladder Room, Short Boost.
- B site: B Apartments (Apps), Balcony, House / TV, Market (Market Door),
  Kitchen, Bench, Van, B Default, B Short, Back Alley, B Site.
- Spawns: T Spawn, CT Spawn.
- Variants: Palace/Pal, Apartments/Apps/Apart, Connector vs Jungle (Connector is
  the mid passage, Jungle is the A corner), Catwalk/Short.

### Inferno

- A site: Apartments (Apps), Balcony, Pit, Graveyard, Truck, A Short, A Long,
  Arch, Arch Side, Library, Kitchen, Moto, Patio, A Default, Close Left, Back Site.
- Mid: Mid, Top Mid, Bottom Mid, Second Mid / Alt Mid, Underpass, Boiler, Bridge,
  T Apps, Bench.
- B site: Banana, Logs, Car, Sandbags, Coffins, Dark, Fountain, Construction /
  Church, Garden, New Box, CT, Boost, B Site.
- Spawns & CT: T Spawn, T Ramp, CT Spawn, Speedway, Terrace, Well.

### Nuke (vertical, always specify the level)

- A site (upper): Heaven, Hell (below Heaven), Rafters, Mustang, Hut (Big Door),
  Squeaky / Silver, Tetris, Sandbags, Mini, A Main / Yard, Radio (Radio Room),
  Crane, Vents (the A section is breakable).
- B site (lower): Ramp, Ramp Room, Control, Lockers, Vents, New Box / Coffin,
  Dark, Secret, Double / Doors, Decon, Window, Blue Box, Back Vents.
- Ramp area: Turn Pike, Headshot (Back Ramp), Big Box, Boost, Bottom Ramp.
- Outside: Silo, Toxic, Garage, Trophy, Warehouse, T Red, CT Red, Secret,
  Main Drop.
- Other: Lobby, CT Roof, T Spawn, CT Spawn.
- Confusion pairs: Heaven vs Hell (different levels), Decon (single door) vs
  Doors (double), Control (room) vs Ramp (path), T Red vs CT Red.

### Ancient

- A site: A Main, A Halls, A Stairs, A Ramp, Boost, Big Box, Plat, Single,
  Triple (Triple Box), A Default (Bomb), Temple, Lane, Cubby, Short.
- Mid: Mid, Top Mid, Bottom / Lower Mid, Xbox, Pit, Snipers Nest (Red Room),
  Elbow, Split, Donut / Tunnels, Cave, Heaven, Mid Cubby.
- B site: B Site, B Main, Cave, Lamp Room, Pillar, House, Back Halls, Square,
  Nest, Alley, B Ramp, Catwalk, Cheetah, Heaven, T Lower, Water, Altar.
- Spawns: T Spawn, T House, CT Spawn.
- Variants: Donut / Pillar (NA vs EU), Temple / A Temple, Cave / Caves.

### Anubis

- A site: A Main, A Long, Temple, A Site, Heaven (Nine), Fountain, A Connector,
  Plateau, A Backsite, Palace, Walkway.
- Mid: Middle, Top Mid, Bridge, Double Doors, Connector, Canal / Lower Mid,
  Ruins, Alley.
- B site: B Main, B Site, B Long, B Connector, Pillar, Gate, Ninja, Back Site,
  Coffins, Window, Street.
- Water: Water, Boat, Arches, Wood, Beach, Stairs, Upper, Drop.
- Spawns: T Spawn, CT Spawn.

### Overpass

- A site: A Main, A Site (also CT Spawn), Truck (Optimus), Van, Bank, Bins,
  Close Left, A Default, A Long, Long Toilets, Cafe, Bench, Rock, Tree,
  Signpost, Hitmarker, Storage.
- Mid: Mid, Top Mid, Toilets, Fountain, Playground, Balloons, Party, Connector,
  Water / River.
- B site: Monster, Sewers, B Site, Pillar, Barrels (Toxic Barrels), Heaven, Pit,
  Walkway, Bridge, ABC / Graffiti, B Short (Construction), Sandbags, Tracks,
  Short Tunnel, Squeaky, Water.
- Tunnels & spawns: Upper Tunnels, Lower Tunnels (Under), Ladder, Dropout,
  T Spawn, CT Spawn.

---

## 5. How this maps to the model

Concrete recommendation:

Replace the single technique idea with three fields on `Throw`:

- `power: ThrowPower` — `left`, `right`, `both`.
- `movement: ThrowMovement` — `standing`, `walk`, `run`, `jump`, `runJump`, `crouch`.
- `isBounce: Bool` — the special bank/wall flag.

And split location into two callout strings, since the app already pairs a
stand image with an aim image:

- `standCallout: String` — where you stand (from the map's callout list).
- `targetCallout: String` — where it lands (also from the list).

Drive both callout fields off a per-map `[String]` callout list (the section 4
lists), so the create/edit form can offer autocomplete instead of free text.
That keeps entries consistent and makes filtering by location possible later.

Optional nicety: a `needsManualJumpthrow: Bool` derived from
`movement == .jump || movement == .runJump`, surfaced in the UI as a small
"manual timing" note given the comp bind ban.

Say the word and I'll fold `ThrowPower` / `ThrowMovement` into Enums.swift and
add the callout lists as a `Callouts.swift` lookup keyed by `GameMap`.
