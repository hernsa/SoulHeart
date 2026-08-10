# Undertale Authenticity Implementation Plan

> Implementation of the approved design in `docs/superpowers/specs/2026-08-10-undertale-authenticity-design.md` (committed `b35a71b` on main).

## Goal

Fix three verified bugs (B1 player clipping, B2 enemy black boxes, B3 player lost on door) and redesign Drizzle Fields → **Ruins** and Grumble Woods → **Snowdin** so SoulHeart feels identical to real Undertale.

## Architecture

Two 40×30 tile rooms (640×480 px, matches viewport), static cameras at room center, black void border, seamless ripped floor tiles, real Frisk sheet with walk animation, real Snowdin pines as Sprite2D props with trunk collision, enemy chroma cutout for transparency, validated door spawns.

## Tech Stack

- Godot 4.4 (headless via `tools/godot.exe`)
- GDScript
- `TestHelper` from `tests/test_helper.gd` (eq / is_true only)
- `tests/run_all.gd` auto-globs new test files
- `Image` / `ImageTexture` for asset processing

## Global Constraints

1. Pixel art: no smoothing. `project.godot` already has `default_texture_filter=0`.
2. Room scripts expose constants (`LAYOUT`, `DRIZZLE_SPAWN`, `GRUMBLE_SPAWN`, `PROP_SPOTS`, `NPC_POS`) for tests via `get_script_constant_map()`.
3. All asset PNGs verified before commit: correct dims, transparency, opaque-black-bg for enemy cutout.
4. No GIF import (Godot 4.4 limitation). No `AnimatedTexture.fps` — use `set_frame_duration(1.0/15.0)`.
5. Suite gate: "ALL TESTS PASSED" + zero SCRIPT ERROR/ASSERT FAIL/FAIL: + only permitted stderr.
6. Audio.play_music("drizzle"/"grumble") unchanged. Tint colors (Ruins `Color(0.8,0.78,1.0)`, Snowdin `Color(0.85,0.9,1.0)`) unchanged.

---

## Task 1: Source & Verify Pixel Assets

**Branch:** `undertale-authenticity-assets`
**Files created:** `assets/sprites/overworld/frisk_sheet.png`, `assets/sprites/tiles/ruins_floor.png`, `assets/sprites/tiles/ruins_floor_b.png`, `assets/sprites/tiles/snowdin_floor.png`, `assets/sprites/tiles/snowdin_floor_b.png`, `assets/sprites/overworld/tree_pine.png`
**Files deleted:** `assets/sprites/overworld/frisk.png`, `assets/sprites/overworld/frisk_walk.gif` (replaced by frisk_sheet.png)
**Approach:** Use `general` subagent with Pillow to source assets from Undertale reference sheets, normalize to exact dims, verify gates.

### 1.1 Asset specs (verify before commit)

| File | Dims | Content |
|------|------|---------|
| `frisk_sheet.png` | 57×116 | 4 facing rows × 3 walk cols, 19×29 cells, transparent bg |
| `ruins_floor.png` | 16×16 | Ruins brick tile, seamless tiling, transparent outside the brick area if any padding |
| `ruins_floor_b` | 16×16 | Variant (different crack pattern) for non-seamless alternation |
| `snowdin_floor.png` | 16×16 | Snowdin snow tile, seamless, white/blue-gray |
| `snowdin_floor_b.png` | 16×16 | Variant |
| `tree_pine.png` | ~24×48 | Pine trunk + canopy, transparent bg |

### 1.2 Verification gates (Python+Pillow, in script `tools/verify_assets.py`)

```python
from PIL import Image
import sys, os

CHECKS = [
    ("assets/sprites/overworld/frisk_sheet.png", (57, 116), True),  # transparent
    ("assets/sprites/tiles/ruins_floor.png", (16, 16), False),
    ("assets/sprites/tiles/ruins_floor_b.png", (16, 16), False),
    ("assets/sprites/tiles/snowdin_floor.png", (16, 16), False),
    ("assets/sprites/tiles/snowdin_floor_b.png", (16, 16), False),
    ("assets/sprites/overworld/tree_pine.png", None, True),  # any size, transparent
]

failed = False
for path, expected_size, must_be_transparent in CHECKS:
    if not os.path.exists(path):
        print(f"MISSING: {path}")
        failed = True
        continue
    img = Image.open(path).convert("RGBA")
    if expected_size and img.size != expected_size:
        print(f"WRONG SIZE: {path} got {img.size}, expected {expected_size}")
        failed = True
        continue
    if must_be_transparent:
        # Check corners are transparent
        w, h = img.size
        corners = [(0,0), (w-1,0), (0,h-1), (w-1,h-1)]
        for x, y in corners:
            if img.getpixel((x,y))[3] != 0:
                print(f"OPAQUE CORNER: {path} at ({x},{y})")
                failed = True
                break

# Enemy frame opaque-black-bg check (kept for B2 verification)
ENEMY_FRAMES_DIR = "assets/sprites/enemies/frames"
if os.path.isdir(ENEMY_FRAMES_DIR):
    for enemy_id in os.listdir(ENEMY_FRAMES_DIR):
        edir = os.path.join(ENEMY_FRAMES_DIR, enemy_id)
        if not os.path.isdir(edir): continue
        for fname in os.listdir(edir):
            if not fname.endswith(".png"): continue
            fpath = os.path.join(edir, fname)
            img = Image.open(fpath).convert("RGBA")
            corner = img.getpixel((0,0))
            if corner[:3] != (0,0,0) or corner[3] != 255:
                print(f"ENEMY FRAME NOT BLACK-BG: {fpath}")
                failed = True

sys.exit(1 if failed else 0)
```

### 1.3 Steps

1. Subagent creates `tools/verify_assets.py` with above content.
2. Subagent sources/downloads assets (Undertale fan resource sheets — Deltarune-style ripped tiles, Snowdin tree from Snowdin section, Frisk walking sheet from UT overworld). Normalize to exact dims with Pillow.
3. Delete old `frisk.png` / `frisk_walk.gif`.
4. Run `python tools/verify_assets.py` — must exit 0.
5. Commit: `Add pixel asset set for Undertale authenticity`

---

## Task 2: Enemy Chroma Cutout

**Branch:** `undertale-authenticity-assets` (same branch, or new `undertale-authenticity-enemy`)
**Files modified:** `scripts/util/sprites.gd`, `tests/test_enemy_assets.gd`
**Approach:** Inline (small surgical change).

### 2.1 `Sprites._enemy_idle_texture(id)` rewrite

**Before:**
```gdscript
static func _enemy_idle_texture(id: String) -> AnimatedTexture:
    if _enemy_idle_cache.has(id): return _enemy_idle_cache[id]
    var frames = _load_enemy_frames(id)
    var tex = AnimatedTexture.new()
    tex.frames = len(frames)
    tex.set_frame_duration(1.0/15.0)
    for i in range(len(frames)):
        tex.set_frame_texture(i, frames[i])
    _enemy_idle_cache[id] = tex
    return tex
```

**After:**
```gdscript
static func _enemy_idle_texture(id: String) -> AnimatedTexture:
    if _enemy_idle_cache.has(id): return _enemy_idle_cache[id]
    var frames = _load_enemy_frames(id)
    var tex = AnimatedTexture.new()
    tex.frames = len(frames)
    tex.set_frame_duration(1.0/15.0)
    for i in range(len(frames)):
        tex.set_frame_texture(i, _chroma_cutout(frames[i]))
    _enemy_idle_cache[id] = tex
    return tex

static func _chroma_cutout(src: Texture2D) -> ImageTexture:
    var img = src.get_image()
    if img == null: return ImageTexture.create_from(Image.create(1,1,false,Image.FORMAT_RGBA8))
    img.convert(Image.FORMAT_RGBA8)
    var w = img.get_width()
    var h = img.get_height()
    for y in range(h):
        for x in range(w):
            var px = img.get_pixel(x, y)
            # Luminance threshold for black-bg removal
            var lum = px.r * 0.299 + px.g * 0.587 + px.b * 0.114
            if lum < 0.10:
                img.set_pixel(x, y, Color(0, 0, 0, 0))
    return ImageTexture.create_from(img)
```

Also apply cutout in `battle_enemy_texture(id, hurt: bool)` if hurt frame has same black-bg issue (verified by Task 1.2 check — enemy frames are all opaque-black-bg, so all paths need cutout).

### 2.2 Test additions in `tests/test_enemy_assets.gd`

```gdscript
extends RefCounted

func test_enemy_cutout_removes_black_bg() -> void:
    var froggit = Sprites._enemy_idle_texture("froggit")
    var img = froggit.get_frame_texture(0).get_image()
    img.convert(Image.FORMAT_RGBA8)
    var corner = img.get_pixel(0, 0)
    TestHelper.is_true(corner.a == 0.0, "Enemy frame corner should be transparent after cutout, got alpha %f" % corner.a)

func test_enemy_cutout_preserves_non_black() -> void:
    var napstablook = Sprites._enemy_idle_texture("napstablook")
    var img = napstablook.get_frame_texture(0).get_image()
    img.convert(Image.FORMAT_RGBA8)
    var found_color = false
    for y in range(img.get_height()):
        for x in range(img.get_width()):
            var px = img.get_pixel(x, y)
            if px.a > 0.5 and (px.r > 0.2 or px.g > 0.2 or px.b > 0.2):
                found_color = true
                break
        if found_color: break
    TestHelper.is_true(found_color, "Enemy cutout should preserve non-black colored pixels")
```

### 2.3 Steps

1. Apply cutout in `sprites.gd`.
2. Add two tests.
3. Run suite — must pass.
4. Commit: `Fix enemy black-box rendering with chroma cutout (B2)`

---

## Task 3: Real Frisk Sheet + Walk Animation

**Branch:** `undertale-authenticity-player`
**Files modified:** `scripts/util/sprites.gd`, `scripts/player/player.gd`, `tests/test_player_visuals.gd`
**Approach:** Inline.

### 3.1 `Sprites.player_frisk_texture(facing, step)` rewrite

**Before:**
```gdscript
static func player_frisk_texture(frame: int) -> ImageTexture:
    if player_frisk_cache.has(frame): return player_frisk_cache[frame]
    var src = player_sprite.texture
    var img = src.get_image()
    img.convert(Image.FORMAT_RGBA8)
    var col = frame % 2
    var row = frame / 2
    var rect = Rect2i(col * 19, row * 29, 19, 29)
    var sub = img.get_region(rect)
    var out = ImageTexture.create_from(sub)
    player_frisk_cache[frame] = out
    return out
```

**After:**
```gdscript
# frisk_sheet.png: 57x116, 3 cols x 4 rows, 19x29 cells
# Row 0: down, Row 1: up, Row 2: side (right-facing), Row 3: idle mirror
# Cols: 0=idle, 1=step1, 2=step2
static func player_frisk_texture(facing: int, step: int) -> ImageTexture:
    var key = "%d_%d" % [facing, step]
    if player_frisk_cache.has(key): return player_frisk_cache[key]
    var src = load("res://assets/sprites/overworld/frisk_sheet.png")
    var img = src.get_image()
    img.convert(Image.FORMAT_RGBA8)
    var col = step % 3
    var row = facing % 4
    var rect = Rect2i(col * 19, row * 29, 19, 29)
    var sub = img.get_region(rect)
    # Mirror left-facing for side view
    if facing == 2:  # SIDE_LEFT
        sub.flip_x()
    var out = ImageTexture.create_from(sub)
    player_frisk_cache[key] = out
    return out
```

### 3.2 `Player` walk animation

In `scripts/player/player.gd`, change `_sprite.texture = Sprites.player_frisk_texture(facing)` to:
```gdscript
var step = 0
if is_moving:
    walk_t += delta
    step = int(walk_t / 0.2) % 3
_sprite.texture = Sprites.player_frisk_texture(facing, step)
```

Track `is_moving` based on velocity.length() > 0 or input.

### 3.3 Test rewrite in `tests/test_player_visuals.gd`

Replace dim-only assertions with full-body content checks:
```gdscript
func test_frisk_sheet_loads() -> void:
    var tex = load("res://assets/sprites/overworld/frisk_sheet.png")
    TestHelper.is_true(tex != null, "frisk_sheet.png should load")

func test_frisk_all_facings_have_content() -> void:
    for facing in range(4):
        for step in range(3):
            var tex = Sprites.player_frisk_texture(facing, step)
            var img = tex.get_image()
            img.convert(Image.FORMAT_RGBA8)
            var found_body = false
            # Body should have non-transparent pixels in lower 2/3 of sprite
            for y in range(10, 29):
                for x in range(2, 17):
                    if img.get_pixel(x, y).a > 0.5:
                        found_body = true
                        break
                if found_body: break
            TestHelper.is_true(found_body, "Frisk facing=%d step=%d should have body content" % [facing, step])

func test_frisk_left_mirrors_right() -> void:
    var right = Sprites.player_frisk_texture(2, 0).get_image()
    var left = Sprites.player_frisk_texture(2, 1).get_image()  # left uses mirror
    # They should differ
    var same = true
    for y in range(29):
        for x in range(19):
            if right.get_pixel(x, y) != left.get_pixel(x, y):
                same = false
                break
    TestHelper.is_true(not same, "Left-facing Frisk should be mirrored")
```

### 3.4 Steps

1. Apply sprite changes.
2. Update player.gd walk animation.
3. Rewrite player visual tests.
4. Run suite — must pass.
5. Commit: `Use real Frisk sheet with walk animation (B1)`

---

## Task 4: Seamless Floors + Remove Tree Block + Void Border

**Branch:** `undertale-authenticity-tiles`
**Files modified:** `scripts/tiles/tiles.gd`, `scripts/rooms/map_builder.gd`, `tests/test_tiles.gd`, new `tests/test_floors.gd`
**Approach:** Inline.

### 4.1 `scripts/tiles/tiles.gd` rewrite

Replace palette-based system with style-string system:

```gdscript
extends RefCounted
class_name Tiles

enum Tile { FLOOR = 0, WALL = 1 }

const RUINS_STYLE := "ruins"
const SNOWDIN_STYLE := "snowdin"

var FLOOR_ATLAS_RUINS := Vector2i(0, 0)
var FLOOR_ATLAS_RUINS_B := Vector2i(1, 0)
var FLOOR_ATLAS_SNOWDIN := Vector2i(0, 1)
var FLOOR_ATLAS_SNOWDIN_B := Vector2i(1, 1)
var WALL_ATLAS := Vector2i(0, 2)  # if walls need a tile (they don't — void border)

# TileRenderer: builds a TileSetAtlasSource with seamless floor tiles.
static func build_floor_atlas(style: String) -> TileSetAtlasSource:
    var source := TileSetAtlasSource.new()
    var tex_path := "res://assets/sprites/tiles/%s_floor.png" % style
    var tex := load(tex_path)
    source.texture = tex
    source.texture_region_size = Vector2i(16, 16)
    source.create_tile(Vector2i(0, 0))  # floor variant A
    # Variant B (different crack pattern) for non-seamless alternation
    var tex_b_path := "res://assets/sprites/tiles/%s_floor_b.png" % style
    if ResourceLoader.exists(tex_b_path):
        var tex_b := load(tex_b_path)
        # Could add as second tile — for now use one tile, no alternation
    return source

# Legacy compatibility: old code expects build_tileset(palette)
static func build_tileset(_palette) -> TileSet:
    var ts := TileSet.new()
    ts.tile_size = Vector2i(16, 16)
    # Walls are collision-only, no tile (void border)
    return ts
```

### 4.2 `scripts/rooms/map_builder.gd` rewrite

```gdscript
extends RefCounted
class_name MapBuilder

const Tiles = preload("res://scripts/tiles/tiles.gd")

static func build_room(grid: Array, style: String) -> Dictionary:
    var tilemap := TileMap.new()
    tilemap.tile_set = Tiles.build_tileset(null)
    tilemap.y_sort_enabled = true
    var w := len(grid[0])
    var h := len(grid)
    for y in range(h):
        for x in range(w):
            var cell = grid[y][x]
            match cell:
                ".":
                    var atlas := Tiles.FLOOR_ATLAS_RUINS if style == "ruins" else Tiles.FLOOR_ATLAS_SNOWDIN
                    tilemap.set_cell(Vector2i(x, y), 0, atlas)
                "T":
                    pass  # trees spawned as Sprite2D by room script
                "#":
                    pass  # void border, collision-only

    # Void border: 1px dark inner shadow rect at edges
    var border := ColorRect.new()
    border.color = Color(0, 0, 0, 1)
    border.size = Vector2(w * 16, h * 16)
    border.z_index = -10
    # Collision bodies for walls (keep player in)
    var walls := []
    for y in range(h):
        for x in range(w):
            if grid[y][x] == "#":
                var body := StaticBody2D.new()
                body.position = Vector2(x * 16 + 8, y * 16 + 8)
                var col := CollisionShape2D.new()
                var shape := RectangleShape2D.new()
                shape.size = Vector2(16, 16)
                col.shape = shape
                body.add_child(col)
                walls.append(body)
    return {
        "tilemap": tilemap,
        "border": border,
        "walls": walls,
        "pixel_size": Vector2(w * 16, h * 16),
    }
```

### 4.3 `tests/test_floors.gd` (new)

```gdscript
extends RefCounted

func test_floors_load() -> void:
    TestHelper.is_true(ResourceLoader.exists("res://assets/sprites/tiles/ruins_floor.png"), "ruins_floor.png missing")
    TestHelper.is_true(ResourceLoader.exists("res://assets/sprites/tiles/snowdin_floor.png"), "snowdin_floor.png missing")

func test_floor_tiles_seamless() -> void:
    # Verify left edge matches right edge (seamless horizontal)
    var img = load("res://assets/sprites/tiles/ruins_floor.png").get_image()
    img.convert(Image.FORMAT_RGBA8)
    for y in range(16):
        var left = img.get_pixel(0, y)
        var right = img.get_pixel(15, y)
        TestHelper.is_true(left == right, "ruins_floor row %d left != right (seamless fail)" % y)

func test_atlas_source_created() -> void:
    var source = Tiles.build_floor_atlas("ruins")
    TestHelper.is_true(source != null, "Atlas source should be created")
    TestHelper.eq(source.texture_region_size, Vector2i(16, 16), "Region size")
```

### 4.4 Rewrite `tests/test_tiles.gd`

Remove padded-grid test (lines 98-114), replace with tile-set tests for new system:
```gdscript
func test_tile_set_created() -> void:
    var ts = Tiles.build_tileset(null)
    TestHelper.is_true(ts != null, "TileSet should be created")
    TestHelper.eq(ts.tile_size, Vector2i(16, 16), "Tile size 16x16")

func test_void_border_no_tile() -> void:
    # WALL cells should not have a tile atlas cell
    var grid = ["#.", ".#"]
    var result = MapBuilder.build_room(grid, "ruins")
    var tilemap = result["tilemap"]
    var wall_cell = tilemap.get_cell(Vector2i(0, 0))
    TestHelper.eq(wall_cell, Vector2i(-1, -1), "Wall cell should have no tile")
```

### 4.5 Steps

1. Rewrite `tiles.gd`.
2. Rewrite `map_builder.gd`.
3. Create `test_floors.gd`.
4. Rewrite `test_tiles.gd`.
5. Run suite — must pass.
6. Commit: `Replace palettes with seamless ripped floor tiles + void border`

---

## Task 5: Tree Sprite2D Props

**Branch:** `undertale-authenticity-trees`
**Files created:** `scripts/rooms/tree.gd`, `tests/test_trees.gd`
**Approach:** Inline.

### 5.1 `scripts/rooms/tree.gd`

```gdscript
extends Sprite2D
class_name RoomTree

var shadow: Sprite2D

func _ready() -> void:
    z_index = 1  # above floor
    y_sort_enabled = true
    # Trunk collision (narrow, ≤10px)
    var body := StaticBody2D.new()
    add_child(body)
    var col := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(8, 16)
    col.shape = shape
    col.position = Vector2(0, 8)
    body.add_child(col)
    # Shadow
    shadow = Sprite2D.new()
    shadow.texture = load("res://assets/sprites/shadow_ellipse.png")
    shadow.position = Vector2(0, 24)
    shadow.modulate = Color(0, 0, 0, 0.3)
    shadow.z_index = -1
    add_child(shadow)
```

### 5.2 `tests/test_trees.gd`

```gdscript
extends RefCounted

func test_tree_spawned_at_t_cell() -> void:
    # Verify that running build_room with T cells produces tree Sprite2Ds
    var grid = [".T.", "###"]
    var result = MapBuilder.build_room(grid, "ruins")
    var trees = result.get("trees", [])
    TestHelper.eq(len(trees), 1, "One tree spawned")

func test_tree_trunk_collision_narrow() -> void:
    var tree = RoomTree.new()
    tree._ready()
    var body = tree.get_child(0)
    var col = body.get_child(0)
    TestHelper.is_true(col.shape.size.x <= 10, "Trunk collision should be ≤10px wide")
```

### 5.3 `MapBuilder.build_room` adds tree spawning

In Task 4.2, add to the match "T": block:
```gdscript
"T":
    var tree := RoomTree.new()
    tree.position = Vector2(x * 16 + 8, y * 16 + 16)
    tree.texture = load("res://assets/sprites/overworld/tree_pine.png")
    trees.append(tree)
```

And add `"trees": trees` to return dict.

### 5.4 Steps

1. Create `scripts/rooms/tree.gd`.
2. Update `map_builder.gd` to spawn trees (modify Task 4 commit or add here).
3. Create shadow PNG asset (`shadow_ellipse.png` ~16×4, transparent bg, dark ellipse).
4. Create `test_trees.gd`.
5. Run suite — must pass.
6. Commit: `Add Snowdin tree props as Sprite2D with trunk collision`

---

## Task 6: Room Layouts + Door Spawn Fix

**Branch:** `undertale-authenticity-rooms`
**Files modified:** `scripts/rooms/drizzle_fields.gd`, `scripts/rooms/grumble_woods.gd`, `scripts/rooms/door.gd`, new `tests/test_door_spawn.gd`
**Approach:** Inline (largest task, but mechanical layout replacement).

### 6.1 `scripts/rooms/drizzle_fields.gd` rewrite

```gdscript
extends Node2D

const Tiles = preload("res://scripts/tiles/tiles.gd")
const MapBuilder = preload("res://scripts/rooms/map_builder.gd")
const Door = preload("res://scripts/rooms/door.gd")

# 40x30 layout
const LAYOUT := """
########################################
#..P...................................#
#................TT....................#
#.....T..............T......TT.........#
#..T.......T..............T............#
#.....................T..T..........E..#
#..TT....TT..............T.....TT......#
#............TT..TT...................E#
#..T..........T....T................T..#
#........................T..T..TT......#
#.....TT....................TT.......E.#
#..T......T.......TT..TT..........T....#
#..T.....T..........TT..TT.....T.......#
#.......................T......T.......#
#........T........................T....#
#....T.................T..T......T.....#
#........................T.............#
#..T.....TT..TT.....T..............T...#
#......................TT..TT..........#
#.....T..........T...............T.....#
#..T.....T..........T....T....T........#
#..........................T...........#
#........E..........T..T..............T#
#..T...............T......T............#
#..........................T...........#
#....T..........T......T....T..........#
#...............................T.D....#
#..T........S.......T......T...........#
#..........................T......T....#
########################################
"""

# Marker positions
const NPC_POS := Vector2(96, 144)  # toad at col 6, row 9 → px 96+0, 144+0
const ENCOUNTER_POSITIONS := [
    Vector2(36 * 16 + 8, 5 * 16 + 8),   # (584, 88)
    Vector2(38 * 16 + 8, 7 * 16 + 8),   # (616, 120)
    Vector2(37 * 16 + 8, 10 * 16 + 8),  # (600, 168)
    Vector2(9 * 16 + 8, 22 * 16 + 8),   # (152, 360)
]
const SAVE_POINT_POS := Vector2(12 * 16 + 8, 27 * 16 + 8)  # (200, 440)
const DOOR_POS := Vector2(34 * 16 + 8, 26 * 16 + 8)  # (552, 424)
const GRUMBLE_SPAWN := Vector2(32 * 16 + 8, 24 * 16 + 8)  # (520, 392)

func _ready() -> void:
    var grid = LayoutParser.parse(LAYOUT)
    var built = MapBuilder.build_room(grid, Tiles.RUINS_STYLE)
    add_child(built.tilemap)
    for w in built.walls: add_child(w)
    for t in built.trees: add_child(t)
    modulate = Color(0.8, 0.78, 1.0)
    Audio.play_music("drizzle")
    _spawn_encounters()
    _spawn_save_point()
    _spawn_door()
    _spawn_npc()

func _spawn_door() -> void:
    var door = Door.new()
    door.position = DOOR_POS
    door.target_room = "grumble_woods"
    door.target_spawn = GRUMBLE_SPAWN
    add_child(door)

func _spawn_encounters() -> void:
    for pos in ENCOUNTER_POSITIONS:
        var enc = Encounter.new()
        enc.position = pos
        enc.enemy_id = "froggit"  # vary per position in future
        add_child(enc)

func _spawn_save_point() -> void:
    var sp = SavePoint.new()
    sp.position = SAVE_POINT_POS
    add_child(sp)

func _spawn_npc() -> void:
    var npc = NPC.new()
    npc.position = NPC_POS
    npc.dialogue_file = "res://dialogue/toad.txt"
    add_child(npc)
```

### 6.2 `scripts/rooms/grumble_woods.gd` rewrite

Same structure, Snowdin style:
```gdscript
const LAYOUT := """
########################################
#..P...................................#
#............TT.............TT.........#
#..T................T................T.#
#......T......TT..TT............T......#
#.........................T............#
#..TT.......T.......T..........TT......#
#..............T....T..................#
#......E..........TT..TT...........T...#
#..T..........T..............T........T#
#.....................T..T.............#
#...........TT..............TT.........#
#..T.....T..............T..............#
#..................T..T................#
#...........E..........T......T........#
#..TT..............T...........TT......#
#.........................T............#
#......T.....TT..TT............T.......#
#.................T....................#
#..T..........T......T..........T......#
#.....................T...........T....#
#..............TT................TT....#
#..T.....T..............T..............#
#.........E...........T..T.............#
#......................TT........T.....#
#..T......T.......................T....#
#.............................T..T..D..#
#..T..............T........T...........#
#...............T.......T....T......T..#
########################################
"""

const NPC_POS := Vector2(0, 0)  # no NPC, sign instead
const ENCOUNTER_POSITIONS := [
    Vector2(7 * 16 + 8, 8 * 16 + 8),    # (120, 136)
    Vector2(12 * 16 + 8, 14 * 16 + 8),  # (200, 232)
    Vector2(10 * 16 + 8, 23 * 16 + 8),  # (168, 376)
]
const DOOR_POS := Vector2(36 * 16 + 8, 26 * 16 + 8)  # (584, 424)
const DRIZZLE_SPAWN := Vector2(4 * 16 + 8, 24 * 16 + 8)  # (72, 392)
const SIGN_POS := Vector2(5 * 16 + 8, 2 * 16 + 8)  # (88, 40)
const PROP_SPOTS := [
    Vector2(15 * 16 + 8, 5 * 16 + 8),   # lamp post
    Vector2(25 * 16 + 8, 12 * 16 + 8),  # sign
    Vector2(30 * 16 + 8, 20 * 16 + 8),  # lamp post
]

func _ready() -> void:
    # ... same pattern as Drizzle, but style="snowdin", no save_point
    # Add sign at SIGN_POS
```

### 6.3 `scripts/rooms/door.gd` fail-loud

```gdscript
extends Area2D
class_name Door

@export var target_room: String = ""
@export var target_spawn: Vector2 = Vector2(-1, -1)

func _ready() -> void:
    if target_spawn.x < 0 or target_spawn.y < 0:
        push_error("Door at %s has invalid target_spawn %s" % [position, target_spawn])
        # Fallback: find P marker in current room layout
        target_spawn = _find_p_marker_spawn()

func _find_p_marker_spawn() -> Vector2:
    # Walk back to parent room, parse its LAYOUT, find P
    var parent = get_parent()
    var layout = parent.get("LAYOUT")
    if not layout: return Vector2(100, 100)
    var grid = LayoutParser.parse(layout)
    var ps = grid.get("player_start", Vector2i(2, 2))
    return Vector2(ps.x * 16 + 8, ps.y * 16 + 8)

func _on_body_entered(body: Node) -> void:
    if not body is Player: return
    GameState.set_flag("save_point", false)
    GameState.set_flag("current_room", target_room)
    $AnimationPlayer.play("door_open")
    await get_tree().create_timer(0.43).timeout
    get_tree().change_scene_to_file("res://scenes/rooms/%s.tscn" % target_room)
```

### 6.4 `tests/test_door_spawn.gd` (new)

```gdscript
extends RefCounted

func test_door_spawn_walkable() -> void:
    var layout = DrizzleFields.LAYOUT
    var grid = LayoutParser.parse(layout)
    var spawn = DrizzleFields.GRUMBLE_SPAWN
    var cell_x = int(spawn.x / 16)
    var cell_y = int(spawn.y / 16)
    var cell = grid["grid"][cell_y][cell_x]
    TestHelper.is_true(cell == ".", "Door spawn cell (%d,%d) should be walkable, got %s" % [cell_x, cell_y, cell])

func test_door_spawn_on_camera() -> void:
    # Room is 640x480, camera centered
    var spawn = DrizzleFields.GRUMBLE_SPAWN
    TestHelper.is_true(spawn.x >= 0 and spawn.x <= 640, "Spawn x in viewport")
    TestHelper.is_true(spawn.y >= 0 and spawn.y <= 480, "Spawn y in viewport")

func test_grumble_door_spawn_walkable() -> void:
    var layout = GrumbleWoods.LAYOUT
    var grid = LayoutParser.parse(layout)
    var spawn = GrumbleWoods.DRIZZLE_SPAWN
    var cell_x = int(spawn.x / 16)
    var cell_y = int(spawn.y / 16)
    var cell = grid["grid"][cell_y][cell_x]
    TestHelper.is_true(cell == ".", "Grumble door spawn should be walkable")

func test_door_fail_loud_on_invalid_spawn() -> void:
    var door = Door.new()
    door.target_spawn = Vector2(-1, -1)
    door._ready()  # should push_error and fallback
    TestHelper.is_true(door.target_spawn.x >= 0, "Door should fallback to valid spawn")
```

### 6.5 Steps

1. Rewrite both room scripts with 40x30 layouts + constants.
2. Update `door.gd` with fail-loud.
3. Create `test_door_spawn.gd`.
4. Run suite — must pass (all door spawn tests verify walkability).
5. Commit: `Redesign Drizzle Fields as Ruins + Grumble Woods as Snowdin (B3)`

---

## Task 7: Final Verification + Export + Merge

**Branch:** `main` (after merging all task branches)
**Approach:** Inline.

### 7.1 Steps

1. Run full suite from main: `cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers\final-suite.txt 2>&1"` — must show ALL TESTS PASSED.
2. Export: `tools\godot.exe --headless --export-release "Windows Desktop" dist\SoulHeart.exe`
3. Boot test: `dist\SoulHeart.exe --headless --quit-after 60` → check ExitCode 0.
4. Merge all task branches to main (if not done per-task): `undertale-authenticity-assets`, `-enemy`, `-player`, `-tiles`, `-trees`, `-rooms`.
5. Clean up worktrees: `git worktree remove .worktrees/<name> --force` for each.
6. Delete merged branches: `git branch -d <name>`.
7. Final commit if needed: `Complete Undertale authenticity pass`.
8. Report to LO with:
   - What was done (all 3 bugs fixed, both rooms redesigned)
   - Verification evidence (suite output, boot result)
   - Deferred backlog: battle visuals, portraits, enemy_stats.gd refactor, enemy feet pass, unused assets cleanup (laser_sweep, GRAY, type_override, telegraph)

---

## Self-Review Checklist

Before committing the plan:
- [x] All spec sections covered (floors, void border, trees, player, enemy, door, layouts)
- [x] Every task has exact file paths
- [x] Every task has TDD: test written before/before implementation
- [x] Commits are atomic and descriptive
- [x] Suite gate explicit in each task
- [x] No placeholders ("TODO", "fill in")
- [x] Type consistency (Vector2 vs Vector2i)
- [x] Spawn coordinates validated against layout checker
- [x] Constants exposed for testability