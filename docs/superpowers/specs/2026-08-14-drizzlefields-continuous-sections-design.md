# DrizzleFields — Continuous-Sections World Design

**Date:** 2026-08-14
**Branch:** main
**Status:** Design approved; implementation begins after spec lands.

## Objective

Replace the rectangular forest rooms in `DrizzleFields` (and later areas) with one **continuous geography** of intentionally designed connected sections — narrow paths, open clearings, side paths, NPC/interactable spaces, landmarks, puzzles, and transitions — and prove the architecture on DrizzleFields before reusing it for Snowdin and beyond.

## Non-Goals

- No scene changes inside the area — everything is one Node2D world with the player walking.
- No redistribution of existing sounds/music beyond what the section metadata already provides.
- No new encounter families; reuse the existing encounter table with per-section zone tags.
- No new full-area art; the `drizzle` atlas is *derived* (recolor pipeline) so original art can replace it without code changes later.

## Hard Constraints

- One scene (`DrizzleFields.tscn`) containing all 9 sections, with the camera following the player and bound to the master area.
- Doors only at the area boundary: `grumbleridge` → `GrumbleWoods.tscn` (north), `snowledge` → `Snowdin.tscn` (east). All other connections are pure walking.
- Existing test invariants stay green:
  - `GRUMBLE_SPAWN` (520, 392) is walkable from the new `grumbleridge` exit cell.
  - The Snowdin spawn cell (drizzle-side, just inside the `snowledge` door) is walkable.
  - `Snowdin.tscn` string is still referenced by the drizzle source.
  - The single save-point policy holds — one star, in the grove. If `test_area_rooms` encoded the old per-room save count, the test is updated to assert exactly 1 save in the continuous Drizzle scene.
- LO's standing implementation policy: **commit + push every code change immediately; do not build exe/zip or update GitHub release assets until explicitly approved.**

## Architecture — `SectionMap` (extensible, decoupled, future-proof)

A new pure-logic script `scripts/rooms/section_map.gd` (RefCounted, unit-testable). The composer is the only new tool we need; everything else (MapBuilder, door, save_point) reuses without changes.

### Section data model

Each section is a plain `Dictionary` with a **fixed schema** plus an **open `extras` bag**. Unknown top-level keys are passed through by the composer unchanged, so future metadata (music, ambience, lighting, weather, narrative flags, scripted events) can be added by writing more section data — **no composer changes required**.

```
{
  "id": "wisp_grove",                       # required, unique
  "layout": ["#####", ".P.P.", ".WWW.", "..S.."],   # required ASCII grid; # walls, . floor
  "edges": { "n": "...", "s": "...", "e": "...", "w": "..." }, # auto-derived if absent
  "identity": {                              # author-readable description
      "label": "the Wisp Grove",
      "tone":  "quiet wonder",
      "gameplay": "hub + save + NPC conversation",
      "visual": "dead-tree cluster, drifting wisp motes"
  },
  "props": [                                # per-cell tree/grass/shadow placement
      {"cell": [5,4], "kind": "dead_tree"},
      {"cell": [6,4], "kind": "dead_tree"},
      {"cell": [4,5], "kind": "tall_grass"}
  ],
  "objects": [                              # author-placed gameplay-meaningful objects
      {"cell": [3,3], "type": "save",    "data": {}},
      {"cell": [6,3], "type": "npc",     "data": {"id": "wisp"}},
      {"cell": [1,2], "type": "landmark","data": {"label": "wisp cluster"}}
  ],
  "flavor": [                               # optional environmental storytelling
      {"cell": [5,6], "kind": "old_boot"},
      {"cell": [7,7], "kind": "stick_circle"}
  ],
  "encounter_zone": "none",                 # none | light | normal
  "music":      null,                       # future: zone music override
  "ambience":   null,                       # future: ambient sound overlay
  "lighting":   null,                       # future: per-section lighting tint
  "weather":    null,                       # future: weather override
  "extras":     {}                          # forward-compatible bag — anything goes
}
```

Two **object classes** are first-class, by design intent:
- `objects[]` — meaning-bearing items (save, NPC, landmark, exit, encounter trigger). Listed in the section's data, sparse, intentional.
- `flavor[]` — optional environmental-storytelling sprites. Ambient, sparse, no gameplay, no test impact. These exist so the world feels *lived in* without every prop being predefined as a landmark.

### Composer (`SectionMap.compose`)

`compose(sections: Array, adjacency: Array) -> { grid, objects, flavor, layout_meta }`

- Places each section at a chosen master-grid origin.
- For each adjacency edge (N/S/E/W) the composer **asserts** that the two sections' edge cells form a valid merge: shared path cells align, no wall is placed where a neighbor expects floor, shared edge columns/rows overlap.
- Incompatible merges raise a clear error during composition (testable).
- Irregular chunk shapes are supported (chunks need not be rectangular; only the edge rows/cols used by adjacency matter).
- On success, returns the master `grid` (Array[String]) and merged `objects[]`/`flavor[]` lists with all cell coordinates remapped to master space.
- Master grid is then handed to the existing `MapBuilder` unchanged; a small `SectionPlacer` consumes the object + flavor lists to spawn props at composed coordinates.

### Forward compatibility

The composer **does not interpret** any key outside its core schema. Sections can carry `music`, `ambience`, `lighting`, `weather`, narrative flags, scripted events, or anything else — the composer preserves them in the returned `layout_meta` so later systems (audio, narrative, save data) can read what they need. This keeps the tool durable and avoids re-architecting for every new feature.

## DrizzleFields — Section Roster (the "recallable" map)

9 sections, two full loops, one quiet transition section with no gameplay, every section with a unique identity, landmark, and tone. Each section is one chunk; the composer stitches them via the adjacency table.

### Layout sketch

```
                              ┌── grumbleridge ──┐  exit → GrumbleWoods
                              └────────┬─────────┘
                                   path_north
                                       ↑
       (hidden gap →) puzzle_pocket  │
                                       │
        ┌────── pond_clearing ─ wisp_grove ── snowledge ──┐ exit → Snowdin
        │           │            hub · save   │              │
        │           │                        │              │
        │       creek_bend ─────────  ringpath_east ─────────┘
        │            (quiet transition)  (loop link)
        └────────────┬───────────────────────┘
                    ┌──┴──────────────┐
                    │  meadow (start) │   large open field
                    └─────────────────┘
```

### Sections

| ID | Size (cols × rows) | Purpose | Landmark | Tone | Encounters |
|---|---|---|---|---|---|
| `meadow` | 18 × 14 | Enlarged intro field; first vista; orientation | the Lone Pine | warm, safe | none |
| `wisp_grove` | 10 × 10 | Central hub; save point; Wisp NPC; wisp motes | wisp cluster | quiet wonder | none |
| `path_north` | 4 × 12 | Narrow tree-walled connector (the "narrow path" beat) | fallen-log arch | hushed | light |
| `grumbleridge` | 12 × 8 | North exit + raised vantage (down-view over ring) | ridge sign | stoic | light |
| `pond_clearing` | 16 × 12 | **Identity: the stone crossing** — stepping-stone creek, cattails, sitting log | the stone crossing | airy, playful | normal |
| `creek_bend` | 6 × 6 | **Quiet transition — zero gameplay**, brook bending through tall grass | the bend stone | serene | none |
| `snowledge` | 6 × 14 | East exit; thinning trees, cold-wind ramp, gate glimpse | the gate glimpse | anticipatory | none |
| `ringpath_east` | 4 × 10 | Loop link, gnarled root arches, pine line | old root arch | muted | light |
| `puzzle_pocket` | 8 × 8 | Hidden side grove off `path_north` via a narrow gap; future puzzle slot | the stone gap | mysterious | none |

### The loops (no dead-ends unless intentional)

- **Loop A** — `wisp_grove` → `pond_clearing` → `creek_bend` → `meadow` → `wisp_grove`
- **Loop B** — `wisp_grove` → `snowledge` → `ringpath_east` → `meadow` → `wisp_grove`
- **Spoke** — `wisp_grove` → `path_north` → `grumbleridge` (exit)
- **Side path** — `path_north` → `puzzle_pocket` (intentional dead end)

### Environmental transitions

- **Ground palette**: per-section floor style, decoupled from asset sheets (style-key + per-section palette override → same atlas, different recolor). Snowledge and grumbleridge blend *into* their exit's natural palette so the world feels like it bleeds outward.
- **Prop density and type**: meadow pine → grove dead trees → snowledge thinning pale pines, read through per-section prop lists, not via runtime tint.
- **Author-controlled sightlines**: tree cells are author-placed, so the layout carves deliberate view rows — Lone Pine visible from grove, wisp cluster crowns above the tree line from meadow, ridge silhouette seen from path_north, gate peek drawn at snowledge's west edge. `landmark` props occupy these cells intentionally.

### Memorable moments at exits

- `grumbleridge` — raised vantage with the ridge sign; stand-and-look beat before the door to GrumbleWoods.
- `snowledge` — slow reveal of the distant Snowdin gate as the trees thin; the door reads as *arrival*, not just an exit.

## Integration & Test Plan

- `drizzle_fields.gd` is the only scene script that changes shape. It builds the section array, calls `SectionMap.compose` with the adjacency list, hands the master grid to `MapBuilder`, then runs `SectionPlacer` to spawn `objects[]` and `flavor[]`.
- `door.gd` stays exactly as it is. Doors only exist at grumbleridge and snowledge boundaries.
- `save_point.gd` unchanged; the one star sits in the grove.
- **New test** `tests/test_section_map.gd`:
  - Composer stitches two compatible sections and the result has a single connected walkable plane.
  - Incompatible edge merges raise a clear error.
  - Object + flavor cells remap to master coordinates correctly.
  - Irregular chunk support.
  - **Flood-fill connectivity**: from spawn, the walkable plane reaches grumbleridge exit, snowledge exit, puzzle_pocket, and completes both loops without isolated islands.
- Existing `test_door_spawn`, `test_grumble_doors`, `test_snowdin.gd`, `test_area_rooms` stay green. If `test_area_rooms` encodes the old per-room save count, we adjust only after confirming — a single save in the continuous scene is the policy.
- Full suite: `tools/godot.exe --headless --path . -s res://tests/run_all.gd` must end with `ALL TESTS PASSED`.

## Asset Strategy — Decoupled from Undertale

The `drizzle` atlas is a *starting point* derived from Undertale sheets (recolor pipeline) so the world can ship without hand-drawn originals. **The runtime does not know the atlas came from Undertale.** The decoupling is enforced three ways:

1. **Style key indirection**: every floor reference is a style name (`drizzle_grass`, `drizzle_path`, `drizzle_creek`, `drizzle_ridge`), not a PNG path. MapBuilder style atlases are populated from a `drizzle_palette.gd`/data file at import time.
2. **Recolor happens offline**: a one-shot `tools/harvest_drizzle_atlas.gd` produces the final PNGs under `assets/sprites/tiles/drizzle/`. The runtime never reads the source Undertale sheets. Replacing the atlas = dropping new PNGs in that folder; no code changes.
3. **Per-section palette override**: each section's `extras.palette_override` (optional) can bias tile IDs toward a regional variant — green-leaning meadow vs cool-leaning snowledge, for example. The atlas supplies both; the override chooses.

This makes the Undertale provenance invisible to the engine and easy to retire when original art lands.

## Validation — Playtesting, Not Architecture

After implementation lands, we validate the design in-engine rather than re-litigate the architecture. The playtest checklist:

- [ ] Spawn in meadow; walk every section; reach every exit and the pocket with no scene change.
- [ ] Both loops complete in each direction without retracing the same corridor.
- [ ] Save in the grove, reload, respawn at the save cell.
- [ ] No encounters in calm sections; light/normal counts in the marked sections.
- [ ] Sightline views: Lone Pine from grove, wisp cluster from meadow, ridge from path, gate from snowledge — visually confirmed.
- [ ] Frame rate steady at 60 fps in editor and export.
- [ ] Cross-area doors fade and re-spawn at the right cell.
- [ ] Full test suite green.

## Acceptance Criteria

- All 9 sections present, correctly stitched, flood-fill connectivity test green.
- Both doors (grumbleridge, snowledge) wired and tested.
- Sightlines designed and visible.
- Save point: exactly one, in the grove.
- Per-section encounters match the table.
- New `test_section_map.gd` and `test_drizzle_continuity.gd` green; full suite green.
- Documentation committed; commit history clean; **no exe/zip or release asset work** until LO approves.

## Open Follow-ups (post-prototype)

- Snowdin adaptation: same composer, new chunks, new palette; aim for the same hub-and-loop architecture but winter-themed.
- The `extras` bag will collect whatever metadata future systems need (music, ambience, lighting, weather) — sections already carry the slots, the systems get hooked up later.
- Original art pass to retire the Undertale-derived atlas.

## Playtest Checklist (addendum)

Run `DrizzleFields.tscn` in the editor and walk the whole area:

- **West loop:** wisp_grove → pond_clearing (the stone crossing) → creek_bend (quiet, zero gameplay) → backwater connector → meadow → back to the grove. Confirm the backwater reads as a natural continuation, not a box.
- **East arm:** grove → snowledge (gate glimpse at the west edge) → ringpath_east. Judge the anticipation-to-vista payoff; after playtesting decide whether ringpath_east becomes a full traversal loop or stays a scenic vista branch (LO decision, exploration-flow-based, not symmetry).
- **Doors:** (21,6) → GrumbleWoods and (37,38) → Snowdin — both transitions land on walkable cells; no fade seams glitching.
- **Save spot:** exactly one, wisp_grove (18,23); respawn lands correctly.
- **Seams & rims:** walk every section edge — no invisible walls, no teleport-box feel; dead-tree rims block solidly (alpha 0.9), path corridor trees collide.
- **East-void corridor:** master cols 17..38, rows 41..50 are unpainted floor and ringpath's west edge touches it at rows 41,43 — check the incidental corridor feels OK; a future section can fill it (no redesign now).
- **Encounter zones:** pond_clearing (2) and ringpath_east (1) only — density/timing feels right? No encounters in hub/grove/creek/backwater.
- **Landmark sightlines:** the Lone Pine from the grove, wisp cluster from the meadow, ridge sign/vantage from grumbleridge, gate glimpse, stone crossing, bend stone, old root arch, stone gap, fallen-log arch — all visible from their designed approach lines.
- **Atmosphere:** "drizzle" music, green CanvasModulate tint, 0.67s fade-in; no runtime tint jumps between sections.
- **Export note:** the 12 dev-run warnings "Loaded resource as image file" fire uniformly for every style tileset via the atlas loader — in any future exported build, confirm the drizzle floor tiles render.
