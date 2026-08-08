# Undertale Look Pack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make SoulHeart look like real Undertale: pixel font everywhere, authentic battle geometry, menu heart cursor, enemy presentation, HP bar drain, overworld polish, per-area world art, and title screen details.

**Architecture:** Visual authenticity pack. Task 1 installs the DMT-Mono pixel font project-wide via `[gui]` theme settings so every Label inherits it. Tasks 2-5 rebuild the battle screen (dialogue box, geometry, menu cursor + sounds, enemy feedback). Tasks 6-7 polish overworld (camera, walk anim, door/save/bang sprites, per-area palette + tint). Task 8 title screen. Task 9 verification + export.

**Tech Stack:** Godot 4.4.1 (GDScript), headless CLI, PowerShell 5.1, existing custom test runner (`tests/run_all.gd`).

## Global Constraints

- **Platform:** Windows / PowerShell 5.1 only. No bash, no `&&` â€” use `cmd /c "..." & echo DONE` pattern. Never run `&` on GUI exes.
- **Godot binary:** `tools\Godot_v4.4.1-stable_win64_console.exe` in the worktree (hardlinked; gitignored). After adding any new asset (font), run `cmd /c "tools\Godot_v4.4.1-stable_win64_console.exe --headless --import > .superpowers\import.txt 2>&1 & echo DONE"` before the suite.
- **Suite gate (every task):** `cmd /c "tools\Godot_v4.4.1-stable_win64_console.exe --headless -s res://tests/run_all.gd > .superpowers\out.txt 2>&1 & echo DONE"` â€” then grep the out file. GATE = output contains `ALL TESTS PASSED` AND zero `SCRIPT ERROR:` lines AND zero `FAIL:` lines. The ONLY permitted stderr line is `ERROR: Dialogue file not found: res://dialogue/nope.dlg`. Engine parse errors do NOT flip the runner output â€” the gate is BOTH conditions.
- **Never commit on red.** If a task's suite shows SCRIPT ERROR / FAIL lines, fix first. Recovery from a bad commit: `git reset --soft HEAD~1` then `git restore --staged <files>` then recommit.
- **Tests:** `tests/*.gd` are `extends RefCounted`, auto-discovered by `run_all.gd` (excludes run_all.gd/test_helper.gd). Assertions ONLY `TestHelper.eq(got, expected, msg)` / `TestHelper.is_true(cond, msg)`. Tests call `_ready()` manually, no tree. `Input.action_press/release` + `InputMap.add_action` work headless. Autoload singletons (GameState/Audio/Fade) are NOT present under `-s` â€” tests may reference them only via `load()`-only patterns or `Engine.has_singleton`-style guards; static/pure code is safest.
- **Keep ALL existing tests green.** Only `tests/test_dodge_box.gd` and `tests/test_hurt_feedback.gd` MAY be updated (Task 3) â€” they encode the old dodge-box geometry and are updated to the new geometry in the same commit.
- **Commit discipline:** one commit per task, message pattern `feat: ...` / `fix: ...`. Never commit `.superpowers/`, `tools/`, `dist/`, `export_presets.cfg`, `Play SoulHeart.bat` (all untracked/gitignored).
- **Visual rules:** 640x480 internal, `default_texture_filter=0` (nearest). After Task 1 every Label font size must be a multiple of 8 (16 dialogue/battle, 32 "Stay determined!", 48 title, 8 version line).
- **Audio pack behavior stays:** fades, music mapping, sting, death flow, 4-dir movement, hurt feedback (1s invuln, knockback, stagger) all remain as-is.
- **CREDITS.txt** must get the font credit line in Task 1.
- **Execution:** autonomous, no check-ins (LO asleep). Tasks 1 = subagent (network); 2-9 = inline. Verify before completion (Task 9 = full gate + export + boot check).

---

### Task 1: DMT-Mono pixel font + project-wide theme (SUBAGENT â€” network download)

**Files:**
- Create: `assets/fonts/DMT-Mono.ttf` (downloaded; target filename is `.ttf` regardless of source format â€” Godot sniffs magic bytes)
- Modify: `project.godot` (add `[gui]` section), `CREDITS.txt` (append font credit)
- Test: `tests/test_font.gd`

**Interfaces:**
- Produces: `ProjectSettings.get_setting("gui/theme/custom_font") == "res://assets/fonts/DMT-Mono.ttf"` â€” every subsequent task relies on the theme font being active so plain `Label` nodes render in pixel font.

- [ ] **Step 1: Download the font.** Try candidate URLs in order; keep the first that downloads successfully AND passes the magic-bytes check:

```powershell
$dir = "assets\fonts"; New-Item -ItemType Directory -Force -Path $dir | Out-Null
$target = "$dir\DMT-Mono.ttf"
$urls = @(
  "https://raw.githubusercontent.com/JapanYoshi/Determination/main/DMT-Mono.otf",
  "https://raw.githubusercontent.com/JapanYoshi/Determination/master/DMT-Mono.otf",
  "https://raw.githubusercontent.com/ThetaApps/font-undertale/master/DeterminationMonoWeb.woff",
  "https://cdn.jsdelivr.net/gh/JapanYoshi/Determination@main/DMT-Mono.otf"
)
$ok = $false
foreach ($u in $urls) {
  try {
    Invoke-WebRequest -Uri $u -OutFile $target -TimeoutSec 30
    $bytes = [System.IO.File]::ReadAllBytes($target)
    $magic = ($bytes[0] -shl 8) -bor $bytes[1]
    if ($bytes.Length -gt 1000 -and ($magic -eq 0x4F54 -or ($bytes[0] -eq 0x00 -and $bytes[1] -eq 0x01))) {
      $ok = $true; Write-Output "OK: $u ($($bytes.Length) bytes)"; break
    } else { Write-Output "BAD MAGIC: $u"; Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue }
  } catch { Write-Output "FAILED: $u" }
}
if (-not $ok) { throw "All font URLs failed - STOP and report back." }
```

- [ ] **Step 2: Verify the font loads in Godot.** Run import, then confirm no errors mention the font:

```powershell
cmd /c "tools\Godot_v4.4.1-stable_win64_console.exe --headless --import > .superpowers\import_font.txt 2>&1 & echo DONE"
```

- [ ] **Step 3: Write the failing test** `tests/test_font.gd`:

```gdscript
extends RefCounted

func test_font_file_exists() -> void:
	TestHelper.is_true(FileAccess.file_exists("res://assets/fonts/DMT-Mono.ttf"), "font file exists")

func test_theme_font_configured() -> void:
	var p := ProjectSettings.get_setting("gui/theme/custom_font", "")
	TestHelper.eq(p, "res://assets/fonts/DMT-Mono.ttf", "custom font path set in project.godot")

func test_font_resource_loads() -> void:
	var f := ResourceLoader.load("res://assets/fonts/DMT-Mono.ttf")
	TestHelper.is_true(f != null, "font resource loads after import")
```

- [ ] **Step 4: Run test to verify it fails.** Run the suite; expect FAIL lines (font path not set yet â€” `ProjectSettings` returns `""`).

- [ ] **Step 5: Add `[gui]` section to `project.godot`.** Append at the end of the file:

```ini
[gui]

theme/custom_font="res://assets/fonts/DMT-Mono.ttf"
theme/default_font_antialiasing=0
theme/default_font_subpixel_positioning=0
theme/default_font_hinting=1
```

- [ ] **Step 6: Append font credit to `CREDITS.txt`:**

```text
Font: Determination Mono (DMT-Mono) by JapanYoshi / ThetaApps â€” 8-Bit Operator-style pixel font, used for fan-project authenticity.
```

- [ ] **Step 7: Run suite â€” verify it passes.** GATE: `ALL TESTS PASSED`, zero `SCRIPT ERROR:`, zero `FAIL:`.

- [ ] **Step 8: Commit**

```powershell
git add assets/fonts/DMT-Mono.ttf project.godot CREDITS.txt tests/test_font.gd
git commit -m "feat: add DMT-Mono pixel font + project-wide gui theme"
```

### Task 2: Dialogue box restyle (solid black + battle mode + visible-only-when-active fix)

**Files:**
- Modify: `scripts/dialogue/dialogue_ui.gd` (box alpha, battle-mode geometry, visibility lifecycle â€” ALSO fixes the latent crash where the shared battle instance `queue_free()`s itself and is reused)
- Modify: `scripts/rooms/npc.gd` (free the dialogue instance after `finished` â€” the UI no longer frees itself)
- Test: `tests/test_dialogue_box.gd`

**Interfaces:**
- Consumes: `Audio.play_sfx(id, pitch)` (Task 1-adjacent, exists).
- Produces: `DialogueUI.open(lines: Array, battle: bool = false)` â€” battle mode â†’ box `Rect2(30, 390, 290, 75)`, labels at (50,410)/(50,392); overworld â†’ box `Rect2(24, 404, 592, 64)`; UI hides itself when finished (never frees). Battle code (Task 3+) and npc.gd consume this.

- [ ] **Step 1: Write the failing test** `tests/test_dialogue_box.gd`:

```gdscript
extends RefCounted

var _ui: Node
var _finished: bool = false

func _make_ui() -> void:
	_ui = load("res://scripts/dialogue/dialogue_ui.gd").new()
	_ui._ready()
	_ui.finished.connect(func() -> void: _finished = true)

func test_battle_box_geometry() -> void:
	_make_ui()
	_ui.open([{"speaker": "", "text": "Hello."}], true)
	TestHelper.eq(_ui._panel.position, Vector2(30, 390), "battle box position")
	TestHelper.eq(_ui._panel.size, Vector2(290, 75), "battle box size")
	TestHelper.is_true(_ui.visible, "ui visible while typing")

func test_overworld_box_geometry() -> void:
	_make_ui()
	_ui.open([{"speaker": "", "text": "Hello."}])
	TestHelper.eq(_ui._panel.position, Vector2(24, 404), "overworld box position")
	TestHelper.eq(_ui._panel.size, Vector2(592, 64), "overworld box size")

func test_solid_black_fill() -> void:
	_make_ui()
	TestHelper.eq(_ui._panel.get_theme_stylebox("panel").bg_color, Color(0, 0, 0, 1), "box fill is solid black")

func test_hides_itself_when_finished() -> void:
	_make_ui()
	_ui.open([{"speaker": "", "text": "Hi."}])
	_ui._index = 1
	_ui._process(0.0)
	TestHelper.is_true(_finished, "finished emitted at end")
	TestHelper.is_true(not _ui.visible, "ui hides when finished (does not free)")
```

- [ ] **Step 2: Run test â€” verify it fails** (solid-black assert fails; geometry asserts fail).

- [ ] **Step 3: Rewrite `scripts/dialogue/dialogue_ui.gd`:**

```gdscript
class_name DialogueUI
extends CanvasLayer

signal finished

const OVERWORLD_BOX := Rect2(24, 404, 592, 64)
const BATTLE_BOX := Rect2(30, 390, 290, 75)

var _lines: Array = []
var _index: int = 0
var _tw := Typewriter.new()
var _panel: Panel
var _label: Label
var _speaker_label: Label
var _active: bool = false
var _prev_chars: int = 0

func _ready() -> void:
	layer = 10
	_panel = Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 1)
	sb.set_border_width_all(1)
	sb.border_color = Color.WHITE
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.position = OVERWORLD_BOX.position
	_panel.size = OVERWORLD_BOX.size
	add_child(_panel)
	_speaker_label = Label.new()
	_speaker_label.position = Vector2(36, 408)
	_speaker_label.add_theme_font_size_override("font_size", 16)
	add_child(_speaker_label)
	_label = Label.new()
	_label.position = Vector2(36, 430)
	_label.size = Vector2(560, 30)
	_label.add_theme_font_size_override("font_size", 16)
	add_child(_label)
	visible = false

func open(lines: Array, battle: bool = false) -> void:
	_lines = lines
	_index = 0
	if _lines.is_empty():
		finished.emit()
		visible = false
		return
	_panel.position = BATTLE_BOX.position if battle else OVERWORLD_BOX.position
	_panel.size = BATTLE_BOX.size if battle else OVERWORLD_BOX.size
	var inset := 20 if battle else 12
	_speaker_label.position = Vector2(BATTLE_BOX.position.x + inset, BATTLE_BOX.position.y + 2) if battle else Vector2(36, 408)
	_label.position = Vector2(BATTLE_BOX.position.x + inset, BATTLE_BOX.position.y + inset + 2) if battle else Vector2(36, 430)
	_label.size = Vector2((BATTLE_BOX.size.x if battle else 560) - inset - 10, 30)
	visible = true
	_active = true
	_prev_chars = 0
	_show_current()

func _process(delta: float) -> void:
	if not _active:
		return
	if _index >= _lines.size():
		_active = false
		visible = false
		finished.emit()
		return
	var line: Dictionary = _lines[_index]
	_tw.advance(delta)
	var vis := _tw.visible_chars()
	var text: String = str(line.get("text", ""))
	if vis > _prev_chars and _prev_chars < text.length():
		var ch := text.substr(_prev_chars, 1)
		if not (ch == " " or ch == "\t" or ch == "\n"):
			Audio.play_sfx("blip", randf_range(0.9, 1.1))
	_prev_chars = vis
	_label.text = text.substr(0, vis)
	if Input.is_action_just_pressed("confirm") or Input.is_action_just_pressed("cancel"):
		if _tw.is_done():
			_index += 1
			if _index < _lines.size():
				_prev_chars = 0
				_show_current()
		else:
			_tw.skip()

func _show_current() -> void:
	var line: Dictionary = _lines[_index]
	_speaker_label.text = str(line.get("speaker", ""))
	_speaker_label.visible = str(line.get("speaker", "")) != ""
	_label.text = ""
	_tw.start(str(line.get("text", "")))
```

- [ ] **Step 4: Update `scripts/rooms/npc.gd`** so the overworld instance is freed by its owner after finishing (the UI no longer frees itself):

```gdscript
extends Area2D

@export var dialogue_file: String = ""

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var lines: Array = DialogueParser.parse_file(dialogue_file)
		var ui := load("res://scripts/dialogue/dialogue_ui.gd").new()
		ui.layer = 10
		get_tree().current_scene.add_child(ui)
		ui.open(lines)
		await ui.finished
		ui.queue_free()
```

- [ ] **Step 5: Run suite â€” verify it passes.** GATE as defined. NOTE: existing tests must stay green (nothing else instantiates DialogueUI in tests).

- [ ] **Step 6: Commit**

```powershell
git add scripts/dialogue/dialogue_ui.gd scripts/rooms/npc.gd tests/test_dialogue_box.gd
git commit -m "feat: solid black dialogue box with battle mode + hide-on-finish lifecycle"
```

### Task 3: Battle geometry â€” Undertale layout (board, info bar, menu box, fight bar, patterns)

**Files:**
- Modify: `scripts/battle/dodge_box.gd` (BOX_RECT, heart start, inset clamp)
- Modify: `scripts/battle/combat_math.gd` (add `clamp_to_box_inset`)
- Modify: `scripts/battle/bullet_patterns.gd` (default origins â†’ new board center)
- Modify: `scripts/battle/battle.gd` (enemy position, player info zone, enemy HP bar lime, menu box, fight bar placement)
- Modify: `scripts/util/sprites.gd` (heart 14x12, bullet 8x8 white + black border)
- Modify: `tests/test_dodge_box.gd` + `tests/test_hurt_feedback.gd` (update geometry constants â€” the ONLY permitted test edits)
- Test: `tests/test_combat_math.gd` (append inset-clamp tests)

**Interfaces:**
- Consumes: `Fade`/`Audio` autoloads (unchanged); `CombatMath.clamp_to_box` (exists).
- Produces: `CombatMath.clamp_to_box_inset(pos: Vector2, box: Rect2, left: float, top: float, right: float, bottom: float) -> Vector2`; `DodgeBox.BOX_RECT := Rect2(32, 250, 570, 135)`; `DodgeBox.HEART_START := Vector2(317, 317)`; new heart/bullet textures from `Sprites`. Battle layout: board (32,250,570,135); enemy at (216,136); player info at y=400; menu box at (400,385) size (202,80); fight bar at (45,415).

- [ ] **Step 1: Append inset-clamp tests to `tests/test_combat_math.gd`** (append before final closing):

```gdscript
func test_clamp_to_box_inset_basic() -> void:
	var box := Rect2(32, 250, 570, 135)
	var p := CombatMath.clamp_to_box_inset(Vector2(0, 0), box, 4.0, 4.0, -16.0, -16.0)
	TestHelper.eq(p, Vector2(36, 254), "inset clamps left/top")
	var q := CombatMath.clamp_to_box_inset(Vector2(1000, 1000), box, 4.0, 4.0, -16.0, -16.0)
	TestHelper.eq(q, Vector2(585, 368), "inset clamps right/bottom")

func test_clamp_to_box_inset_inside_unchanged() -> void:
	var box := Rect2(32, 250, 570, 135)
	var p := CombatMath.clamp_to_box_inset(Vector2(300, 300), box, 4.0, 4.0, -16.0, -16.0)
	TestHelper.eq(p, Vector2(300, 300), "inside stays put")
```

- [ ] **Step 2: Add `clamp_to_box_inset` to `scripts/battle/combat_math.gd`:**

```gdscript
static func clamp_to_box_inset(pos: Vector2, box: Rect2, left: float, top: float, right: float, bottom: float) -> Vector2:
	var inner := Rect2(box.position + Vector2(left, top), box.size - Vector2(left - right, top - bottom))
	return clamp_to_box(pos, inner)
```

- [ ] **Step 3: Run the two test files â€” verify new tests fail** (function missing â†’ SCRIPT ERROR on that test file is expected at this point; the rest of the suite must still show ALL TESTS PASSED minus these).

- [ ] **Step 4: Update `scripts/battle/dodge_box.gd` geometry:**

```gdscript
const BOX_RECT := Rect2(32, 250, 570, 135)
const HEART_START := Vector2(317, 317)
```
(Replace the old `BOX_RECT := Rect2(200, 60, 240, 220)` line; in `_ready`, heart position becomes `HEART_START` instead of `BOX_RECT.get_center()`; in `_process`, the input-move line becomes `heart.position = CombatMath.clamp_to_box_inset(heart.position + input * HEART_SPEED * delta, BOX_RECT, 4.0, 4.0, -16.0, -16.0)`.)

- [ ] **Step 5: Update `scripts/battle/bullet_patterns.gd` default origins** â€” both `burst` and `fan` get `origin := Vector2(317, 317)` (was `Vector2(320, 90)` â€” old origin spawns bullets outside the new board where they are instantly culled).

- [ ] **Step 6: Update the two geometry-encoding test files.**

`tests/test_dodge_box.gd` â€” change ONLY these expectations:
- `test_heart_starts_at_center_and_visibility`: `heart.position == Vector2(317, 317)` (was (320,170))
- `test_player_hit_emitted_once_per_invuln`: bullet at `(317, 317)` (was (320,170))
- `test_heart_moves_and_clamps_to_box`: move_right 10s â†’ `x == 585.0`; left â†’ `36.0`; up â†’ `254.0`; down â†’ `368.0`; no-input stays `(36, 368)` (recompute final resting point: after moving left/down the heart rests at the inset corner)

`tests/test_hurt_feedback.gd` â€” change ONLY these expectations:
- `test_invuln_time_is_one_second`: bullet at `(317, 317)` (was (320,170))
- `test_knockback_moves_heart_away_from_bullet`: bullet at `(315, 317)` (was (318,170)); assert `heart.x > 315.0`

- [ ] **Step 7: Update `scripts/util/sprites.gd`** â€” replace `heart_texture` with 14x12 (same diamond, 1px outline via 0.2x darkening, red (0.85,0.15,0.15) center) and `bullet_texture` with 8x8 white fill + 1px black border:

```gdscript
static func heart_texture() -> ImageTexture:
	var img := Image.create(14, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var fill := Color(0.85, 0.15, 0.15)
	var dark := Color(0.45, 0.05, 0.05)
	var rows := ["...XXXXXXX...", "..XXXXXXXXX..", ".XXXXXXXXXXX.", "XXXXXXXXXXXXX", "XXXXXXXXXXXXX", ".XXXXXXXXXXX.", "..XXXXXXXXX..", "...XXXXXXX..."]
	for y in rows.size():
		for x in rows[y].length():
			if rows[y][x] == "X":
				var dark_edge := y == 0 or y == rows.size() - 1 or x == 0 or x == rows[y].length() - 1
				img.set_pixel(x, y, dark if dark_edge else fill)
	return ImageTexture.create_from_image(img)

static func bullet_texture() -> ImageTexture:
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 8:
		for x in 8:
			var edge := x == 0 or x == 7 or y == 0 or y == 7
			img.set_pixel(x, y, Color.BLACK if edge else Color.WHITE)
	return ImageTexture.create_from_image(img)
```
(The existing 14x12 shape rows above is the classic Undertale soul shape. Hit radius stays 4.0 â€” unchanged.)

- [ ] **Step 8: Update `scripts/battle/battle.gd` layout** â€” exact edits:
1. `_build_ui`: `_enemy_sprite.position = Vector2(216, 136)` (was (480,220)).
2. Player info zone (was name at (30,300), bar at (30,322), label at (30,336)):
   - `_player_name_label.position = Vector2(30, 400)`; text `"DREAMCATCHER LV 1"` (set in `_refresh_player_ui` as `"DREAMCATCHER LV %d" % int(GameState.player_stats.get("lv", 1))`)
   - `_player_hp_bar` (RED underlay): position (275,400), size (24,20) â€” constant: `Vector2(24, 20)` sized by `24.0 * hp / max_hp` in refresh (1.2px per HP Ã— maxhp 20)
   - NEW `_player_hp_fill` ColorRect YELLOW at same rect (275,400) size (24,20), created beside the underlay
   - `_player_hp_label` position (302,400), text `"%02d / %02d" % [hp, max]`
3. Enemy HP bar: `_hp_bar` becomes lime `Color(0.75, 1.0, 0.25)`; add NEW `_hp_bar_bg` ColorRect BLACK size (18,6) at (207,161) behind it; `_hp_bar` at (208,162) size (16,4) (16 wide = wisp width; bar.width = `16.0 * hp / max_hp` in refresh).
4. `_build_menu`: wrap labels in a Panel: new `_menu_box` Panel with 1px white border, position (400,385), size (202,80), added before labels; label positions become `Vector2(432 + MENU_GRID[i].x * 90, 413 + MENU_GRID[i].y * 30)`; label font size 16 (was 18). Add `_menu_cursor := Sprite2D` with `Sprites.heart_texture()`, scale 1, added above labels; `_update_menu_colors()` additionally sets `_menu_cursor.position = selected_label_position - Vector2(14, 0)`.
5. `_build_fight_bar`: panel position (45,415) size (260,28); marker at `(45 + marker * 256, 415)` (update `_process` marker line accordingly; marker size stays (2,28)).
6. `_refresh_enemy_ui`: `_hp_bar.size.x = 16.0 * float(_enemy.hp) / float(_enemy.max_hp)`; name label unchanged (white/yellow logic stays).
7. `_refresh_player_ui`: `_player_hp_fill.size.x = 24.0 * float(hp) / float(max_hp)`; `_player_hp_bar.size.x = 24.0` (full red underlay always); text `"%02d / %02d" % [hp, max_hp]`.
8. All menu/battle label font sizes â†’ 16.

- [ ] **Step 9: Run suite â€” verify green.** GATE. The two edited test files pass with new geometry; everything else unchanged.

- [ ] **Step 10: Commit**

```powershell
git add scripts/battle/dodge_box.gd scripts/battle/combat_math.gd scripts/battle/bullet_patterns.gd scripts/battle/battle.gd scripts/util/sprites.gd tests/test_dodge_box.gd tests/test_hurt_feedback.gd tests/test_combat_math.gd
git commit -m "feat: undertale battle geometry - board, info bar, menu box, fight bar"
```

### Task 4: Menu heart cursor + submenu grids + UI sounds

**Files:**
- Modify: `scripts/battle/battle.gd` (submenu panel + grids per context, cursor follows, play sfx on move/confirm/cancel/heal)

**Interfaces:**
- Consumes: cursor sprite from Task 3 (`_menu_cursor`); `Audio.play_sfx` ids: `select` (cursor move = UT snd_squeak), `confirm` (= snd_select), `cancel`, `heal` (item use).
- Produces: submenu geometry â€” ACT 2 cols box (250,385,152,44); ITEM 4x2 box (250,385,292,80); MERCY 2 rows box (250,385,152,80); items 16px; cursor at item pos âˆ’ (14,0).

- [ ] **Step 1: Rework `_open_submenu` in `scripts/battle/battle.gd`:**

```gdscript
const SUBMENU_BOXES := {
	"ACT": Rect2(250, 385, 152, 44),
	"ITEM": Rect2(250, 385, 292, 80),
	"MERCY": Rect2(250, 385, 152, 80),
}

func _open_submenu(items: Array[String], context: String) -> void:
	_submenu_open = true
	_submenu_context = context
	_submenu_index = 0
	_submenu_items = items
	var box := SUBMENU_BOXES[context]
	_menu_box.position = box.position
	_menu_box.size = box.size
	_render_menu_labels()
	_menu.visible = true
	_update_menu_colors()
	Audio.play_sfx("select")
```

- [ ] **Step 2: Add `_submenu_items` var and rework `_render_menu_labels` for grids.** Add `var _submenu_items: Array[String] = []`. In `_render_menu_labels`, when `_submenu_open` use per-context positions (16px labels):

```gdscript
func _submenu_pos(i: int) -> Vector2:
	match _submenu_context:
		"ACT":
			return Vector2(276 + (i % 2) * 70, 413 + (i / 2) * 30)
		"ITEM":
			return Vector2(276 + (i % 4) * 70, 413 + (i / 4) * 30)
		_:
			return Vector2(276, 413 + i * 30)
```

- [ ] **Step 3: Cursor + sounds in input handlers.**
- `_handle_menu_input`: on direction change â†’ `Audio.play_sfx("select")`; on confirm (`_choose`) â†’ `Audio.play_sfx("confirm")`.
- `_handle_submenu_input`: move â†’ `Audio.play_sfx("select")`; confirm â†’ `Audio.play_sfx("confirm")` then `_resolve_submenu()`; cancel â†’ `Audio.play_sfx("cancel")` then close + `_enter_player_turn()`.
- `_resolve_submenu` ITEM branch: after `use_item` succeeds â†’ `Audio.play_sfx("heal")`.
- `_update_menu_colors`: also position cursor â€” when `_submenu_open` the cursor targets `_submenu_pos(_submenu_index)` else the main grid position; cursor sits at `target - Vector2(14, 0)`; ensure `_menu_cursor.visible = true` whenever `_menu.visible`.

- [ ] **Step 4: MERCY list** â€” `_choose` MERCY branch calls `_open_submenu(["Spare", "Flee"], "MERCY")` (already the case; keep). `_resolve_submenu` MERCY rows: index 0 = Spare, 1 = Flee (current code already indexes into the items array â€” verify it uses `_submenu_items[_submenu_index]`).

- [ ] **Step 5: Run suite â€” verify green.** GATE (no new tests; battle.gd is parse-only in the suite â€” the gate catches parse errors).

- [ ] **Step 6: Commit**

```powershell
git add scripts/battle/battle.gd
git commit -m "feat: menu heart cursor, context submenu grids, ui blip sounds"
```

### Task 5: Enemy presentation â€” entrance, idle bob, hit flash, damage digits, shake, defeat fade, HP drain

**Files:**
- Modify: `scripts/battle/battle.gd` (entrance tween, bob in `_process`, flash + digits on hit, shake on player hurt, defeat fade, lag drain)
- Modify: `scripts/battle/combat_math.gd` (add `drain_toward`)
- Modify: `tests/test_combat_math.gd` (append drain tests)

**Interfaces:**
- Consumes: `_enemy_sprite`, `_dodge_box`, `_hp_bar`, `_enemy_hp_display` (new), `Time.get_ticks_msec()`, `Audio.play_sfx("hurt")` (already in `_on_player_hit`).
- Produces: `CombatMath.drain_toward(current: float, target: float, delta: float, rate: float = 40.0) -> float`; battle flow: entrance â†’ intro â†’ bob; hit â†’ flash + red damage digit; player hurt â†’ board shake; defeat â†’ sprite fade then `_end_battle`.

- [ ] **Step 1: Append drain tests to `tests/test_combat_math.gd`:**

```gdscript
func test_drain_toward_moves_toward_target() -> void:
	var v := CombatMath.drain_toward(8.0, 3.0, 0.05)
	TestHelper.eq(v, 6.0, "drains 40/s")

func test_drain_toward_never_overshoots() -> void:
	var v := CombatMath.drain_toward(3.2, 3.0, 0.05)
	TestHelper.eq(v, 3.0, "clamps at target")

func test_drain_toward_holds_when_equal() -> void:
	var v := CombatMath.drain_toward(3.0, 3.0, 0.05)
	TestHelper.eq(v, 3.0, "no movement at target")
```

- [ ] **Step 2: Add to `scripts/battle/combat_math.gd`:**

```gdscript
static func drain_toward(current: float, target: float, delta: float, rate: float = 40.0) -> float:
	var step := rate * delta
	if current > target:
		return maxf(target, current - step)
	return minf(target, current + step)
```

- [ ] **Step 3: Run the two tests â€” verify the new ones fail** (SCRIPT ERROR on test_combat_math until the function exists; other tests still green).

- [ ] **Step 4: Battle changes in `scripts/battle/battle.gd`:**

1. Add vars: `var _enemy_hp_display: float = 0.0` and `var _enemy_in: bool = false`.
2. `_ready`: after `_build_ui()`, set `_enemy_sprite.position = Vector2(216, -40)`, `_enemy_hp_display = float(_enemy.max_hp)`, then await the entrance tween BEFORE the intro `_say`:

```gdscript
	_enemy_sprite.position = Vector2(216, -40)
	var entrance := create_tween()
	entrance.tween_property(_enemy_sprite, "position", Vector2(216, 136), 0.4)
	await entrance.finished
	_enemy_in = true
```

3. `_process` (top, after the `_ending` guard): idle bob + drain:

```gdscript
	if _enemy_in:
		_enemy_sprite.position.y = 136.0 + sin(Time.get_ticks_msec() * 0.003) * 2.0
		_enemy_hp_display = CombatMath.drain_toward(_enemy_hp_display, float(_enemy.hp), delta, 40.0)
		_hp_bar.size.x = 16.0 * (_enemy_hp_display / float(_enemy.max_hp))
```

4. `_resolve_fight` hit branch (after `_enemy.hp -= dmg`): flash + digit:

```gdscript
		_enemy_sprite.modulate = Color(3.0, 3.0, 3.0)
		var flash := create_tween()
		flash.tween_property(_enemy_sprite, "modulate", Color(1, 1, 1), 0.1)
		_spawn_damage_digit(dmg, false)
```

5. `_spawn_damage_digit` (new func; MISS variant gray, no minus sign):

```gdscript
func _spawn_damage_digit(amount: int, miss: bool) -> void:
	var digit := Label.new()
	digit.add_theme_font_size_override("font_size", 16)
	digit.text = "MISS" if miss else "-%d" % amount
	digit.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6) if miss else Color(1.0, 0.2, 0.2))
	digit.position = _enemy_sprite.position + Vector2(-10, -16)
	add_child(digit)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(digit, "position:y", digit.position.y - 12.0, 0.6)
	t.tween_property(digit, "modulate:a", 0.0, 0.6)
	t.chain().tween_callback(digit.queue_free)
```

6. MISS branch in `_resolve_fight` (`intent < 0.1`): call `_spawn_damage_digit(0, true)` instead of only the say.
7. `_on_player_hit`: add board shake (player hurt):

```gdscript
func _on_player_hit() -> void:
	Audio.play_sfx("hurt")
	GameState.change_hp(-1)
	_refresh_player_ui()
	var shake := create_tween()
	shake.tween_property(_dodge_box, "position", Vector2(2, 0), 0.05)
	shake.tween_property(_dodge_box, "position", Vector2(-2, 0), 0.05)
	shake.tween_property(_dodge_box, "position", Vector2.ZERO, 0.1)
```

8. Defeat fade (WIN branch in `_resolve_fight`, before `_end_battle()`): tween `_enemy_sprite.modulate:a` â†’ 0 over 0.5 and await it.
9. `_refresh_enemy_ui`: keep `_hp_bar.size.x` driven by `_enemy_hp_display` (already handled in `_process`; remove the direct size set here to avoid fighting the drain â€” only set name label + `_hp_label` text here).

- [ ] **Step 5: Run suite â€” verify green.** GATE. (battle.gd is parse-only in tests; engine compile errors surface as SCRIPT ERROR lines.)

- [ ] **Step 6: Commit**

```powershell
git add scripts/battle/battle.gd scripts/battle/combat_math.gd tests/test_combat_math.gd
git commit -m "feat: enemy entrance, bob, hit flash, damage digits, shake, hp drain"
```

### Task 6: Overworld polish â€” static camera, walk anim + shadow, door sprite, save star + banner, bang pop, transition timings

**Files:**
- Modify: `scripts/rooms/drizzle_fields.gd` (static centered camera)
- Modify: `scripts/rooms/grumble_woods.gd` (static centered camera)
- Modify: `scripts/player/player.gd` (2-frame walk anim + flip_h + shadow child)
- Modify: `scripts/util/sprites.gd` (player frame textures, shadow, door)
- Modify: `scripts/rooms/door.gd` (door sprite; fade 0.43)
- Modify: `scripts/rooms/save_point.gd` (star scale 2.8 + pulse; banner box)
- Modify: `scripts/rooms/encounter.gd` ("!" pop tween)
- Modify: `scripts/rooms/drizzle_fields.gd` + `grumble_woods.gd` (fade_from_black(0.67))
- Test: `tests/test_player_visuals.gd`

**Interfaces:**
- Consumes: `Sprites.player_texture_frame(frame: int)`, `Sprites.player_shadow_texture()`, `Sprites.door_texture()` (new); `Fade.fade_to_black(0.43)` / `fade_from_black(0.67)`.
- Produces: static camera centered on room (`cam.position = Vector2(room_pixel_size(grid)) / 2` rounded), player anim toggle via `_anim_time`, door/save/bang visuals.

- [ ] **Step 1: Write the failing test** `tests/test_player_visuals.gd`:

```gdscript
extends RefCounted

func test_player_frames_exist() -> void:
	TestHelper.is_true(Sprites.player_texture_frame(0) != null, "frame 0 exists")
	TestHelper.is_true(Sprites.player_texture_frame(1) != null, "frame 1 exists")

func test_player_frames_differ() -> void:
	var a := Sprites.player_texture_frame(0).get_image()
	var b := Sprites.player_texture_frame(1).get_image()
	TestHelper.is_true(not a.is_equal_to(b), "walk frames differ")

func test_aux_textures_exist() -> void:
	TestHelper.is_true(Sprites.player_shadow_texture() != null, "shadow exists")
	TestHelper.is_true(Sprites.door_texture() != null, "door exists")
```

- [ ] **Step 2: Run test â€” verify it fails** (SCRIPT ERROR: functions missing).

- [ ] **Step 3: Add to `scripts/util/sprites.gd`:**

```gdscript
static func player_texture_frame(frame: int) -> ImageTexture:
	var img := Image.create(8, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 12:
		for x in 8:
			var hair := y < 2
			var body := y >= 2 and y < 10
			var leg_row := y >= 10
			var color := Color(0, 0, 0, 0)
			if hair:
				color = Color(0.25, 0.15, 0.1)
			elif body:
				if y % 2 == 1:
					color = Color(0.3, 0.45, 0.8)
				else:
					color = Color(0.95, 0.8, 0.65)
			elif leg_row:
				color = Color(0.2, 0.12, 0.08)
			img.set_pixel(x, y, color)
	if frame == 1:
		img.set_pixel(3, 11, Color(0, 0, 0, 0))
		img.set_pixel(4, 10, Color(0.2, 0.12, 0.08))
		img.set_pixel(2, 11, Color(0.2, 0.12, 0.08))
	img.set_pixel(2, 3, Color(0, 0, 0, 0))
	img.set_pixel(5, 3, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)

static func player_shadow_texture() -> ImageTexture:
	var img := Image.create(6, 3, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in 6:
		for y in 3:
			if not (x == 0 or x == 5 or (y == 0 and (x == 1 or x == 4))):
				img.set_pixel(x, y, Color(0, 0, 0, 0.4))
	return ImageTexture.create_from_image(img)

static func door_texture() -> ImageTexture:
	var img := Image.create(16, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var wood := Color(0.45, 0.3, 0.15)
	var dark := Color(0.3, 0.2, 0.1)
	for y in 32:
		for x in 16:
			var edge := x == 0 or x == 15 or y == 0 or y == 31
			var seam := x == 7 or x == 8
			var frame_dark := x == 1 or x == 14
			if edge:
				img.set_pixel(x, y, Color.WHITE)
			elif seam or frame_dark:
				img.set_pixel(x, y, dark)
			else:
				img.set_pixel(x, y, wood)
	img.set_pixel(8, 24, Color(0.9, 0.85, 0.4))
	img.set_pixel(8, 23, Color(0.9, 0.85, 0.4))
	return ImageTexture.create_from_image(img)
```

- [ ] **Step 4: Update `scripts/player/player.gd`** â€” add walk anim + shadow + flip:

```gdscript
var _anim_time: float = 0.0
var _frame: int = 0
var _moving: bool = false
var _sprite: Sprite2D
var _shadow: Sprite2D
```
In `_ready`: replace the texture assignment with `_sprite = $Sprite2D; _sprite.texture = Sprites.player_texture_frame(0); _shadow = Sprite2D.new(); _shadow.texture = Sprites.player_shadow_texture(); _shadow.position = Vector2(0, 9); add_child(_shadow)`.
In `_physics_process` (after `set_movement_input`): if `res[0] != Vector2.ZERO`: `_moving = true; _anim_time += get_physics_process_delta_time(); _frame = int(_anim_time / 0.15) % 2; _sprite.texture = Sprites.player_texture_frame(_frame); _sprite.flip_h = res[0].x < 0` else `_moving = false; _sprite.texture = Sprites.player_texture_frame(0)`. (Keep `facing` update and `move_and_slide()` exactly as-is.)

- [ ] **Step 5: Static centered camera in both rooms.** In `drizzle_fields.gd` `_spawn_player` and `grumble_woods.gd` `_spawn_player`:
- Remove `position_smoothing_enabled = true` and `speed = 8.0` and the limit assignments.
- Create the camera as a child of the room root (not the player), `make_current()`, at `Vector2(room_pixel_size(grid) / 2.0).round()` â€” the rooms are smaller than 640x480 so the camera sits centered and never moves (Undertale void look, zero jitter).
- Keep the player-facing line `_spawn_player(start, grid)` signature unchanged.

- [ ] **Step 6: Door visuals + timing.** `scripts/rooms/door.gd` `_ready`: add `var sprite := Sprite2D.new(); sprite.texture = Sprites.door_texture(); sprite.position = Vector2(0, 0); add_child(sprite)`. In `_on_body_entered`: `Fade.fade_to_black(0.43)` and `await get_tree().create_timer(0.43).timeout` before `change_scene_to_file` (was 0.3/0.3).

- [ ] **Step 7: Room fade-ins â†’ 0.67s.** In both room `_ready`s: `Fade.fade_from_black(0.67)` (was 0.3).

- [ ] **Step 8: Save star + banner box.** `scripts/rooms/save_point.gd`:
- `_ready`: star scale â†’ 2.8 (was 1.5); add pulse: `var pulse := create_tween(); pulse.set_loops(); pulse.tween_property(sprite, "scale", Vector2(3.1, 3.1), 0.5); pulse.tween_property(sprite, "scale", Vector2(2.8, 2.8), 0.5)`.
- `_show_banner`: replace the bare floating label with a Panel (1px white border, position (24,404), size (120,32)) + Label 16px at (30,410) "Game saved."; tween the panel's `modulate:a` 1â†’0 over 0.8s after 1.0s interval, then `queue_free` the panel.

- [ ] **Step 9: "!" pop.** `scripts/rooms/encounter.gd` `_show_bang`: after creating the Label at scale 0.5, `var pop := create_tween(); pop.tween_property(bang, "scale", Vector2(1.2, 1.2), 0.08); pop.tween_property(bang, "scale", Vector2(1.0, 1.0), 0.1)` (Label pivot: set `bang.pivot_offset = Vector2(7, 7)`).

- [ ] **Step 10: Run suite â€” verify green.** GATE (test_player_visuals passes; room scripts are load-only so camera changes are parse-checked only).

- [ ] **Step 11: Commit**

```powershell
git add scripts/rooms/drizzle_fields.gd scripts/rooms/grumble_woods.gd scripts/player/player.gd scripts/util/sprites.gd scripts/rooms/door.gd scripts/rooms/save_point.gd scripts/rooms/encounter.gd tests/test_player_visuals.gd
git commit -m "feat: overworld polish - static camera, walk anim, door sprite, save star, bang pop"
```

### Task 7: World art â€” tile detail, per-area palette, area tint

**Files:**
- Modify: `scripts/tiles/tiles.gd` (build_tileset palette param + detail speckles/edge shading)
- Modify: `scripts/rooms/map_builder.gd` (build_tilemap palette param)
- Modify: `scripts/rooms/drizzle_fields.gd` (CanvasModulate purple)
- Modify: `scripts/rooms/grumble_woods.gd` (snow palette + CanvasModulate blue)
- Test: `tests/test_tiles_palette.gd`

**Interfaces:**
- Consumes: `GameTiles.build_tileset()` (existing callers unchanged â€” default param), `MapBuilder.build_tilemap(grid)` (default param).
- Produces: `GameTiles.build_tileset(palette: Dictionary = {}) -> TileSet`; `MapBuilder.build_tilemap(grid: Array, palette: Dictionary = {}) -> TileMapLayer`; `GameTiles.SNOW_PALETTE: Dictionary` (grumble) â€” drizzle keeps default.

- [ ] **Step 1: Write the failing test** `tests/test_tiles_palette.gd`:

```gdscript
extends RefCounted

func test_build_tileset_default() -> void:
	var ts := GameTiles.build_tileset()
	TestHelper.is_true(ts != null, "default tileset builds")
	var src := ts.get_source(0)
	TestHelper.is_true(src != null, "source exists")

func test_build_tileset_snow_palette() -> void:
	var ts := GameTiles.build_tileset(GameTiles.SNOW_PALETTE)
	TestHelper.is_true(ts != null, "snow tileset builds")

func test_build_tilemap_palette_param() -> void:
	var tm := MapBuilder.build_tilemap([["#", "#"], ["#", "#"]], GameTiles.SNOW_PALETTE)
	TestHelper.is_true(tm != null, "tilemap builds with palette")

func test_snow_palette_colors() -> void:
	TestHelper.eq(GameTiles.SNOW_PALETTE[GameTiles.Tile.GRASS], Color(0.92, 0.92, 0.95), "snow grass")
```

- [ ] **Step 2: Run test â€” verify it fails** (SCRIPT ERROR: optional params missing).

- [ ] **Step 3: Rewrite `scripts/tiles/tiles.gd`:**

```gdscript
class_name GameTiles

enum Tile { GRASS = 0, PATH = 1, TREE = 2, WALL = 3 }

const DEFAULT_PALETTE := {
	Tile.GRASS: Color(0.3, 0.5, 0.28),
	Tile.PATH: Color(0.72, 0.62, 0.4),
	Tile.TREE: Color(0.18, 0.38, 0.2),
	Tile.WALL: Color(0.42, 0.42, 0.5),
}

const SNOW_PALETTE := {
	Tile.GRASS: Color(0.92, 0.92, 0.95),
	Tile.PATH: Color(0.6, 0.62, 0.7),
	Tile.TREE: Color(0.35, 0.4, 0.5),
	Tile.WALL: Color(0.3, 0.35, 0.45),
}

static func build_tileset(palette: Dictionary = {}) -> TileSet:
	var cols := DEFAULT_PALETTE.duplicate()
	for k in palette:
		cols[k] = palette[k]
	var atlas := Image.create(64, 16, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(0.1, 0.1, 0.1))
	for tile_id in 4:
		_fill_tile_detailed(atlas, tile_id, cols[tile_id])
	var tex := ImageTexture.create_from_image(atlas)
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(16, 16)
	for tile_id in 4:
		src.create_tile(Vector2i(tile_id, 0))
	ts.add_source(src, 0)
	return ts

static func _fill_tile_detailed(img: Image, tile_id: int, base: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + tile_id * 31337
	var ox := tile_id * 16
	for y in 16:
		for x in 16:
			var c := base
			if y < 2:
				c = base.darkened(0.2)
			elif y >= 14:
				c = base.darkened(0.1)
			var speckle := rng.randf()
			if speckle < 0.06:
				c = base.lightened(0.15)
			elif speckle > 0.94:
				c = base.darkened(0.2)
			img.set_pixel(ox + x, y, c)
```
(Replace the old `_atlas_texture`/`_fill_tile` helpers; keep the `enum Tile` and the 4-tile layout identical so existing tests keep passing.)

- [ ] **Step 4: Update `scripts/rooms/map_builder.gd`** â€” `build_tilemap(grid: Array, palette: Dictionary = {})` â†’ `GameTiles.build_tileset(palette)`.

- [ ] **Step 5: Area tints.** `drizzle_fields.gd` `_ready` (after building the tilemap): `var mod := CanvasModulate.new(); mod.color = Color(0.8, 0.78, 1.0); add_child(mod)`. `grumble_woods.gd` `_ready`: `build_tilemap(grid, GameTiles.SNOW_PALETTE)` instead of `build_tilemap(grid)`; `CanvasModulate` color `Color(0.85, 0.9, 1.0)`.

- [ ] **Step 6: Run suite â€” verify green.** GATE. (Existing test_tiles.gd must still pass â€” it asserts the 4-tile atlas layout, which is unchanged.)

- [ ] **Step 7: Commit**

```powershell
git add scripts/tiles/tiles.gd scripts/rooms/map_builder.gd scripts/rooms/drizzle_fields.gd scripts/rooms/grumble_woods.gd tests/test_tiles_palette.gd
git commit -m "feat: detailed tiles with per-area palettes and area tints"
```

### Task 8: Title screen â€” blinking prompt, version line

**Files:**
- Modify: `scripts/main.gd` (blinking "Press Z to fall", version line "SOULHEART v0.3" 8px gray)

**Interfaces:**
- Consumes: theme font from Task 1 (labels auto-render pixel font at their size).
- Produces: title with blinking hint (sin-based) + version footer; everything else (music, fade to DrizzleFields on confirm) unchanged.

- [ ] **Step 1: Update `scripts/main.gd`** â€” add `var _hint: Label` member; in `_ready` store the existing hint label in `_hint` and add a version label:

```gdscript
	_hint = Label.new()
	_hint.text = "Press Z to fall"
	_hint.position = Vector2(260, 320)
	_hint.add_theme_font_size_override("font_size", 16)
	add_child(_hint)
	var version := Label.new()
	version.text = "SOULHEART v0.3"
	version.position = Vector2(160, 232)
	version.add_theme_font_size_override("font_size", 8)
	version.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_child(version)
```
(Replace the existing hint creation block; keep the title label "SoulHeart" 48px and the sub line as-is.)

In `_process` (top): `_hint.visible = sin(Time.get_ticks_msec() * 0.004) > 0.0`.

- [ ] **Step 2: Run suite â€” verify green.** GATE (main.gd is load-only in tests).

- [ ] **Step 3: Commit**

```powershell
git add scripts/main.gd
git commit -m "feat: title screen blinking prompt + version line"
```

### Task 9: Final verification, export, delivery

**Files:**
- Copy in (untracked, do NOT commit): `export_presets.cfg` and `Play SoulHeart.bat` from `C:\Users\Admin\Downloads\SoulHeart\` into the worktree root.
- Deliverable: `dist\SoulHeart.exe` in the worktree.

- [ ] **Step 1: Full suite** (Global Constraints) â€” ALL TESTS PASSED, zero SCRIPT ERROR, zero FAIL, only permitted nope.dlg stderr line.
- [ ] **Step 2: Copy export files**

```powershell
Copy-Item "C:\Users\Admin\Downloads\SoulHeart\export_presets.cfg" -Destination "export_presets.cfg"
Copy-Item "C:\Users\Admin\Downloads\SoulHeart\Play SoulHeart.bat" -Destination "Play SoulHeart.bat"
```

- [ ] **Step 3: Export.** Stop any running instance first (`Stop-Process -Name SoulHeart -Force -ErrorAction SilentlyContinue`), then:

```powershell
cmd /c "tools\Godot_v4.4.1-stable_win64_console.exe --headless --export-debug ""Windows Desktop"" ""dist/SoulHeart.exe"" > .superpowers\export.txt 2>&1 & echo DONE"
```
(Ignore the harmless `rcedit` "Could not create child process" warnings â€” pre-existing, cosmetic. If "Failed to rename temporary file" appears, the old exe is locked â€” stop SoulHeart and retry.)

- [ ] **Step 4: Boot check**

```powershell
Start-Process -FilePath ".\dist\SoulHeart.exe" -ArgumentList "--headless","--quit-after","60" -Wait -PassThru | Select-Object ExitCode
```
ExitCode 0 = clean boot. Confirm `dist\SoulHeart.exe` size > 95MB (font + bigger textures add ~1-2MB over the 100.4MB audio-pack build).

- [ ] **Step 5: Report** â€” final suite tail, export log tail, boot exit code, exe size, and a per-task completion table (tasks 1-9 with commit hashes).

## Self-Review (run before committing the plan)

1. **Spec coverage:** bible Â§16 checklist â€” fonts (T1) âœ“; 4 battle zones (T3) âœ“; board edge easing â€” SKIPPED (stretch-sprites easing out of scope; board appears instantly â€” acceptable, noted); black-outside fill â€” SKIPPED (board is a solid panel; void already exists outside camera in rooms); Typer voiceâ†’blip (T2 keeps blip, per-voice map out of scope â€” one blip family as before); instant skip (already via `_tw.skip()` âœ“); inset +20/+20 (T2 battle inset 20 âœ“); menu heart cursor + 32px rows + 2-col ACT + 4x2 ITEM + squeak/select (T4 âœ“); feedback lime bar + red damage digits + white flash + shake (T5 âœ“); yellow-on-red HP bar 1.2px/HP padded (T3 âœ“); heart clamp +4/-16 + 1s blink (T3 uses existing invuln blink âœ“); overworld walk anim + Y-depth (T6 walk anim âœ“; depth sorting = scene child order, existing); 13f/20f fades (T6 0.43/0.67 âœ“); white sting flash (exists) âœ“; meta screens name grid â€” SKIPPED (deferred, content pack); save star 0.2 (T6 pulse âœ“); version text (T8 âœ“); hard music cut â€” SKIPPED (audio pack's death flow keeps music; acceptable).
2. **Placeholder scan:** no TBD/TODO; every code step complete.
3. **Type consistency:** `clamp_to_box_inset` defined T3, used T3; `drain_toward` defined T5, used T5; `build_tileset(palette)` / `build_tilemap(grid, palette)` defined T7, used T7; `player_texture_frame`/`player_shadow_texture`/`door_texture` defined T6, used T6; `DialogueUI.open(lines, battle := false)` defined T2, used by battle (T3+ calls `open(lines, true)` for battle narration â€” NOTE: battle `_say` must pass `true`; overworld npc passes nothing) â€” ADD to T2 step 4: battle.gd `_say` call sites must become `_text.open(lines, true)`. (Executors: verify battle.gd `_say` passes `true`.)
