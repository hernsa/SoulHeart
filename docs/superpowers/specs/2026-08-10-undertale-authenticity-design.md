# Undertale Authenticity Pass — Design Spec

**Date:** 2026-08-10
**Status:** Approved by LO (2026-08-10)
**Scope:** 3 rendering/spawn bug fixes + full map art redesign of Drizzle Fields (Ruins) and Grumble Woods (Snowdin) to feel identical to Undertale/Deltarune.

---

## 1. Goals

1. Fix three confirmed bugs (player sprite clipping, enemy black boxes, player lost on door transition).
2. Redesign both overworld rooms with authentic Undertale art: Ruins look for Drizzle Fields, Snowdin look for Grumble Woods.
3. Kill procedural visual noise: grid lines between tiles, flat gray-blue wall border, tree tiles that look like gray stones.
4. Pixel-perfect rendering (crisp, unfiltered) like real UT.
5. Keep the existing ASCII-layout system, dialogue, music, encounters, save points, door flow.

## 2. Root Causes (verified, with file:line)

| # | Symptom | Root cause |
|---|---------|-----------|
| B1 | Player shows half body on A/D, half head on W/S | `assets/sprites/overworld/frisk.png` (38x58) is a **single sprite**, not a 2x2 atlas. `Sprites.player_frisk_texture()` (scripts/util/sprites.gd:281-292) slices 19x29 cells: frame 0/1 = head halves, frame 2/3 = body halves. Four-direction data does not exist in the asset; tests only assert cell size + "frames distinct", so the broken output is green. |
| B2 | Enemies render as black boxes on tiles | Enemy frame PNGs (`assets/sprites/enemies/frames/<id>/*.png`, incl. hurt) have fully opaque **black backgrounds** baked in (verified pixel content: corner (0,0,0,255) on froggit/whimsun). Battle's black backdrop (battle.gd:68-71) hides it; overworld `encounter.gd:15` shows the black rectangle. Loader `Sprites._enemy_idle_texture()` (sprites.gd:230-239) passes frames through as-is. |
| B3 | Player lost after first door | `drizzle_fields.gd:111` `door.target_spawn = Vector2(160,100)` is **unpadded** coords; GrumbleWoods pads +80/+128 (PAD_PIXELS). Spawn (168,108) lands inside the solid top tree band (rows 0-7) and above the camera view (camera at room center, y-range [128,608]). `door.gd:4` default `target_spawn := Vector2(160,100)` is the same stale constant. Grumble layout has no `P` marker → fallback (8,8) also invalid. |

## 3. Design Decisions (LO-approved direction; details chosen by ENI)

### 3.1 Room structure: authentic 640x480 single-screen rooms
- Both rooms redesigned to exactly **40x30 cells = 640x480 px** — no scrolling, static centered camera, like UT's single-screen rooms.
- **Remove the padding system entirely** (`build_padded_grid`, `PAD_PIXELS`, `PAD_SIDE`, `PAD_TOP` in grumble_woods.gd). No more padded vs unpadded coordinate confusion (kills the whole class of B3 bugs).
- Border = **black void**: beyond the room floor there is nothing (black). No WALL tiles used for borders. Subtle inner shadow edge (1px dark line on the outermost floor row/col) for depth.
- Room floor spans the full 640x480.

### 3.2 Floor tiles: seamless, authentic, no grid lines
- **Drizzle Fields = Ruins floor**: authentic Undertale Ruins brick tile (purple/magenta brick pattern), ripped from Spriters Resource (Undertale - PC - Ruins tileset), 16x16, **seamless** (wrap-tileable: sample edges match, no visible seams).
- **Grumble Woods = Snowdin floor**: authentic Snowdin outdoor snow tile, seamless.
- The procedural `_fill_tile_detailed` per-row darkening (`y % 16 < 2` / `>= 14` in scripts/tiles/tiles.gd:55-65) that creates horizontal grid lines is **removed**; tiles are the ripped art.
- Palette system (DEFAULT/SNOW) replaced by tile-set selection (RUINS/SNOWDIN).

### 3.3 Trees: real Snowdin pines, y-sorted, clustered
- Rip authentic Undertale Snowdin pine tree sprites (Spriters Resource). Tall (2x2 tiles ≈ 32x32+), transparent background, pixel content verified.
- **Trees become Sprite2D props** (new `scripts/rooms/tree.gd`): texture + StaticBody2D collision limited to the **trunk footprint** (narrow rect at the base), so the player walks in front of trunks and under canopies.
- **Y-sort**: rooms get `y_sort_enabled = true`; trees, player, NPCs, props all y-sort by base position — canopy renders above the player when behind it, exactly like UT/Deltarune.
- **Drop shadow**: 2-3px dark ellipse (procedural ImageTexture) beneath each trunk.
- **Natural clustering**: room layouts redrawn with trees in groves/clusters (2-6 trees in loose groups + a few scattered singles), not the current scattered grid pattern. `T` cells in ASCII still mark trunk positions.

### 3.4 Player: real Frisk overworld sprites
- Rip the real Undertale Frisk overworld sheet (Spriters Resource: Frisk (Overworld)): 4 directions with walk animation (down 2 frames, up 2 frames, side 2 frames; left = mirrored right in code like UT).
- `Sprites.player_frisk_texture(frame, facing)` rewritten to the real sheet layout; walk bob uses the 2-frame walk anim.
- Native cell ~19x29 (UT size), transparent background.
- Tests assert **full-body content per direction cell** (opaque pixels in both head rows and leg rows, centered with margins) — quartered head/body must fail.

### 3.5 Enemy sprites: alpha cutout
- In `Sprites._enemy_idle_texture()` / hurt loader: post-process each loaded frame Image — **near-black pixels → transparent** (RGB luminance below threshold ~0.10, opaque → alpha 0), then build ImageTexture per frame. Cache as today (`_enemy_cache`).
- Applies to both overworld and battle (battle unchanged visually). Hurt frames get the same cutout.
- Regression test: decode `froggit_000.png` corner → alpha must be 0 after processing; a texture built through the loader must have transparent corners.

### 3.6 Door spawn fix
- `drizzle_fields.gd`: `door.target_spawn` → a **verified walkable, on-camera cell in the new 40x30 Grumble layout** (near the Grumble door, 2+ cells inside).
- `grumble_woods.gd`: return door → Drizzle spawn kept valid (verify against new Drizzle layout).
- `door.gd:4`: remove stale default — spawn from GameState only; if missing, `push_error` + fallback to layout `P` marker (which will now always exist).
- Both layouts get `P` markers.
- New test: simulate door trigger → assert destination spawn cell is walkable (not TREE/WALL) and inside the 640x480 viewport.

### 3.7 Rendering: pixel-perfect
- CanvasItem default texture filter = nearest (project setting), viewport stretch as-is (640x480 native). No smoothing anywhere.

### 3.8 Layouts
- **Drizzle Fields** (Ruins, 40x30): brick floor, groves of snow/ruins-style trees, keep: start `P` (top-left area), `S` save point, `E` encounters (froggit/whimsun/vegetoid/loox zones), `D` door bottom-right, `T` tree clusters, NPC toad + sign + props (golden flowers, rocks) repositioned to walkable cells.
- **Grumble Woods** (Snowdin, 40x30): snow floor, pine groves, `E` migosp/loox zones, `D` door (return to Drizzle), `S`-style sign, props, `P` marker.
- Room scripts' prop/encounter/npc positions recomputed to new layouts (16px grid, +8 center offset).

## 4. Architecture Changes

| File | Change |
|------|--------|
| `scripts/util/sprites.gd` | Rewrite `player_frisk_texture` (real sheet layout + mirroring); add enemy frame cutout in `_enemy_idle_texture` (+hurt); add `tree_texture(id)`, `shadow_texture()` (procedural ellipse); keep `prop_texture` |
| `scripts/tiles/tiles.gd` | Replace procedural tiles with ripped Ruins/Snowdin seamless floor tiles; drop per-row darkening; tile set = floor + solid markers (no WALL visuals); remove old palette fns or keep for tests |
| `scripts/rooms/map_builder.gd` | Remove WALL-border behavior; TREE cells → collision-only (visual handled by tree props) or keep trunk tile under tree sprite; void outside room (no border tiles) |
| `scripts/rooms/tree.gd` (new) | Tree prop: sprite, y-sort origin at base, trunk collision, shadow sprite |
| `scripts/rooms/drizzle_fields.gd` | New 40x30 layout, Ruins tiles, y-sort, tree props, spawn fixes |
| `scripts/rooms/grumble_woods.gd` | New 40x30 layout, Snowdin tiles, y-sort, tree props, delete padding code, spawn fixes |
| `scripts/rooms/door.gd` | Remove stale default spawn; fail loudly if missing |
| `scripts/rooms/encounter.gd` | Add small shadow under enemy (optional, if cheap) — primary fix is cutout |
| `scripts/rooms/npc.gd` | y-sort compat (nothing needed if it uses position-based sorting) |
| `project.godot` | texture filter nearest (pixel-perfect) |
| `tests/*` | Update: `test_tiles.gd` (padded-grid test → new expectations), `test_layout_parser.gd`, `test_overworld_assets.gd` (content-level Frisk assertions), `test_player_visuals.gd` (full-body per frame), `test_enemy_assets.gd`/`test_sprites.gd` (cutout alpha), new `test_door_spawn.gd` (walkable on-camera destination), `test_trees.gd` (tree prop + shadow + y-sort presence), `test_floors.gd` (seamless edges) |

## 5. Asset Sourcing Plan
- Sources: Spriters Resource (Undertale - PC) and undertale.wiki — same sourcing as prior work (frisk.png came from undertale.wiki; battle/overworld rips came from Spriters Resource).
- All assets stored as **PNG** (Godot 4.4 cannot import GIF).
- Every downloaded asset gets a **pixel-content verification step** (dimensions, transparency, opaque-black-bg check) before it can be committed — a gate, not a formality (B1 and B2 both passed "shape-only" gates last time).
- Specific rips needed:
  1. Frisk overworld sheet (4 directions, walk frames)
  2. Ruins floor tile (16x16 seamless)
  3. Snowdin floor tile (16x16 seamless)
  4. Snowdin pine tree (tall, transparent)
  5. (optional) Ruins/Snowdin accent props to replace procedural look where cheap
- Fallback if a rip can't be verified: hand-author the tile in the same style (last resort).

## 6. Testing Plan (TDD)
- Every bug fix starts with a failing test (pixel-content level where possible).
- New/updated tests: B1 full-body cells; B2 corner-alpha 0 after cutout; B3 destination spawn walkable + on-camera; floor seamlessness (edge-pixel wrap match); tree prop structure (sprite + shadow + trunk collision + y-sort); layout validity (P/S/E/D cells exist, all props/doors/encounters on walkable cells, room = 40x30).
- Full suite gate: ALL TESTS PASSED, zero SCRIPT ERROR / ASSERT FAIL / FAIL:, only permitted stderr.
- Export + boot gate: `--export-release "Windows Desktop" dist\SoulHeart.exe`, boot `--headless --quit-after 60` ExitCode 0.

## 7. Delivery
- Same pipeline: plan(s) → branches/worktrees → hybrid execution (inline tasks vs subagent tasks chosen per task) → final whole-branch review → merge to main → fresh suite on main → export/boot on main → cleanup worktrees/branches → delivery report with what to test.

## 8. Out of Scope (deferred)
- Battle-screen visual overhaul (already authentic), dialogue portraits, new rooms, controller support, enemy stats refactor (dead `enemy_stats.gd`), T2 feet/collision visual pass, unused laser_sweep/GRAY/type_override/telegraph data, unused atlas tiles cleanup.
