# Enemy Art & Presentation (Ripped Ruins Sprites) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single flat blue-circle wisp with authentic Undertale Ruins enemies (Froggit, Whimsun, Moldsmal, Loox, Vegetoid, Migosp) using ripped idle/hurt sprites, per-enemy attack patterns from the battle plan, hurt-frame swapping, and vaporize presentation.

**Architecture:** Ripped battle sprites (PNG statics + GIF idles) land in `assets/sprites/enemies/`; `Sprites.battle_enemy_texture(id, frame)` loads them (GIFs import as AnimatedTexture); `enemy_library.gd` becomes a 6-enemy registry mapping id -> stats, ACTs, lines, patterns (consuming the battle plan's pattern library); `battle.gd` gains hurt-frame swap and vaporize poof; `encounter.gd` shows a visible enemy sprite on the overworld trigger.

**Tech Stack:** Godot 4.4 (tools/godot.exe, headless tests), GDScript 2.0 (explicit types), GIF -> AnimatedTexture import, PNG rips.

## Global Constraints

- Execute AFTER plan `2026-08-09-battle-undertale-authentic.md` (its pattern types, `Bullet.Type`, `Bullet.Rule`, `BulletPatterns.make(pattern, heart_pos)` and `Audio.play_sfx` ids are required).
- Create an isolated worktree first via superpowers:using-git-worktrees (branch `undertale-enemies`).
- Suite command (from repo root): `cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers\enemies1.txt 2>&1 & echo DONE"` then read `.superpowers\enemies1.txt`.
- Gate: ALL TESTS PASSED, zero SCRIPT ERROR, zero FAIL, only permitted stderr (`Dialogue file not found nope.dlg` + exit-time RID/resource leak lines). Never commit on red.
- Explicit types mandatory. Tests: `extends RefCounted`, `test_*` methods, auto-discovered by `res://tests/run_all.gd`.
- Asset URLs verified working (undertale.wiki; TSR returns 403 — do not use it). Fetch with `Invoke-WebRequest` + browser UA; COMMIT assets.
- Keep all existing tests green.

---
### Task 1: Fetch and commit enemy sprites

**Files:**
- Create: `assets/sprites/enemies/froggit_idle.gif`, `froggit_hurt.png`, `whimsun_idle.gif`, `whimsun_hurt.png`, `moldsmal_idle.gif`, `loox_idle.gif`, `loox_hurt.png`, `vegetoid_idle.gif`, `vegetoid_hurt.png`, `migosp_idle.gif`, `migosp_hurt.png`, `napstablook_idle.gif`

**Interfaces:**
- Produces: 12 committed sprite files. (Napstablook is flavor-only for a future room; included for completeness.)

- [ ] **Step 1: Download**

```powershell
New-Item -ItemType Directory -Path assets\sprites\enemies -Force | Out-Null
$ProgressPreference = 'SilentlyContinue'
$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
$urls = @{
  "froggit_idle.gif"       = "https://undertale.wiki/images/Froggit_battle_idle.gif"
  "froggit_hurt.png"       = "https://undertale.wiki/images/Froggit_battle_hurt.png"
  "whimsun_idle.gif"       = "https://undertale.wiki/images/Whimsun_battle_idle.gif"
  "whimsun_hurt.png"       = "https://undertale.wiki/images/Whimsun_battle_hurt.png"
  "moldsmal_idle.gif"      = "https://undertale.wiki/images/Moldsmal_battle.gif"
  "loox_idle.gif"          = "https://undertale.wiki/images/Loox_battle_idle.gif"
  "loox_hurt.png"          = "https://undertale.wiki/images/Loox_battle_hurt.png"
  "vegetoid_idle.gif"      = "https://undertale.wiki/images/Vegetoid_battle_idle.gif"
  "vegetoid_hurt.png"      = "https://undertale.wiki/images/Vegetoid_battle_hurt.png"
  "migosp_idle.gif"        = "https://undertale.wiki/images/Migosp_battle_idle.gif"
  "migosp_hurt.png"        = "https://undertale.wiki/images/Migosp_battle_hurt.png"
  "napstablook_idle.gif"   = "https://undertale.wiki/images/Napstablook_battle_idle.gif"
}
foreach ($k in $urls.Keys) {
  Invoke-WebRequest -Uri $urls[$k] -OutFile "assets\sprites\enemies\$k" -UserAgent $ua -TimeoutSec 30
}
Get-ChildItem assets\sprites\enemies | Select-Object Name, Length
```
Expected: 12 files; froggit_idle 26,608 B, whimsun_idle 28,093 B, moldsmal 14,358 B (verified sizes; others > 1 KB).

**AMENDMENT (executed): Godot 4.4 cannot import GIF files (GIF support was removed in 4.0 — no `.import` sidecar is generated and `load()` returns null).** Idle animation is achieved by converting each GIF to a PNG frame sequence with Python + Pillow, committing the frames, and building `AnimatedTexture` at runtime from the PNGs. Frame counts (verified): froggit_idle 38, whimsun_idle 65, moldsmal_idle 44, loox_idle 9, vegetoid_idle 5, migosp_idle 19, napstablook_idle 2.

- [ ] **Step 2: Convert GIFs to PNG frames (Pillow)** — after Step 1 downloads the 12 files:

```powershell
python -c "from PIL import Image; import os; src='assets/sprites/enemies'; out='assets/sprites/enemies/frames'; counts={}
for f in sorted(os.listdir(src)):
    if not f.endswith('.gif'): continue
    stem=f[:-4]; img=Image.open(os.path.join(src,f)); d=os.path.join(out,stem); os.makedirs(d,exist_ok=True); n=0
    try:
        while True:
            img.convert('RGBA').save(os.path.join(d, f'{stem}_{n:03d}.png')); n+=1; img.seek(img.tell()+1)
    except EOFError: pass
    counts[stem]=n; print(stem,n)
print(counts)"
```
Then DELETE the .gif files (`Remove-Item assets\sprites\enemies\*.gif`) — they are unimportable dead weight. Committed assets = 4 hurt PNGs + 7 frame dirs (182 PNGs total).

- [ ] **Step 3: Write asset test** — `tests/test_enemy_assets.gd`:

```gdscript
extends RefCounted

func test_enemy_sprites_downloaded() -> void:
	for f in ["froggit_hurt.png", "whimsun_hurt.png", "loox_hurt.png",
			"vegetoid_hurt.png", "migosp_hurt.png"]:
		TestHelper.is_true(FileAccess.file_exists("res://assets/sprites/enemies/" + f),
				"enemy sprite exists: " + f)

func test_enemy_frame_sequences() -> void:
	var counts := {"froggit": 38, "whimsun": 65, "moldsmal": 44, "loox": 9,
			"vegetoid": 5, "migosp": 19, "napstablook": 2}
	for id in counts:
		var d := DirAccess.open("res://assets/sprites/enemies/frames/" + id)
		TestHelper.is_true(d != null, "frames dir exists: " + id)
		if d == null:
			continue
		TestHelper.eq(d.get_files().size(), counts[id], "frame count for " + id)
```

- [ ] **Step 4: Run — verify fail** (files missing), then `tools\godot.exe --headless --import` and re-run.

- [ ] **Step 5: Commit**

```bash
git add assets/sprites/enemies tests/test_enemy_assets.gd
git commit -m "assets: ruin monsters battle sprites (froggit/whimsun/moldsmal/loox/vegetoid/migosp)"
```

---
### Task 2: Enemy sprite loader in Sprites

**Files:**
- Modify: `scripts/util/sprites.gd`
- Test: `tests/test_sprites.gd` (append)

**Interfaces:**
- Consumes: `assets/sprites/enemies/*` (Task 1: `frames/<id>/<id>_NNN.png` sequences + `<id>_hurt.png`).
- Produces: `Sprites.battle_enemy_texture(id: String, hurt: bool) -> Texture2D` (cache; id keys: froggit, whimsun, moldsmal, loox, vegetoid, migosp, napstablook). Idle = AnimatedTexture built at runtime from the frame PNGs (fps 15, frame count from the FRAME_COUNTS const). Hurt = `_hurt.png` when available; moldsmal (no hurt rip) falls back to idle.

- [ ] **Step 1: Write the failing test** (append to `tests/test_sprites.gd`):

```gdscript
func test_battle_enemy_textures() -> void:
	for id in ["froggit", "whimsun", "moldsmal", "loox", "vegetoid", "migosp"]:
		var idle := Sprites.battle_enemy_texture(id, false)
		TestHelper.is_true(idle != null, "enemy idle loads: " + id)
		var hurt := Sprites.battle_enemy_texture(id, true)
		TestHelper.is_true(hurt != null, "enemy hurt loads: " + id)
		if id != "moldsmal":
			TestHelper.is_true(hurt != idle, "hurt differs from idle: " + id)
		else:
			TestHelper.is_true(hurt == idle, "moldsmal has no hurt rip -> idle fallback")
```

- [ ] **Step 2: Run — verify fail** (method missing).

- [ ] **Step 3: Implement** (append to `sprites.gd`):

```gdscript
static var _enemy_cache := {}
static var _enemy_frames := {"froggit": 38, "whimsun": 65, "moldsmal": 44, "loox": 9,
		"vegetoid": 5, "migosp": 19, "napstablook": 2}

static func battle_enemy_texture(id: String, hurt: bool) -> Texture2D:
	var key := id + ("_hurt" if hurt else "_idle")
	if _enemy_cache.has(key):
		return _enemy_cache[key]
	var tex := _load_enemy_hurt(id) if hurt else _load_enemy_idle(id)
	_enemy_cache[key] = tex
	return tex

static func _load_enemy_hurt(id: String) -> Texture2D:
	var path := "res://assets/sprites/enemies/" + id + "_hurt.png"
	var tex := load(path) as Texture2D
	if tex == null:
		return _load_enemy_idle(id)
	return tex

static func _load_enemy_idle(id: String) -> Texture2D:
	var count := int(_enemy_frames.get(id, 1))
	var anim := AnimatedTexture.new()
	anim.fps = 15
	anim.frames = count
	for i in count:
		anim.set_frame_texture(i, load("res://assets/sprites/enemies/frames/"
				+ id + "/" + id + "_%03d.png" % i) as Texture2D)
	return anim
```
Note: AnimatedTexture.set_frame_texture requires each frame to be a valid Texture2D; frames were verified present in Task 1's test. If a frame fails to load, set_frame_texture logs an error — the Task 1 frame-count test guards this.

- [ ] **Step 4: Run suite — verify pass.**

- [ ] **Step 5: Commit**

```bash
git add scripts/util/sprites.gd tests/test_sprites.gd
git commit -m "feat: battle enemy sprite loader with hurt variants"
```

---
### Task 3: Enemy registry — 6 monsters with authentic stats and patterns

**Files:**
- Modify: `scripts/battle/enemy_library.gd` (full rewrite of the data)
- Test: `tests/test_enemy_library.gd` (new)

**Interfaces:**
- Consumes: `Bullet.Type`, `Bullet.Rule`, `BulletPatterns.make(pattern, heart_pos)` (battle plan).
- Produces: `enemy_library.get_enemy(id: String) -> Dictionary` with keys: id, name, hp, atk, def, acts (Array of strings), spare_after (int), attack_lines (Array[String]), patterns (Array[Dictionary] — each a pattern dict possibly with "rule"/"telegraph"), sprite_id (String). `enemy_library.enemy_ids() -> Array[String]`.

- [ ] **Step 1: Write the failing test** — `tests/test_enemy_library.gd`:

```gdscript
extends RefCounted

func test_all_enemies_present() -> void:
	var ids := EnemyLibrary.enemy_ids()
	TestHelper.is_equal_to(ids.size(), 6, "six enemies")
	for id in ["froggit", "whimsun", "moldsmal", "loox", "vegetoid", "migosp"]:
		TestHelper.is_true(ids.has(id), "has enemy: " + id)

func test_froggit_profile() -> void:
	var e := EnemyLibrary.get_enemy("froggit")
	TestHelper.is_equal_to(e["name"], "FROGGIT", "name")
	TestHelper.is_equal_to(e["hp"], 20, "hp 20")
	TestHelper.is_equal_to(e["atk"], 4, "atk 4")
	TestHelper.is_true(e["patterns"].size() >= 2, "at least two patterns")
	TestHelper.is_true(e["attack_lines"].size() >= 1, "has attack lines")
	TestHelper.is_equal_to(e["sprite_id"], "froggit", "sprite id")

func test_vegetoid_uses_green_heal() -> void:
	var e := EnemyLibrary.get_enemy("vegetoid")
	var has_green := false
	for p in e["patterns"]:
		if int(p.get("rule", Bullet.Rule.NONE)) == Bullet.Rule.GREEN:
			has_green = true
	TestHelper.is_true(has_green, "vegetoid drops green heal bullets")

func test_unknown_enemy_falls_back() -> void:
	var e := EnemyLibrary.get_enemy("nonexistent")
	TestHelper.is_equal_to(e["id"], "froggit", "falls back to froggit")
```

- [ ] **Step 2: Run — verify fail.**

- [ ] **Step 3: Implement** — rewrite `scripts/battle/enemy_library.gd`:

```gdscript
class_name EnemyLibrary

static var _enemies := {
	"froggit": {
		"id": "froggit", "name": "FROGGIT", "hp": 20, "atk": 4, "def": 0,
		"acts": ["Check", "Ribbit"], "spare_after": 1,
		"attack_lines": ["Froggit attacks!", "* Froggit is watching you."],
		"sprite_id": "froggit",
		"patterns": [
			{"type": "sine", "count": 5, "speed": 70.0, "rule": Bullet.Rule.BLUE},
			{"type": "aimed", "count": 3, "speed": 110.0},
		],
	},
	"whimsun": {
		"id": "whimsun", "name": "WHIMSUN", "hp": 12, "atk": 5, "def": 0,
		"acts": ["Check", "Calm"], "spare_after": 1,
		"attack_lines": ["Whimsun cries out!", "* Whimsun is frightened."],
		"sprite_id": "whimsun",
		"patterns": [
			{"type": "sine", "count": 6, "speed": 60.0},
			{"type": "ring", "count": 10, "speed": 80.0},
		],
	},
	"moldsmal": {
		"id": "moldsmal", "name": "MOLDSMAL", "hp": 30, "atk": 6, "def": 0,
		"acts": ["Check", "Hug"], "spare_after": 1,
		"attack_lines": ["Moldsmal wobbles!", "* Moldsmal is thinking of nothing."],
		"sprite_id": "moldsmal",
		"patterns": [
			{"type": "burst", "count": 4, "speed": 60.0},
			{"type": "burst", "count": 6, "speed": 90.0, "rule": Bullet.Rule.BLUE},
		],
	},
	"loox": {
		"id": "loox", "name": "LOOX", "hp": 40, "atk": 7, "def": 0,
		"acts": ["Check", "Don't Pick On Me"], "spare_after": 2,
		"attack_lines": ["Loox shoots a mean look!", "* Loox does not like you."],
		"sprite_id": "loox",
		"patterns": [
			{"type": "fan", "count": 5, "spread": 50.0, "speed": 100.0},
			{"type": "aimed", "count": 4, "speed": 130.0, "rule": Bullet.Rule.ORANGE},
		],
	},
	"vegetoid": {
		"id": "vegetoid", "name": "VEGETOID", "hp": 18, "atk": 4, "def": 0,
		"acts": ["Check", "Talk"], "spare_after": 1,
		"attack_lines": ["Vegetoid sprouts!", "* Vegetoid is a vegetable."],
		"sprite_id": "vegetoid",
		"patterns": [
			{"type": "ring", "count": 8, "speed": 70.0, "rule": Bullet.Rule.GREEN},
			{"type": "fan", "count": 4, "spread": 40.0, "speed": 90.0},
		],
	},
	"migosp": {
		"id": "migosp", "name": "MIGOSP", "hp": 24, "atk": 5, "def": 0,
		"acts": ["Check", "Doubt"], "spare_after": 1,
		"attack_lines": ["Migosp skitters!", "* Migosp is silent."],
		"sprite_id": "migosp",
		"patterns": [
			{"type": "spiral", "count": 8, "speed": 60.0},
			{"type": "fan", "count": 6, "spread": 70.0, "speed": 110.0},
		],
	},
}

static func get_enemy(id: String) -> Dictionary:
	if not _enemies.has(id):
		return _enemies["froggit"]
	return _enemies[id]

static func enemy_ids() -> Array[String]:
	var out: Array[String] = []
	for k in _enemies:
		out.append(k)
	return out
```

- [ ] **Step 4: Run suite — verify pass.**

- [ ] **Step 5: Commit**

```bash
git add scripts/battle/enemy_library.gd tests/test_enemy_library.gd
git commit -m "feat: enemy registry - froggit/whimsun/moldsmal/loox/vegetoid/migosp"
```

---
### Task 4: Battle presentation — idle anim, hurt swap, vaporize

**Files:**
- Modify: `scripts/battle/battle.gd` (enemy sprite setup, hurt frame, defeat poof)
- Test: `tests/test_battle_presentation.gd` (new)

**Interfaces:**
- Consumes: `Sprites.battle_enemy_texture` (Task 2), `EnemyLibrary.get_enemy` (Task 3), `Audio.play_sfx("vaporize")` (battle plan Task 6).
- Produces: `battle.gd` `_enemy_sprite` uses AnimatedTexture idle; `_on_enemy_hurt_frame()` toggles hurt texture 0.3s; defeat spawns a white expanding square poof node.

- [ ] **Step 1: Write the failing test** — `tests/test_battle_presentation.gd`:

```gdscript
extends RefCounted

func test_enemy_sprite_uses_animated_texture() -> void:
	var battle := Battle.new()
	battle._enemy = EnemyLibrary.get_enemy("froggit")
	battle._spawn_enemy_sprite()
	TestHelper.is_true(battle._enemy_sprite != null, "sprite exists")
	TestHelper.is_true(battle._enemy_sprite.texture is AnimatedTexture, "idle is animated")
	battle.free()

func test_hurt_frame_swap() -> void:
	var battle := Battle.new()
	battle._enemy = EnemyLibrary.get_enemy("froggit")
	battle._spawn_enemy_sprite()
	var idle_tex := battle._enemy_sprite.texture
	battle._on_enemy_hurt_frame()
	TestHelper.is_true(battle._enemy_sprite.texture != idle_tex, "hurt texture applied")
	battle._restore_enemy_frame()
	TestHelper.is_true(battle._enemy_sprite.texture == idle_tex, "idle restored")
	battle.free()

func test_vaporize_spawns_poof() -> void:
	var battle := Battle.new()
	battle._spawn_vaporize_poof(Vector2(200, 140))
	TestHelper.is_true(battle.get_node_or_null("VaporizePoof") != null, "poof node exists")
	battle.free()
```
(Follow the repo's existing battle test style — if Battle requires scene setup, construct via `preload("res://scenes/Battle.tscn").instantiate()` and call the same methods; adjust method names to match what you implement.)

- [ ] **Step 2: Run — verify fail.**

- [ ] **Step 3: Implement in `battle.gd`**

Replace the enemy sprite creation (current wisp texture line) with:
```gdscript
func _spawn_enemy_sprite() -> void:
	_enemy_sprite = Sprite2D.new()
	_enemy_sprite.texture = Sprites.battle_enemy_texture(_enemy["sprite_id"], false)
	_enemy_sprite.position = Vector2(216, 136)
	_enemy_sprite.scale = Vector2(0.8, 0.8)
	add_child(_enemy_sprite)
	_hp_bar_base.position = Vector2(207, 161)
	_hp_bar_fill.position = Vector2(208, 162)
```
(Keep existing entrance tween/bob — adjust scale so rips fit the 315x170 box; whimsun is 98x107 -> 0.8 scale => 78x86, fits above the box top at y=136.)
```gdscript
func _on_enemy_hurt_frame() -> void:
	var hurt_tex := Sprites.battle_enemy_texture(_enemy["sprite_id"], true)
	if hurt_tex != _enemy_sprite.texture:
		_enemy_sprite.texture = hurt_tex
		await get_tree().create_timer(0.3).timeout
		_restore_enemy_frame()

func _restore_enemy_frame() -> void:
	_enemy_sprite.texture = Sprites.battle_enemy_texture(_enemy["sprite_id"], false)

func _spawn_vaporize_poof(at: Vector2) -> void:
	Audio.play_sfx("vaporize")
	var poof := ColorRect.new()
	poof.name = "VaporizePoof"
	poof.color = Color(1, 1, 1)
	poof.position = at
	poof.size = Vector2(8, 8)
	poof.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(poof)
	var tween := create_tween()
	tween.tween_property(poof, "size", Vector2(64, 64), 0.3)
	tween.parallel().tween_property(poof, "color:a", 0.0, 0.3)
	tween.tween_callback(poof.queue_free)
```
Call `_on_enemy_hurt_frame()` where the current hit-flash happens in `_resolve_fight`, and replace the defeat fade block with `_spawn_vaporize_poof(_enemy_sprite.position)` + the existing fade.

- [ ] **Step 4: Run suite — verify pass.**

- [ ] **Step 5: Commit**

```bash
git add scripts/battle/battle.gd tests/test_battle_presentation.gd
git commit -m "feat: enemy idle anim, hurt frame swap, vaporize poof"
```

---
### Task 5: Visible overworld encounters

**Files:**
- Modify: `scripts/rooms/encounter.gd`
- Modify: `scripts/rooms/drizzle_fields.gd`, `scripts/rooms/grumble_woods.gd` (encounter spawn sites pass enemy id)
- Test: `tests/test_encounter.gd` (append)

**Interfaces:**
- Consumes: `Sprites.battle_enemy_texture` (Task 2).
- Produces: `encounter.gd` `enemy_id` (String) member; overworld shows the small bob sprite above the trigger + "!" popup on touch (existing).

- [ ] **Step 1: Write the failing test** (append to `tests/test_encounter.gd`):

```gdscript
func test_encounter_shows_enemy_sprite() -> void:
	var enc := Encounter.new()
	enc.enemy_id = "froggit"
	enc._ready()
	var spr := enc.get_node_or_null("EnemySprite")
	TestHelper.is_true(spr != null, "enemy sprite node exists")
	if spr != null:
		TestHelper.is_true(spr.texture != null, "sprite has texture")
	enc.free()
```
(Adjust `_ready` call style to the repo's existing encounter test.)

- [ ] **Step 2: Run — verify fail.**

- [ ] **Step 3: Implement in `encounter.gd`**

```gdscript
var enemy_id := "froggit"
```
In `_ready` (before/after the "!" popup setup), add:
```gdscript
var spr := Sprite2D.new()
spr.name = "EnemySprite"
spr.texture = Sprites.battle_enemy_texture(enemy_id, false)
spr.scale = Vector2(0.5, 0.5)
spr.position = Vector2(0, -26)
add_child(spr)
var bob := create_tween().set_loops()
bob.tween_property(spr, "position:y", -30.0, 0.6).set_trans(Tween.TRANS_SINE)
bob.tween_property(spr, "position:y", -26.0, 0.6).set_trans(Tween.TRANS_SINE)
```
In `drizzle_fields.gd`/`grumble_woods.gd`, set `enemy_id` per spawn site (e.g. froggit in drizzle near start, whimsun deeper, migosp in grumble) — find the existing encounter creation blocks and add `enc.enemy_id = "whimsun"` etc.

- [ ] **Step 4: Run suite — verify pass.**

- [ ] **Step 5: Commit**

```bash
git add scripts/rooms/encounter.gd scripts/rooms/drizzle_fields.gd scripts/rooms/grumble_woods.gd tests/test_encounter.gd
git commit -m "feat: visible overworld enemy sprites on encounter zones"
```

---
### Task 6: Full verify, export, report

- [ ] **Step 1: Full suite** — run suite command; grep `.superpowers\enemies1.txt` for `SCRIPT ERROR|FAIL` — must be empty; must contain ALL TESTS PASSED.

- [ ] **Step 2: Export + boot check** (same as battle plan Task 8 Steps 2-3): export to `dist\SoulHeart.exe`, boot `--headless --quit-after 60` -> ExitCode 0, size > 99,000,000 bytes.

- [ ] **Step 3: Commit import sidecars** (`git add assets/sprites/enemies` + any `.uid`/`.import`) as `chore: enemy sprite import sidecars`.

- [ ] **Step 4: Update ledger** `.superpowers\sdd\progress.md`.
