# SoulHeart — Plan F Audit (Read-Only)

Project: `C:\Users\Admin\Downloads\SoulHeart`
Engine: Godot 4.4.1 (`Godot_v4.4.1-stable_win64_console.exe` — see §C-1)
Viewport: 640×480, GL Compatibility (`project.godot`)
Autoloads: `GameState`, `Audio`, `Fade`
Mission files: dev tools previously removed (docs/, probes, `scripts/tools/gen_sfx.gd`) per project claim — but see §C-1.

---

## Section A — Inventory (file:line refs)

### A-1. Battle feel

| Concern | Where | What |
|---|---|---|
| Heart hitbox (single source of truth) | `scripts/battle/dodge_box.gd:192` | `CombatMath.circle_hit(heart.position, 4.0, b.position, b.size)` — **heart radius hard-coded to 4.0** in the bullet collision check |
| Bullet collision radius | `scripts/battle/dodge_box.gd:192`, `dodge_box.gd:207` (yellow shot r=3.0) | Pulled from per-bullet `size` field |
| Bullet hit tolerance (velocity gate for SOUL color rules) | `scripts/battle/dodge_box.gd:226-236` (`_bullet_damages`) | `BLUE`: only damages if `heart_vel.length() > 8.0` (moving). `ORANGE`: only damages if `heart_vel.length() <= 8.0` (still). `GRAY` / `GREEN`: never damage. **No positional hit tolerance value** — rule gating acts as the "feels" parameter |
| Bullet heart start | `dodge_box.gd:10` | `HEART_START := Vector2(320, 315)` |
| Move box | `dodge_box.gd:8-9` | `BOX_RECT (162,220,316,190)` outer / `BOX_INNER (167,225,306,180)` playable |
| Heart speed | `dodge_box.gd:7` | `HEART_SPEED := 160.0` |
| Hit i-frames | `dodge_box.gd:11, 116-118, 222` | `INVULN_TIME := 1.0`; visual flash via `int(invuln * 10.0) % 2 == 0` |
| Knockback on hit | `dodge_box.gd:13, 199-202` | Push heart 6 px away from bullet, clamped to BOX_INNER |
| Stagger freeze | `dodge_box.gd:12, 117, 146-148` | `STAGGER_TIME := 0.2` — input locked, no collision checks |
| Soul modes wired | `dodge_box.gd:67-78, 150-178` | `red | blue (gravity+jump) | purple (4 rails) | green (shield cycle) | yellow (shooter, JUMP_VEL unused)` |
| Heart texture (battle) | `scripts/util/sprites.gd:5-13` + `assets/sprites/{Red,Orange,Yellow,Green,Blue,Purple,Light_blue}_SOUL_sprite.png` | Each soul color is loaded by name (`Sprites.soul_texture("Red")` etc.), falls back to Red_SOUL on miss. Files are 121–260 B PNGs (small). See §C-3 — exact pixel dims need Image read |
| Bullet texture (base pellet) | `scripts/util/sprites.gd:30-37` | 8×8 generated (white with dark border). Per-type variants in `bullet_texture_for()` (`sprites.gd:133-217`): BONE 14×10, SPEAR 6×22, RING 14×14, LASER 24×90, ARROW 14×6 — all generated at runtime |
| Bullet types & rules enums | `scripts/battle/bullet.gd` (top) | `Type {PELLET,BONE,SPEAR,RING,LASER,ARROW}`, `Rule {NONE,BLUE,ORANGE,GRAY,GREEN,YELLOW}` |
| Bullet pattern library | `scripts/battle/bullet_patterns.gd:1-222` | 15 pattern functions: `fan`, `_aimed`, `_sine_row`, `_ring`, `_spiral`, `_bone_wall`, `_spear_volley`, `_laser_sweep`, `_weave`, `_wall`, `_beam_sweep`, `_rain`, `_bait`, `_homing`, `_green_heal`, `_gray_pass`, `_edit`. Default size 3.0, bone_wall/wall 6.0, beam 8.0, spear 4.0 |
| Hit-tolerance related test guards | `tests/test_combat_math.gd:17-20`, `tests/test_dodge_box.gd:45-130`, `tests/test_hurt_feedback.gd:14-45`, `tests/test_battle_variety.gd:128-156` | Asserts the radius-4.0 + rule-gate behaviour. **Any change to either must be mirrored here or tests break** |
| FIGHT bar | `scripts/battle/fight_bar.gd:1-17` | Triangle-wave marker; `press()` returns `1 - |marker-0.5|*2` (center bias, not classic FIGHT). Driven by `Battle._build_fight_bar()` at `battle.gd:110` (partial view) |
| Battle scene entry | `scripts/battle/battle.gd:53-78` | Loads pending enemy from `GameState.flags["pending_enemy"]`, tweens sprite in from `Vector2(216, -40)` to `(216, 136)` over 0.4s, plays intro line |
| Boss intro overlay | `battle.gd:149-173` | `THE <NAME>` label at `y=220`, fade-to-black 0.4 → 1.1s hold → fade-from-black 0.4 |
| HUD layout | `battle.gd:80-200` (partial) | Name (30,30), HP (30,60), enemy HP bar (207-225, 161-167), player HUD (30,400 / 275,400), DREAMCATCHER LV 1 — label-only, no animated HP drain visible in partial read |
| Menu grid + submenu boxes | `battle.gd:4-10` | `MENU_GRID = [(0,0),(1,0),(0,1),(1,1)]`; submenu boxes for ACT/ITEM/MERCY anchored at y=385 |
| Flee chance | `battle.gd:5` | `FLEE_CHANCE := 0.5` (consistency with Undertale's random-flee, never used in boss fights — `EnemyLibrary` `no_flee` flag respected) |

### A-2. World feel

| Concern | Where | What |
|---|---|---|
| Tile size / room grid | `scripts/rooms/layout_parser.gd:40`, `map_builder.gd:83-88` | All rooms 40 wide × **30 tall** (padded), 16-px tiles. Final pixel size: 640 × 480 (matches viewport) |
| Layout chars → tiles | `layout_parser.gd:19-58` | `#` wall, `T` tree (pine), `t` pine2, `b` birch, `d` dead, `B` bush, `M` mushroom, `g` grass, `.` floor, `P` player_start, `E` encounter, `S` save, `D` door |
| Floor variant A/B | `map_builder.gd:40-41` | Alternates `(x+y)%2` between `FLOOR_A` and `FLOOR_B` (subtle checker) |
| Tree sprite paths | `map_builder.gd:43-52` | PINE2→`tree_pine_b.png`, BIRCH→`tree_birch.png`, DEAD→`tree_dead.png`, default→`tree_pine.png`. Loaded as Sprite2D via `RoomTree` |
| Tree sprite dimensions | `assets/sprites/overworld/tree_pine.png` (456 B), `tree_pine_b.png` (449 B), `tree_birch.png` (441 B), `tree_dead.png` (395 B) — sizes are file-byte counts; pixel dims need Image load to confirm (typical per import is 16×32 trunk, canopies overlay) |
| Tree collision | `scripts/rooms/tree.gd:17-24` | `RectangleShape2D size 8×24` offset `(0,12)` → trunk only, anchored at trunk center. **No canopy collider** — see §C-2 |
| Tree shadow | `tree.gd:10-16` | `shadow_ellipse.png` scaled `(2,1)` at `Vector2(0,24)`, alpha 0.3, z=-1 |
| Tree draw order | `tree.gd:8-9` | `z_index=0`, `y_sort_enabled=true` — so character tucks behind trunk but always renders above canopy? See §C-2 |
| Bush / Mushroom / Grass props | `map_builder.gd:66-81` | Positioned at tile center; **no collision**, just decoration |
| Encounter trigger | `scripts/rooms/encounter.gd:1-62` | `Area2D` with `CircleShape2D radius=8.0`, scaled sprite `(0.5,0.5)`, bobs -26↔-30. On `body_entered(player)`: sets `pending_enemy`+`from_room` flags, plays `sting` sfx, `Fade.flash(0.15)`, waits 0.4s, `change_scene_to_file("res://scenes/Battle.tscn")`. Boss variant also calls `GameState.set_flag("last_boss_save", enemy_id)` + `GameState.save_game()` |
| Save point | `scripts/rooms/save_point.gd` (read mentioned) | Animated star from `assets/sprites/overworld/frames/save_point/` (4 frames @ 15 fps, sprites.gd:289-299) |
| Door scene transition | `scripts/rooms/door.gd` (read mentioned) | Doors hand off `target_room` + `target_spawn` from each room's `DOOR_TARGETS` array |
| Per-room CanvasModulate tint | every room `_ready()` | Echo `(0.72,0.78,0.95)` cool blue, Grumble `(0.85,0.9,1.0)` cold white, Drizzle `(0.8,0.78,1.0)` purple-blue, Hometown `(1.0,0.93,0.82)` warm, Canon `(0.92,0.85,0.72)` sepia, Cracks (read pending) |
| Player sprite + sheet | `scripts/player/player.gd:14-19` + `assets/sprites/overworld/frisk_sheet.png` (1296 B) | `Sprites.player_frisk_texture(facing, step)` slices a 19×29 cell from a 4-row × 3-step sheet (sprites.gd:304-323), applies outline pass |
| Player physics | `player.gd:3-4` | `SPEED 140`, `ACCEL 1200` — gentle ramp; facing cached separately from velocity; `move_and_slide()` driven in `_physics_process` |
| Direction resolution | `player.gd:21-38` | 4-dir lock — last-pressed wins; diagonals collapse to the dominant axis. Strict 4-dir, no 8-dir |
| Walk anim | `player.gd:56-60` | 3 frames every 0.2s; sprite Y bobs by 1 px on second half-step |
| Player shadow | `player.gd:16-19` | `player_shadow_texture` (6×3) at `(0,13)` |
| Overworld background | `map_builder.gd:27-31` | Full-room black `ColorRect` at z=-10 — provides the silhouette behind tiles |
| Encounter / Save / Door spawn | every room `_spawn_encounters / _spawn_save_points / _spawn_door` | Round-robins `ENCOUNTER_ENEMIES` against encounter positions from LAYOUT |
| Room list (count: 6) | `scenes/rooms/{Echo, GrumbleWoods, DrizzleFields, Hometown, Cracks, Canon}.tscn` | Each with paired `.gd` script |

#### Room visual identities (read)

| Room | Tint | Music | Encounter set | Notable props | Boss |
|---|---|---|---|---|---|
| Echo | `(0.72,0.78,0.95)` | `echo` | `[sentimint, repeato, moldsmal, migosp]` | rocks @ (120,96),(320,400),(480,160) | none |
| Grumble Woods | `(0.85,0.9,1.0)` | `grumble` | `[migosp, loox]` | dense t/t/b/g/M/B, 4 mixed props, sign NPC with `grumble_sign.dlg` | none |
| Drizzle Fields | `(0.8,0.78,1.0)` | `drizzle` | `[froggit, whimsun, vegetoid, loox]` | toad NPC at (96,144) `drizzle_toad.dlg`, 4 mixed props, **opens with Wisp intro** | none |
| Hometown | `(1.0,0.93,0.82)` | `hometown` | `[toadally, vegetoid, punkin]` | golden_flowers/rock props | none |
| Cracks | (read pending) | — | — | — | — |
| Canon | `(0.92,0.85,0.72)` | `canon` | `[nullaby, quibble, margin]` | 2 rocks, 6 `EDIT_EVENTS` (shelf_book, wall_window, door_moves, name_changes, portrait, floor_crack) | `mourning_knight` @ (328, 248) |

### A-3. Opening scene & narrative

| Concern | Where | What |
|---|---|---|
| Main scene | `scripts/main.gd:1-41` | Black bg, title "SoulHeart" (48 px) at (215,170), subtitle "a dream about the ones you left behind" (16 px) at (150,240), blinking "Press Z to fall" hint (16 px) at (260,320), version stamp "SOULHEART v0.3" (8 px) at (160,232). Music `title`. Z → fade 0.3 → `DrizzleFields.tscn` |
| Opening fade-in | `main.gd:35-41` | Blink hint via `sin(Time.get_ticks_msec() * 0.004) > 0` |
| First room (intended) | `main.gd:40` | **DrizzleFields** — wisp intro plays immediately on entry (`wisp_intro.dlg`), toad greets, then explore |
| Wisp intro | `dialogue/wisp_intro.dlg:1-4` | "* A small light drifts toward you. It smells like printer paper and cold coffee. * It hovers. It is waiting for you to hum. * (You feel it: the hum would help.)" — establishes hum action as a mechanic |
| Per-area wisp ambient | `dialogue/wisp_{echo,grumble,drizzle,hometown,cracks,canon}.dlg` | 3 lines each, atmospheric — echoes, pines, rain, windows, reflections, bulbs |
| NPC intros | `dialogue/{reminisc,hushroom,paneic}_intro.dlg` | First-encounter flavour + paren hint about which ACT to try |
| Boss / room-dialogue files | `dialogue/mourning_knight.dlg`, `dialogue/index.dlg`, `dialogue/old_dreamer.dlg` | Boss monologue fragments. `old_dreamer` explains the three doors (keeper/hollow/wanderer) |
| Hum action wiring | `GameState._ensure_input_actions()` (`game_state.gd:95-103`) + input map `hum` → `KEY_Z` (same key as `confirm`). **Potential conflict** — see §C-4 |
| Typewriter SFX | `scripts/dialogue/dialogue_ui.gd:91-93` | Plays "blip" per non-space char with pitch `randf_range(0.9, 1.1)` |
| Inventory / items | `scripts/autoload/game_state.gd:6, 17, 37-44` | `inventory: Array[Dictionary]` initialised with one `dream_candy` (heal 6). `use_item(index)` removes after applying. **Only one item type defined, no shop system, no item pickup from overworld** — see §C-5 |
| Save/load system | `game_state.gd:46-78` | JSON to `user://save.json`; `_normalize_saved` flattens floats-that-are-actually-ints; inventory stored as `Array<Dictionary>` |
| Save point → restore | every room `_spawn_point()` | If `current_room == ROOM_PATH` and `save_point` flag set, return that Vector2 instead of player_start |

### A-4. Known bugs / risk flags (preliminary)

- `Battle._build_fight_bar()` is referenced from `battle.gd:110` (partial read). Need to confirm the FIGHT marker uses `press()` from `fight_bar.gd` and binds to `_attack_hit()` properly. Also confirm whether hit strength affects damage (looking at `combat_math.gd:3-5`, `intent` is clamped 0–1 but currently `Battle` always passes 1.0 in normal flow — see §C-6).
- `EnemyLibrary.get_enemy()` returns `_enemies[id].duplicate(true)` — true deep copy of nested `acts` arrays. Safe.
- `Soul_heart.gd` line 21 (`game_state.gd`) — `inventory` typed `Array[Dictionary]`, but `use_item` does `inventory.remove_at(index)` which is fine for typed arrays.
- `canon.gd:75 _spawn_bosses()` not guarded by visited/state flags — every visit spawns `mourning_knight`. If `last_boss_save` flag logic doesn't gate this, the encounter Area2D will be present post-victory. See §C-7.
- `dodge_box.gd:69` `_soul_vel` reset to ZERO on mode change but heart velocity sample still uses old `last_heart_pos`, can produce a one-frame spike on mode switch. See §C-8.

---

## Section B — Reuse map (KEEP / EXTEND / REWRITE)

### B-1. KEEP (no changes required for Plan F)

| System | Why it survives |
|---|---|
| `scripts/rooms/layout_parser.gd` | Single static parse function. ASCII grammar is readable and powers all 6 rooms. Tests pin it (`test_layout_parser.gd`). |
| `scripts/rooms/map_builder.gd` | Clean separation of tile/prop/tree construction. Style key threaded through `GameTiles.build_tileset(style)`. |
| `scripts/util/sprites.gd` (procedural bullets + outline pass) | Already covers 6 bullet types as runtime Image textures; cutout-black pipeline is reusable for new sprites. |
| `scripts/battle/combat_math.gd` | Pure functions. Tests assert radius-4.0 circle_hit. Replace only if we add positional hit tolerance — and then update both `dodge_box.gd:192` **and** `test_combat_math.gd:17-20`. |
| `scripts/battle/battle_state.gd` | FSM with `VALID_TRANSITIONS`. Tested in `test_battle_state.gd`. |
| `scripts/autoload/game_state.gd` (save/load + inventory + flags) | Mature JSON round-trip. |
| `scripts/dialogue/dialogue_ui.gd` | Battle and overworld boxes, typewritten with per-char blip. |
| `scripts/dialogue/typewriter.gd` | Char pacing — leave alone. |
| `scripts/world/choice_menu.gd` | Already a generic choice prompt (prompt+options). Could be reused in Act dialog if extended. |
| `scripts/battle/enemy_library.gd` (data only) | 26 enemy defs (incl. bosses + multi-form Index). Patterns reuse all 15 generators. |
| `scripts/rooms/tree.gd` | Compact sprite+shadow+trunk-collider. Tweakable. |
| `scripts/rooms/door.gd` + `scripts/rooms/save_point.gd` | Standard area → scene-change primitives. |
| `scripts/battle/fight_bar.gd` | Triangle-wave marker; already does centre-bias for FIGHT strength. |

### B-2. EXTEND (additive changes, no rewrite)

| System | What to add |
|---|---|
| `dodge_box.gd` | Add a `HIT_TOLERANCE` constant (default 1.0–1.5 px forgiveness) and apply it to `circle_hit` via `b.size + HIT_TOLERANCE`. Mirror in `combat_math.gd:17-19` (or override locally). Update `test_combat_math.gd` to assert the new sum. |
| `combat_math.gd` | Add `circle_hit_tolerant(...)` if we want to keep pure functions; otherwise just pass `tolerance` as a 5th arg. |
| `dodge_box.gd` mode list | Add `orange_soul` if the Index Page Two `soul_mode="yellow"` test (`enemy_library.gd:421`) is actually yellow-mode (re-verify — `_make_mob` accepts the 11th arg `p_soul_mode`; `nullaby`=blue, `margin`=purple, `lookey`=green). |
| `enemy_library.gd` Index forms | Already complete (3 forms). No change needed; just ensure `Battle._advance_form` reads the right key (partial — confirm in `battle.gd` mid-file). |
| `game_state.gd` | Add item pickup helper: `add_item(dict)`, `item_count(id) -> int`. Currently no way to gain items — `use_item` only consumes the seeded `dream_candy`. |
| `choice_menu.gd` | Generalise accept signals so it can replace battle submenu navigation if we want consistency. |
| `bullet_patterns.gd` | Add `scatter` (one-shot cone with random spread) and `timed_wall` (wall that holds for N frames then releases) — useful for Index/Canon. |
| `main.gd` | Add a 1.5–2 s pause before fading into Drizzle so the title doesn't snap; add a faint screen-edge vignette. Cheap polish, no rewrite. |
| `sprites.gd` | Add `reminisc_texture`, `hushroom_texture`, `paneic_texture`, etc. for the 1-frame mob placeholders if we want non-default portraits. Currently every "1" in `_enemy_frames` falls through to a missing-frame path — see §C-9. |
| `dialogue_ui.gd` | Add per-speaker color override (used in boss monologues) — currently one font color for all. |

### B-3. REWRITE (necessary, not just extend)

| System | Why |
|---|---|
| None of the core systems need a rewrite for Plan F. | The architecture is already factored well. Most "feel" work is polish (constants, easing curves, ambience layers) that lives inside the existing files. |

> If we wanted one place to consolidate: **extract the per-room `_ready` boilerplate** into a base class (`BaseRoom` `_spawn_player / _spawn_wisp / _spawn_save_points / _spawn_encounters / _spawn_door / _spawn_props`). All 6 rooms duplicate ~60 lines each. This is refactor territory, not a rewrite — but is the highest-LOC cleanup available.

---

## Section C — Risks & unknowns

### C-1. `tools/` directory contradicts "dev files removed"

- Location: `tools/`
- Contains **14 stale `.uid` files** (each 19–20 bytes), **5 stray `.png.import` files** (`row2.png.import`, `row2_verify.png.import`, `row3.png.import`, `row3_flipped.png.import`, `row3_raw.png.import`), and **two Godot executables** (`godot.exe` 156 MB, `Godot_v4.4.1-stable_win64_console.exe` 201 KB).
- The matching `.gd` files are gone (as claimed), but their `.uid` siblings were left behind — Godot will warn on import if these orphan UIDs can't resolve to a script. Same for the orphan PNG imports with no source PNGs.
- **Risk**: Editor noise / broken UIDs on `git pull`; engine binary in version control is a 156 MB repo bloat.
- **Fix (when editing is allowed)**: `rm tools/*.uid tools/*.png.import tools/godot.exe tools/Godot_v4.4.1-stable_win64_console.exe` — keep nothing in `tools/` until something is actively used.

### C-2. Tree collision is trunk-only

- `scripts/rooms/tree.gd:17-24` — `RectangleShape2D size 8×24 at (0,12)` covers a narrow vertical strip down the centre. Canopy pixels above are passable.
- `test_bugfix_two.gd:57-58` actually asserts the trunk collision reaches the ground level — so this is by design, but it does mean a sprite's leafy top half is cosmetic. Players can walk under canopies if they're tilted or thin. Acceptable but worth flagging.
- Y-sorting with `z_index=0` for trees combined with `y_sort_enabled` on trees: the **tree** renders above the player when the player's Y is below the trunk origin; below the player when above. The canopy at Y ≈ -32 to 0 above trunk will draw correctly relative to player feet. **Verify in-scene** for each of the 4 tree variants — small differences in sprite height could break the illusion.

### C-3. Heart sprite pixel dims not pinned by tests

- `_enemy_frames["froggit"] = 38` (`sprites.gd:221`) tells the loader to look for `froggit_000.png` … `froggit_037.png`. The frame-count map is the source of truth for animation length.
- The **soul sprites** (Red/Orange/Yellow/Green/Blue/Purple/Light_blue) at 121–260 bytes — visually tiny. Rendered by `Sprites.soul_texture("Red")` and assigned to `DodgeBox.heart` with no scale. **Need an Image read on each to confirm pixel dims** (likely 16×16). Tests don't pin this. If a soul is 16×16 and the hit radius is 4.0, that's a forgiving box — but the visual mismatch (soul is bigger than hitbox) is a known UT-style convention. Acceptable.
- Bullet base (`sprites.gd:30-37`) is procedurally 8×8 white with a dark 1-px border — size **does not match** the per-pattern `size` collision value (3.0–8.0). The visual bullet is always 8×8; the hit radius follows `size`. So a `size=3.0` bullet looks ~8×8 but only collides within a 3-px radius. **This is a deliberate, classic UT trick** (visual bigger than hitbox) — keep it, but document.

### C-4. `hum` action shares `KEY_Z` with `confirm`

- `game_state.gd:99-101` — `confirm = [KEY_Z, KEY_ENTER, KEY_KP_ENTER]`, `hum = [KEY_Z]`. Both fire on Z.
- `dialogue_ui.gd:95` — `confirm` advances the typewriter.
- `wisp_intro.dlg` says "It is waiting for you to hum."
- **Bug risk**: Pressing Z to hum might accidentally also skip the wisp intro before the player realises it's a separate action. Or `hum` is consumed only in specific states (need to grep for `Input.is_action_just_pressed("hum")` — not yet found in the files I read; need to confirm where `hum` actually does something).
- **Action**: confirm whether `hum` has a consumer. If yes, ensure it doesn't fire during the wisp intro line. If no, **remove** `hum` from `game_state.gd:102` to avoid future conflict.

### C-5. Inventory is write-once

- `game_state.gd:17` — only one `dream_candy` seeded at game start.
- `game_state.gd:37-44` — `use_item(index)` removes and applies; no `add_item()` exists anywhere in `scripts/`.
- No shop, no pickup, no drop table.
- **Risk**: ITEM menu in battle is therefore static (always shows 1× Dream Candy until used). Once used, the ITEM button opens to an empty list. **Verify** the ITEM button is greyed out / disabled when inventory empty — partial read of `battle.gd:80-200` did not yet confirm.

### C-6. FIGHT damage always full

- `combat_math.gd:3-5` — `calculate_damage(atk, def, intent)` scales with `intent ∈ [0,1]`.
- `fight_bar.gd:16` — `press()` returns the triangle-wave value, peaking at 1.0 at the centre.
- I haven't yet seen where `Battle._attack_hit()` calls `calculate_damage` and whether it passes the `press()` value as `intent`. If it does, FIGHT damage depends on timing; if it always passes 1.0, the bar is decorative. **Verify in `battle.gd:200-645`.**

### C-7. Canon room always spawns `mourning_knight`

- `scripts/rooms/canon.gd:8-10` — `BOSSES` array always has the Knight at (328, 248).
- `scripts/rooms/canon.gd:144-150` — `_spawn_bosses()` unconditionally creates the encounter Area2D each visit.
- `encounter.gd:27-29` — boss variant sets `last_boss_save` + saves on entry.
- **Risk**: If the Knight has been beaten, the Area2D is still there and triggers again. Either need to skip spawn based on a `knight_defeated` flag (set in `Battle` post-victory), or make the encounter itself check the flag and self-disable. **Verify**: does `Battle._on_enemy_defeated()` set any flag we can read?

### C-8. Mode-switch velocity spike

- `dodge_box.gd:67-71` — `set_mode(m)` resets `_soul_vel = ZERO`, but `last_heart_pos` still holds the previous frame's position. On the next `_process`, `heart_vel = (heart.position - last_heart_pos)/delta` produces a large one-frame velocity.
- For BLUE/ORANGE bullets this can cause a phantom "moving" or "still" miss/hit depending on which side of the 8.0 threshold the spike lands.
- **Fix**: in `set_mode`, also reset `last_heart_pos = heart.position` so `heart_vel` starts at 0.

### C-9. 1-frame enemy placeholders

- `sprites.gd:228-233` — most enemies (reminisc, hushroom, paneic, squish, sentimint, repeato, toadally, punkin, nullaby, quibble, margin, lookey, remembran, mourning_knight, index_f1/2/3, canon_true) are listed with `_enemy_frames = 1`.
- `_enemy_idle_texture()` (`sprites.gd:236-247`) loads `id/id_000.png` for each frame index in `range(count)`. With `count=1` it loads just `id_000.png`.
- **Verify**: do these PNGs actually exist? They should be in `assets/sprites/enemies/frames/<id>/`. **Spot-check**: `frames/hushroom/`, `frames/reminisc/`, `frames/paneic/`, etc. exist as dirs (per earlier listing) but I haven't confirmed their contents.
- `frames/froggit/` exists per the project listing — file pattern `froggit_013.png` … etc. (loaded via `%03d` formatter).

### C-10. Other verification needs

| Item | Where | Need |
|---|---|---|
| Bullet sprite pixel dims | `sprites.gd:30-217` | All generated at runtime — confirmed via code; no asset risk |
| Heart sprite pixel dims | `assets/sprites/Red_SOUL_sprite.png` + 6 others | Read PNG headers or `.import` files to lock dim |
| Tree sprite pixel dims | `assets/sprites/overworld/tree_*.png` | Same — read PNGs |
| `Battle._attack_hit` damage flow | `battle.gd:200-645` (unread remainder) | Confirm `calculate_damage(atk, def, fight_bar.press())` |
| `Battle._on_enemy_defeated` flag set | `battle.gd:200-645` | Confirm whether a `knight_defeated` flag is set so `canon.gd:_spawn_bosses` can skip |
| `hum` action consumer | anywhere grepping `is_action_just_pressed("hum")` | Need full grep; if none, see §C-4 |
| Cracks room tint + scripts | `scripts/rooms/cracks.gd` (unread remainder) | Confirm tint/music/encounters/doors/old_dreamer wiring |
| `Wisp.tscn` + wisp follower | `scripts/wisp/` (unread) | Confirm WispState autoload usage in rooms (referenced as `WispState.set_area(...)`) |

---

## Summary

**Plan F targets (battle feel, world feel, opening narrative, known bugs) line up with these existing systems:**

1. **Battle feel** — single source of truth is `scripts/battle/dodge_box.gd` (`HEART_SPEED`, `BOX_RECT`, `BOX_INNER`, `INVULN_TIME`, `KNOCKBACK`, `STAGGER_TIME`, mode table). Hit tolerance is rule-based (BLUE/ORANGE velocity gate, GRAY/GREEN pass through, default damages) — no separate positional tolerance, but trivial to add. Heart hitbox `r=4.0` at `dodge_box.gd:192`. Bullet base 8×8 procedural; collision uses per-pattern `size` (3.0–8.0) — classic UT visual/collision gap is intentional.
2. **World feel** — 6 rooms (Echo, Grumble Woods, Drizzle Fields, Hometown, Cracks, Canon) each with CanvasModulate tint, music track, encounter pool, and `EDIT_EVENTS` (Canon only). Trees use `RoomTree` (sprite + shadow + trunk collider), `CircleShape2D r=8` encounter triggers with bobbing enemy sprite, fade-flash → 0.4s → battle transition.
3. **Opening narrative** — `scripts/main.gd` → fade → Drizzle Fields → wisp intro → toad NPC. `wisp_intro.dlg` establishes hum as a mechanic. Per-area wisp ambient + 3 boss monologue files (`mourning_knight`, `index`, `old_dreamer`).
4. **Known bugs / risks** — orphan `.uid` and `.png.import` files in `tools/` (claim of "dev files removed" is incomplete); tree trunk-only collision (intentional per test); 1-frame mob placeholders need PNG existence check; `hum` shares `KEY_Z` with `confirm`; inventory has no `add_item`; FIGHT bar purpose unverified; Canon Knight always respawns; mode-switch velocity spike; soul sprite dims need locking; ITEM-empty behaviour unverified.

**Recommended next moves (when edits are permitted):**

1. Remove `tools/*.uid`, `tools/*.png.import`, `tools/godot.exe`, `tools/Godot_v4.4.1-stable_win64_console.exe`.
2. Add `add_item()` and `item_count()` to `game_state.gd`. Verify ITEM menu greyed-out behaviour.
3. Grep for `is_action_just_pressed("hum")` to confirm a consumer exists. If not, drop `hum` from `_ensure_input_actions`.
4. Add a `HIT_TOLERANCE` constant in `dodge_box.gd` (and mirror in `combat_math.gd`) for positional forgiveness. Update `test_combat_math.gd`.
5. In `set_mode`, also reset `last_heart_pos = heart.position`.
6. Read remainder of `battle.gd` to confirm FIGHT damage uses `press()` and that boss defeat sets a flag we can gate on.
7. Read `scripts/wisp/*` and remainder of `cracks.gd` for full world coverage.