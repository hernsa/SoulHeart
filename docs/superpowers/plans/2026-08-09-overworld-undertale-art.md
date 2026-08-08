# Overworld Art (Frisk, Trees, Decor, Rooms) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Kill the "blocky and simple" look of the overworld: Frisk's ripped sprite replaces the striped block (4 directions + walk bob), trees become real canopy+trunk pixel art, ripped props (golden flowers, rocks, echo flowers, SAVE point) scatter across rooms, the toad NPC becomes Froggit, and GrumbleWoods' black void bars disappear.

**Architecture:** Ripped overworld PNGs/GIFs land in `assets/sprites/overworld/`; `sprites.gd` gains `player_frisk_texture(frame: int)` (2x2 atlas from the 38x58 rip: down/up/left/right) and prop loaders; `tiles.gd` redraws TREE/WALL as 32x32 prop art with a solid base tile; `layout_parser.gd` gains decoration chars ('F','R','E','S' handled by rooms); rooms scatter props; save point and NPC use rips; GrumbleWoods grid pads to 40x30.

**Tech Stack:** Godot 4.4 (tools/godot.exe, headless tests), GDScript 2.0 (explicit types), PNG/GIF imports.

## Global Constraints

- Execute AFTER plans `2026-08-09-battle-undertale-authentic.md` and `2026-08-09-enemies-undertale-sprites.md` (Sprites loaders, Audio ids, enemy registry available; test_assets.gd pattern reused).
- Create an isolated worktree first via superpowers:using-git-worktrees (branch `undertale-overworld`).
- Suite command (from repo root): `cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers\overworld1.txt 2>&1 & echo DONE"` then read `.superpowers\overworld1.txt`.
- Gate: ALL TESTS PASSED, zero SCRIPT ERROR, zero FAIL, only permitted stderr. Never commit on red.
- Explicit types mandatory. Tests: `extends RefCounted`, `test_*` methods, auto-discovered.
- Asset URLs verified (undertale.wiki; TSR 403 — never use TSR). Fetch with `Invoke-WebRequest` + browser UA; COMMIT assets.
- Keep all existing tests green; where a test asserts the old procedural look (e.g. test_player_visuals.gd), update it in the same task.

---
### Task 1: Fetch and commit overworld assets

**Files:**
- Create: `assets/sprites/overworld/frisk.png` (38x58, 4-frame 2x2 grid), `frisk_walk.gif` (38x60, 4 direction frames), `save_point.gif` (40x38, 4 frames), `rock.png` (40x36), `golden_flowers.png` (118x80), `echo_flower.png`, `froggit_npc.png` (40x36-ish)

**Interfaces:**
- Produces: 7 committed assets (verified URLs below; echo_flower uses the overworld echo flower rip — if the wiki URL 404s, use golden_flowers.png for that slot instead and note it in the commit).

- [ ] **Step 1: Download**

```powershell
New-Item -ItemType Directory -Path assets\sprites\overworld -Force | Out-Null
$ProgressPreference = 'SilentlyContinue'
$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
$urls = @{
  "frisk.png"           = "https://undertale.wiki/images/Frisk_overworld.png"
  "frisk_walk.gif"      = "https://undertale.wiki/images/Frisk_overworld_walk_unused.gif"
  "save_point.gif"      = "https://undertale.wiki/images/SAVE_Point_overworld.gif"
  "rock.png"            = "https://undertale.wiki/images/Rock_overworld.png"
  "golden_flowers.png"  = "https://undertale.wiki/images/Golden_flowers_overworld.png"
  "echo_flower.png"     = "https://undertale.wiki/images/Echo_Flower_overworld.png"
  "froggit_npc.png"     = "https://undertale.wiki/images/Froggit_overworld.png"
}
foreach ($k in $urls.Keys) {
  try {
    Invoke-WebRequest -Uri $urls[$k] -OutFile "assets\sprites\overworld\$k" -UserAgent $ua -TimeoutSec 30
  } catch {
    Write-Host "FAILED: $k"
  }
}
Get-ChildItem assets\sprites\overworld | Select-Object Name, Length
```
Expected: frisk.png 263 B, frisk_walk.gif 1,283 B, save_point.gif 743 B, rock.png 200 B, golden_flowers.png 704 B (verified). Echo flower + froggit NPC are new URLs — if FAILED appears, re-run with the fallback: `echo_flower.png = https://undertale.wiki/images/Golden_flowers_overworld.png` and `froggit_npc.png = https://undertale.wiki/images/Froggit_overworld.png` re-tried with `?format=original` suffix if needed.

- [ ] **Step 2: Write asset test** — `tests/test_overworld_assets.gd`:

```gdscript
extends RefCounted

func test_overworld_assets_exist() -> void:
	for f in ["frisk.png", "frisk_walk.gif", "save_point.gif", "rock.png", "golden_flowers.png"]:
		TestHelper.is_true(FileAccess.file_exists("res://assets/sprites/overworld/" + f),
				"overworld asset: " + f)

func test_frisk_dimensions() -> void:
	var img := Image.load_from_file("res://assets/sprites/overworld/frisk.png")
	TestHelper.is_true(img != null, "frisk loads")
	if img == null:
		return
	TestHelper.is_equal_to(img.get_width(), 38, "frisk width 38 (2x2 grid of 19x29)")
	TestHelper.is_equal_to(img.get_height(), 58, "frisk height 58")
```

- [ ] **Step 3: Run — verify fail**, then `tools\godot.exe --headless --import`, re-run.

- [ ] **Step 4: Commit**

```bash
git add assets/sprites/overworld tests/test_overworld_assets.gd
git commit -m "assets: frisk overworld sprite, save point, props"
```

---
### Task 2: Frisk player sprite — 4 directions + walk bob

**Files:**
- Modify: `scripts/util/sprites.gd` (add player frisk frames)
- Modify: `scripts/player/player.gd` (use new texture, 4-dir frames, bob)
- Modify: `scenes/Player.tscn` (scale 1x)
- Test: `tests/test_player_visuals.gd` (update)

**Interfaces:**
- Consumes: `assets/sprites/overworld/frisk.png` (Task 1).
- Produces: `Sprites.player_frisk_texture(frame: int) -> Texture2D` — frame 0=down, 1=up, 2=left, 3=right (2x2 atlas, each cell 19x29, cached). Player uses `flip_h = false`; facing stored as index.

- [ ] **Step 1: Write the failing test** — update `tests/test_player_visuals.gd`:

```gdscript
func test_player_uses_frisk_rip() -> void:
	for frame in 4:
		var tex := Sprites.player_frisk_texture(frame)
		TestHelper.is_true(tex != null, "frisk frame " + str(frame) + " loads")
		if tex != null:
			var img := tex.get_image()
			TestHelper.is_equal_to(img.get_width(), 19, "frame width 19")
			TestHelper.is_equal_to(img.get_height(), 29, "frame height 29")

func test_frames_are_distinct() -> void:
	var hashes := {}
	for frame in 4:
		hashes[Sprites.player_frisk_texture(frame).get_image().get_data().hash()] = true
	TestHelper.is_true(hashes.size() >= 3, "at least 3 distinct directions: " + str(hashes.size()))
```

- [ ] **Step 2: Run — verify fail.**

- [ ] **Step 3: Implement** (append to `sprites.gd`):

```gdscript
static var _frisk_cache := {}

static func player_frisk_texture(frame: int) -> Texture2D:
	if _frisk_cache.has(frame):
		return _frisk_cache[frame]
	var img := Image.load_from_file("res://assets/sprites/overworld/frisk.png")
	var cell := Rect2i((frame % 2) * 19, (frame / 2) * 29, 19, 29)
	var out := Image.create(19, 29, false, Image.FORMAT_RGBA8)
	for y in 29:
		for x in 19:
			out.set_pixel(x, y, img.get_pixel(cell.position.x + x, cell.position.y + y))
	var tex := ImageTexture.create_from_image(out)
	_frisk_cache[frame] = tex
	return tex
```

- [ ] **Step 4: Update `player.gd`** — replace the texture/frame logic:

```gdscript
var facing := 0  # 0 down, 1 up, 2 left, 3 right
var walk_t := 0.0
```
In `_physics_process` (or the existing movement handler), after computing `res` (movement vector):
```gdscript
if res.length() > 0.0:
	if abs(res.x) > abs(res.y):
		facing = 3 if res.x > 0.0 else 2
	else:
		facing = 0 if res.y > 0.0 else 1
	walk_t += delta
else:
	walk_t = 0.0
_sprite.texture = Sprites.player_frisk_texture(facing)
_sprite.position.y = -1.0 if (fmod(walk_t, 0.4) < 0.2 and res.length() > 0.0) else 0.0
```
Remove the old `player_texture_frame` usage and `flip_h` logic (frames handle direction). Keep the shadow node. In `scenes/Player.tscn`, set sprite scale to 1.0 (collision rect stays 8x12-ish; adjust to 10x10 if the new sprite's feet don't align — verify visually at the end).

- [ ] **Step 5: Run suite — verify pass** (updated player visuals test + all green).

- [ ] **Step 6: Commit**

```bash
git add scripts/util/sprites.gd scripts/player/player.gd scenes/Player.tscn tests/test_player_visuals.gd
git commit -m "feat: frisk overworld sprite - 4 directions, walk bob"
```

---
### Task 3: Real trees — canopy + trunk props

**Files:**
- Modify: `scripts/tiles/tiles.gd` (tree/wall prop textures)
- Modify: `scripts/rooms/map_builder.gd` (tree offset + solid base)
- Test: `tests/test_tiles.gd` (append)

**Interfaces:**
- Consumes: existing tile pipeline (`GameTiles.build_tileset(palette)`, `MapBuilder.build_tilemap(grid, palette)`).
- Produces: TREE rendered as 32x32 prop: trunk (rows 20-31, brown) + layered canopy (dark mid, light top) drawn procedurally in the tile atlas cells 2 (tree) and 3 (wall stays a 16x16 block but gains a bevel); `MapBuilder._add_solid_body` keeps the 16x16 base box but the tree's visual sprite is anchored at `cell*16 - (16,16)`.

- [ ] **Step 1: Write the failing test** (append to `tests/test_tiles.gd`):

```gdscript
func test_tree_has_canopy_and_trunk() -> void:
	var img := GameTiles._atlas_texture({}).get_image()
	var brown := Color(0.42, 0.26, 0.12)
	var has_brown := false
	var has_green := false
	for y in 32:
		for x in 32:
			var c := img.get_pixel(2 * 16 + x, y)
			if c.is_equal_approx(brown):
				has_brown = true
			if c.g > c.r and c.g > 0.2:
				has_green = true
	TestHelper.is_true(has_brown, "tree has trunk pixels")
	TestHelper.is_true(has_green, "tree has canopy pixels")
```
(Note: this test reads atlas row 0 columns 2-3; if the tree ends up drawn at row 1 of the atlas, adjust the pixel math accordingly — the atlas is 64x16 and each tile is 16x16; a 32x32 tree needs two atlas cells (2 and 6) OR the atlas becomes 64x32. Choose: enlarge atlas to 64x32, tree occupies cells (2,0)+(6,0) top and (2,1)+(6,1) bottom; wall stays 16x16 at cell 3.)

- [ ] **Step 2: Run — verify fail.**

- [ ] **Step 3: Implement in `tiles.gd`**

Grow the atlas to 64x32 and draw the tree as a 32x32 composition in columns 2-3 (top) and 6-7 (bottom):
```gdscript
static func _fill_tile_detailed(img: Image, col: int, c: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 100 + col
	if col == GameTiles.Tile.TREE:
		_draw_tree(img, c)
		return
	for y in 16:
		for x in 16:
			var color := c
			if y < 2:
				color = c.darkened(0.2)
			elif y >= 14:
				color = c.darkened(0.1)
			elif rng.randf() < 0.08:
				color = c.darkened(0.08)
			img.set_pixel(col * 16 + x, y, color)

static func _draw_tree(img: Image, c: Color) -> void:
	var trunk := Color(0.42, 0.26, 0.12)
	for y in 32:
		for x in 32:
			var px := Vector2(x - 16.0, y - 24.0)
			var d := px.length()
			if d <= 9.0 and y >= 4:
				var canopy := c.lightened(0.15) if (d < 6.0) else c
				img.set_pixel(32 + x, y, canopy)
			elif y >= 20 and y <= 31 and x >= 13 and x <= 18:
				img.set_pixel(32 + x, y, trunk)
```
And in `build_tileset`, change the source creation so tiles 2-3 exist at row 0 AND row 1:
```gdscript
src.texture_region_size = Vector2i(16, 16)
for x in 4:
	src.create_tile(Vector2i(x, 0))
for x in 4:
	src.create_tile(Vector2i(x, 1))
```
`_atlas_texture` fills row 1 with the same base colors as row 0 (`_fill_tile_detailed` per tile, tree gets drawn in both row-0 cell 2 and row-1 cell 6 area via the 32x32 block at atlas x 32-63).

- [ ] **Step 4: Update `map_builder.gd`** — when a TREE cell is placed, also place a visual anchor at the tile above:
```gdscript
if tile == GameTiles.Tile.TREE:
	tml.set_cell(Vector2i(x, y - 1), 0, Vector2i(2, 1))
	tml.set_cell(Vector2i(x, y), 0, Vector2i(2, 0))
```
(Skip `y - 1` when y == 0 — layout trees are never in row 0 in current rooms; add the guard anyway.) Keep the 16x16 solid body at the base cell.

- [ ] **Step 5: Run suite — verify pass** (existing tile tests + new tree test; adjust the new test's atlas coordinates if implementation differs, but keep the trunk/canopy assertions).

- [ ] **Step 6: Commit**

```bash
git add scripts/tiles/tiles.gd scripts/rooms/map_builder.gd tests/test_tiles.gd
git commit -m "feat: trees as canopy+trunk props, wall bevel"
```

---
### Task 4: Props — flowers, rocks, save point rip, NPC swap

**Files:**
- Modify: `scripts/rooms/drizzle_fields.gd`, `scripts/rooms/grumble_woods.gd` (prop scattering)
- Modify: `scripts/rooms/save_point.gd` (SAVE gif rip)
- Modify: `scripts/rooms/npc.gd` (Froggit overworld rip)
- Test: `tests/test_props.gd` (new)

**Interfaces:**
- Consumes: overworld assets (Task 1).
- Produces: `Sprites.prop_texture(name: String) -> Texture2D` (loads `res://assets/sprites/overworld/<name>.png` or `.gif`; cached); rooms spawn `Sprite2D` props at fixed decor positions; save point uses `save_point.gif` (AnimatedTexture); toad NPC uses `froggit_npc.png`.

- [ ] **Step 1: Write the failing test** — `tests/test_props.gd`:

```gdscript
extends RefCounted

func test_prop_textures_load() -> void:
	for name in ["rock.png", "golden_flowers.png", "froggit_npc.png"]:
		var tex := Sprites.prop_texture(name)
		TestHelper.is_true(tex != null, "prop loads: " + name)

func test_save_point_uses_rip() -> void:
	var sp := SavePoint.new()
	sp._ready()
	var spr := sp.get_node_or_null("StarSprite")
	TestHelper.is_true(spr != null, "save star sprite exists")
	if spr != null:
		TestHelper.is_true(spr.texture != null, "save star uses texture")
	sp.free()

func test_rooms_have_props() -> void:
	var drizzle := preload("res://scripts/rooms/drizzle_fields.gd").new()
	drizzle._ready()
	var count := 0
	for child in drizzle.get_children():
		if child is Sprite2D and child.name.begins_with("Prop"):
			count += 1
	TestHelper.is_true(count >= 3, "drizzle has at least 3 props: " + str(count))
	drizzle.free()
```
(Follow the repo's existing room test style — rooms may need `_ready` guards; if a room test pattern already exists (e.g. smoke tests), mirror it.)

- [ ] **Step 2: Run — verify fail.**

- [ ] **Step 3: Implement**

`sprites.gd`:
```gdscript
static var _prop_cache := {}

static func prop_texture(name: String) -> Texture2D:
	if _prop_cache.has(name):
		return _prop_cache[name]
	var path := "res://assets/sprites/overworld/" + name
	var tex := load(path) as Texture2D
	_prop_cache[name] = tex
	return tex
```
`save_point.gd` — replace the procedural star with:
```gdscript
var _star: Sprite2D
# in _ready:
_star = Sprite2D.new()
_star.name = "StarSprite"
_star.texture = Sprites.prop_texture("save_point.gif")
_star.scale = Vector2(1.5, 1.5)
add_child(_star)
```
Keep the existing pulse tween on `_star.scale`. `npc.gd` — replace the toad texture with:
```gdscript
sprite.texture = Sprites.prop_texture("froggit_npc.png")
sprite.scale = Vector2(1.0, 1.0)
```
Rooms — add a helper in each room `_ready` (after tiles are added):
```gdscript
func _spawn_props() -> void:
	var spots: Array[Vector2] = [Vector2(96, 96), Vector2(160, 320), Vector2(480, 160), Vector2(560, 400)]
	for i in spots.size():
		var p := Sprite2D.new()
		p.name = "Prop" + str(i)
		p.texture = Sprites.prop_texture("golden_flowers.png" if i % 2 == 0 else "rock.png")
		p.scale = Vector2(0.5, 0.5)
		p.position = spots[i]
		add_child(p)
```
Call `_spawn_props()` from each room's `_ready`. (Vary positions per room; keep them off walkable paths from the layouts.)

- [ ] **Step 4: Run suite — verify pass.**

- [ ] **Step 5: Commit**

```bash
git add scripts/util/sprites.gd scripts/rooms/save_point.gd scripts/rooms/npc.gd scripts/rooms/drizzle_fields.gd scripts/rooms/grumble_woods.gd tests/test_props.gd
git commit -m "feat: props - flowers, rocks, save point rip, froggit npc"
```

---
### Task 5: GrumbleWoods void fix + room polish

**Files:**
- Modify: `scripts/rooms/grumble_woods.gd` (pad grid to 40x30, centered)
- Modify: `scripts/tiles/tiles.gd` (add lighten speckles, grass tufts on GRASS)
- Test: `tests/test_tiles.gd` (append)

**Interfaces:**
- Consumes: existing layout/parse pipeline.
- Produces: `grumble_woods.gd` grid padded to 40 rows (30 columns kept, centered horizontally by padding 5 cols each side) so the room fills 640x480; GRASS tiles gain 4% lightened speckle + occasional 2x1 grass-tuft pixels in the top-left of the tile.

- [ ] **Step 1: Write the failing test** (append to `tests/test_tiles.gd`):

```gdscript
func test_grass_has_light_speckles() -> void:
	var img := GameTiles._atlas_texture({}).get_image()
	var base := Color(0.3, 0.5, 0.28)
	var lighter := false
	for y in 16:
		for x in 16:
			var c := img.get_pixel(x, y)
			if c.r > base.r + 0.05 and c.g > base.g + 0.05:
				lighter = true
	TestHelper.is_true(lighter, "grass has lighter speckles")
```

- [ ] **Step 2: Run — verify fail.**

- [ ] **Step 3: Implement** — in `tiles.gd` `_fill_tile_detailed` (GRASS branch):
```gdscript
if col == GameTiles.Tile.GRASS:
	var roll := rng.randf()
	if roll < 0.04:
		color = c.lightened(0.1)
	elif roll > 0.96:
		color = c.darkened(0.12)
	elif y == 0 and x < 3 and rng.randf() < 0.5:
		color = Color(0.45, 0.65, 0.32)
```
(In drizzle, the "grassy" floor stays; snow palette keeps its own look via palette colors.)
`grumble_woods.gd` — after parsing, pad:
```gdscript
var parsed: Dictionary = LayoutParser.parse(RAW_LAYOUT)
var grid: Array = parsed["grid"]
var padded: Array = []
var pad_top := 8
var pad_side := 5
for row in grid:
	var new_row: Array = []
	for i in pad_side:
		new_row.append(GameTiles.Tile.WALL)
	for cell in row:
		new_row.append(cell)
	for i in pad_side:
		new_row.append(GameTiles.Tile.WALL)
	padded.append(new_row)
for i in pad_top:
	padded.push_front(_blank_row(padded[0].size(), GameTiles.Tile.TREE))
for i in pad_top:
	padded.push_back(_blank_row(padded[0].size(), GameTiles.Tile.TREE))
parsed["grid"] = padded
```
with:
```gdscript
func _blank_row(width: int, fill: int) -> Array:
	var row: Array = []
	for i in width:
		row.append(fill)
	return row
```
Adjust the camera/room-size code to use `parsed["grid"]` after padding (the camera centers on the padded room).

- [ ] **Step 4: Run suite — verify pass.**

- [ ] **Step 5: Commit**

```bash
git add scripts/rooms/grumble_woods.gd scripts/tiles/tiles.gd tests/test_tiles.gd
git commit -m "feat: grumble woods fills viewport, grass tuft speckles"
```

---
### Task 6: Full verify, export, report

- [ ] **Step 1: Full suite** — run suite command; grep `.superpowers\overworld1.txt` for `SCRIPT ERROR|FAIL` — must be empty; must contain ALL TESTS PASSED.

- [ ] **Step 2: Export + boot check** — export to `dist\SoulHeart.exe`, boot `--headless --quit-after 60` -> ExitCode 0, size > 99,000,000 bytes.

- [ ] **Step 3: Commit import sidecars** (`git add assets/sprites/overworld` + `.uid`/`.import`) as `chore: overworld sprite import sidecars`.

- [ ] **Step 4: Update ledger** `.superpowers\sdd\progress.md`.

- [ ] **Step 5: Manual playtest checklist for LO** — walk both rooms: Frisk faces each direction while moving; trees have trunks; flowers/rocks visible; save star spins with the rip; GrumbleWoods has no black bars; toad is now Froggit.
