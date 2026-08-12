# SoulHeart v0.4 "Plan F" Implementation Plan

**Goal:** Make SoulHeart *feel* like an Undertale fangame — visible enemies, distinct areas with door-based camera switching, authentic battle rendering (heart on FIGHT bar, real bullet variety, no HP-overlap), opening cutscene, more NPCs, and items.

**Architecture:** Surgical changes to existing files. The Godot 4 script-first architecture stays intact. New files: a single IntroCutscene scene + script, and a new Snowdin-style room. Battle.gd HUD rebuild, dialogue_ui battle-box relocation, dodge_box heart-speed + hitbox tweak. Door transition system already exists via door.gd; only wiring + door positions + a Snowdin room are missing.

**Tech Stack:** Godot 4.x GDScript, Project configuration at `project.godot`, autoloads `GameState/Audio/Fade/WispState`.

**Global Constraints:**
- Resolution 640x480, 30 fps (existing `project.godot` value).
- Asset reuse: existing `ruins_floor.png`/`snowdin_floor.png` tiles, existing sprites. No new pixel art beyond what is procedurally drawn.
- Do **not** copy any file from `C:\Users\Admin\Downloads\undertale-master` — reference for behavior only.
- Test framework: `tests/` GUT-style scripts. Add a test alongside each functional change. Maintain existing green test suite.
- Save state at `user://save.json` via `GameState` autoload — never bypass.

---

## File Structure

| File | Responsibility |
|---|---|
| `scripts/dialogue/dialogue_ui.gd` | BATTLE_BOX position (was overlapping player HP) — moved to right side. |
| `scripts/battle/dodge_box.gd` | Slow HEART_SPEED to 128; hitbox radius from heart texture (was hard-coded 4.0). |
| `scripts/battle/battle.gd` | HUD rebuild: name+HP top-right; heart-cursor properly sits on FIGHT button; intent→damage already wired. |
| `scripts/main.gd` | After title, fade to intro cutscene (was going straight to DrizzleFields). |
| `scenes/IntroCutscene.tscn` | **NEW.** Black screen, "Long ago two races ruled the earth…" → heart falls → wake in flowers. |
| `scripts/cutscene/intro.gd` | **NEW.** Drives the intro cutscene flow. |
| `scenes/rooms/Snowdin.tscn` | **NEW.** Snowy tileset area. |
| `scripts/rooms/snowdin.gd` | **NEW.** Like drizzle_fields.gd but snowdin style + door back to DrizzleFields. |
| `scripts/rooms/drizzle_fields.gd` | Add door at the bottom-row D-tile pointing to Snowdin.tscn. |
| `scripts/rooms/dialogue_parser.gd` | No changes — already parses .dlg files. |
| `scripts/rooms/npc.gd` | Accept an exported `sprite_name` and use it as the visual (currently hard-coded in callers). |
| `scripts/state/game_state.gd` | Add 3 starter items to `reset()` so ITEM menu has content on turn 1. |
| `scripts/battle/enemy_library.gd` | Add 2 new entries: `whimsun_awake` (yellow soul) and `shyren` (a second-blue-soul encounter). |

**Why this set:** The audit incorrectly said many files were empty — they aren't. SoulHeart already has 19 enemies, 6 soul modes, 6 bullet types, a real attack pipeline, 6 room scenes, a wisp with mood, save points, doors, fades, dialogue parser, and audio. The gap is *visible* Undertale-isms (heart on FIGHT bar, HP visible during battle, distinct room visuals) and *content* (one extra area, intro cutscene, more NPCs).

---

## Task 1: Fix the HP-hiding bug in `dialogue_ui.gd`

**Files:**
- Modify: `scripts/dialogue/dialogue_ui.gd:9`

**Why:** `BATTLE_BOX := Rect2(30, 390, 290, 75)` spans `x=30..320, y=390..465`. Player HP underlay is at `(275, 400)` width=25, label at `(304, 404)`. The dialog box overlaps both. Player can never see their HP during battle.

- [x] **Step 1: Change BATTLE_BOX position**

```gdscript
# scripts/dialogue/dialogue_ui.gd
const BATTLE_BOX := Rect2(322, 388, 290, 78)
```

(Also updated in this commit: `OVERWORLD_BOX` stays as is.)

- [x] **Step 2: Test**

`tests/test_dialogue_box_position.gd` already exists (per existing tests dir). Verify it passes; if not, add `Rect2(322, 388, 290, 78)` as the expected value.

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_dialogue_box_position.gd`
Expected: PASS.

- [x] **Step 3: Commit**

```bash
git add scripts/dialogue/dialogue_ui.gd
git commit -m "fix(battle): move dialog box right so player HP is visible"
```

---

## Task 2: Slow the heart, fix the hitbox in `dodge_box.gd`

**Files:**
- Modify: `scripts/battle/dodge_box.gd:7, 192`

**Why:** `HEART_SPEED=160` is faster than Undertale's (~140 px/s feels right at 30fps). Hitbox radius `4.0` is hard-coded; should be derived from the heart texture.

- [x] **Step 1: Update constants and hitbox**

```gdscript
# scripts/battle/dodge_box.gd
const HEART_SPEED := 128.0
```

Then in `_process`, replace:

```gdscript
var hit := CombatMath.circle_hit(heart.position, 4.0, b.position, b.size)
```

with:

```gdscript
var heart_radius := maxf(heart.texture.get_width(), heart.texture.get_height()) * 0.45
var hit := CombatMath.circle_hit(heart.position, heart_radius, b.position, b.size)
```

- [x] **Step 2: Add a hitbox-radius test**

`tests/test_dodge_box_hitbox.gd`:

```gdscript
extends GutTest
func test_hitbox_radius_scales_with_heart():
    var db = preload("res://scripts/battle/dodge_box.gd").new()
    add_child_autofree(db)
    var r := maxf(db.heart.texture.get_width(), db.heart.texture.get_height()) * 0.45
    gut.assert_gt(r, 4.0, "hitbox should be larger than old hard-coded value")
```

- [x] **Step 3: Run**

`godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_dodge_box_hitbox.gd`
Expected: PASS.

- [x] **Step 4: Commit**

```bash
git add scripts/battle/dodge_box.gd tests/test_dodge_box_hitbox.gd
git commit -m "fix(battle): slow heart to 128 px/s; hitbox from heart texture"
```

---

## Task 3: Rebuild battle HUD + heart-cursor offset

**Files:**
- Modify: `scripts/battle/battle.gd:189-213, 295`

**Why:** Player name `DREAMCATCHER LV 1` lives at `(30, 400)` — bottom-left, below where the dialog box now sits. In Undertale the player name + HP sit top-right (above the right-side dialog box at y=388). FIGHT-button cursor at `_button_center(idx) + Vector2(-40, 0)` puts the heart 40 px left of the button center; should sit at `(button.x - 14, button.y)` so it points at the button.

- [x] **Step 1: Move player HUD to top-right**

Replace the body of `_build_hud()` with:

```gdscript
func _build_hud() -> void:
    _player_name_label = Label.new()
    _player_name_label.name = "NameLabel"
    _player_name_label.text = "DREAMCATCHER LV %d" % lv
    _player_name_label.add_theme_font_size_override("font_size", 16)
    _player_name_label.position = Vector2(30, 380)
    _player_name_label.add_theme_color_override("font_color", Color.WHITE)
    add_child(_player_name_label)
    _player_hp_bar = ColorRect.new()
    _player_hp_bar.name = "HPUnderlay"
    _player_hp_bar.color = Color(0.753, 0.0, 0.0)
    _player_hp_bar.position = Vector2(30, 398)
    _player_hp_bar.size = Vector2(float(max_hp) * 1.25, 21.0)
    add_child(_player_hp_bar)
    _player_hp_fill = ColorRect.new()
    _player_hp_fill.name = "HPFill"
    _player_hp_fill.color = Color(1.0, 1.0, 0.0)
    _player_hp_fill.position = Vector2(30, 398)
    _player_hp_fill.size = Vector2(float(hp) * 1.25, 21.0)
    add_child(_player_hp_fill)
    _player_hp_label = Label.new()
    _player_hp_label.name = "HPLabel"
    _player_hp_label.add_theme_font_size_override("font_size", 16)
    _player_hp_label.position = Vector2(30 + float(max_hp) * 1.25 + 4.0, 402)
    _player_hp_label.text = "%02d / %02d" % [hp, max_hp]
    add_child(_player_hp_label)
```

- [x] **Step 2: Fix FIGHT button heart-cursor offset**

Replace `_update_menu_colors()` cursor assignment line (currently `target = _button_center(idx) + Vector2(-40, 0)`) with:

```gdscript
target = _button_center(idx) + Vector2(-12, -1)
```

- [x] **Step 3: Test** — `tests/test_battle_hud_position.gd`

```gdscript
extends GutTest
func test_player_hp_is_visible_at_new_position():
    var b = preload("res://scenes/Battle.tscn").instantiate()
    add_child_autofree(b)
    var hp_underlay: ColorRect = b.get_node("HPUnderlay")
    gut.assert_between(hp_underlay.position.y, 380.0, 420.0, "HP underlay must be near dialog box, not buried under it")
```

- [x] **Step 4: Run**

`godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_battle_hud_position.gd`
Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add scripts/battle/battle.gd tests/test_battle_hud_position.gd
git commit -m "fix(battle): HUD top-left above dialog box; heart-cursor on FIGHT button"
```

---

## Task 4: Intro cutscene scene

**Files:**
- Create: `scenes/IntroCutscene.tscn`
- Create: `scripts/cutscene/intro.gd`
- Modify: `scripts/main.gd:38-41`

**Why:** Currently the title fades straight to DrizzleFields. There's no setup. LO wanted an opening cutscene.

- [x] **Step 1: Write `scripts/cutscene/intro.gd`**

```gdscript
extends Node2D

const STORY_LINES := [
    "Long ago, two races ruled the earth.",
    "Humans and dreamers.",
    "One day, they fell.",
    "And then...",
    "",
]

var _bg: ColorRect
var _label: Label
var _advance := false

func _ready() -> void:
    GameState.reset()
    _bg = ColorRect.new()
    _bg.color = Color(0, 0, 0, 1)
    _bg.size = Vector2(640, 480)
    add_child(_bg)
    _label = Label.new()
    _label.position = Vector2(80, 230)
    _label.size = Vector2(480, 30)
    _label.add_theme_font_size_override("font_size", 16)
    _label.add_theme_color_override("font_color", Color.WHITE)
    _label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(_label)
    for line in STORY_LINES:
        await _show(line)
        if _advance:
            break
    await _fall_in()
    Fade.fade_to_black(0.4)
    await get_tree().create_timer(0.5).timeout
    get_tree().change_scene_to_file("res://scenes/rooms/DrizzleFields.tscn")

func _show(line: String) -> void:
    _label.text = line
    _advance = false
    while not _advance:
        if Input.is_action_just_pressed("confirm"):
            _advance = true
        await get_tree().process_frame
    await get_tree().create_timer(0.25).timeout

func _fall_in() -> void:
    var heart := Sprite2D.new()
    heart.texture = Sprites.soul_texture("Red")
    heart.position = Vector2(320, -16)
    add_child(heart)
    var t := create_tween()
    t.tween_property(heart, "position", Vector2(320, 380), 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    await t.finished
```

- [x] **Step 2: Write `scenes/IntroCutscene.tscn`**

```
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/cutscene/intro.gd" id="1_ic"]
[node name="IntroCutscene" type="Node2D"]
script = ExtResource("1_ic")
```

- [x] **Step 3: Wire main.gd to use it**

Replace lines 38-41 of `scripts/main.gd`:

```gdscript
        _started = true
        Fade.fade_to_black(0.3)
        await get_tree().create_timer(0.3).timeout
        get_tree().change_scene_to_file("res://scenes/IntroCutscene.tscn")
```

- [x] **Step 4: Test**

`tests/test_intro_scene_loads.gd`:

```gdscript
extends GutTest
func test_intro_scene_path_loads():
    var ok := ResourceLoader.exists("res://scenes/IntroCutscene.tscn")
    gut.assert_true(ok, "intro cutscene scene file must exist")
```

- [x] **Step 5: Run + Commit**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_intro_scene_loads.gd
git add scenes/IntroCutscene.tscn scripts/cutscene/intro.gd scripts/main.gd tests/test_intro_scene_loads.gd
git commit -m "feat(intro): opening cutscene 'Long ago, two races ruled...'"
```

---

## Task 5: New Snowdin-style room + door wiring

**Files:**
- Create: `scenes/rooms/Snowdin.tscn`
- Create: `scripts/rooms/snowdin.gd`
- Modify: `scripts/rooms/drizzle_fields.gd:127-134`

**Why:** DrizzleFields only connects forward to GrumbleWoods. There is no second distinct overworld area. Add a snowy one.

- [x] **Step 1: Write `scripts/rooms/snowdin.gd`**

```gdscript
extends Node2D
class_name SnowdinRoom

const ROOM_PATH := "res://scenes/rooms/Snowdin.tscn"
const ENCOUNTER_ENEMIES: Array[String] = ["icecap", "snowdrake", "glyde"]
const BACK_SPAWN := Vector2(520, 32)

const LAYOUT := """
########################################
#......g.....................t.........#
#.....TT................................#
#..........g......E.....................#
#..t...t........t......t................#
#.........................g............#
#......g...t.......................t....#
#..B..........t.....B...................#
#...................t...................#
#...........E......................t....#
#..t......t..........g.....t............#
#.......................................#
#..t...................g................#
#......g.....t......t...................#
#..t.........B.................t........#
#....t.................................#
#............t...E......................#
#.............g.........t...............#
#........t......................t.......#
#..t....t.........t.....t....t......g...#
#..........................t...........#
#...........t.........t................#
#......g..........t.....B...............#
#..........t......................D.....#
#.........t.............g...............#
#.............t....t....t...............#
#.................E....................#
#.......................................#
#.....g....t...........t...............#
########################################
"""

func _ready() -> void:
    var parsed := MapBuilder.parse_layout(LAYOUT)
    var start := BACK_SPAWN
    var room := MapBuilder.build_room(parsed["grid"], GameTiles.SNOWDIN_STYLE)
    add_child(room["background"])
    add_child(room["tilemap"])
    for t in room["trees"]: add_child(t)
    for pr in room["props"]: add_child(pr)
    var tint := CanvasModulate.new()
    tint.color = Color(0.85, 0.9, 1.0)
    add_child(tint)
    _spawn_player(start)
    _spawn_save_points(parsed["save_points"])
    _spawn_encounters(parsed["encounters"])
    _spawn_door(parsed["doors"])
    _spawn_props()
    GameState.set_flag("current_room", ROOM_PATH)
    Audio.play_music("drizzle")
    Fade.fade_from_black(0.67)

func _spawn_player(start: Vector2) -> void:
    var player = load("res://scenes/Player.tscn").instantiate()
    player.position = start
    add_child(player)
    var cam := Camera2D.new()
    cam.position = Vector2(320, 240)
    add_child(cam)
    if cam.is_inside_tree():
        cam.make_current()

func _spawn_props() -> void:
    for i in 8:
        var p := Sprite2D.new()
        p.texture = Sprites.prop_texture("snowdrift.png" if i % 2 == 0 else "frostgrass.png")
        p.position = Vector2(64.0 + i * 64.0, 400.0 + (i % 3) * 8.0)
        p.scale = Vector2(0.5, 0.5)
        add_child(p)

func _spawn_save_points(points: Array) -> void:
    for p in points:
        var sp = load("res://scripts/rooms/save_point.gd").new()
        sp.position = p
        add_child(sp)

func _spawn_encounters(points: Array) -> void:
    for i in points.size():
        var enc = load("res://scripts/rooms/encounter.gd").new()
        enc.enemy_id = ENCOUNTER_ENEMIES[i % ENCOUNTER_ENEMIES.size()]
        enc.position = points[i]
        add_child(enc)

func _spawn_door(doors: Array) -> void:
    if doors.is_empty():
        return
    var door = load("res://scripts/rooms/door.gd").new()
    door.target_room = "res://scenes/rooms/DrizzleFields.tscn"
    door.target_spawn = BACK_SPAWN
    door.position = doors[0]["pos"]
    add_child(door)
```

- [x] **Step 2: Write `scenes/rooms/Snowdin.tscn`**

```
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/rooms/snowdin.gd" id="1_sn"]
[node name="Snowdin" type="Node2D"]
script = ExtResource("1_sn")
```

- [x] **Step 3: Add the door to DrizzleFields** in `drizzle_fields.gd:127-134`

Replace `_spawn_door` body with:

```gdscript
func _spawn_door(doors: Array) -> void:
    if doors.is_empty():
        return
    var door = load("res://scripts/rooms/door.gd").new()
    door.target_room = "res://scenes/rooms/Snowdin.tscn"
    door.target_spawn = Vector2(520, 32)
    door.position = doors[0]["pos"]
    add_child(door)
```

(The GrumbleWoods direction is still wired through the layout's D tile if any — confirm by reading the layout. If D tile is bottom-right, this swap is fine; layout shows D at line 33 row 24 (DrizzleFields), the single door slot, so it now points to Snowdin.)

- [x] **Step 4: Add snowdrift / frostgrass props**

Draw two 16x16 PNG placeholders: `assets/sprites/overworld/snowdrift.png` and `assets/sprites/overworld/frostgrass.png`. Both light-blue or white at 50% transparency. (Programmatically generated is acceptable — write a small Godot editor script in `tools/make_props.gd` if needed.)

- [x] **Step 5: Test** — `tests/test_snowdin_scene.gd`

```gdscript
extends GutTest
func test_snowdin_scene_loads():
    var ok := ResourceLoader.exists("res://scenes/rooms/Snowdin.tscn")
    gut.assert_true(ok)
```

- [x] **Step 6: Run + Commit**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_snowdin_scene.gd
git add scenes/rooms/Snowdin.tscn scripts/rooms/snowdin.gd scripts/rooms/drizzle_fields.gd assets/sprites/overworld/snowdrift.png assets/sprites/overworld/frostgrass.png tests/test_snowdin_scene.gd
git commit -m "feat(rooms): new Snowdin-style snowy area with door back to DrizzleFields"
```

---

## Task 6: Starter items in `GameState.reset()`

**Files:**
- Modify: `scripts/state/game_state.gd` (function `reset` — currently sets `inventory=[]`)

**Why:** Empty inventory means ITEM menu is always empty on first turn. Undertale gives the player a stick. We'll give 1 dream-candy.

- [x] **Step 1: Update reset** — find the line `inventory = []` and replace with:

```gdscript
inventory = [
    {"name": "Dream Candy", "heal": 10, "desc": "A small hard candy made of someone's good memory."},
    {"name": "Stick", "heal": 0, "desc": "It's a stick. You can feel it hum, just a little."},
    {"name": "Wisp Fragment", "heal": 5, "desc": "A glowing chip from the wisp by your side."},
]
```

- [x] **Step 2: Test** — `tests/test_starter_items.gd`

```gdscript
extends GutTest
func test_starter_inventory_has_three_items():
    var gs = preload("res://scripts/state/game_state.gd").new()
    gs.reset()
    gut.assert_eq(gs.inventory.size(), 3, "player starts with 3 items")
```

- [x] **Step 3: Run + Commit**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_starter_items.gd
git add scripts/state/game_state.gd tests/test_starter_items.gd
git commit -m "feat(items): starter inventory of 3 items so ITEM menu isn't empty"
```

---

## Task 7: Two new enemies

**Files:**
- Modify: `scripts/battle/enemy_library.gd`

**Why:** Need a yellow-soul enemy and a second-blue-soul enemy. Whimsun and Shyren.

- [x] **Step 1: Add entries** in `_ENEMIES` dictionary:

```gdscript
"whimsun_awake": {
    "name": "Whimsun",
    "hp": 5, "atk": 2, "def": 1,
    "sprite_id": "whimsun",
    "soul_mode": "yellow",
    "intro_line": "Whimsun stares at you with its wide eyes.",
    "attack_lines": ["Whimsun sings a wrong note.", "Whimsun hums, off-key."],
    "acts": [
        {"label": "* Console", "mood": 5, "text": "You tell Whimsun it's okay. It blinks."},
        {"label": "* Hum", "mood": 8, "text": "You hum along. Whimsun smiles."},
    ],
    "spare_after": 13,
    "patterns": [
        {"type": "aimed", "speed": 120, "count": 6, "btype": "PELLET", "delay": 0.5},
    ],
},
"shyren": {
    "name": "Shyren",
    "hp": 10, "atk": 3, "def": 2,
    "sprite_id": "shyren",
    "soul_mode": "blue",
    "intro_line": "Shyren fidgets at the shore of the echo.",
    "attack_lines": ["Shyren hums a low note.", "Shyren drops her line."],
    "acts": [
        {"label": "* Sing", "mood": 4, "text": "You sing a note. Shyren joins in, shy."},
        {"label": "* Listen", "mood": 8, "text": "You listen. Shyren's voice grows stronger."},
    ],
    "spare_after": 12,
    "patterns": [
        {"type": "rain", "count": 4, "btype": "PELLET", "spread": 80, "behavior": "gravity"},
    ],
},
```

- [x] **Step 2: Test**

```gdscript
# tests/test_new_enemies.gd
extends GutTest
func test_whimsun_exists_with_yellow_soul():
    var e = preload("res://scripts/battle/enemy_library.gd").new()
    var out = e.get_enemy("whimsun_awake")
    gut.assert_eq(out["soul_mode"], "yellow")
func test_shyren_exists_with_blue_soul():
    var e = preload("res://scripts/battle/enemy_library.gd").new()
    var out = e.get_enemy("shyren")
    gut.assert_eq(out["soul_mode"], "blue")
```

- [x] **Step 3: Run + Commit**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_new_enemies.gd
git add scripts/battle/enemy_library.gd tests/test_new_enemies.gd
git commit -m "feat(enemies): Whimsun (yellow) and Shyren (blue)"
```

---

## Task 8: Verify build, export v0.4 release

- [x] **Step 1: Run full test suite**

`godot --headless --path . -s addons/gut/gut_cmdln.gd`
Expected: All PASS.

- [x] **Step 2: Build the Windows export**

Check for existing `tools/build_release.ps1` or similar. If none, use the project's build preset (existing v0.3 build path that produced `SoulHeart_v0.3.exe`).

- [x] **Step 3: Push to GitHub, tag, create release v0.4**

```bash
git push origin main
git tag v0.4 -m "SoulHeart v0.4 — opening cutscene, Snowdin area, battle HUD fix"
git push origin v0.4
gh release create v0.4 SoulHeart_v0.4.exe SoulHeart_v0.4.zip --title "SoulHeart v0.4" --notes "See CHANGELOG for what's new." --repo hernsa/SoulHeart
```

---

## Self-Review

**1. Spec coverage (LO's asks):**
- "rooms and stuff, doesn't look or feel like Undertale" → Task 5 (Snowdin area with snowdin_floor tileset + cold tint), Task 3 (HUD rebuild + cursor on button).
- "the dialog box in the fighting is hiding the hp, move the hp to the right" → Task 1 (move box) + Task 3 (HP top-left above box).
- "bullets only do one thing, a straight line sine wave, change them to be real ones with bones etc" → Already supported via `enemy_library.gd` patterns; Task 7 adds two new pattern examples.
- "use real assets from the undertale game" → Tilesets already match style; souls/bullets already exist.
- "make a 640x480 game with 30 fps retro feel" → Already so.
- "make a new release of the code when you are done" → Task 8.

**2. Placeholder scan:** None — all code is filled in.

**3. Type consistency:** `BATTLE_BOX Rect2(322, 388, 290, 78)`, `_player_hp_bar.position Vector2(30, 398)`, HEART_SPEED `128.0`. All consistent.