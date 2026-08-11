# SoulHeart — Plan D Design: Story, Endings, Music, Delivery

**Date:** 2026-08-12
**Status:** Approved (direction delegated to implementer by LO)
**Source:** `2026-08-11-soulheart-full-game-design.md` §7 Plan D (lines 265-272), §5.2 (edit events, save point echoes, endings), §4.5/4.6 (The Canon, The Cracks)

---

## 1. Scope

Plan D ships the story layer of SoulHeart:

1. Edit event system + 6 scripted edit events (The Canon).
2. Save point echoes.
3. Ending choice at The Cracks (Old Dreamer + 3 doors).
4. 3 endings (Keeper, Wanderer, Hollow) with credits.
5. Music: 4 new area/thematic tracks + Wisp leitmotif; fix wrong room themes.
6. Final commit, export, delivery kit, README rewrite.

**Shippable:** full playable game, walkable start-to-ending with consequences.

---

## 2. Design Decisions (made by implementer, delegated by LO)

### 2.1 Edit event system

- `scripts/world/edit_event.gd` — `class_name EditEvent`, Area2D.
  - `@export var event_id: String` (one of 6 fixed ids).
  - `@export var prompt: String` — the world-rewrite description shown before the choice.
  - On player touch: show `ChoiceMenu` (Flee / Refuse / Accept).
  - Resolution via **pure static** `static func choose(event_id: String, choice: String) -> String` — headless-testable, no UI:
    - Updates `GameState` flags: `edit_event_<id>` = choice; `edit_accepts` / `edit_refuses` / `edit_flees` counters incremented.
    - Plays `edit_bell` SFX + applies a visual prop change (spawn/free a Sprite2D per event) — visual part guarded so it no-ops headless.
  - Flee = skip without taking a side (world notes it; counts toward nothing).
- `scripts/world/choice_menu.gd` — `class_name ChoiceMenu`, Control UI. 3 labels, W/S moves cursor, Z confirms, X = Flee. Emits `chosen` signal with the label. Builds its own buttons from an Array[String]; generic enough to reuse for the ending choice if ever needed.
- **6 events in `canon.gd`** (floor-verified in tests; centers at col*16+8, row*16+8):

| # | event_id | prompt (short) | pos | world change |
|---|----------|----------------|-----|--------------|
| 1 | `shelf_book` | A bookshelf gains a book. | (72, 40) | book sprite appears/removes |
| 2 | `wall_window` | A wall gains a window. | (584, 40) | window sprite appears/removes |
| 3 | `door_moves` | A door now leads somewhere else. | (72, 424) | small sign flips |
| 4 | `name_changes` | A sign's name changes. | (584, 424) | sign text sprite swaps |
| 5 | `portrait` | A portrait appears on the wall. | (296, 72) | portrait sprite |
| 6 | `floor_crack` | A crack in the floor closes. | (360, 424) | crack sprite appears/removes |

- `edit_bell` SFX: `assets/audio/sfx/edit_bell.wav` (short two-tone ding), registered in audio.gd.

### 2.2 Save point echoes

- `save_point.gd`: after the "Game saved." banner, show an echo line via a second banner.
- Pure static `static func echo_for(index: int) -> String` — index from `GameState.flags.get("echo_index", 0)` incremented each save.
- Echo pool (8 lines), deterministic rotation:
  1. `Game saved?`
  2. `The save point remembers a save you didn't make.`
  3. `Someone named {name} saved here.` (name cycles: Merritt / Anja / Silas / Ro)
  4. `You will choose. You have already chosen.`  ← the foreshadow line (first-save echo target per spec)
  5. `It hums the wisp's tune, one note early.`
  6. `A crack closes somewhere. It was probably this one.`
  7. `This is the version where you stayed.`
  8. `Game saved.` (echo of the echo)
- Echo shown for every save; `echo_for` picks `pool[(index) % pool.size()]` with the name substituted.

### 2.3 Ending choice at The Cracks

- `dialogue/old_dreamer.dlg` — final NPC dialogue (5-6 lines, flavor per spec: the first dream, knows everything).
- `scripts/rooms/npc.gd` reuse: Old Dreamer NPC spawned in `cracks.gd` at (320, 360); dialogue_file = old_dreamer.dlg.
- **3 ending doors** — `scripts/world/ending_door.gd` (`class_name EndingDoor`, Area2D):
  - `@export var door_id: String` — `keeper` | `wanderer` | `hollow`.
  - Sprite: `assets/sprites/overworld/door_keeper.png` / `door_wanderer.png` / `door_hollow.png` (16x16: amber door / blue door / void-black door), loaded via `Sprites.prop_texture`.
  - Touch behavior:
    - Locked → `Audio.play_sfx("sting")` + banner `The way is sealed.`
    - Unlocked → banner `You step through.` → fade → route:
      - **keeper**: sets `pending_enemy=canon_true`, `from_room=Cracks`, `last_boss_save_canon_true`, `GameState.save_game()` → `change_scene_to_file Battle.tscn` (Canon true form fight — already in enemy library from Plan C).
      - **wanderer / hollow**: `Ending.play_ending(door_id)`.
- **Availability (pure, testable)** — `scripts/world/ending.gd`:
  - `static func door_unlocked(door_id: String) -> bool`
    - hollow: `int(GameState.flags.get("edit_accepts", 0)) >= 6`
    - keeper: `int(GameState.flags.get("edit_refuses", 0)) >= 4`
    - wanderer: always `true`
  - `static func available_doors() -> Array[String]`
- `cracks.gd` changes:
  - **Remove `canon_true` from unconditional BOSSES** (it moves behind the Keeper door).
  - `_spawn_ending_doors()`: 3 doors at (120, 440), (320, 440), (520, 440); Old Dreamer at (320, 360).
  - `_ready` post-victory hook: if `flags.get("keeper_victory")` → clear flag → `Ending.play_ending("keeper")` (after Index/canon_true battles return to Cracks).

### 2.4 Three endings + credits

- `scripts/world/ending.gd` (`class_name Ending`, Node):
  - `static func play_ending(id: String) -> void` — fade to black → music (`credits`, or `hollow` for hollow) → typewriter lines via DialogueUI (awaits finished) → `THE END` → fade → `change_scene_to_file Main.tscn` (title).
  - **Keeper** lines: Canon puts down the quill / cracks stay open / world plural again / you are still deciding — good / THE END.
  - **Wanderer** lines: one crack closes, rest stay open / world half-remembered / save points remember you, not why / Wisp hums alone — you hum back / THE END.
  - **Hollow** lines: world is one thing now / perfect, quiet, finished / you wake in your own bed / you don't remember falling / you don't remember playing / THE END.
  - **Hollow** additionally: `GameState.wipe_save()` (reset + delete `user://save.json`) — pure `static func wipe_save() -> void`, testable.
  - `static func credits_lines() -> Array[String]` — hardcoded credits block (title, "a dream about the ones you left behind", dev credit from CREDITS.txt spirit, engine credit, thank-you line).
- `battle.gd` WIN branch: if `str(_enemy.get("id","")) == "canon_true"` → `GameState.set_flag("keeper_victory", true)` before `_end_battle`.

### 2.5 Music

- Extend `tools/gen_area_music.gd` with 5 new motifs (same synth pipeline, 8-bit mono WAV, 22.05kHz):

| id | file | motif (Hz; 0 = silence) | feel |
|----|------|-------------------------|------|
| `canon` | `mus_canon.wav` | [196.0, 196.0, 233.08, 233.08, 293.66, 261.63, 233.08, 196.0] | mechanical march (opens on leitmotif root) |
| `cracks` | `mus_cracks.wav` | [440.0, 0.0, 523.25, 0.0, 440.0, 0.0, 587.33, 0.0] | sparse tension |
| `credits` | `mus_credits.wav` | [261.63, 329.63, 392.0, 523.25, 659.25, 523.25, 392.0, 329.63] | warm resolution |
| `hollow` | `mus_hollow.wav` | [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 440.0] | silence + one note |
| `wisp` | `mus_wisp.wav` | [523.25, 659.25, 783.99, 659.25] | the 4-note leitmotif |

- **Wisp leitmotif**: 4-note C5-E5-G5-E5. It "resolves differently in each area": canon motif opens on 196.0 (G3 — leitmotif resolution root); credits ends on 329.63 (E4); hollow's single note is 440.0 (A4 — unresolved). Documented in README.
- `audio.gd`: register 5 new MUSIC keys (canon, cracks, credits, hollow, wisp).
- **Fix wrong room themes**: `canon.gd` currently plays `grumble` → change to `canon`; `cracks.gd` plays `drizzle` → change to `cracks`.
- New SFX `edit_bell` + `door_seal` (low thud for locked door).

### 2.6 Delivery

- `dist\SoulHeart.exe` rebuilt (export_presets.cfg is gitignored — copy from main repo into worktree).
- Delivery kit: `dist\SoulHeart_v1.0.zip` = SoulHeart.exe + README.md + CREDITS.txt.
- README rewrite: story premise, controls, areas, edit events, endings guide, credits, build/run instructions.
- Spec §7 mark: `Plan D: COMPLETE`.

---

## 3. New/Edited Files

**New:**
- `scripts/world/edit_event.gd`, `scripts/world/choice_menu.gd`, `scripts/world/ending_door.gd`, `scripts/world/ending.gd`
- `dialogue/old_dreamer.dlg`
- `tools/gen_ending_sprites.gd` (3 door PNGs)
- `assets/sprites/overworld/door_{keeper,wanderer,hollow}.png`
- `assets/audio/music/mus_{canon,cracks,credits,hollow,wisp}.wav`
- `assets/audio/sfx/edit_bell.wav`, `assets/audio/sfx/door_seal.wav`
- `tests/test_edit_events.gd`, `tests/test_save_point_echo.gd`, `tests/test_ending_routing.gd`, `tests/test_plan_d_music.gd`, `tests/test_plan_d_integration.gd`

**Edited:**
- `scripts/rooms/canon.gd` (6 edit events + music key), `scripts/rooms/cracks.gd` (doors, dreamer, canon_true removal, music key, keeper_victory hook)
- `scripts/rooms/save_point.gd` (echo), `scripts/autoload/audio.gd` (5 music + 2 sfx keys), `scripts/autoload/game_state.gd` (wipe_save), `scripts/battle/battle.gd` (keeper_victory flag), `tools/gen_area_music.gd` (5 motifs), `scripts/util/sprites.gd` (3 door textures via prop_texture — no change needed, prop_texture loads by name)
- `docs/superpowers/specs/2026-08-11-soulheart-full-game-design.md` (§7 Plan D mark), `README.md`

---

## 4. Testing Strategy

- All new logic is pure-static where possible → direct headless asserts.
- Layout floor checks via `MapBuilder.parse_layout` (grid cells are int enum values; `int(grid[y][x]) == GameTiles.Tile.FLOOR`).
- `battle.gd` / `ending.gd` UI paths: parse-clean + flag/logic assertions only (no simulated play).
- Suite gate: `ALL TESTS PASSED`, no SCRIPT ERROR.
- Export + headless boot `--quit-after 60` ExitCode 0.

---

## 5. Non-Goals

- No new rooms, mobs, or boss fights (Plan A/B/C territory).
- No new tile styles.
- No save-scum protection beyond the Hollow wipe.
- No branching dialogue engine (dlg format unchanged).
