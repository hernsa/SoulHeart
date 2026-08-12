# Plan E: Battle Variety & Polish Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Hybrid execution in use: tasks are tagged `[inline]` (main agent) or `[subagent]` (parallel subagent dispatch). No commits (user never asked; opencode rule: commit only when explicitly requested).

**Goal:** Give SoulHeart real Undertale/Deltarune battle variety (new bullet patterns, soul modes, per-enemy signatures, escalation, boss intros) and close out every audit finding from the Post-Plan-D audit.

**Architecture:** Extend the existing dict-driven pattern pipeline (`BulletPatterns.make` -> `Bullet.setup` -> `DodgeBox._process`). Add new behavior strings (weave/wall/beam_sweep/rain/bait/homing) + `delay` field + per-rule sprite tinting + orbit radius/speed params. Add soul modes to DodgeBox (red/blue/purple/green/yellow) driven by a per-enemy `soul_mode` field set at turn start. Wire battle.gd for boss intros, spare bullet-fade, turn escalation. Everything else is wiring (wisp->UI, credits, outline, style pass, housekeeping).

**Tech Stack:** Godot 4.4.1, GDScript, headless test runner `tools\run_tests.ps1` (-> `& .\tools\godot.exe --headless -s res://tests/run_all.gd`), `tools\verify_assets.py` asset gate, bundled godot at `tools\godot.exe`.

## Global Constraints

- Keep 640x480, GL Compatibility, DMT-Mono, `default_texture_filter=0` pixel look.
- All bullet dicts flow through `BulletPatterns.make(pattern: Dictionary, heart_pos: Vector2) -> Array[Dictionary]`; every dict key must be read defensively with `.get()` defaults.
- Pattern default origin stays `Vector2(317, 317)` (near new box center 320,305 — patterns stay centered).
- Game must stay connected to UT/DR core: soul modes and rules mirror UT (BLUE=stand still, ORANGE=keep moving, GRAY=no damage, GREEN=heal, white=damage, yellow=shootable).
- Existing test suite (67 files) must stay green; new behavior gets new tests in `tests/`.
- No `load_from_file("res://...")` — export-unsafe; use `load()` + `get_image()`.
- Rule tint colors (exact): BLUE `Color(0.35, 0.85, 1.0)`, ORANGE `Color(1.0, 0.6, 0.2)`, GRAY `Color(0.55, 0.55, 0.55)`, GREEN `Color(0.4, 1.0, 0.4)`, YELLOW `Color(1.0, 1.0, 0.3)`.
- Escalation multiplier: `minf(1.0 + 0.08 * float(maxi(_turn_count - 1, 0)), 1.6)`, applied to `vel` of non-orbit bullets only.
- Overworld typewriter = 8px pitch, battle = 16px (visual bible rule: 16/32 battle, 8/18 overworld).

---

## PHASE 1 — BUG FIXES `[inline]`

### Task 1: Fix the dead test assertion

**Files:**
- Modify: `tests/test_plan_d_integration.gd:12`
- Test: run full suite

- [ ] **Step 1: Fix the assertion** — replace
```gdscript
		TestHelper.is_true(GameState.flags.get("edit_event_" + id, false),
			"accept sets flag for " + id)
```
with (mirror the str() pattern at line 21)
```gdscript
		TestHelper.eq(str(GameState.flags.get("edit_event_" + id, "")), "accept",
			"accept sets flag for " + id)
```
- [ ] **Step 2: Run suite** — `tools\run_tests.ps1`; expected: all PASS, no new errors.

### Task 2: Font outline (UT black-outline look)

**Files:**
- Modify: `project.godot` `[gui]` section

- [ ] **Step 1:** append to `[gui]`:
```ini
theme/default_font_outline_size=2
theme/default_font_outline_color=Color(0,0,0,1)
```
- [ ] **Step 2:** run suite (font change only; must stay green).

### Task 3: Null guards in fade.gd + encounter.gd

**Files:**
- Modify: `scripts/autoload/fade.gd`
- Modify: `scripts/rooms/encounter.gd`

- [ ] **Step 1: fade.gd** — guard `_tween_alpha` and the public faders against a null rect / not-inside-tree:
```gdscript
func _tween_alpha(rect: ColorRect, target: float, dur: float, hold: float = 0.0) -> void:
	if rect == null or not is_inside_tree():
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	if is_equal_approx(rect.color.a, target) and hold <= 0.0:
		return
	_tween = create_tween()
	_tween.tween_property(rect, "color:a", target, dur)
	if hold > 0.0:
		_tween.tween_interval(hold)
		_tween.tween_property(rect, "color:a", 0.0, dur)
```
- [ ] **Step 2: encounter.gd `_show_bang`** — return early when tree unavailable:
```gdscript
func _show_bang() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	var label := Label.new()
	...
	var player := tree.get_first_node_in_group("player")
	if player:
		label.global_position = player.global_position + Vector2(6, -30)
	var scene := tree.current_scene
	if scene != null:
		scene.add_child(label)
	...
```
- [ ] **Step 3:** run suite; the two SCRIPT ERRORs must be gone from output.

### Task 4: Export-safe asset loading

**Files:**
- Modify: `scripts/tiles/tiles.gd:39-47` (`_atlas_texture`)
- Modify: `scripts/util/sprites.gd:308-309` (`player_frisk_texture`)
- Modify: `scripts/wisp/wisp.gd:83` (wisp_lit load)

- [ ] **Step 1: tiles.gd** — replace both `Image.load_from_file` calls with `load()`:
```gdscript
static func _atlas_texture(style: String) -> Texture2D:
	var img := Image.create(48, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var a := load("res://assets/sprites/tiles/%s_floor.png" % style) as Texture2D
	if a != null:
		img.blit_rect(a.get_image(), Rect2i(0, 0, 16, 16), Vector2i.ZERO)
	var b := load("res://assets/sprites/tiles/%s_floor_b.png" % style) as Texture2D
	if b != null:
		img.blit_rect(b.get_image(), Rect2i(0, 0, 16, 16), Vector2i(16, 0))
	return ImageTexture.create_from_image(img)
```
- [ ] **Step 2: sprites.gd** —
```gdscript
	if _frisk_sheet == null:
		var sheet_tex := load("res://assets/sprites/overworld/frisk_sheet.png") as Texture2D
		if sheet_tex == null:
			return ImageTexture.create_from_image(Image.create(19, 29, false, Image.FORMAT_RGBA8))
		_frisk_sheet = sheet_tex.get_image()
```
- [ ] **Step 3: wisp.gd** — same pattern (`load(...) as Texture2D` then `.get_image()`).
- [ ] **Step 4:** run suite; grep output for `load_from_file` warnings — none.

### Task 5: Housekeeping

**Files:**
- Delete: `scripts/battle/enemy_stats.gd`, `dialogue/index.dlg`, `dialogue/mourning_knight.dlg`, `dialogue/sample.dlg`, `assets/sprites/frisk.png.import`, `assets/sprites/overworld/echo_flower.png`, `assets/sprites/wisp/wisp_idle.png`, `assets/sprites/overworld/save_point.gif`, root `probe_*.txt`
- Modify: `scripts/main.gd:29` version string

- [ ] **Step 1:** grep first (`grep -r "enemy_stats\|index.dlg\|mourning_knight.dlg\|sample.dlg\|echo_flower\|wisp_idle\|save_point.gif\|napstablook" tests/ scripts/`) to confirm nothing references deleted files; if `napstablook` frames referenced anywhere, keep them.
- [ ] **Step 2:** delete the confirmed-dead files (keep `assets/sprites/enemies/frames/napstablook/` if present — harmless).
- [ ] **Step 3:** `main.gd:29` -> `version.text = "SOULHEART v1.0"`.
- [ ] **Step 4:** run suite; still green.

---

## PHASE 2 — BATTLE VARIETY CORE `[inline]`

### Task 6: Bullet rule tinting + delay field + orbit params + YELLOW rule

**Files:**
- Modify: `scripts/battle/bullet.gd`
- Modify: `scripts/battle/dodge_box.gd`
- Test: `tests/test_bullet_patterns.gd` (existing — extend) or new `tests/test_bullet_tint.gd`

- [ ] **Step 1: bullet.gd** — extend enum + fields + setup:
```gdscript
enum Rule { NONE, BLUE, ORANGE, GRAY, GREEN, YELLOW }
```
```gdscript
var delay := 0.0
var orbit_radius := 80.0
var orbit_speed := 2.0
```
in `setup()` after sprite creation:
```gdscript
	delay = float(d.get("delay", 0.0))
	orbit_radius = float(d.get("orbit_radius", 80.0))
	orbit_speed = float(d.get("orbit_speed", 2.0))
	_sprite.modulate = _tint_for(rule)
	if delay > 0.0:
		_sprite.visible = false
```
```gdscript
static func _tint_for(r: int) -> Color:
	match r:
		Bullet.Rule.BLUE:
			return Color(0.35, 0.85, 1.0)
		Bullet.Rule.ORANGE:
			return Color(1.0, 0.6, 0.2)
		Bullet.Rule.GRAY:
			return Color(0.55, 0.55, 0.55)
		Bullet.Rule.GREEN:
			return Color(0.4, 1.0, 0.4)
		Bullet.Rule.YELLOW:
			return Color(1.0, 1.0, 0.3)
	return Color(1, 1, 1)
```
- [ ] **Step 2: dodge_box.gd `_process` bullet loop** — delay gate before `b.phase += delta`:
```gdscript
	for b in bullets:
		if b.delay > 0.0:
			b.delay -= delta
			if b.delay <= 0.0:
				b._sprite.visible = true
			continue
		b.phase += delta
```
(Note: `b.life -= delta` stays inside the non-delay path — move it after the match, already there.)
- [ ] **Step 3: dodge_box.gd orbit behavior** — use per-bullet params:
```gdscript
			"orbit":
				b.position = b.orbit_center + Vector2.from_angle(b.phase * b.orbit_speed) * b.orbit_radius
```
- [ ] **Step 4:** add tests asserting: tint color per rule, `delay` hides sprite, orbit uses custom radius/speed. Run suite.

### Task 7: New pattern archetypes

**Files:**
- Modify: `scripts/battle/bullet_patterns.gd`
- Test: extend `tests/test_bullet_patterns.gd`

- [ ] **Step 1:** add to the `match` in `make()`:
```gdscript
		"weave":
			return _with_rule(_weave(count, speed, dir, origin), rule, base_type)
		"wall":
			return _with_rule(_wall(count, speed, origin, heart_pos), rule, base_type)
		"beam_sweep":
			return _with_rule(_beam_sweep(count, origin), rule, base_type)
		"rain":
			return _with_rule(_rain(count, speed, origin), rule, base_type)
		"bait":
			return _with_rule(_bait(count, speed, origin, heart_pos), rule, base_type)
		"homing":
			return _with_rule(_homing(count, speed, origin), rule, base_type)
		"green_heal":
			return _green_heal(count, speed, origin)
		"gray_pass":
			return _gray_pass(count, speed, origin, heart_pos)
```
- [ ] **Step 2:** add the generator funcs (exact code):
```gdscript
static func _weave(count: int, speed: float, direction: Vector2, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var side := Vector2(-direction.y, direction.x)
	for i in count:
		var pos := origin + side * (i - count / 2.0) * 22.0
		out.append({"pos": pos, "vel": direction * speed, "life": 6.0, "size": 3.0,
				"behavior": "sine", "phase": float(i) * PI})
	return out

static func _wall(count: int, speed: float, origin: Vector2, heart_pos: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var gap_y := heart_pos.y
	var start := origin.y - float(count) * 14.0
	for i in count:
		var y := start + i * 28.0
		if absf(y - gap_y) < 30.0:
			continue
		out.append({"pos": Vector2(origin.x - 340.0, y), "vel": Vector2(speed, 0.0),
				"life": 5.0, "size": 6.0, "type": Bullet.Type.BONE})
	return out

static func _beam_sweep(count: int, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		var radius := 10.0 + float(i) * 14.0
		out.append({"pos": origin, "vel": Vector2.ZERO, "life": 3.5, "size": 8.0,
				"type": Bullet.Type.LASER, "behavior": "orbit",
				"phase": 0.0, "orbit_center": origin,
				"orbit_radius": radius, "orbit_speed": 1.2})
	return out

static func _rain(count: int, speed: float, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		var x := randf_range(origin.x - 140.0, origin.x + 140.0)
		out.append({"pos": Vector2(x, origin.y - 170.0), "vel": Vector2(0.0, speed * 0.6),
				"life": 3.0, "size": 3.0, "behavior": "gravity",
				"delay": float(i) * 0.15})
	return out

static func _bait(count: int, speed: float, origin: Vector2, heart_pos: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var dir := (heart_pos - origin).normalized()
	for i in count:
		var t := -0.5 + float(i) / float(maxi(count - 1, 1))
		var vel := dir.rotated(deg_to_rad(14.0) * t) * speed
		out.append({"pos": origin, "vel": vel, "life": 4.0, "size": 3.0, "delay": 0.7})
	return out

static func _homing(count: int, speed: float, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		out.append({"pos": origin + Vector2((i - count / 2.0) * 30.0, -40.0),
				"vel": Vector2(0.0, speed), "life": 5.0, "size": 3.0, "behavior": "homing"})
	return out

static func _green_heal(count: int, speed: float, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		var angle := TAU * float(i) / float(count)
		var vel := Vector2.from_angle(angle) * speed
		out.append({"pos": origin, "vel": vel, "life": 4.0, "size": 4.0,
				"type": Bullet.Type.RING, "rule": Bullet.Rule.GREEN})
	return out

static func _gray_pass(count: int, speed: float, origin: Vector2, heart_pos: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var dir := (heart_pos - origin).normalized()
	for i in count:
		var t := -0.5 + float(i) / float(maxi(count - 1, 1))
		out.append({"pos": origin + Vector2(0.0, -60.0),
				"vel": dir.rotated(deg_to_rad(8.0) * t) * speed,
				"life": 5.0, "size": 3.0, "rule": Bullet.Rule.GRAY})
	return out
```
- [ ] **Step 3:** fix `_laser_sweep` vertical spread (old rows ran off-screen below the new box): center rows on origin:
```gdscript
static func _laser_sweep(count: int, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var start_y := origin.y - float(count - 1) * 45.0
	for i in count:
		out.append({"pos": Vector2(-40.0, start_y + i * 90.0), "vel": Vector2(180.0, 0.0),
				"life": 5.0, "size": 8.0})
	return out
```
- [ ] **Step 4:** tests — each new type returns expected count, stamps expected rule/type (green_heal -> GREEN+RING, gray_pass -> GRAY, wall -> BONE, beam_sweep -> LASER), bait has delay 0.7, rain has staggered delays. Run suite.

### Task 8: Turn escalation + per-enemy signature patterns + soul_mode assignments

**Files:**
- Modify: `scripts/battle/battle.gd`
- Modify: `scripts/battle/enemy_library.gd`

- [ ] **Step 1: battle.gd** — add `var _turn_count := 0`; at top of `_enemy_turn()`: `_turn_count += 1`. Replace the spawn call block:
```gdscript
		var mult := minf(1.0 + 0.08 * float(maxi(_turn_count - 1, 0)), 1.6)
		var bullets := BulletPatterns.make(pattern, _dodge_box.heart_position())
		if mult > 1.0:
			for d in bullets:
				if str(d.get("behavior", "straight")) != "orbit":
					d["vel"] = (d.get("vel", Vector2.ZERO) as Vector2) * mult
		_dodge_box.spawn_patterns(bullets)
```
- [ ] **Step 2: battle.gd** — set soul mode each enemy turn (before `set_active(true)`):
```gdscript
	_dodge_box.set_mode(str(_enemy.get("soul_mode", "red")))
```
and reset to red in `_enter_player_turn()`:
```gdscript
	_dodge_box.set_mode("red")
```
- [ ] **Step 3: enemy_library.gd** — append signature patterns to the listed enemies (add to each `"patterns"` array; keep existing entries):
  - froggit: `{"type": "weave", "count": 5, "speed": 80.0, "rule": Bullet.Rule.BLUE}`
  - whimsun: `{"type": "gray_pass", "count": 6, "speed": 50.0}`
  - moldsmal: `{"type": "rain", "count": 8, "speed": 70.0}`
  - loox: `{"type": "bait", "count": 4, "speed": 90.0, "telegraph": true}`
  - vegetoid: `{"type": "green_heal", "count": 6, "speed": 60.0}`
  - migosp: `{"type": "beam_sweep", "count": 10}`
  - reminisc: `{"type": "gray_pass", "count": 6, "speed": 45.0, "rule": Bullet.Rule.GRAY}`
  - hushroom: `{"type": "bait", "count": 5, "speed": 75.0, "telegraph": true}`
  - paneic: `{"type": "rain", "count": 10, "speed": 60.0}`
  - squish: `{"type": "wall", "count": 9, "speed": 80.0}`
  - sentimint: `{"type": "homing", "count": 5, "speed": 50.0}`
  - repeato: `{"type": "weave", "count": 6, "speed": 65.0, "rule": Bullet.Rule.ORANGE}`
  - toadally: `{"type": "green_heal", "count": 6, "speed": 55.0}`
  - punkin: `{"type": "wall", "count": 8, "speed": 75.0}`
  - nullaby: `{"type": "bait", "count": 3, "speed": 55.0, "telegraph": true}` + `"soul_mode": "blue"`
  - quibble: `{"type": "homing", "count": 4, "speed": 55.0}`
  - margin: `"soul_mode": "purple"` (rails = lines of a page)
  - lookey: `{"type": "gray_pass", "count": 8, "speed": 40.0, "rule": Bullet.Rule.GRAY}` + `"soul_mode": "green"`
  - remembran: `{"type": "beam_sweep", "count": 12}`
  - mourning_knight: add `{"type": "wall", "count": 10, "speed": 75.0, "rule": Bullet.Rule.BLUE}` and `{"type": "bait", "count": 6, "speed": 80.0, "telegraph": true}`
  - index form f1 (both top-level and forms[0]): add `{"type": "homing", "count": 6, "speed": 60.0}`
  - index form f2 (forms[1]): add `{"type": "rain", "count": 12, "speed": 80.0}` + `"soul_mode": "yellow"` (it edits bullets out of existence)
  - index form f3 (forms[2]): add `{"type": "beam_sweep", "count": 14}`
  - canon_true: add `{"type": "rain", "count": 14, "speed": 90.0}` and `{"type": "wall", "count": 12, "speed": 85.0, "rule": Bullet.Rule.ORANGE}`
  IMPORTANT: `EnemyLibrary.apply_form` copies only keys in its list — add `"soul_mode"` to that list (`["name", "hp", "def", "spare_after", "acts", "attack_lines", "patterns", "intro_line", "sprite_id", "soul_mode"]`).
- [ ] **Step 4:** test — `EnemyLibrary.get_enemy("migosp")["patterns"].size() == 3`, `get_enemy("nullaby")["soul_mode"] == "blue"`, `get_enemy("margin")["soul_mode"] == "purple"`, apply_form copies soul_mode. Run suite.

### Task 9: Soul modes in DodgeBox (blue/purple/green/yellow)

**Files:**
- Modify: `scripts/battle/dodge_box.gd`
- Test: new `tests/test_soul_modes.gd`

- [ ] **Step 1:** add state + constants:
```gdscript
const GRAVITY := 900.0
const JUMP_VEL := -330.0
const RAIL_COUNT := 4
const YELLOW_FIRE_CD := 0.35

var mode := "red"
var _soul_vel := Vector2.ZERO
var _rail_index := 2
var _shield_dir := Vector2.UP
var _yellow_cd := 0.0
var _shots: Array = []
```
- [ ] **Step 2:** `set_mode(m: String)`:
```gdscript
func set_mode(m: String) -> void:
	mode = m
	heart.texture = Sprites.soul_texture(m.capitalize())
	_soul_vel = Vector2.ZERO
	heart.rotation = PI if m == "yellow" else 0.0
	if m == "purple":
		_rail_index = clampi(_rail_index, 0, RAIL_COUNT - 1)
		heart.position.y = _rail_y(_rail_index)
	elif m == "green":
		heart.position = HEART_START
	elif m == "red" or m == "blue":
		heart.position.y = BOX_INNER.end.y - 4.0 if m == "blue" else HEART_START.y
```
```gdscript
func _rail_y(i: int) -> float:
	var inset := 24.0
	var span := BOX_INNER.size.y - inset * 2.0
	return BOX_INNER.position.y + inset + span * float(i) / float(RAIL_COUNT - 1)
```
- [ ] **Step 3:** replace the movement block in `_process` (the `var input := ...` … `last_heart_pos = heart.position` lines) with:
```gdscript
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	match mode:
		"blue":
			_soul_vel.y += GRAVITY * delta
			if Input.is_action_just_pressed("confirm") and heart.position.y >= BOX_INNER.end.y - 6.0:
				_soul_vel.y = JUMP_VEL
			heart.position.x = clampf(heart.position.x + input.x * HEART_SPEED * 0.8 * delta,
					BOX_INNER.position.x, BOX_INNER.end.x)
			heart.position.y = clampf(heart.position.y + _soul_vel.y * delta,
					BOX_INNER.position.y, BOX_INNER.end.y - 4.0)
			if heart.position.y >= BOX_INNER.end.y - 4.0:
				_soul_vel.y = 0.0
		"purple":
			if Input.is_action_just_pressed("move_up") and _rail_index > 0:
				_rail_index -= 1
			elif Input.is_action_just_pressed("move_down") and _rail_index < RAIL_COUNT - 1:
				_rail_index += 1
			heart.position.y = move_toward(heart.position.y, _rail_y(_rail_index), 260.0 * delta)
			heart.position.x = clampf(heart.position.x + input.x * HEART_SPEED * delta,
					BOX_INNER.position.x, BOX_INNER.end.x)
		"green":
			if Input.is_action_just_pressed("confirm"):
				_shield_dir = _cycle_dir(_shield_dir)
		"yellow":
			heart.position = CombatMath.clamp_to_box(heart.position + input * HEART_SPEED * delta, BOX_INNER)
			_yellow_cd -= delta
			if Input.is_action_just_pressed("confirm") and _yellow_cd <= 0.0:
				_fire_yellow()
		_:
			heart.position = CombatMath.clamp_to_box(heart.position + input * HEART_SPEED * delta, BOX_INNER)
	var heart_vel := (heart.position - last_heart_pos) / delta
	last_heart_pos = heart.position
```
```gdscript
func _cycle_dir(d: Vector2) -> Vector2:
	if d == Vector2.UP: return Vector2.DOWN
	if d == Vector2.DOWN: return Vector2.LEFT
	if d == Vector2.LEFT: return Vector2.RIGHT
	return Vector2.UP

func _fire_yellow() -> void:
	_yellow_cd = YELLOW_FIRE_CD
	var b := Bullet.new()
	b.setup({"pos": heart.position,
			"vel": (Vector2(216, 136) - heart.position).normalized() * 380.0,
			"life": 1.2, "size": 3.0, "type": Bullet.Type.PELLET, "rule": Bullet.Rule.YELLOW})
	add_child(b)
	_shots.append(b)
```
- [ ] **Step 4:** collision loop — skip player shots; block via green shield; yellow shots destroy enemy bullets:
in the hit loop, before the circle_hit check add:
```gdscript
		if mode == "green":
			var to_b := (b.position - heart.position)
			if to_b.length() > 0.0 and (to_b / to_b.length()).dot(_shield_dir) > 0.7:
				b.life = 0.0
				continue
```
and after the hit loop add yellow shot cleanup:
```gdscript
	var keep_shots: Array = []
	for s in _shots:
		var hit_target: Bullet = null
		for b in bullets:
			if not b.dead() and CombatMath.circle_hit(s.position, 3.0, b.position, b.size):
				hit_target = b
				break
		if hit_target != null:
			hit_target.life = 0.0
			s.queue_free()
			Audio.play_sfx("whoosh")
		elif BOX_RECT.grow(4.0).has_point(s.position):
			keep_shots.append(s)
		else:
			s.queue_free()
	_shots = keep_shots
```
- [ ] **Step 5:** `_remove_dead` unchanged (bullets only). `_clear_bullets` also clears `_shots`:
```gdscript
func _clear_bullets() -> void:
	for b in bullets:
		b.queue_free()
	bullets = []
	for s in _shots:
		s.queue_free()
	_shots = []
```
- [ ] **Step 6:** add `fade_out_bullets()` (used by spare):
```gdscript
func fade_out_bullets() -> void:
	for b in bullets:
		var tw := create_tween()
		tw.tween_property(b, "modulate:a", 0.0, 0.4)
		tw.tween_callback(b.queue_free)
	bullets = []
	for s in _shots:
		s.queue_free()
	_shots = []
```
- [ ] **Step 7:** tests: set_mode changes texture path (blue/purple/green/yellow don't fall back to Red — needs the generated sprites from Task 10, so run Task 10 first), rail positions ordered, green shield blocks from shield dir, yellow shot spawns and destroys a pellet. Run suite.

### Task 10: Purple + Yellow soul sprites (gen script)

**Files:**
- Create: `tools/gen_soul_sprites.gd`
- Modify: `scripts/util/sprites.gd` (nothing — cache fallback fine once files exist)

- [ ] **Step 1:** create `tools/gen_soul_sprites.gd` (run via `& .\tools\godot.exe --headless -s res://tools/gen_soul_sprites.gd`):
```gdscript
extends SceneTree

func _init() -> void:
	for color in ["Purple", "Yellow"]:
		var src := Image.load_from_file("res://assets/sprites/Red_SOUL_sprite.png")
		var tint := Color(0.72, 0.35, 0.9) if color == "Purple" else Color(1.0, 0.9, 0.2)
		for y in src.get_height():
			for x in src.get_width():
				var px := src.get_pixel(x, y)
				if px.a > 0.0:
					var lum := px.r * 0.299 + px.g * 0.587 + px.b * 0.114
					var f := lum / maxf(px.r + px.g + px.b, 0.001)
					src.set_pixel(x, y, Color(tint.r * f, tint.g * f, tint.b * f, px.a))
		src.save_png("res://assets/sprites/%s_SOUL_sprite.png" % color)
		print("wrote %s_SOUL_sprite.png" % color)
	quit()
```
- [ ] **Step 2:** run it; confirm both PNGs exist; `soul_texture("Purple")` and `("Yellow")` return non-red textures (test in `tests/test_sprites.gd`). Run suite.

### Task 11: Spare stops bullets + boss intro

**Files:**
- Modify: `scripts/battle/battle.gd`

- [ ] **Step 1: spare path** — in `_resolve_submenu` MERCY/Spare success branch, before `_say`:
```gdscript
				if _mood >= int(_enemy["spare_after"]):
					_state.transition(BattleState.Phase.SPARED)
					GameState.add_spare()
					_dodge_box.fade_out_bullets()
					await get_tree().create_timer(0.5).timeout
					await _say([{"speaker": "", "text": "You spare %s. It settles, grateful." % _enemy["name"]}])
					_end_battle()
					return
```
- [ ] **Step 2: boss intro** — in `_ready()`, after `_spawn_enemy_sprite()` and `_enemy_sprite.position = Vector2(216, -40)`, insert:
```gdscript
	if bool(_enemy.get("boss", false)):
		await _show_boss_intro()
```
and add:
```gdscript
func _show_boss_intro() -> void:
	var tree := get_tree()
	if tree == null:
		return
	Fade.fade_to_black(0.4)
	await tree.create_timer(0.45).timeout
	if not is_inside_tree():
		return
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	var label := Label.new()
	label.text = "THE %s" % str(_enemy["name"]).to_upper()
	label.add_theme_font_size_override("font_size", 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(640, 40)
	label.position = Vector2(0, 220)
	layer.add_child(label)
	await tree.create_timer(1.1).timeout
	layer.queue_free()
	Fade.fade_from_black(0.4)
	await tree.create_timer(0.45).timeout
```
- [ ] **Step 3:** tests: boss intro helper exists (text format), spare path calls fade_out (hard to unit-test; assert `fade_out_bullets` empties bullets array on a spawned pattern). Run suite.

---

## PHASE 3 — SUBAGENT TASKS (parallel dispatch)

### Task 12 `[subagent]`: Boss Check acts + hurt frames + asset gate

**Files:**
- Modify: `scripts/battle/enemy_library.gd` (add Check acts to mourning_knight, index top-level + 3 forms, canon_true)
- Create: `tools/gen_hurt_frames.gd`
- Modify: `tools/gen_boss_sprites.gd` (opaque black fill first so corner pixel is (0,0,0,255))
- Test: `tools\verify_assets.py` must PASS; suite green

**Check act texts (exact):**
- mourning_knight: `* MOURNING KNIGHT - ATK 5 DEF 2. The armor remembers someone. It is waiting to be remembered back.`
- index f1 (top-level `index` + `forms[0]`): `* THE INDEX - ATK 7 DEF 3. It crosses out what it cannot carry.`
- index f2 (`forms[1]`): `* THE INDEX - ATK 7 DEF 4. It edits what was, so that what is might stay.`
- index f3 (`forms[2]`): `* THE INDEX - ATK 7 DEF 5. It offers you the final page, blank and patient.`
- canon_true: `* CANON - ATK 9 DEF 6. The shape of what was. It is not unkind, merely certain.`
All with `"id": "check", "label": "* Check", "mood": 0` (check is mood-0; battle.gd shows the text automatically).

**Hurt frames:** `gen_hurt_frames.gd` (extends SceneTree, `_init`): for each id in `["mourning_knight", "index_f1", "index_f2", "index_f3", "canon_true", "moldsmal"]` load `res://assets/sprites/enemies/frames/<id>/<id>_000.png`, for every pixel with `a > 0.0` lerp toward white 60% (`px.lerp(Color(1,1,1,px.a), 0.6)`), `save_png("res://assets/sprites/enemies/<id>_hurt.png")`. Run with `& .\tools\godot.exe --headless -s res://tools/gen_hurt_frames.gd`.

**Boss frame gate:** in `gen_boss_sprites.gd`, `img.fill(Color(0, 0, 0, 1))` before drawing art (opaque black bg), regenerate the 5 boss frames, then `python tools\verify_assets.py` must pass.

**Report back:** files created, verify_assets.py output, suite result.

### Task 13 `[subagent]`: Route wisp dialogue to screen

**Files:**
- Modify: `scripts/dialogue/dialogue_ui.gd` (add helper)
- Modify: `scripts/rooms/canon.gd`, `scripts/rooms/cracks.gd`, `scripts/rooms/echo.gd`, `scripts/rooms/drizzle_fields.gd`, `scripts/rooms/grumble_woods.gd`, `scripts/rooms/hometown.gd`, `scripts/wisp/wisp.gd`

**Exact change:** add to `dialogue_ui.gd`:
```gdscript
func open_wisp(text: String) -> void:
	var parts := text.split(": ", false, 1) if text.contains(": ") else ["", text]
	open([{"speaker": parts[0], "text": parts[1]}], false)
```
In each room script: replace `print(WispDialogue.get_line("<ctx>"))` with a `_wisp("<ctx>")` call and add:
```gdscript
func _wisp(context: String) -> void:
	if not is_instance_valid(_wisp_ui):
		_wisp_ui = load("res://scripts/dialogue/dialogue_ui.gd").new()
		add_child(_wisp_ui)
	_wisp_ui.open_wisp(WispDialogue.get_line(context))
	await _wisp_ui.finished
```
plus `var _wisp_ui: Node` member. In `scripts/wisp/wisp.gd:90` (hum_ready): same pattern — instantiate UI, `open_wisp(WispDialogue.get_line("hum_ready"))`, await finished. Keep all `Audio` hum sfx behavior untouched. `print()` calls removed.

**Report back:** list of 7 sites changed, suite result.

### Task 14 `[subagent]`: Credits + THE END

**Files:**
- Modify: `scripts/world/ending.gd` (`play_ending`)

**Exact change:** after `await ui.finished` / `ui.queue_free()` / hollow wipe, insert:
```gdscript
	if not is_instance_valid(current) or not current.is_inside_tree():
		return
	Fade.fade_to_black(0.4)
	await tree.create_timer(0.5).timeout
	if not is_instance_valid(current) or not current.is_inside_tree():
		return
	Audio.play_music("credits")
	var credits := load("res://scripts/dialogue/dialogue_ui.gd").new()
	credits.layer = 10
	current.add_child(credits)
	credits.open(credits_lines())
	await credits.finished
	credits.queue_free()
	var layer := CanvasLayer.new()
	layer.layer = 50
	current.add_child(layer)
	var end_label := Label.new()
	end_label.text = "THE END"
	end_label.add_theme_font_size_override("font_size", 32)
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_label.size = Vector2(640, 40)
	end_label.position = Vector2(0, 220)
	layer.add_child(end_label)
	await tree.create_timer(2.0).timeout
	tree.change_scene_to_file(MAIN_SCENE)
```
(replacing the final `tree.change_scene_to_file(MAIN_SCENE)`).

**Report back:** diff summary, suite result.

### Task 15 `[subagent]`: Ending door transitions

**Files:**
- Modify: `scripts/world/ending_door.gd`

**Exact change:** keeper path — replace lines 27-33 with:
```gdscript
	if door_id == "keeper":
		Ending.flag_keeper_battle(str(GameState.flags.get("current_room", "")))
		Audio.play_sfx("door_seal")
		Fade.fade_to_black(0.67)
		await get_tree().create_timer(0.8).timeout
		if not is_inside_tree():
			return
		_show_banner("You step through.")
		await get_tree().create_timer(1.0).timeout
		if get_tree() != null:
			get_tree().change_scene_to_file("res://scenes/Battle.tscn")
		return
```
non-keeper path — before `await Ending.play_ending(...)` add `_show_banner("You step through.")` + `await get_tree().create_timer(0.9).timeout`.

**Report back:** diff summary, suite result.

### Task 16 `[subagent]`: Edit event decoration sprites

**Files:**
- Create: `tools/gen_edit_decos.gd`
- Modify: `scripts/world/edit_event.gd` (`_deco_texture`)

**Exact change:** `gen_edit_decos.gd` (extends SceneTree, `_init`): generate 6 sprites as 16x16 pixel art, opaque-black-free (transparent bg), save to `res://assets/sprites/overworld/edits/<id>.png`:
- `shelf_book`: brown book (fill `Color(0.55,0.35,0.18)` rect 3,6..12,12 + white pages 4..11 y7..11 + dark spine x7)
- `wall_window`: blue-ish window (frame white 1px rect, fill `Color(0.35,0.55,0.8)` 3..12, cross bar)
- `door_moves`: white door rect 5..10 x 3..13 + yellow knob
- `name_changes`: text glyph — 8 white pixels in a name-tag rect `Color(0.9,0.9,0.7)` + 3 dark dots
- `portrait`: small face — skin rect + 2 dark eyes + hair
- `floor_crack`: dark jagged line (set pixels along an offset polyline `Color(0.05,0.05,0.05)`)
All drawn with direct `img.set_pixel` loops; `save_png`; print each path.
`_deco_texture(id)` in edit_event.gd: replace the colored-square branch with:
```gdscript
	var tex := load("res://assets/sprites/overworld/edits/%s.png" % id) as Texture2D
	if tex != null:
		return tex
	# fallback: keep existing flat colored square
```

**Report back:** files generated, suite result (test_sprites must stay green).

---

## PHASE 4 — STYLE PASS `[inline]`

### Task 17: Dodge box geometry + slide-in, damage digits fall, player speed, enemy HP bar

**Files:**
- Modify: `scripts/battle/dodge_box.gd` (constants + slide-in in `set_active`)
- Modify: `scripts/battle/battle.gd` (damage digit direction, enemy HP bar width, `_enemy_turn` slide-in await)

- [ ] **Step 1: dodge_box.gd constants** — UT-authentic near-full-width lower board:
```gdscript
const BOX_RECT := Rect2(35, 235, 570, 140)
const BOX_INNER := Rect2(40, 240, 560, 130)
const HEART_START := Vector2(320, 305)
```
(pattern origin 317,317 stays; `_laser_sweep` already re-centered in Task 7.)
- [ ] **Step 2: slide-in** — in `set_active(a)`:
```gdscript
func set_active(a: bool) -> void:
	active = a
	visible = a
	if a:
		position = Vector2(0, 300)
		var tw := create_tween()
		tw.tween_property(self, "position", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		position = Vector2.ZERO
		_clear_bullets()
```
- [ ] **Step 3: battle.gd damage digits** — `digit.position.y - 12.0` -> `digit.position.y + 12.0` (digits sink, like UT).
- [ ] **Step 4: enemy HP bar scales to sprite width** — in `_ready` after `_enemy_max_hp = ...`:
```gdscript
	var bar_w := clampf(_enemy_sprite.texture.get_width() * 0.8, 16.0, 60.0)
	_hp_bar.size.x = bar_w
	_hp_bar_bg.size.x = bar_w + 2.0
```
and in `_process` replace `_hp_bar.size.x = 16.0 * (...)` with `_hp_bar.size.x = _hp_bar_bg.size.x - 2.0 ...` — i.e. keep the ratio line but use stored width: add `var _hp_bar_w := 16.0` member set in `_ready`; use `_hp_bar.size.x = _hp_bar_w * (_enemy_hp_display / float(_enemy_max_hp))`.
- [ ] **Step 5:** run suite (geometry-only changes; visual check deferred to run-game).

### Task 18: Overworld font 8px (dialogue, banners, choice menus)

**Files:**
- Modify: `scripts/dialogue/dialogue_ui.gd` (overworld font sizes + label geometry)
- Modify: `scripts/rooms/save_point.gd` (banner fonts)
- Modify: `scripts/world/choice_menu.gd` (fonts)

- [ ] **Step 1: dialogue_ui.gd** — in `open()`, when `battle == false`, apply 8px:
```gdscript
	var fs := 16 if battle else 8
	_speaker_label.add_theme_font_size_override("font_size", fs)
	_label.add_theme_font_size_override("font_size", fs)
```
and shrink overworld inset: keep `inset := 20 if battle else 12`; speaker/body positions already computed from box — fine.
- [ ] **Step 2: save_point.gd** — banner label `font_size` 16 -> 8, `position` adjust (y-4); keep panel size.
- [ ] **Step 3: choice_menu.gd** — labels 14/18 -> 8/8 (or 8 prompt / 8 options), positions re-centered.
- [ ] **Step 4:** run suite.

### Task 19: README + final version

**Files:**
- Modify: `README.md`, `scripts/main.gd:29`

- [ ] **Step 1:** README — add sections: areas (Echo, Grumble Woods, Drizzle Fields, Hometown, Cracks, The Canon), the three endings + how to reach each (Keeper = refuse 4 edits, Hollow = accept all 6, Wanderer = always), Wisp hum control (hold the hum key — check wisp.gd input action name, likely `hum`), edit events note.
- [ ] **Step 2:** ensure `main.gd` version label reads `SOULHEART v1.0`.

---

## PHASE 5 — VERIFICATION `[inline]`

### Task 20: Full verification + export

- [ ] **Step 1:** `tools\run_tests.ps1` — all PASS, zero SCRIPT ERRORs.
- [ ] **Step 2:** `python tools\verify_assets.py` — PASS.
- [ ] **Step 3:** grep for `load_from_file` in scripts/ — none.
- [ ] **Step 4:** boot check: `& .\tools\godot.exe --headless --quit-after 120 .` (headless smoke) then export: `& .\tools\godot.exe --headless --export-release "Windows Desktop" dist\SoulHeart.exe` (preset name from `export_presets.cfg`), verify `dist\SoulHeart.exe` exists and boots.
- [ ] **Step 5:** delete `dist\SoulHeart_v1.0.zip` and re-zip the new build (keep same naming).
- [ ] **Step 6:** final report to LO: everything shipped, test/asset/export evidence.

## Self-Review

- **Spec coverage:** every audit item A1-A17 (A2 outline Task 2, A4 soul modes Task 9, A5 boss intro Task 11, A6 boss checks Task 12, A12 credits Task 14, A14 door transitions Task 15, A17 slide-in Task 17), B1-B11 (B1 wisp Task 13, B2 test Task 1, B3 hurt frames Task 12, B4-B6 housekeeping Task 5, B7 Task 3, B8 Task 12, B10 Task 4), C2 edit decos Task 16, C4-C5 Tasks 14-15, D1 Task 18, D3/D5/D6/D7 Tasks 17+4, D8 Task 19; battle variety (LO's core ask) Tasks 6-11. A1/A3/A8/A15 (name entry, title menu, shops, checkables) deferred — noted for a future Plan F.
- **Placeholder scan:** no TBDs; every subagent task carries complete code.
- **Type consistency:** `set_mode(String)`, `fade_out_bullets()`, `open_wisp(String)`, `_wisp(String)`, `orbit_radius/orbit_speed` float fields, `delay` float field — consistent across tasks.
