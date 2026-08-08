# Battle Authenticity (Soul, Bullets, SFX, Frame) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make SoulHeart's battle look and feel like authentic Undertale: ripped heart soul, varied bullet types with real colored mechanics (blue/orange/gray/green + red "!" telegraphs), attack sound effects, and the measured 315x170 battle frame with authentic HP bar and FIGHT buttons.

**Architecture:** Ripped sprites (verified URLs, undertale.wiki) land in `assets/sprites/` and are loaded at runtime via `Sprites` helpers; bullets become typed (`Bullet.Type` + `Bullet.Rule`) with per-type procedural pixel textures and per-behavior motion (straight/sine/homing/gravity/orbit); `bullet_patterns.gd` gains 7 new patterns and compound waves; `gen_sfx.gd` synthesizes 7 new attack sounds; `dodge_box.gd`/`battle.gd` get the authentic frame, HP bar and button sprites.

**Tech Stack:** Godot 4.4 (tools/godot.exe, headless tests), GDScript 2.0 (explicit types), procedurally generated WAV via gen_sfx.gd, PNG/GIF imports via Godot's importer.

## Global Constraints

- Working tree: create an isolated worktree first via superpowers:using-git-worktrees (branch `undertale-battle`) from repo `C:\Users\Admin\Downloads\SoulHeart`.
- Suite command (run from repo root): `cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers\battle1.txt 2>&1 & echo DONE"` then read `.superpowers\battle1.txt`.
- Gate: ALL TESTS PASSED, zero SCRIPT ERROR, zero FAIL, and only permitted stderr (`Dialogue file not found nope.dlg` + exit-time RID/resource leak lines). Never commit on red.
- All GDScript must use explicit types on every `var`/parameter/return.
- Tests: files in `tests/`, classes `extends RefCounted`, methods named `test_*` — auto-discovered by `res://tests/run_all.gd`.
- Assets are fetched with PowerShell `Invoke-WebRequest` + browser UA and COMMITTED to the repo (verified URLs below — do not substitute TSR, it returns 403).
- Keep existing tests green (test_tiles.gd, test_sprites.gd, test_bullet patterns, etc.). Where behavior intentionally changes (e.g. heart texture), update the affected test in the same task.
- Export preset "Windows Desktop" exists (export_presets.cfg). Final deliverable `dist\SoulHeart.exe` must boot `--headless --quit-after 60` with ExitCode 0 and be > 95 MB.

---
### Task 1: Fetch and commit ripped assets

**Files:**
- Create: `assets/sprites/Red_SOUL_sprite.png`, `Blue_SOUL_sprite.png`, `Light_blue_SOUL_sprite.png`, `Orange_SOUL_sprite.png`, `Green_SOUL_sprite.png`, `FIGHT_sprite_button.png`, `ACT_sprite_button.png`, `ITEM_sprite_button.png`, `MERCY_sprite_button.png`

**Interfaces:**
- Produces: 9 committed asset files (verified working URLs). Later tasks reference these exact paths.

- [ ] **Step 1: Create the assets directory and download**

```powershell
New-Item -ItemType Directory -Path assets\sprites -Force | Out-Null
$ProgressPreference = 'SilentlyContinue'
$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
$urls = @{
  "Red_SOUL_sprite.png"            = "https://undertale.wiki/images/Red_SOUL_sprite.png"
  "Blue_SOUL_sprite.png"           = "https://undertale.wiki/images/Blue_SOUL_sprite.png"
  "Light_blue_SOUL_sprite.png"     = "https://undertale.wiki/images/Light_blue_SOUL_sprite.png"
  "Orange_SOUL_sprite.png"         = "https://undertale.wiki/images/Orange_SOUL_sprite.png"
  "Green_SOUL_sprite.png"          = "https://undertale.wiki/images/Green_SOUL_sprite.png"
  "FIGHT_sprite_button.png"        = "https://undertale.wiki/images/FIGHT_sprite_button.png"
  "ACT_sprite_button.png"          = "https://undertale.wiki/images/ACT_sprite_button.png"
  "ITEM_sprite_button.png"         = "https://undertale.wiki/images/ITEM_sprite_button.png"
  "MERCY_sprite_button.png"        = "https://undertale.wiki/images/MERCY_sprite_button.png"
}
foreach ($k in $urls.Keys) {
  Invoke-WebRequest -Uri $urls[$k] -OutFile "assets\sprites\$k" -UserAgent $ua -TimeoutSec 30
}
Get-ChildItem assets\sprites | Select-Object Name, Length
```
Expected: 9 files; souls 121 B each (16x16), buttons 248 B each (110x42).

- [ ] **Step 2: Verify dimensions with a test**

Create `tests/test_assets.gd`:
```gdscript
extends RefCounted

func test_soul_sprites_exist() -> void:
	for f in ["Red_SOUL_sprite.png", "Blue_SOUL_sprite.png", "Green_SOUL_sprite.png",
			"Light_blue_SOUL_sprite.png", "Orange_SOUL_sprite.png"]:
		var img := Image.load_from_file("res://assets/sprites/" + f)
		TestHelper.is_true(img != null, "soul asset loads: " + f)
		if img == null:
			continue
		TestHelper.is_equal_to(img.get_width(), 16, "soul width 16: " + f)
		TestHelper.is_equal_to(img.get_height(), 16, "soul height 16: " + f)

func test_button_sprites_exist() -> void:
	for f in ["FIGHT_sprite_button.png", "ACT_sprite_button.png",
			"ITEM_sprite_button.png", "MERCY_sprite_button.png"]:
		var img := Image.load_from_file("res://assets/sprites/" + f)
		TestHelper.is_true(img != null, "button asset loads: " + f)
		if img == null:
			continue
		TestHelper.is_equal_to(img.get_width(), 110, "button width 110: " + f)
		TestHelper.is_equal_to(img.get_height(), 42, "button height 42: " + f)
```
Note: `TestHelper` is a global helper the suite exposes (used by existing tests).

- [ ] **Step 3: Run the suite — verify the new tests fail**

Run the suite command from the Global Constraints. Expected: tests/test_assets.gd FAIL entries (load_from_file returns null before the PNGs are imported by Godot — run the import first if needed: `tools\godot.exe --headless --import` once, then re-run).

- [ ] **Step 4: Import and re-run**

```powershell
tools\godot.exe --headless --import
```
Then re-run the suite. Expected: tests/test_assets.gd PASS (all 18 assertions). Full suite green.

- [ ] **Step 5: Commit**

```bash
git add assets/sprites tests/test_assets.gd
git commit -m "assets: add undertale soul + fight button sprites"
```

---
### Task 2: Heart soul — use the ripped Red SOUL sprite

**Files:**
- Modify: `scripts/util/sprites.gd` (heart_texture → soul_texture)
- Modify: `scripts/battle/dodge_box.gd:30-33` (use soul_texture)
- Test: `tests/test_sprites.gd`

**Interfaces:**
- Consumes: `assets/sprites/Red_SOUL_sprite.png` (Task 1).
- Produces: `Sprites.soul_texture(color_name: String) -> Texture2D` — loads `res://assets/sprites/<color>_SOUL_sprite.png` with cache; falls back to Red. `dodge_box.gd` heart and `battle.gd` menu cursor use it.

- [ ] **Step 1: Write the failing test** (append to `tests/test_sprites.gd`)

```gdscript
func test_soul_texture_is_ripped_heart() -> void:
	var tex := Sprites.soul_texture("Red")
	TestHelper.is_true(tex != null, "soul texture loads")
	var img := tex.get_image()
	TestHelper.is_equal_to(img.get_width(), 16, "soul is 16px wide")
	TestHelper.is_equal_to(img.get_height(), 16, "soul is 16px tall")
	TestHelper.is_true(img.get_pixel(8, 4).r > 0.9, "heart body is bright red at (8,4)")
	TestHelper.is_true(img.get_pixel(3, 0).a < 0.1, "corner (3,0) is transparent (lobe notch)")

func test_soul_texture_fallback() -> void:
	var tex := Sprites.soul_texture("Nonexistent")
	TestHelper.is_true(tex != null, "fallback loads red soul")
```

- [ ] **Step 2: Run — verify fail**

Run the suite. Expected: FAIL — `soul_texture` does not exist (SCRIPT ERROR or "not found").

- [ ] **Step 3: Implement**

In `scripts/util/sprites.gd`, replace `heart_texture()` with:
```gdscript
static var _soul_cache := {}

static func soul_texture(color_name: String) -> Texture2D:
	if _soul_cache.has(color_name):
		return _soul_cache[color_name]
	var path := "res://assets/sprites/" + color_name + "_SOUL_sprite.png"
	var tex := load(path) as Texture2D
	if tex == null:
		tex = load("res://assets/sprites/Red_SOUL_sprite.png") as Texture2D
	_soul_cache[color_name] = tex
	return tex
```
(Keep `_atlas_texture` and tile helpers untouched. If any other caller used `heart_texture()`, search and update: `grep -rn "heart_texture" scripts tests` — only dodge_box.gd and battle.gd cursor should reference it.)

- [ ] **Step 4: Update consumers**

In `scripts/battle/dodge_box.gd:30-33`:
```gdscript
heart = Sprite2D.new()
heart.texture = Sprites.soul_texture("Red")
heart.position = HEART_START
add_child(heart)
```
In `scripts/battle/battle.gd` (menu cursor creation, ~line 154):
```gdscript
cursor.texture = Sprites.soul_texture("Red")
```

- [ ] **Step 5: Run suite — verify pass**

Expected: ALL TESTS PASSED; zero SCRIPT ERROR.

- [ ] **Step 6: Commit**

```bash
git add scripts/util/sprites.gd scripts/battle/dodge_box.gd scripts/battle/battle.gd tests/test_sprites.gd
git commit -m "feat: ripped red soul heart replaces procedural block"
```

---
### Task 3: Typed bullets — shapes, rules, and motions

**Files:**
- Modify: `scripts/battle/bullet.gd` (full rewrite)
- Modify: `scripts/util/sprites.gd` (add bullet textures per type)
- Modify: `scripts/battle/dodge_box.gd:58-60` (motion per behavior)
- Test: `tests/test_bullet.gd` (new)

**Interfaces:**
- Consumes: existing `Sprites` static helpers; existing `BulletPatterns.make`.
- Produces: `Bullet.Type` enum {PELLET, BONE, SPEAR, RING, LASER, ARROW}; `Bullet.Rule` enum {NONE, BLUE, ORANGE, GRAY, GREEN}; `setup(d: Dictionary)` reads keys: pos, vel, life, size, type, rule, behavior, phase, orbit_center; `Sprites.bullet_texture_for(t: int) -> Texture2D`; `Sprites.bone_texture()`, `Sprites.spear_texture()`, `Sprites.laser_texture()`, `Sprites.arrow_texture()`, `Sprites.ring_texture()`.

- [ ] **Step 1: Write the failing test** — `tests/test_bullet.gd`:

```gdscript
extends RefCounted

func test_bullet_textures_are_distinct() -> void:
	var seen := {}
	for t in [0, 1, 2, 3, 4, 5]:
		var tex := Sprites.bullet_texture_for(t)
		TestHelper.is_true(tex != null, "bullet texture exists for type " + str(t))
		if tex == null:
			continue
		seen[tex.get_image().get_data().hash()] = true
	TestHelper.is_equal_to(seen.size(), 6, "six distinct bullet textures")

func test_setup_reads_type_and_rule() -> void:
	var b := Bullet.new()
	b.setup({"pos": Vector2(10, 10), "vel": Vector2(0, 100), "life": 3.0,
			"size": 4.0, "type": Bullet.Type.BONE, "rule": Bullet.Rule.BLUE,
			"behavior": "sine", "phase": 1.0, "orbit_center": Vector2(100, 100)})
	TestHelper.is_equal_to(b.btype, Bullet.Type.BONE, "type parsed")
	TestHelper.is_equal_to(b.rule, Bullet.Rule.BLUE, "rule parsed")
	TestHelper.is_equal_to(b.behavior, "sine", "behavior parsed")
	TestHelper.is_equal_to(b.position, Vector2(10, 10), "position set")
	b.free()
```

- [ ] **Step 2: Run — verify fail** (missing enums/methods).

- [ ] **Step 3: Implement `bullet.gd`** (full file):

```gdscript
class_name Bullet
extends Node2D

enum Type { PELLET, BONE, SPEAR, RING, LASER, ARROW }
enum Rule { NONE, BLUE, ORANGE, GRAY, GREEN }

var vel := Vector2.ZERO
var life := 4.0
var size := 3.0
var btype := Type.PELLET
var rule := Rule.NONE
var behavior := "straight"
var phase := 0.0
var orbit_center := Vector2.ZERO

func setup(d: Dictionary) -> void:
	var pos: Vector2 = d.get("pos", Vector2.ZERO)
	position = Vector2(roundi(pos.x), roundi(pos.y))
	vel = d.get("vel", Vector2.ZERO)
	life = float(d.get("life", 4.0))
	size = float(d.get("size", 3.0))
	btype = int(d.get("type", Type.PELLET))
	rule = int(d.get("rule", Rule.NONE))
	behavior = str(d.get("behavior", "straight"))
	phase = float(d.get("phase", 0.0))
	orbit_center = d.get("orbit_center", Vector2.ZERO)
	var spr := Sprite2D.new()
	spr.texture = Sprites.bullet_texture_for(btype)
	add_child(spr)

func dead() -> bool:
	return life <= 0.0
```

- [ ] **Step 4: Add textures to `sprites.gd`** (append):

```gdscript
static func bullet_texture_for(t: int) -> Texture2D:
	match t:
		Bullet.Type.BONE:
			return bone_texture()
		Bullet.Type.SPEAR:
			return spear_texture()
		Bullet.Type.RING:
			return ring_texture()
		Bullet.Type.LASER:
			return laser_texture()
		Bullet.Type.ARROW:
			return arrow_texture()
	return bullet_texture()

static func bone_texture() -> Texture2D:
	var img := Image.create(14, 10, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 10:
		for x in 14:
			var fill := false
			if y >= 2 and y <= 7:
				fill = true
			elif (x >= 2 and x <= 11) and (y == 1 or y == 8):
				fill = true
			elif (x >= 4 and x <= 9) and (y == 0 or y == 9):
				fill = true
			if fill:
				img.set_pixel(x, y, Color.WHITE)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)

static func spear_texture() -> Texture2D:
	var img := Image.create(6, 22, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 22:
		var w := 1
		if y == 0:
			w = 5
		elif y < 4:
			w = 3
		elif y < 8:
			w = 2
		elif y < 20:
			w = 2
		for x in range(3 - w / 2, 3 + w / 2 + 1):
			if x >= 0 and x < 6:
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)

static func ring_texture() -> Texture2D:
	var img := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(6.5, 6.5)
	for y in 14:
		for x in 14:
			var d := Vector2(x, y).distance_to(c)
			if d >= 5.5 and d <= 6.5:
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)

static func laser_texture() -> Texture2D:
	var img := Image.create(24, 90, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 90:
		for x in 24:
			if x >= 10 and x <= 13:
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)

static func arrow_texture() -> Texture2D:
	var img := Image.create(14, 6, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 6:
		for x in 14:
			var fill := false
			if x >= 2 and x <= 11:
				fill = (y >= 2 and y <= 3)
			elif x <= 2:
				fill = (y >= 1 and y <= 4)
			elif x >= 11:
				fill = (y == 0 or y == 5) or (y >= 2 and y <= 3)
			if fill:
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)
```
Note: existing `bullet_texture()` (8x8 white square) stays as the PELLET texture. `Color.WHITE` inside `match` arms: wrap in `return` bodies as shown (a `match` arm cannot be a bare expression).

- [ ] **Step 5: Motion per behavior in `dodge_box.gd`** — replace lines 58-60 with:

```gdscript
for b in bullets:
	b.phase += delta
	match b.behavior:
		"sine":
			b.position += b.vel * delta
			b.position.y += sin(b.phase * 6.0) * 40.0 * delta
		"homing":
			var to := (heart.position - b.position).normalized() * b.vel.length()
			b.vel = b.vel.move_toward(to, 60.0 * delta)
			b.position += b.vel * delta
		"gravity":
			b.vel.y += 120.0 * delta
			b.position += b.vel * delta
		"orbit":
			b.position = b.orbit_center + Vector2.from_angle(b.phase * 2.0) * 80.0
		_:
			b.position += b.vel * delta
	b.life -= delta
```
Also update the cull loop: `dead()` unchanged; keep culling outside `BOX_RECT.grow(4)` but use the NEW `BOX_RECT` from Task 7 — for now keep existing rect (Task 7 redefines it; this task only adds motion).

- [ ] **Step 6: Run suite — verify pass** (both new tests + existing green).

- [ ] **Step 7: Commit**

```bash
git add scripts/battle/bullet.gd scripts/util/sprites.gd scripts/battle/dodge_box.gd tests/test_bullet.gd
git commit -m "feat: typed bullets - shapes, colored rules data, per-behavior motion"
```

---
### Task 4: Pattern library — 7 new patterns + compound waves

**Files:**
- Modify: `scripts/battle/bullet_patterns.gd` (full rewrite of make + new builders)
- Modify: `scripts/battle/battle.gd:368-378` (`_enemy_turn` compound waves)
- Test: `tests/test_patterns.gd` (append)

**Interfaces:**
- Consumes: `Bullet.Type`, `Bullet.Rule`, behavior strings from Task 3.
- Produces: `make(pattern: Dictionary, heart_pos: Vector2) -> Array[Dictionary]` — pattern keys: type in {burst, fan, aimed, sine, ring, spiral, bone_wall, spear_volley, laser_sweep}, count, speed, spread, dir, origin, rule (int), telegraph (bool). Each item dict may carry: pos, vel, life, size, type, rule, behavior, phase, orbit_center.

- [ ] **Step 1: Append tests to `tests/test_patterns.gd`**

```gdscript
func test_aimed_bullets_track_heart() -> void:
	var out := BulletPatterns.make({"type": "aimed", "count": 3, "speed": 100.0,
			"origin": Vector2(317, 100)}, Vector2(317, 300))
	TestHelper.is_equal_to(out.size(), 3, "three aimed bullets")
	for d in out:
		var vel: Vector2 = d["vel"]
		TestHelper.is_true(vel.y > 0.0, "aimed bullet moves toward heart (down)")

func test_sine_row_has_behavior() -> void:
	var out := BulletPatterns.make({"type": "sine", "count": 5, "speed": 60.0,
			"origin": Vector2(317, 100)}, Vector2(317, 300))
	TestHelper.is_equal_to(out.size(), 5, "five sine bullets")
	TestHelper.is_equal_to(str(out[0]["behavior"]), "sine", "sine behavior set")

func test_ring_is_radial() -> void:
	var out := BulletPatterns.make({"type": "ring", "count": 12, "speed": 90.0,
			"origin": Vector2(317, 300)}, Vector2(317, 300))
	TestHelper.is_equal_to(out.size(), 12, "twelve ring bullets")
	var dirs := {}
	for d in out:
		var v: Vector2 = d["vel"]
		dirs[Vector2(roundi(v.x / 10.0), roundi(v.y / 10.0))] = true
	TestHelper.is_true(dirs.size() >= 8, "radial spread: " + str(dirs.size()))

func test_bone_wall_uses_bone_type() -> void:
	var out := BulletPatterns.make({"type": "bone_wall", "count": 5, "speed": 140.0,
			"origin": Vector2(317, 100)}, Vector2(317, 300))
	for d in out:
		TestHelper.is_equal_to(int(d["type"]), Bullet.Type.BONE, "bone wall uses BONE")

func test_spear_volley_uses_gravity() -> void:
	var out := BulletPatterns.make({"type": "spear_volley", "count": 3, "speed": 200.0,
			"origin": Vector2(317, 100)}, Vector2(317, 300))
	for d in out:
		TestHelper.is_equal_to(str(d["behavior"]), "gravity", "spears fall")
		TestHelper.is_equal_to(int(d["type"]), Bullet.Type.SPEAR, "spears typed")
```

- [ ] **Step 2: Run — verify fail** (make has no heart_pos param / new types).

- [ ] **Step 3: Implement `bullet_patterns.gd`** (full file):

```gdscript
class_name BulletPatterns

static func make(pattern: Dictionary, heart_pos: Vector2) -> Array[Dictionary]:
	var origin: Vector2 = pattern.get("origin", Vector2(317, 317))
	var rule := int(pattern.get("rule", Bullet.Rule.NONE))
	var base_type := int(pattern.get("type_override", Bullet.Type.PELLET))
	var dir_arr: Array = pattern.get("dir", [0.0, 1.0])
	var dir := Vector2(float(dir_arr[0]), float(dir_arr[1])).normalized()
	var count := int(pattern.get("count", 5))
	var speed := float(pattern.get("speed", 100.0))
	match str(pattern.get("type", "burst")):
		"fan":
			return _with_rule(fan(count, float(pattern.get("spread", 60.0)), speed, dir, origin), rule, base_type)
		"aimed":
			return _with_rule(_aimed(count, speed, origin, heart_pos), rule, base_type)
		"sine":
			return _with_rule(_sine_row(count, speed, dir, origin), rule, base_type)
		"ring":
			return _with_rule(_ring(count, speed, origin), rule, base_type)
		"spiral":
			return _with_rule(_spiral(count, speed, origin), rule, base_type)
		"bone_wall":
			return _with_rule(_bone_wall(count, speed, origin), rule, Bullet.Type.BONE)
		"spear_volley":
			return _with_rule(_spear_volley(count, speed, origin), rule, Bullet.Type.SPEAR)
		"laser_sweep":
			return _with_rule(_laser_sweep(count, origin), rule, Bullet.Type.LASER)
		_:
			return _with_rule(burst(count, speed, dir, origin), rule, base_type)

static func _with_rule(items: Array[Dictionary], rule: int, btype: int) -> Array[Dictionary]:
	for d in items:
		d["rule"] = rule
		d["type"] = btype
	return items

static func burst(count: int, speed: float, direction: Vector2, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		out.append({"pos": origin, "vel": direction * speed, "life": 4.0, "size": 3.0})
	return out

static func fan(count: int, spread_deg: float, speed: float, direction: Vector2, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if count <= 1:
		return burst(1, speed, direction, origin)
	var base := direction.angle()
	for i in count:
		var t := -0.5 + float(i) / float(count - 1)
		var vel := Vector2.from_angle(base + deg_to_rad(spread_deg) * t) * speed
		out.append({"pos": origin, "vel": vel, "life": 4.0, "size": 3.0})
	return out

static func _aimed(count: int, speed: float, origin: Vector2, heart_pos: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var dir := (heart_pos - origin).normalized()
	var spread := 10.0
	for i in count:
		var t := -0.5 + float(i) / float(maxi(count - 1, 1))
		var vel := dir.rotated(deg_to_rad(spread) * t) * speed
		out.append({"pos": origin, "vel": vel, "life": 4.0, "size": 3.0})
	return out

static func _sine_row(count: int, speed: float, direction: Vector2, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var side := Vector2(-direction.y, direction.x)
	for i in count:
		var pos := origin + side * (i - count / 2.0) * 26.0
		out.append({"pos": pos, "vel": direction * speed, "life": 6.0, "size": 3.0,
				"behavior": "sine", "phase": float(i)})
	return out

static func _ring(count: int, speed: float, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		var vel := Vector2.from_angle(TAU * float(i) / float(count)) * speed
		out.append({"pos": origin, "vel": vel, "life": 3.0, "size": 3.0})
	return out

static func _spiral(count: int, speed: float, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		out.append({"pos": origin, "vel": Vector2.ZERO, "life": 4.0, "size": 3.0,
				"behavior": "orbit", "phase": TAU * float(i) / float(count),
				"orbit_center": origin})
	return out

static func _bone_wall(count: int, speed: float, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		var y := origin.y + (i - count / 2.0) * 30.0
		out.append({"pos": Vector2(origin.x, y), "vel": Vector2(0, speed), "life": 3.0,
				"size": 6.0})
	return out

static func _spear_volley(count: int, speed: float, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		var x := origin.x + (i - count / 2.0) * 60.0
		out.append({"pos": Vector2(x, origin.y), "vel": Vector2(0, speed), "life": 2.0,
				"size": 4.0, "behavior": "gravity"})
	return out

static func _laser_sweep(count: int, origin: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in count:
		out.append({"pos": Vector2(-40.0, origin.y + i * 90.0), "vel": Vector2(180.0, 0.0),
				"life": 5.0, "size": 8.0})
	return out
```
Note: `_with_rule` overwrites the type so `bone_wall`/`spear_volley`/`laser_sweep` force their shape even if `type_override` was passed.

- [ ] **Step 4: Compound waves in `battle.gd` `_enemy_turn`** — replace the inner pattern loop:

```gdscript
_dodge_box.set_active(true)
for i in _enemy.patterns.size():
	var pattern: Dictionary = _enemy.patterns[i]
	if bool(pattern.get("telegraph", false)):
		await _dodge_box.show_telegraph(0.6)
	_dodge_box.spawn_patterns(BulletPatterns.make(pattern, _dodge_box.heart_position()))
	var frames := 0
	while _dodge_box.has_bullets() and frames < 60 * 15:
		await get_tree().process_frame
		frames += 1
	if i < _enemy.patterns.size() - 1:
		await get_tree().create_timer(0.8).timeout
_dodge_box.set_active(false)
```
(`show_telegraph` and `heart_position` come from Task 5/3 — `heart_position()` returns `heart.position`; add it to dodge_box in Task 3 Step 5 if missing: `func heart_position() -> Vector2: return heart.position`.)

- [ ] **Step 5: Run suite — verify pass** (5 new pattern tests).

- [ ] **Step 6: Commit**

```bash
git add scripts/battle/bullet_patterns.gd scripts/battle/battle.gd tests/test_patterns.gd
git commit -m "feat: pattern library - aimed/sine/ring/spiral/bone/spear/laser + compound waves"
```

---
### Task 5: Colored bullet rules + red "!" telegraph

**Files:**
- Modify: `scripts/battle/dodge_box.gd` (hit check, telegraph, heal signal)
- Modify: `scripts/battle/battle.gd` (heal wiring)
- Test: `tests/test_dodge_box.gd` (append)

**Interfaces:**
- Consumes: `Bullet.Rule` (Task 3); `Audio.play_sfx("warn")` (Task 6 — for now play nothing if missing, Task 6 wires it).
- Produces: `dodge_box.gd` signal `heal_requested(amount: int)`; `dodge_box.show_telegraph(duration: float) -> void` (red-outline rect + "!" label, plays "warn" via Audio); `_bullet_damages(b: Bullet, heart_vel: Vector2) -> bool`.

- [ ] **Step 1: Append tests to `tests/test_dodge_box.gd`**

```gdscript
func test_blue_bullet_rule() -> void:
	var box := DodgeBox.new()
	box._ready()
	var b := Bullet.new()
	b.setup({"pos": box.heart_position(), "vel": Vector2.ZERO, "type": Bullet.Type.PELLET,
			"rule": Bullet.Rule.BLUE})
	TestHelper.is_true(not box._bullet_damages(b, Vector2.ZERO), "blue + still = safe")
	TestHelper.is_true(box._bullet_damages(b, Vector2(10, 0)), "blue + moving = damage")
	b.free()
	box.free()

func test_orange_bullet_rule() -> void:
	var box := DodgeBox.new()
	box._ready()
	var b := Bullet.new()
	b.setup({"pos": box.heart_position(), "vel": Vector2.ZERO, "type": Bullet.Type.PELLET,
			"rule": Bullet.Rule.ORANGE})
	TestHelper.is_true(box._bullet_damages(b, Vector2(10, 0)), "orange + moving = damage")
	TestHelper.is_true(not box._bullet_damages(b, Vector2.ZERO), "orange + still = safe")
	b.free()
	box.free()

func test_gray_and_green_never_damage() -> void:
	var box := DodgeBox.new()
	box._ready()
	for rule in [Bullet.Rule.GRAY, Bullet.Rule.GREEN]:
		var b := Bullet.new()
		b.setup({"pos": box.heart_position(), "vel": Vector2.ZERO, "type": Bullet.Type.PELLET,
				"rule": rule})
		TestHelper.is_true(not box._bullet_damages(b, Vector2(50, 0)), "no damage for rule")
		b.free()
	box.free()
```
Note: `_bullet_damages` must be callable with a `Bullet` whose `rule`/`size` are set (setup does this). If `_ready()` requires a tree, use `box.process_mode = Node.PROCESS_MODE_DISABLED` and call setup manually instead of `_ready` — adapt to the existing dodge_box test style in the repo.

- [ ] **Step 2: Run — verify fail** (methods missing).

- [ ] **Step 3: Implement in `dodge_box.gd`**

```gdscript
signal heal_requested(amount: int)

func heart_position() -> Vector2:
	return heart.position

func _bullet_damages(b: Bullet, heart_vel: Vector2) -> bool:
	match b.rule:
		Bullet.Rule.GRAY:
			return false
		Bullet.Rule.GREEN:
			return false
		Bullet.Rule.BLUE:
			return heart_vel.length() > 8.0
		Bullet.Rule.ORANGE:
			return heart_vel.length() <= 8.0
	return true

func show_telegraph(duration: float) -> void:
	Audio.play_sfx("warn")
	var frame := ColorRect.new()
	frame.color = Color(1, 0, 0, 0.25)
	frame.position = BOX_RECT.position + Vector2(40, 20)
	frame.size = BOX_RECT.size - Vector2(80, 40)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	var label := Label.new()
	label.text = "!"
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.position = frame.position + frame.size / 2 - Vector2(10, 24)
	frame.add_child(label)
	await get_tree().create_timer(duration).timeout
	frame.queue_free()
```
Replace the hit check at ~line 69 to track velocity and use rules:
```gdscript
var last_heart_pos := heart.position
# ... in the collision loop:
var heart_vel := heart.position - last_heart_pos
last_heart_pos = heart.position
for b in bullets:
	if b.dead():
		continue
	var hit := CombatMath.circle_hit(heart.position, 4.0, b.position, b.size)
	if hit and _bullet_damages(b, heart_vel):
		_on_hit()
		break
	elif hit and b.rule == Bullet.Rule.GREEN:
		heal_requested.emit(2)
		b.life = 0.0
```

- [ ] **Step 4: Wire heal in `battle.gd`** (in `_ready` or setup after `_dodge_box` creation):
```gdscript
_dodge_box.heal_requested.connect(_on_heal_collected)

func _on_heal_collected(amount: int) -> void:
	hp = mini(hp + amount, max_hp)
	Audio.play_sfx("heal")
```
(`hp`, `max_hp` are the existing battle state members.)

- [ ] **Step 5: Run suite — verify pass** (rule tests + existing).

- [ ] **Step 6: Commit**

```bash
git add scripts/battle/dodge_box.gd scripts/battle/battle.gd tests/test_dodge_box.gd
git commit -m "feat: blue/orange/gray/green bullet rules + red ! telegraph"
```

---
### Task 6: Attack sound effects

**Files:**
- Modify: `scripts/tools/gen_sfx.gd` (7 new generators)
- Modify: `scripts/battle/battle.gd` (play per-pattern SFX, slice on hit, vaporize on defeat)
- Test: `tests/test_audio.gd` (append)

**Interfaces:**
- Consumes: existing gen_sfx.gd pattern (writes `assets/audio/sfx/<id>.wav`); `Audio.play_sfx(id)`.
- Produces: WAV files `whoosh`, `bone_clack`, `laser`, `warn`, `slice`, `vaporize`, `levelup`; a `Sprites`-free map in battle.gd: pattern type -> sfx id.

- [ ] **Step 1: Append test to `tests/test_audio.gd`**

```gdscript
func test_attack_sfx_files_exist() -> void:
	for id in ["whoosh", "bone_clack", "laser", "warn", "slice", "vaporize", "levelup"]:
		TestHelper.is_true(FileAccess.file_exists("res://assets/audio/sfx/" + id + ".wav"),
				"sfx exists: " + id)

func test_play_sfx_does_not_error() -> void:
	for id in ["whoosh", "bone_clack", "laser", "warn", "slice", "vaporize"]:
		Audio.play_sfx(id)
	TestHelper.is_true(true, "no errors playing attack sfx")
```

- [ ] **Step 2: Run — verify fail** (files missing).

- [ ] **Step 3: Regenerate SFX** — append to `gen_sfx.gd` (inside the existing generation function pattern):

```gdscript
# whoosh: white noise with quick fade
var whoosh := AudioStreamWAV.new()
whoosh.format = AudioStreamWAV.FORMAT_16_BITS
whoosh.mix_rate = 22050
whoosh.stereo = false
var wbuf := PackedByteArray()
for i in 3300:
	var t := float(i) / 22050.0
	var env := exp(-6.0 * t)
	var s := (randf() * 2.0 - 1.0) * env * 0.5
	wbuf.append(clampi(int(s * 32767.0) & 0xFF, -128, 255))
	wbuf.append(clampi(int(s * 32767.0) >> 8, -128, 255))
whoosh.data = wbuf
ResourceSaver.save(whoosh, "res://assets/audio/sfx/whoosh.wav")

# bone_clack: two square blips
var clack := AudioStreamWAV.new()
clack.format = AudioStreamWAV.FORMAT_16_BITS
clack.mix_rate = 22050
clack.stereo = false
var cbuf := PackedByteArray()
for i in 4400:
	var t := float(i) / 22050.0
	var f := 220.0
	if t > 0.07:
		f = 180.0
	var env := 0.6 if (t < 0.07 or (t >= 0.15 and t < 0.22)) else 0.0
	var s := 1.0 if (fmod(t * f, 1.0) < 0.5) else -1.0
	s *= env * 0.4
	cbuf.append(clampi(int(s * 32767.0) & 0xFF, -128, 255))
	cbuf.append(clampi(int(s * 32767.0) >> 8, -128, 255))
clack.data = cbuf
ResourceSaver.save(clack, "res://assets/audio/sfx/bone_clack.wav")

# laser: sine sweep down 880->110
var laser := AudioStreamWAV.new()
laser.format = AudioStreamWAV.FORMAT_16_BITS
laser.mix_rate = 22050
laser.stereo = false
var lbuf := PackedByteArray()
for i in 6600:
	var t := float(i) / 22050.0
	var f := lerpf(880.0, 110.0, t / 0.3)
	var s := sin(TAU * f * t) * (1.0 - t / 0.3) * 0.5
	lbuf.append(clampi(int(s * 32767.0) & 0xFF, -128, 255))
	lbuf.append(clampi(int(s * 32767.0) >> 8, -128, 255))
laser.data = lbuf
ResourceSaver.save(laser, "res://assets/audio/sfx/laser.wav")

# warn: three alternating two-tone blips
var warn := AudioStreamWAV.new()
warn.format = AudioStreamWAV.FORMAT_16_BITS
warn.mix_rate = 22050
warn.stereo = false
var wabuf := PackedByteArray()
for i in 8800:
	var t := float(i) / 22050.0
	var beat := fmod(t, 0.2)
	var f := 440.0 if beat < 0.1 else 660.0
	var env := 0.5 if t < 0.6 else 0.0
	var s := 1.0 if (fmod(t * f, 1.0) < 0.5) else -1.0
	s *= env * 0.4
	wabuf.append(clampi(int(s * 32767.0) & 0xFF, -128, 255))
	wabuf.append(clampi(int(s * 32767.0) >> 8, -128, 255))
warn.data = wabuf
ResourceSaver.save(warn, "res://assets/audio/sfx/warn.wav")

# slice: short noise burst + 1200Hz square drop
var slice := AudioStreamWAV.new()
slice.format = AudioStreamWAV.FORMAT_16_BITS
slice.mix_rate = 22050
slice.stereo = false
var sibuf := PackedByteArray()
for i in 1760:
	var t := float(i) / 22050.0
	var f := lerpf(1200.0, 300.0, t / 0.08)
	var s := (randf() * 2.0 - 1.0) * (1.0 - t / 0.08) * 0.3
	s += (1.0 if (fmod(t * f, 1.0) < 0.5) else -1.0) * (1.0 - t / 0.08) * 0.3
	sibuf.append(clampi(int(s * 32767.0) & 0xFF, -128, 255))
	sibuf.append(clampi(int(s * 32767.0) >> 8, -128, 255))
slice.data = sibuf
ResourceSaver.save(slice, "res://assets/audio/sfx/slice.wav")

# vaporize: rising triangle zap
var vapor := AudioStreamWAV.new()
vapor.format = AudioStreamWAV.FORMAT_16_BITS
vapor.mix_rate = 22050
vapor.stereo = false
var vbuf := PackedByteArray()
for i in 5500:
	var t := float(i) / 22050.0
	var f := lerpf(300.0, 900.0, t / 0.25)
	var ph := fmod(f * t, 1.0)
	var s := (2.0 * abs(ph - 0.5)) * (1.0 - t / 0.25) * 0.5
	vbuf.append(clampi(int(s * 32767.0) & 0xFF, -128, 255))
	vbuf.append(clampi(int(s * 32767.0) >> 8, -128, 255))
vapor.data = vbuf
ResourceSaver.save(vapor, "res://assets/audio/sfx/vaporize.wav")

# levelup: rising arpeggio 523-659-784-1047
var lvl := AudioStreamWAV.new()
lvl.format = AudioStreamWAV.FORMAT_16_BITS
lvl.mix_rate = 22050
lvl.stereo = false
var lbuf2 := PackedByteArray()
var notes := [523.0, 659.0, 784.0, 1047.0]
for i in 11000:
	var t := float(i) / 22050.0
	var idx := mini(int(t / 0.12), 3)
	var f := notes[idx]
	var env := 1.0 - fmod(t, 0.12) / 0.12
	var s := 1.0 if (fmod(t * f, 1.0) < 0.5) else -1.0
	s *= env * 0.35
	lbuf2.append(clampi(int(s * 32767.0) & 0xFF, -128, 255))
	lbuf2.append(clampi(int(s * 32767.0) >> 8, -128, 255))
lvl.data = lbuf2
ResourceSaver.save(lvl, "res://assets/audio/sfx/levelup.wav")
```
Then run the generator: `tools\godot.exe --headless -s res://scripts/tools/gen_sfx.gd` (same invocation used to generate the existing 9 SFX — check gen_sfx.gd's top for the exact run pattern and match it).

- [ ] **Step 4: Wire into `battle.gd`** — in `_enemy_turn` after each `spawn_patterns` call:
```gdscript
match str(pattern.get("type", "burst")):
	"bone_wall":
		Audio.play_sfx("bone_clack")
	"spear_volley":
		Audio.play_sfx("whoosh")
	"laser_sweep":
		Audio.play_sfx("laser")
	"ring", "spiral":
		Audio.play_sfx("whoosh")
	_:
		Audio.play_sfx("whoosh")
```
In `_resolve_fight` (player attack lands): add `Audio.play_sfx("slice")` where the enemy flash happens. On defeat (where the enemy fade begins): `Audio.play_sfx("vaporize")`.

- [ ] **Step 5: Run suite — verify pass** (audio tests + full green).

- [ ] **Step 6: Commit**

```bash
git add scripts/tools/gen_sfx.gd assets/audio/sfx tests/test_audio.gd scripts/battle/battle.gd
git commit -m "feat: attack sfx - whoosh/bone/laser/warn/slice/vaporize/levelup"
```

---
### Task 7: Authentic battle frame, HP bar, FIGHT buttons

**Files:**
- Modify: `scripts/battle/dodge_box.gd` (BOX_RECT 315x170 at (162,220), 5px frame)
- Modify: `scripts/battle/battle.gd` (HP bar 1.25px/HP red+yellow 21px, name "DREAMCATCHER LV 1", FIGHT/ACT/ITEM/MERCY button sprites)
- Test: `tests/test_dodge_box.gd`, `tests/test_battle_ui.gd` (new)

**Interfaces:**
- Consumes: button sprites (Task 1), `Sprites.soul_texture` cursor (Task 2).
- Produces: `DodgeBox.BOX_RECT := Rect2(162, 220, 315, 170)`; inner clamp rect `Rect2(167, 225, 305, 160)`; `DodgeBox.HEART_START := Vector2(319, 305)`.

- [ ] **Step 1: Write the failing test** — `tests/test_battle_ui.gd`:

```gdscript
extends RefCounted

func test_authentic_box_geometry() -> void:
	TestHelper.is_equal_to(DodgeBox.BOX_RECT, Rect2(162, 220, 315, 170), "box 315x170 at 162,220")
	TestHelper.is_equal_to(DodgeBox.HEART_START, Vector2(319, 305), "heart starts centered")

func test_hp_bar_dimensions() -> void:
	var battle := Battle.new()
	battle.max_hp = 20
	battle.hp = 12
	battle._build_hud()
	var underlay: ColorRect = battle.get_node("HPUnderlay")
	var fill: ColorRect = battle.get_node("HPFill")
	TestHelper.is_equal_to(underlay.size, Vector2(20.0 * 1.25, 21.0), "underlay 1.25px/HP, 21 tall")
	TestHelper.is_equal_to(fill.size, Vector2(12.0 * 1.25, 21.0), "fill tracks hp")
	TestHelper.is_equal_to(underlay.color, Color(0.753, 0.0, 0.0), "underlay is undertale red")
	TestHelper.is_equal_to(fill.color, Color(1.0, 1.0, 0.0), "fill is yellow")
	battle.free()

func test_fight_buttons_load_rips() -> void:
	var battle := Battle.new()
	battle._build_menu()
	for name in ["FIGHT", "ACT", "ITEM", "MERCY"]:
		var spr: Sprite2D = battle.get_node("MenuButtons/" + name)
		TestHelper.is_true(spr != null, "button node: " + name)
		if spr != null:
			var img := spr.texture.get_image()
			TestHelper.is_equal_to(img.get_width(), 110, "button 110 wide: " + name)
			TestHelper.is_equal_to(img.get_height(), 42, "button 42 tall: " + name)
	battle.free()
```
(Adjust node paths to whatever the existing `battle.gd` menu build looks like — `_build_hud`/`_build_menu` are new helper methods this task introduces; if `Battle` requires tree/scene setup, follow the existing test_battle* style in the repo and call the builder methods directly on a bare instance.)

- [ ] **Step 2: Run — verify fail** (BOX_RECT mismatch, missing nodes/methods).

- [ ] **Step 3: Re-geometry `dodge_box.gd`**

```gdscript
const BOX_RECT := Rect2(162, 220, 315, 170)
const BOX_INNER := Rect2(167, 225, 305, 160)
const HEART_START := Vector2(319, 305)
```
Replace the 1px white border ColorRect with a 5px frame built from four ColorRects:
```gdscript
func _build_frame() -> void:
	var white := Color(1, 1, 1)
	for rect in [
			Rect2(BOX_RECT.position, Vector2(BOX_RECT.size.x, 5)),
			Rect2(Vector2(BOX_RECT.position.x, BOX_RECT.end.y - 5), Vector2(BOX_RECT.size.x, 5)),
			Rect2(BOX_RECT.position, Vector2(5, BOX_RECT.size.y)),
			Rect2(Vector2(BOX_RECT.end.x - 5, BOX_RECT.position.y), Vector2(5, BOX_RECT.size.y))]:
		var bar := ColorRect.new()
		bar.color = white
		bar.position = rect.position
		bar.size = rect.size
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bar)
```
Call `_build_frame()` from `_ready` (replacing the old border creation). Update the clamp to use `BOX_INNER` and heart start to `HEART_START`.

- [ ] **Step 4: Authentic HUD + buttons in `battle.gd`**

Add `_build_hud()` (call from `_ready`, replacing the current HP bar construction):
```gdscript
func _build_hud() -> void:
	var underlay := ColorRect.new()
	underlay.name = "HPUnderlay"
	underlay.color = Color(0.753, 0.0, 0.0)
	underlay.position = Vector2(275, 400)
	underlay.size = Vector2(float(max_hp) * 1.25, 21.0)
	add_child(underlay)
	var fill := ColorRect.new()
	fill.name = "HPFill"
	fill.color = Color(1.0, 1.0, 0.0)
	fill.position = Vector2(275, 400)
	fill.size = Vector2(float(hp) * 1.25, 21.0)
	add_child(fill)
	hp_label.position = Vector2(275 + float(max_hp) * 1.25 + 4.0, 404)
	hp_label.text = "%02d / %02d" % [hp, max_hp]
	name_label.text = "DREAMCATCHER LV %d" % [lv]
```
(`lv` member exists in battle state — if not, add `var lv := 1`.) Make sure `hp_label`/`name_label` still update on `_on_player_hit` (update `HPFill.size` and label text there too).

Add `_build_menu()` (replacing the four text labels):
```gdscript
func _build_menu() -> void:
	var buttons := Node2D.new()
	buttons.name = "MenuButtons"
	add_child(buttons)
	var names := ["FIGHT", "ACT", "ITEM", "MERCY"]
	for i in 4:
		var spr := Sprite2D.new()
		spr.name = names[i]
		spr.texture = Sprites.soul_texture("Red")  # placeholder, replaced below
		spr.texture = load("res://assets/sprites/" + names[i] + "_sprite_button.png")
		spr.position = Vector2(432 + MENU_GRID[i].x * 90.0 + 55.0, 413 + MENU_GRID[i].y * 30.0 + 21.0)
		spr.scale = Vector2(0.5, 0.5)
		buttons.add_child(spr)
		cursor = Sprite2D.new()
		cursor.texture = Sprites.soul_texture("Red")
		cursor.position = Vector2(432 + MENU_GRID[i].x * 90.0 - 14.0, 413 + MENU_GRID[i].y * 30.0)
		buttons.add_child(cursor)
```
Note: buttons are 110x42 at scale 0.5 => 55x21, centered on the existing grid positions. `cursor` is reused per button here for simplicity — better: create one cursor and move it (see existing battle.gd cursor logic; keep its existing `_move_cursor` update but position relative to buttons). Keep `MENU_GRID` as-is.

- [ ] **Step 5: Run suite — verify pass** (box geometry, HUD, buttons).

- [ ] **Step 6: Commit**

```bash
git add scripts/battle/dodge_box.gd scripts/battle/battle.gd tests/test_dodge_box.gd tests/test_battle_ui.gd
git commit -m "feat: authentic battle frame, hp bar ratio, fight button rips"
```

---
### Task 8: Full verify, export, report

**Files:** none (verification only)

- [ ] **Step 1: Run the full suite**

Run the suite command. Expected: ALL TESTS PASSED; zero SCRIPT ERROR; zero FAIL. Grep the log: `select-string -Pattern "SCRIPT ERROR|FAIL" .superpowers\battle1.txt` → empty.

- [ ] **Step 2: Export**

```powershell
New-Item -ItemType Directory -Path dist -Force | Out-Null
tools\godot.exe --headless --export-release "Windows Desktop" dist\SoulHeart.exe
```
Expected: "Project export for preset \"Windows Desktop\" completed" (cosmetic rcedit warnings OK).

- [ ] **Step 3: Boot check**

```powershell
$p = Start-Process -FilePath ".\dist\SoulHeart.exe" -ArgumentList "--headless","--quit-after","60" -Wait -PassThru
$p.Refresh(); $p.ExitCode
```
Expected: `0`. Also verify size: `(Get-Item .\dist\SoulHeart.exe).Length` > 99,000,000 (95 MB gate).

- [ ] **Step 4: Commit any leftover asset import sidecars** (`.import`/`.uid` for the new PNGs — commit them so main imports cleanly):

```bash
git add assets/sprites
git commit -m "chore: sprite import sidecars"
```

- [ ] **Step 5: Update the ledger** `.superpowers\sdd\progress.md` with the battle plan summary (per-suite results, commit hashes).
