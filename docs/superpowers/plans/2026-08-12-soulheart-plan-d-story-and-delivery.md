# Plan D — Story system + Endings + Music + Edit events + Delivery

**Status:** draft → commit → execute in worktree `plan-d-story`
**Branch:** `plan-d-story` (off `main` @ `de2a18f`)
**Spec source:** `docs/superpowers/specs/2026-08-12-soulheart-plan-d-design.md` (full design) + `2026-08-11-soulheart-full-game-design.md` lines 265-272 (Plan D scope).

## Goal

Ship the story layer: 6 edit events, save point echoes, ending choice + 3 endings, 4 new music tracks + Wisp leitmotif, and the final delivery (export, kit, README). Game becomes fully playable start-to-ending.

---

## Engine Reality (verified ground truth)

| File | Key facts |
|------|-----------|
| `scripts/autoload/game_state.gd` | `flags: Dictionary`, `save_game()`, `load_game()`, `reset()`. No wipe helper yet. Save path `user://save.json`. |
| `scripts/rooms/save_point.gd` | Area2D; `_show_banner(text)` (Panel+Label at (24,404), auto-fade 1.0s + 0.8s). `_on_body_entered` → set flag, save, sfx, banner. |
| `scripts/autoload/audio.gd` | `MUSIC` const dict of preloads (keys: title,drizzle,grumble,echo,hometown,battle,death,door_open,door_close). `SFX` const dict. `play_music(id)`, `play_sfx(id)`. WAVs need `loop_mode` set via `setup_stream_loop`. |
| `scripts/rooms/canon.gd` | `class_name Canon`. LAYOUT 40x30 grid (rows 0-29; row 0/29 wall; walls col 0/39). Plays `grumble` (WRONG — fix to canon). `_spawn_bosses()` uses `BOSSES` const. `_spawn_save_points/_spawn_encounters/_spawn_props` patterns to mimic. Encounters at (13,4),(13,9),(13,17),(11,24); save (8,7); doors (1,14),(38,14); boss (20,15). |
| `scripts/rooms/cracks.gd` | Same shape. `BOSSES` = index (328,248) + canon_true (88,392) — **canon_true must move behind Keeper door**. Plays `drizzle` (WRONG — fix to cracks). Door (1,14). |
| `scripts/rooms/npc.gd` | Area2D with `@export dialogue_file`; on body_entered: parse + DialogueUI + await finished + free. Reusable for Old Dreamer. |
| `scripts/dialogue/dialogue_ui.gd` | `ui.open(lines: Array[Dictionary])`, signal `finished`. Lines are `{speaker, text}`. |
| `scripts/dialogue/dialogue_parser.gd` | `parse_file(path)` → Array[Dictionary]. Lines `* text` or `Speaker: text`. |
| `scripts/battle/battle.gd` | 544 lines; `_enemy` from `EnemyLibrary.get_enemy`; WIN branch in `_resolve_fight` hp<=0 → `_end_battle` returns to `from_room`. `canon_true` entry EXISTS in library (Plan C). |
| `scripts/util/sprites.gd` | `prop_texture(name)` loads `res://assets/sprites/overworld/<name>`. `save_point_texture()` animated. |
| `tools/gen_area_music.gd` | `@tool extends SceneTree`; MOTIFS dict id→[freqs]; writes 8-bit mono WAV via `AudioStreamWAV.save_to_wav("res://assets/audio/music/mus_<id>.wav")`. Extend with 5 motifs. |
| `tools/godot.exe`, `export_presets.cfg` | gitignored; must be copied from main repo into worktree (Plan C pattern). |
| `tests/run_all.gd` | Loads every `test_*.gd`, runs `test_*` methods; `TestHelper.eq/is_true` (msg MANDATORY); "ALL TESTS PASSED" gate. |
| `scripts/main.gd` | Title scene (Main.tscn): "Press Z to fall" → DrizzleFields. Endings return here. |

**Layout pixel math:** pixel = tile*16; spawns use center `col*16+8, row*16+8`.

**Canon event floor spots (verified against LAYOUT in tests):** (72,40)=row2col4, (584,40)=row2col36, (72,424)=row26col4, (584,424)=row26col36, (296,72)=row4col18, (360,424)=row26col22. All dots in layout — no E/S/D overlap.

**Cracks ending spots:** doors (120,440)=row27col7, (320,440)=row27col20, (520,440)=row27col32; dreamer (320,360)=row22col20. All floor.

---

## Tasks (TDD ordered)

### T1 — Design docs + plan doc [INLINE]
**Files:** `docs/superpowers/specs/2026-08-12-soulheart-plan-d-design.md` (written), this plan.
- Commit both to `main`. Create worktree `plan-d-story` from `de2a18f`. Copy `tools/godot.exe` + `export_presets.cfg` into worktree. Baseline `--import` + suite (must be ALL TESTS PASSED).

### T2 — Edit event system + 6 events [INLINE]
**Files:** `scripts/world/edit_event.gd`, `scripts/world/choice_menu.gd`, `scripts/rooms/canon.gd`, `assets/audio/sfx/edit_bell.wav` (gen in T6 tooling or inline gen), `tests/test_edit_events.gd`
- `edit_event.gd`: `class_name EditEvent extends Area2D`. Exports `event_id`, `prompt`. `static func choose(event_id: String, choice: String) -> String` — pure: sets `edit_event_<id>`, increments `edit_accepts/refuses/flees`, returns choice. Area: touch → ChoiceMenu → choose() → sfx → visual prop toggle (guarded `if get_tree() == null or Engine.is_editor_hint(): return` style — actually guard on `not is_inside_tree()` for headless safety; visual code lives in `_apply_world_change()`).
- `choice_menu.gd`: `class_name ChoiceMenu extends Control`. `open(options: Array[String])`; W/S move, Z confirm, X = flee (first option). Emits `chosen(String)`. Reuses Label styling like save_point banner.
- `canon.gd`: `_spawn_edit_events()` — 6 EditEvent nodes at the 6 floor spots with prompts per design doc.
- `edit_bell.wav`: generate with a tiny inline gen (reuse synth pattern) or extend `gen_area_music.gd` SFX section — simplest: extend gen_area_music with an SFX dict `{edit_bell: [660.0, 880.0]}` → write to `assets/audio/sfx/edit_bell.wav`. Register in audio.gd SFX.
- Tests: choose() updates counters+flags per choice; 6 event ids all floor-placed in canon layout (`int(grid[y][x]) == GameTiles.Tile.FLOOR`); prompt strings non-empty; choice_menu parses.

### T3 — Save point echoes [INLINE]
**Files:** `scripts/rooms/save_point.gd`, `tests/test_save_point_echo.gd`
- `static func echo_for(index: int) -> String` on save_point.gd (pool of 8 per design; name cycles Merritt/Anja/Silas/Ro; index 3 = foreshadow line "You will choose. You have already chosen.").
- `_on_body_entered`: after save banner, increment `echo_index` flag, show echo banner (delay 1.2s).
- Tests: echo_for deterministic for all 8; contains foreshadow line; names cycle; pool size 8; save_point.gd parses.

### T4 — Ending choice: dreamer + 3 doors + routing [INLINE]
**Files:** `dialogue/old_dreamer.dlg`, `scripts/world/ending_door.gd`, `scripts/world/ending.gd`, `scripts/rooms/cracks.gd`, `tools/gen_ending_sprites.gd`, `assets/sprites/overworld/door_*.png`, `assets/audio/sfx/door_seal.wav`, `tests/test_ending_routing.gd`
- `old_dreamer.dlg`: 6 lines (flavor, delivers the choice).
- `ending.gd`: `class_name Ending extends Node`. Static: `door_unlocked(door_id)` (hollow: accepts>=6; keeper: refuses>=4; wanderer: true), `available_doors()`, `wipe_save()` (reset + delete save file), `credits_lines()`.
- `ending_door.gd`: Area2D, `door_id`; sprite via `Sprites.prop_texture("door_<id>.png")`; touch: locked → sfx door_seal + banner "The way is sealed."; unlocked → keeper: pending_enemy=canon_true + from_room + save_game + fade + Battle.tscn; else `Ending.play_ending(door_id)`.
- `gen_ending_sprites.gd`: writes 16x16 door PNGs (keeper amber #e8a33c, wanderer blue #5a7bd8, hollow black #0a0a0e with frame) to `assets/sprites/overworld/`.
- `cracks.gd`: remove canon_true from BOSSES; `_spawn_ending_doors()` (3 doors + dreamer NPC via npc.gd); `_ready` keeper_victory hook (clear flag → Ending.play_ending("keeper") after 0.5s).
- `door_seal.wav`: gen in same tool (low thud [110.0]).
- Tests: door_unlocked gates (0/6, 6/6 accepts; 0/4, 4/4 refuses; wanderer always); available_doors; wipe_save deletes user://save.json + resets stats; cracks layout floor for 3 doors + dreamer; canon_true NOT in cracks BOSSES anymore; old_dreamer.dlg parses to >=4 lines.

### T5 — Endings + battle hook [INLINE]
**Files:** `scripts/world/ending.gd` (play sequences), `scripts/battle/battle.gd`, `tests/test_ending_routing.gd` (extend) or `tests/test_plan_d_endings.gd`
- `Ending.play_ending(id)`: fade_to_black → play music (credits; hollow→hollow) → DialogueUI lines (keeper/wanderer/hollow per design) → THE END → hollow: wipe_save → fade → `change_scene_to_file("res://scenes/Main.tscn")`. Guard all awaits behind `is_inside_tree()`.
- `battle.gd` WIN branch: after vaporize, if `str(_enemy.get("id","")) == "canon_true"`: `GameState.set_flag("keeper_victory", true)`.
- `credits_lines()`: 8 lines (title, subtitle, dev, engine, music, testers, thanks, THE END).
- Tests: battle.gd + ending.gd parse clean; credits_lines non-empty; keeper_victory flag set on WIN for canon_true (direct call into `_resolve_fight`-equivalent via flags helper — assert via parse + static helper `Ending.end_for_victory(enemy_id) -> String?` pure mapping: canon_true→"keeper", else null — battle uses it).

### T6 — Music + room themes [INLINE]
**Files:** `tools/gen_area_music.gd` (5 motifs + edit_bell/door_seal SFX), `scripts/autoload/audio.gd`, `scripts/rooms/canon.gd` (→"canon"), `scripts/rooms/cracks.gd` (→"cracks"), `assets/audio/music/mus_{canon,cracks,credits,hollow,wisp}.wav`, `tests/test_plan_d_music.gd`
- Extend MOTIFS: canon, cracks, credits, hollow, wisp (per design). SFX: edit_bell [660,880], door_seal [110].
- audio.gd: +5 MUSIC keys, +2 SFX keys (preloads).
- canon.gd → `Audio.play_music("canon")`; cracks.gd → `Audio.play_music("cracks")`.
- Run gen → `--import` → tests: all 5 WAVs exist + loadable; audio.gd MUSIC has the 5 keys; canon.gd source contains play_music("canon"); cracks contains play_music("cracks"); SFX has edit_bell/door_seal.

### T7 — Integration + export + boot [INLINE]
**Files:** `tests/test_plan_d_integration.gd`, `dist/SoulHeart.exe`
- Integration test: full chain — 6 events floor-placed + choose() math, 3 doors floor-placed, dreamer dlg parses, ending gates, music keys resolve non-null preloads, battle/ending parse clean, keeper_victory mapping.
- `--import` → suite ALL TESTS PASSED (worktree).
- Export `dist\SoulHeart.exe` (rcedit errors cosmetic per Plan C). Boot `--headless --quit-after 60` ExitCode 0.

### T8 — Delivery kit + README + spec mark [INLINE]
**Files:** `README.md`, `dist/SoulHeart_v1.0.zip`, spec mark
- README rewrite: premise/story, controls, 6 areas, edit events + endings guide (spoiler section), music (wisp leitmotif note), credits, run/build/test instructions.
- Zip: SoulHeart.exe + README.md + CREDITS.txt → `dist/SoulHeart_v1.0.zip`.
- Spec §7: mark `Plan D: COMPLETE` after line 272.
- Suite re-run on main after merge (finishing-a-development-branch flow).

---

## Execution Order

1. Commit T1 docs to main.
2. Worktree `plan-d-story` off `de2a18f`; copy godot.exe + export_presets.cfg; baseline import + suite green.
3. T2 inline → suite. 4. T3 inline → suite. 5. T4 inline → gen sprites → `--import` → suite. 6. T5 inline → suite. 7. T6 inline → gen music → `--import` → suite. 8. T7 inline → suite + export + boot. 9. T8 inline → kit + README + spec mark → final suite.
10. Commit each milestone separately (T2..T8). finishing-a-development-branch → merge to main → import + suite on main → export + boot → remove worktree + prune + delete branch → report.

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| ChoiceMenu UI breaks headless suite | All resolution logic pure-static; UI never instantiated in tests. |
| play_ending awaits hang headless | Tests never call play_ending; parse + pure helpers only. Guard awaits behind is_inside_tree(). |
| Spawn spots hit walls | Tests assert FLOOR at all 6 event + 3 door + dreamer spots via MapBuilder.parse_layout (int enum compare). |
| SCRIPT ERROR aborts test function silently | After every battle.gd/ending.gd edit, run suite immediately; kill godot proc if hang (Plan C lesson). |
| WAV loop mode missing → music stops | audio.gd `setup_stream_loop` handles AudioStreamWAV (LOOP_FORWARD) on play_music. |
| export_presets.cfg missing in worktree | Copy from main repo (gitignored, Plan C pattern). |
| prop_texture returns null if PNG missing | gen tool writes PNGs before `--import`; tests assert non-null. |
| battle.gd from_room mismatch after canon_true win | Door sets from_room="Cracks" (parent name of room node — verify room node name in Cracks.tscn; fallback: from_room flag check in cracks _ready uses `current_room` flag instead). |

## Definition of Done

- All 8 tasks complete; suite ALL TESTS PASSED on worktree + main.
- Full game flow: title → Hush…Cracks → 6 edit events → Index → Old Dreamer → doors; Keeper door → canon_true fight → Keeper ending; Wanderer/Hollow endings play; Hollow wipes save.
- 5 new music files + 2 SFX; canon/cracks play correct themes; wisp leitmotif track registered.
- `dist\SoulHeart_v1.0.zip` kit; README rewritten; spec §7 marked Plan D: COMPLETE.
- Worktree removed, branch deleted, final report to LO.
