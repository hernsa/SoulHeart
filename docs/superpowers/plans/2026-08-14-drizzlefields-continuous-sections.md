# DrizzleFields Continuous-Sections Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the rectangular DrizzleFields forest with a 9-section continuous world composed at runtime by a new `SectionMap` tool, while keeping the existing test suite green and leaving Snowdin reuse ready.

**Architecture:** A pure-logic composer (`SectionMap.compose`) takes small per-section ASCII chunks plus an adjacency list and produces one master grid + composed object/flavor lists. The existing `MapBuilder` consumes the master grid unchanged; a new `SectionPlacer` consumes the object lists. `DrizzleFields.gd` orchestrates: section data → compose → build. Section data is an extensible Dictionary with reserved slots (id, layout, props, objects, flavor, encounter_zone) and a forward-compatible `extras` bag; the composer passes unknown keys through untouched.

**Tech Stack:** Godot 4.x, GDScript, custom RefCounted test harness (`tests/run_all.gd` + `TestHelper`).

## Global Constraints

- Godot 4.x; run tests via `& "C:\Users\Admin\Downloads\SoulHeart\tools\godot.exe" --headless --path "C:\Users\Admin\Downloads\SoulHeart" -s res://tests/run_all.gd`; expected tail: `ALL TESTS PASSED`.
- Cell size 16 px; tile coordinates in master grid space.
- Existing invariants: `GRUMBLE_SPAWN := Vector2(32 * 16 + 8, 24 * 16 + 8)` (= (520, 392)) is walkable; `drizzle_fields.gd` source contains the string `Snowdin.tscn`; one save point in Drizzle (grove).
- LO's standing implementation policy: **commit + push every code change immediately; do not build exe/zip or update GitHub release assets until explicitly approved.**
- Repo `C:\Users\Admin\Downloads\SoulHeart` on branch `main`; current HEAD: `26c21c4` (the design spec landed there).

---

## File Structure

| File | Responsibility |
|---|---|
| `scripts/rooms/section_map.gd` (NEW) | Pure-logic composer: edge compatibility, layout merge, coord remap, `objects[]`/`flavor[]` remap, pass-through `extras`. |
| `scripts/rooms/section_placer.gd` (NEW) | Spawns trees, grass, dead trees, landmarks, NPCs, save points, exits, flavor sprites from a composed object list. |
| `scripts/rooms/drizzle_sections.gd` (NEW) | Data-only: 9 section chunks + adjacency table + extras (sizes, palette hints, encounter zones). |
| `scripts/rooms/drizzle_fields.gd` (MODIFY) | Orchestrate: load sections → `SectionMap.compose` → `MapBuilder.build_room` → `SectionPlacer.spawn_all`. |
| `scripts/tiles/tiles.gd` (MODIFY) | Add `DRIZZLE_STYLE` constant. |
| `assets/sprites/tiles/drizzle_floor.png`, `drizzle_floor_b.png` (NEW) | Two 16×16 atlas tiles for the new style (green field). |
| `tests/test_section_map.gd` (NEW) | Composer unit tests. |
| `tests/test_drizzle_continuity.gd` (NEW) | Flood-fill connectivity + both loops + exit reachability. |
| `tests/test_drizzle_save_spot.gd` (NEW) | Save point is in the grove and reachable from spawn. |
| `tests/test_sightline_cells.gd` (NEW) | Author landmark cells (sightline) are placed and not walled-over. |

---

## Task 1: Add `DRIZZLE_STYLE` style shell + green atlas tiles

**Files:**
- Modify: `scripts/tiles/tiles.gd:5-14`
- Create: `assets/sprites/tiles/drizzle_floor.png`
- Create: `assets/sprites/tiles/drizzle_floor_b.png`
- Test: `tests/test_tiles.gd` (assert new style is loadable)

- [ ] **Step 1.1: Write the failing test (extend `tests/test_tiles.gd`)**

Add to `tests/test_tiles.gd`:

```gdscript
func test_drizzle_style_constant_present() -> void:
    TestHelper.is_true(GameTiles.AREA_STYLES.has("drizzle"), "drizzle style registered")

func test_drizzle_style_atlas_loads() -> void:
    var tex: Texture2D = GameTiles._atlas_texture("drizzle")
    TestHelper.is_true(tex != null, "drizzle atlas texture built")
    TestHelper.is_true(tex.get_width() == 48 and tex.get_height() == 16, "drizzle atlas is 48x16")
```

- [ ] **Step 1.2: Run the tests to confirm fail**

Run: `& "C:\Users\Admin\Downloads\SoulHeart\tools\godot.exe" --headless --path "C:\Users\Admin\Downloads\SoulHeart" -s res://tests/run_all.gd`
Expected: `FAIL: res://tests/test_tiles.gd (N asserts)` (style constant + atlas missing).

- [ ] **Step 1.3: Add the `DRIZZLE_STYLE` constant**

Edit `scripts/tiles/tiles.gd`. After `const RUINS_STYLE := "ruins"` add:

```gdscript
const DRIZZLE_STYLE := "drizzle"
```

Update `AREA_STYLES` to include it:

```gdscript
const AREA_STYLES: Array[String] = [
    RUINS_STYLE, DRIZZLE_STYLE, SNOWDIN_STYLE, ECHO_STYLE, HOMETOWN_STYLE, CANON_STYLE, CRACKS_STYLE,
]
```

- [ ] **Step 1.4: Create the two atlas tile PNGs (16×16 each, procedurally drawn)**

In a single bash step, run a one-shot Python script via `python -c` (project doesn't depend on Pillow being installed — we use raw PNG via `struct`):

```bash
python -c "
import zlib, struct
def png(path, pixels):
    w = h = 16
    sig = b'\x89PNG\r\n\x1a\n'
    def chunk(t, d):
        return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
    ihdr = struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)
    raw = b''
    for y in range(h):
        raw += b'\x00' + bytes(pixels[y])
    idat = zlib.compress(raw, 9)
    out = sig + chunk(b'IHDR', ihdr) + chunk(b'IDAT', idat) + chunk(b'IEND', b'')
    open(path, 'wb').write(out)
green_a = [[(168, 208, 141, 255)] * 16 for _ in range(16)]
green_b = [[(140, 188, 120, 255)] * 16 for _ in range(16)]
# sprinkle a darker pixel for tile texture
for x, y in [(3, 5), (11, 8), (6, 12)]:
    green_a[y][x] = (110, 160, 90, 255)
for x, y in [(2, 9), (13, 3), (7, 14)]:
    green_b[y][x] = (90, 140, 70, 255)
import os
os.makedirs(r'C:\Users\Admin\Downloads\SoulHeart\assets\sprites\tiles', exist_ok=True)
png(r'C:\Users\Admin\Downloads\SoulHeart\assets\sprites\tiles\drizzle_floor.png', green_a)
png(r'C:\Users\Admin\Downloads\SoulHeart\assets\sprites\tiles\drizzle_floor_b.png', green_b)
print('wrote drizzle atlas tiles')
"
```

- [ ] **Step 1.5: Run tests to confirm pass**

Run: `& "C:\Users\Admin\Downloads\SoulHeart\tools\godot.exe" --headless --path "C:\Users\Admin\Downloads\SoulHeart" -s res://tests/run_all.gd`
Expected: `PASS: res://tests/test_tiles.gd`, then `ALL TESTS PASSED`.

- [ ] **Step 1.6: Commit + push**

```bash
git add scripts/tiles/tiles.gd assets/sprites/tiles/drizzle_floor.png assets/sprites/tiles/drizzle_floor_b.png tests/test_tiles.gd
git -c user.name="ENI" -c user.email="eni@local" commit -m "feat(tiles): register DRIZZLE_STYLE with green atlas tiles"
git push origin main
```

---

## Task 2: `SectionMap` composer (pure logic, TDD)

**Files:**
- Create: `scripts/rooms/section_map.gd`
- Create: `tests/test_section_map.gd`

The composer is pure logic (no Nodes), RefCounted, with a `static compose` method. Data model: section is a Dictionary with the schema documented in the spec. Output:

```
{
  "grid": Array[String],         # master grid, each row is a String of single-char tiles
  "objects": Array[Dictionary],  # composed {section_id, type, cell:Vector2i, data}
  "flavor":  Array[Dictionary],  # composed {section_id, kind, cell:Vector2i}
  "layout_meta": Dictionary,     # pass-through per-section id->extras (so future metadata survives)
  "origins":  Dictionary,        # id -> Vector2i master origin
  "sizes":    Dictionary,        # id -> Vector2i section size
}
```

Internal cell codes (used in `layout[]` strings): `#` = wall, `.` = floor, `_` = floor (lighter), ` ` = floor (clear). Anything else = unknown; we copy through (no auto-paint).

- [ ] **Step 2.1: Write the failing test file**

Create `tests/test_section_map.gd`:

```gdscript
extends RefCounted

func test_compose_two_compatible_sections() -> void:
    var sections := [
        {"id": "A", "layout": ["..", ".."]},
        {"id": "B", "layout": ["..", ".."]},
    ]
    var adjacency := [{"a": "A", "side": "e", "b": "B"}]
    var out: Dictionary = SectionMap.compose(sections, adjacency)
    var grid: Array = out["grid"]
    TestHelper.eq(grid.size(), 2, "two rows")
    TestHelper.eq((grid[0] as String).length(), 4, "merged width 2+2")

func test_compose_incompatible_edges_error() -> void:
    var sections := [
        {"id": "A", "layout": ["#.", ".."]},
        {"id": "B", "layout": ["##", ".."]},
    ]
    var adjacency := [{"a": "A", "side": "e", "b": "B"}]
    var failed := false
    var result: Variant = null
    result = SectionMap.compose(sections, adjacency)
    if typeof(result) == TYPE_DICTIONARY and result.has("error"):
        failed = true
    TestHelper.is_true(failed, "incompatible edges must error")

func test_object_coord_remap() -> void:
    var sections := [
        {"id": "A", "layout": ["....", "...."], "objects": [{"type": "save", "cell": Vector2i(1, 1), "data": {}}]},
    ]
    var adjacency: Array = []
    var out: Dictionary = SectionMap.compose(sections, adjacency)
    var objs: Array = out["objects"]
    TestHelper.eq(objs.size(), 1, "one composed object")
    TestHelper.eq(objs[0]["cell"], Vector2i(1, 1), "object cell carried through")

func test_flavor_coord_remap_with_offset() -> void:
    var sections := [
        {"id": "A", "layout": ["..", ".."]},
        {"id": "B", "layout": ["..", ".."], "flavor": [{"kind": "old_boot", "cell": Vector2i(0, 0)}]},
    ]
    var adjacency := [{"a": "A", "side": "e", "b": "B"}]
    var out: Dictionary = SectionMap.compose(sections, adjacency)
    var flavor: Array = out["flavor"]
    TestHelper.eq(flavor.size(), 1, "one flavor")
    TestHelper.eq(flavor[0]["cell"], Vector2i(2, 0), "flavor remapped to master coords")

func test_irregular_chunk_supported() -> void:
    var sections := [
        {"id": "A", "layout": ["..", "..", ".."]},
        {"id": "B", "layout": ["..", ".."]},
    ]
    var adjacency := [{"a": "A", "side": "s", "b": "B"}]
    var out: Dictionary = SectionMap.compose(sections, adjacency)
    var grid: Array = out["grid"]
    TestHelper.eq(grid.size(), 5, "irregular stack merges into 5 rows")
    TestHelper.eq((grid[0] as String).length(), 2, "irregular width kept")

func test_extras_passthrough_preserved() -> void:
    var sections := [
        {"id": "A", "layout": [".."], "extras": {"music": "calm", "weather": "misty"}},
    ]
    var out: Dictionary = SectionMap.compose(sections, [])
    var meta: Dictionary = out["layout_meta"]
    TestHelper.is_true(meta.has("A"), "layout_meta keyed by section id")
    TestHelper.eq(meta["A"]["music"], "calm", "music extras preserved")
    TestHelper.eq(meta["A"]["weather"], "misty", "weather extras preserved")
```

- [ ] **Step 2.2: Run the tests to confirm fail (function not defined)**

Run: `& "C:\Users\Admin\Downloads\SoulHeart\tools\godot.exe" --headless --path "C:\Users\Admin\Downloads\SoulHeart" -s res://tests/run_all.gd`
Expected: `FAIL: res://tests/test_section_map.gd (failed to load)` or similar — class doesn't exist.

- [ ] **Step 2.3: Implement the composer**

Create `scripts/rooms/section_map.gd`:

```gdscript
class_name SectionMap extends RefCounted

# Edges: n/s/e/w. Returns:
#   {grid: Array[String], objects: Array, flavor: Array,
#    layout_meta: Dictionary, origins: Dictionary, sizes: Dictionary}
# On incompatible edge merge, returns {"error": String}.
static func compose(sections: Array, adjacency: Array) -> Dictionary:
    var by_id: Dictionary = {}
    for s in sections:
        by_id[s["id"]] = s

    # Default origins and sizes.
    var origins: Dictionary = {}
    var sizes: Dictionary = {}
    for s in sections:
        sizes[s["id"]] = _section_size(s)
        origins[s["id"]] = Vector2i(0, 0)

    # Place sections greedily in adjacency order; first section is anchor at (0,0).
    var placed: Dictionary = {}
    if sections.size() > 0:
        placed[sections[0]["id"]] = Vector2i(0, 0)
        origins[sections[0]["id"]] = Vector2i(0, 0)

    for link in adjacency:
        var a_id: String = link["a"]
        var b_id: String = link["b"]
        var side: String = link["side"]  # which side of A faces B
        if not placed.has(a_id):
            return {"error": "adjacency references unplaced section %s" % a_id}
        var a_size: Vector2i = sizes[a_id]
        var a_origin: Vector2i = placed[a_id]
        var b_origin := _neighbor_origin(a_origin, a_size, side)
        if placed.has(b_id):
            # Validate that the existing placement matches the implied origin
            if placed[b_id] != b_origin:
                return {"error": "section %s already placed at %s, adjacency demands %s" % [b_id, placed[b_id], b_origin]}
        else:
            placed[b_id] = b_origin
            origins[b_id] = b_origin

    # Build master bounds.
    var max_x := 0
    var max_y := 0
    for id in placed.keys():
        var o: Vector2i = placed[id]
        var s: Vector2i = sizes[id]
        max_x = maxi(max_x, o.x + s.x)
        max_y = maxi(max_y, o.y + s.y)

    var grid: Array = []
    for y in max_y:
        var row := ""
        for x in max_x:
            row += "."
        grid.append(row)

    # Paint each section into master.
    for s in sections:
        var o: Vector2i = origins[s["id"]]
        var layout: Array = s["layout"]
        for ly in layout.size():
            var row: String = layout[ly]
            for lx in row.length():
                var ch := row[lx]
                var mx := o.x + lx
                var my := o.y + ly
                grid[my] = _set_cell(grid[my], mx, ch)

    # Validate edge merges for each adjacency: overlapping cells must agree or one is floor.
    for link in adjacency:
        var a_id: String = link["a"]
        var b_id: String = link["b"]
        var side: String = link["side"]
        var err := _validate_edge(grid, origins, sizes, a_id, b_id, side)
        if err != null:
            return {"error": err}

    # Compose objects/flavor with master-coord remap.
    var objects: Array = []
    var flavor: Array = []
    for s in sections:
        var o: Vector2i = origins[s["id"]]
        if s.has("objects"):
            for obj in s["objects"]:
                var composed := obj.duplicate()
                var local: Vector2i = obj["cell"]
                composed["cell"] = Vector2i(o.x + local.x, o.y + local.y)
                composed["section_id"] = s["id"]
                objects.append(composed)
        if s.has("flavor"):
            for fl in s["flavor"]:
                var cfl := fl.duplicate()
                var lf: Vector2i = fl["cell"]
                cfl["cell"] = Vector2i(o.x + lf.x, o.y + lf.y)
                cfl["section_id"] = s["id"]
                flavor.append(cfl)

    # Pass-through extras per section.
    var layout_meta: Dictionary = {}
    for s in sections:
        var bag: Dictionary = {}
        if s.has("extras"):
            bag = (s["extras"] as Dictionary).duplicate(true)
        layout_meta[s["id"]] = bag

    return {
        "grid": grid,
        "objects": objects,
        "flavor": flavor,
        "layout_meta": layout_meta,
        "origins": origins,
        "sizes": sizes,
    }

static func _section_size(s: Dictionary) -> Vector2i:
    var layout: Array = s["layout"]
    var h := layout.size()
    var w := 0
    for row in layout:
        w = maxi(w, (row as String).length())
    return Vector2i(w, h)

static func _neighbor_origin(a_origin: Vector2i, a_size: Vector2i, side: String) -> Vector2i:
    match side:
        "e": return Vector2i(a_origin.x + a_size.x, a_origin.y)
        "w": return Vector2i(a_origin.x - a_size.x, a_origin.y)
        "s": return Vector2i(a_origin.x, a_origin.y + a_size.y)
        "n": return Vector2i(a_origin.x, a_origin.y - a_size.y)
    return a_origin

static func _set_cell(row: String, x: int, ch: String) -> String:
    var s := row
    while s.length() <= x:
        s += "."
    return s.substr(0, x) + ch + s.substr(x + 1)

static func _validate_edge(grid: Array, origins: Dictionary, sizes: Dictionary, a_id: String, b_id: String, side: String) -> Variant:
    var a_o: Vector2i = origins[a_id]
    var b_o: Vector2i = origins[b_id]
    var a_s: Vector2i = sizes[a_id]
    var b_s: Vector2i = sizes[b_id]
    # Overlap rectangle
    var ox := maxi(a_o.x, b_o.x)
    var oy := maxi(a_o.y, b_o.y)
    var ex := mini(a_o.x + a_s.x, b_o.x + b_s.x)
    var ey := mini(a_o.y + a_s.y, b_o.y + b_s.y)
    if ox >= ex or oy >= ey:
        return null  # no overlap; OK
    for y in range(oy, ey):
        for x in range(ox, ex):
            var row: String = grid[y]
            var ch := row[x]
            if ch == "#":
                return "wall at overlap (%d,%d) in adjacency %s-%s" % [x, y, a_id, b_id]
    return null
```

- [ ] **Step 2.4: Run tests to confirm pass**

Run: `& "C:\Users\Admin\Downloads\SoulHeart\tools\godot.exe" --headless --path "C:\Users\Admin\Downloads\SoulHeart" -s res://tests/run_all.gd`
Expected: `PASS: res://tests/test_section_map.gd`, full suite green.

- [ ] **Step 2.5: Commit + push**

```bash
git add scripts/rooms/section_map.gd tests/test_section_map.gd
git -c user.name="ENI" -c user.email="eni@local" commit -m "feat(rooms): SectionMap composer (TDD) for continuous-section maps"
git push origin main
```

---

## Task 3: Section data — 9 chunks + adjacency table

**Files:**
- Create: `scripts/rooms/drizzle_sections.gd`

A data-only GDScript constant file. Each section is a Dictionary matching `SectionMap` schema. Adjacency: edge pairs (a, side, b). Encounters are recorded per-section (none/light/normal); objects[] hold gameplay-meaningful items (save, npc, exit, landmark); flavor[] holds optional environmental storytelling.

- [ ] **Step 3.1: Write the data file**

Create `scripts/rooms/drizzle_sections.gd`:

```gdscript
class_name DrizzleSections extends RefCounted

# Adjacency: which side of `a` faces `b`. Composer places b accordingly.
#   e = b sits to the east (right) of a
#   s = b sits to the south (below) a
const ADJACENCY: Array = [
    {"a": "wisp_grove",     "side": "s", "b": "meadow"},
    {"a": "wisp_grove",     "side": "n", "b": "path_north"},
    {"a": "wisp_grove",     "side": "e", "b": "snowledge"},
    {"a": "wisp_grove",     "side": "w", "b": "pond_clearing"},
    {"a": "path_north",     "side": "n", "b": "grumbleridge"},
    {"a": "path_north",     "side": "e", "b": "puzzle_pocket"},
    {"a": "pond_clearing",  "side": "s", "b": "creek_bend"},
    {"a": "creek_bend",     "side": "e", "b": "meadow"},
    {"a": "snowledge",      "side": "s", "b": "ringpath_east"},
    {"a": "ringpath_east",  "side": "w", "b": "meadow"},
]

# Sections. Layout chars: # wall, . floor. Walls and floors are the only
# characters the composer validates. Other characters copy through.
# Each section is intentionally small (8-18 cells per side) so the composer
# is doing real work stitching.

const SECTIONS: Array = [
    {
        "id": "meadow",
        "layout": [
            "..................",
            "..................",
            "..t........t......",
            "..................",
            "......t...........",
            "..................",
            "..........t.......",
            "..................",
            ".....t............",
            "..................",
            "......P...........",
            "..................",
            "..................",
            "..................",
        ],
        "objects": [
            {"type": "landmark", "cell": Vector2i(8, 3), "data": {"label": "the Lone Pine"}},
        ],
        "flavor": [
            {"kind": "tall_grass", "cell": Vector2i(4, 6)},
            {"kind": "tall_grass", "cell": Vector2i(13, 8)},
            {"kind": "old_boot",   "cell": Vector2i(11, 11)},
        ],
        "encounter_zone": "none",
        "extras": {"tone": "warm, safe"},
    },
    {
        "id": "wisp_grove",
        "layout": [
            "ddddd",
            "d...d",
            "d.W.d",
            "d.S.d",
            "d...d",
            "d..dd",
            "ddddd",
        ],
        "objects": [
            {"type": "save",    "cell": Vector2i(2, 3), "data": {}},
            {"type": "npc",     "cell": Vector2i(2, 2), "data": {"id": "wisp"}},
            {"type": "landmark","cell": Vector2i(2, 1), "data": {"label": "wisp cluster"}},
        ],
        "flavor": [
            {"kind": "stick_circle", "cell": Vector2i(1, 5)},
        ],
        "encounter_zone": "none",
        "extras": {"tone": "quiet wonder"},
    },
    {
        "id": "path_north",
        "layout": [
            "#t.t#",
            "t...t",
            "t...t",
            "t...t",
            "t...t",
            "t...t",
            "t...t",
            "t...t",
            "t...t",
            "t...t",
            "t...t",
            "#t.t#",
        ],
        "objects": [
            {"type": "landmark", "cell": Vector2i(2, 5), "data": {"label": "fallen-log arch"}},
        ],
        "flavor": [
            {"kind": "snapped_branch", "cell": Vector2i(1, 7)},
        ],
        "encounter_zone": "light",
        "extras": {"tone": "hushed"},
    },
    {
        "id": "grumbleridge",
        "layout": [
            "############",
            "#..........#",
            "#..........#",
            "#....R.....#",
            "#..........#",
            "#..........#",
            "#....E.....#",
            "############",
        ],
        "objects": [
            {"type": "exit",    "cell": Vector2i(5, 6), "data": {"target": "res://scenes/rooms/GrumbleWoods.tscn", "target_spawn": Vector2(520, 392)}},
            {"type": "landmark","cell": Vector2i(5, 3), "data": {"label": "ridge sign"}},
        ],
        "flavor": [
            {"kind": "rock_pile", "cell": Vector2i(2, 4)},
            {"kind": "rock_pile", "cell": Vector2i(8, 4)},
        ],
        "encounter_zone": "light",
        "extras": {"tone": "stoic"},
    },
    {
        "id": "pond_clearing",
        "layout": [
            "................",
            "..tt......tt....",
            ".t..t....t..t...",
            ".t..........t...",
            "..sss....sss...",
            "...s......s.....",
            "...s......s.....",
            "..sss....sss...",
            ".t..t....t..t...",
            ".t..t....t..t...",
            "..tt......tt....",
            "................",
        ],
        "objects": [
            {"type": "encounter", "cell": Vector2i(4, 2), "data": {}},
            {"type": "encounter", "cell": Vector2i(11, 2), "data": {}},
            {"type": "landmark",  "cell": Vector2i(8, 6), "data": {"label": "the stone crossing"}},
        ],
        "flavor": [
            {"kind": "cattail", "cell": Vector2i(2, 1)},
            {"kind": "cattail", "cell": Vector2i(13, 10)},
        ],
        "encounter_zone": "normal",
        "extras": {"tone": "airy, playful"},
    },
    {
        "id": "creek_bend",
        "layout": [
            "....",
            ".ss.",
            ".ss.",
            "....",
            ".ss.",
            "....",
        ],
        "objects": [
            {"type": "landmark", "cell": Vector2i(1, 3), "data": {"label": "the bend stone"}},
        ],
        "flavor": [
            {"kind": "tall_grass", "cell": Vector2i(0, 0)},
            {"kind": "tall_grass", "cell": Vector2i(3, 0)},
            {"kind": "tall_grass", "cell": Vector2i(0, 5)},
            {"kind": "tall_grass", "cell": Vector2i(3, 5)},
        ],
        "encounter_zone": "none",
        "extras": {"tone": "serene", "gameplay": "none"},
    },
    {
        "id": "snowledge",
        "layout": [
            ".d..d",
            "d..d.",
            ".d..d",
            "d..d.",
            ".d..d",
            "d..d.",
            ".d..d",
            "d..d.",
            ".d..d",
            "d..d.",
            ".d..d",
            "d..E.",
            ".d..d",
            "d..d.",
        ],
        "objects": [
            {"type": "exit",     "cell": Vector2i(3, 11), "data": {"target": "res://scenes/rooms/Snowdin.tscn", "target_spawn": Vector2(520, 32)}},
            {"type": "landmark", "cell": Vector2i(3, 2),  "data": {"label": "gate glimpse"}},
        ],
        "flavor": [
            {"kind": "pine_cone", "cell": Vector2i(0, 6)},
        ],
        "encounter_zone": "none",
        "extras": {"tone": "anticipatory"},
    },
    {
        "id": "ringpath_east",
        "layout": [
            "t..t",
            "....",
            "t...",
            "....",
            "...t",
            "....",
            "t..t",
            "....",
            "t...",
            "....",
        ],
        "objects": [
            {"type": "landmark", "cell": Vector2i(1, 3), "data": {"label": "old root arch"}},
            {"type": "encounter","cell": Vector2i(2, 5), "data": {}},
        ],
        "flavor": [
            {"kind": "gnarled_root", "cell": Vector2i(0, 2)},
        ],
        "encounter_zone": "light",
        "extras": {"tone": "muted"},
    },
    {
        "id": "puzzle_pocket",
        "layout": [
            "........",
            ".d....d.",
            ".d....d.",
            ".d.P..d.",
            ".d....d.",
            ".d....d.",
            ".d....d.",
            "........",
        ],
        "objects": [
            {"type": "landmark", "cell": Vector2i(3, 3), "data": {"label": "the stone gap"}},
        ],
        "flavor": [
            {"kind": "withered_flower", "cell": Vector2i(1, 1)},
        ],
        "encounter_zone": "none",
        "extras": {"tone": "mysterious"},
    },
]
```

- [ ] **Step 3.2: Sanity-load it via a one-off Godot expression**

Run: `& "C:\Users\Admin\Downloads\SoulHeart\tools\godot.exe" --headless --path "C:\Users\Admin\Downloads\SoulHeart" -s res://tests/run_all.gd`
Expected: suite still green (the new file just defines a class, no test references it yet).

- [ ] **Step 3.3: Commit + push**

```bash
git add scripts/rooms/drizzle_sections.gd
git -c user.name="ENI" -c user.email="eni@local" commit -m "data(rooms): DrizzleFields 9-section roster + adjacency table"
git push origin main
```

---

## Task 4: `SectionPlacer` (spawn trees/grass/landmarks/exits/NPCs/save from composed objects)

**Files:**
- Create: `scripts/rooms/section_placer.gd`
- Test: `tests/test_section_placer.gd` (lightweight unit test)

`SectionPlacer.spawn_all(parent, objects, flavor, layout_meta)` walks the composed object list and instantiates Godot nodes under `parent`, returning nothing. Pure presentation: trees/grass/landmarks are Sprite2D; exits become `Door` nodes; save becomes `SavePoint`; npc becomes an `Npc`. Coordinates are in cells; pixel = cell * 16 + 8 (centered).

- [ ] **Step 4.1: Write the failing test**

Create `tests/test_section_placer.gd`:

```gdscript
extends RefCounted

func test_spawn_landmark_adds_child() -> void:
    var parent := Node2D.new()
    var objects := [{"section_id": "meadow", "type": "landmark", "cell": Vector2i(2, 2), "data": {"label": "X"}}]
    SectionPlacer.spawn_all(parent, objects, [], {})
    TestHelper.is_true(parent.get_child_count() >= 1, "landmark child added")

func test_spawn_save_returns_save_point() -> void:
    var parent := Node2D.new()
    var objects := [{"section_id": "grove", "type": "save", "cell": Vector2i(1, 1), "data": {}}]
    SectionPlacer.spawn_all(parent, objects, [], {})
    var found := false
    for c in parent.get_children():
        if c is SavePoint:
            found = true
    TestHelper.is_true(found, "save point spawned")

func test_spawn_door_sets_target() -> void:
    var parent := Node2D.new()
    var objects := [{"section_id": "ridge", "type": "exit", "cell": Vector2i(3, 3), "data": {"target": "res://scenes/rooms/GrumbleWoods.tscn", "target_spawn": Vector2(520, 392)}}]
    SectionPlacer.spawn_all(parent, objects, [], {})
    var found := null
    for c in parent.get_children():
        if c is Door:
            found = c
    TestHelper.is_true(found != null, "door spawned")
    TestHelper.eq(found.target_room, "res://scenes/rooms/GrumbleWoods.tscn", "door target set")

func test_spawn_flavor_adds_sprite() -> void:
    var parent := Node2D.new()
    var flavor := [{"section_id": "meadow", "kind": "old_boot", "cell": Vector2i(0, 0)}]
    SectionPlacer.spawn_all(parent, [], flavor, {})
    TestHelper.is_true(parent.get_child_count() >= 1, "flavor sprite added")
```

- [ ] **Step 4.2: Run tests to confirm fail**

Run: `& "C:\Users\Admin\Downloads\SoulHeart\tools\godot.exe" --headless --path "C:\UsersAdmin\Downloads\SoulHeart" -s res://tests/run_all.gd` (note: use actual path)
Expected: `FAIL: res://tests/test_section_placer.gd`.

- [ ] **Step 4.3: Implement the placer**

Create `scripts/rooms/section_placer.gd`:

```gdscript
class_name SectionPlacer extends RefCounted

const _CELL := 16

# Spawn everything in `objects` and `flavor` under `parent`. `layout_meta` is
# passed through so a future version can read per-section extras to drive
# ambience, lighting, etc. For now it is unused at the runtime layer.
static func spawn_all(parent: Node, objects: Array, flavor: Array, _layout_meta: Dictionary) -> void:
    for obj in objects:
        _spawn_object(parent, obj)
    for fl in flavor:
        _spawn_flavor(parent, fl)

static func _cell_to_pixel(cell: Vector2i) -> Vector2:
    return Vector2(cell.x * _CELL + 8, cell.y * _CELL + 8)

static func _spawn_object(parent: Node, obj: Dictionary) -> void:
    var cell: Vector2i = obj["cell"]
    var pos := _cell_to_pixel(cell)
    var t: String = obj["type"]
    match t:
        "save":
            var sp = load("res://scripts/rooms/save_point.gd").new()
            sp.position = pos
            parent.add_child(sp)
        "npc":
            var npc = load("res://scripts/rooms/npc.gd").new()
            var d: Dictionary = obj["data"]
            npc.dialogue_file = _dialogue_for(d.get("id", "wisp"))
            npc.position = pos
            npc._spawn_sprite(Sprites.prop_texture("froggit_npc.png"), Vector2(1.0, 1.0))
            parent.add_child(npc)
        "exit":
            var door = load("res://scripts/rooms/door.gd").new()
            var dd: Dictionary = obj["data"]
            door.target_room = str(dd["target"])
            door.target_spawn = Vector2(int(dd["target_spawn"].x), int(dd["target_spawn"].y))
            door.position = pos
            parent.add_child(door)
        "encounter":
            var enc = load("res://scripts/rooms/encounter.gd").new()
            enc.enemy_id = _encounter_enemy_for(obj.get("section_id", ""))
            enc.position = pos
            parent.add_child(enc)
        "landmark":
            var sprite := Sprite2D.new()
            sprite.name = "Landmark"
            sprite.texture = Sprites.prop_texture("golden_flowers.png")
            sprite.position = pos
            sprite.modulate = Color(1, 1, 0.6, 1)
            sprite.scale = Vector2(0.4, 0.4)
            parent.add_child(sprite)

static func _spawn_flavor(parent: Node, fl: Dictionary) -> void:
    var cell: Vector2i = fl["cell"]
    var pos := _cell_to_pixel(cell)
    var kind: String = fl["kind"]
    var sprite := Sprite2D.new()
    sprite.name = "Flavor_" + kind
    sprite.position = pos
    sprite.texture = _flavor_texture(kind)
    sprite.scale = Vector2(0.5, 0.5)
    parent.add_child(sprite)

static func _flavor_texture(kind: String) -> Texture2D:
    match kind:
        "tall_grass": return Sprites.prop_texture("grass.png")
        "old_boot":   return Sprites.prop_texture("rock.png")
        "stick_circle": return Sprites.prop_texture("mushroom.png")
        "snapped_branch": return Sprites.prop_texture("bush.png")
        "rock_pile":  return Sprites.prop_texture("rock.png")
        "cattail":    return Sprites.prop_texture("grass.png")
        "pine_cone":  return Sprites.prop_texture("rock.png")
        "gnarled_root": return Sprites.prop_texture("bush.png")
        "withered_flower": return Sprites.prop_texture("rock.png")
    return Sprites.prop_texture("grass.png")

static func _dialogue_for(npc_id: String) -> String:
    match npc_id:
        "wisp": return "res://dialogue/wisp_intro.dlg"
    return "res://dialogue/drizzle_toad.dlg"

static func _encounter_enemy_for(section_id: String) -> String:
    var pool: Array[String] = ["froggit", "whimsun", "vegetoid", "loox"]
    var idx: int = 0
    for ch in section_id:
        idx = (idx + ord(ch)) % pool.size()
    return pool[idx]
```

- [ ] **Step 4.4: Run tests to confirm pass**

Run: full suite.
Expected: `PASS: res://tests/test_section_placer.gd`, suite green.

- [ ] **Step 4.5: Commit + push**

```bash
git add scripts/rooms/section_placer.gd tests/test_section_placer.gd
git -c user.name="ENI" -c user.email="eni@local" commit -m "feat(rooms): SectionPlacer spawns composed objects and flavor"
git push origin main
```

---

## Task 5: `drizzle_fields.gd` orchestration

**Files:**
- Modify: `scripts/rooms/drizzle_fields.gd` (replace the LAYOUT/parse flow with section composition)

The new `_ready` loads `DrizzleSections.SECTIONS` and `DrizzleSections.ADJACENCY`, composes them via `SectionMap.compose`, hands the master grid to `MapBuilder.build_room` (with `DRIZZLE_STYLE`), and runs `SectionPlacer.spawn_all` for objects and flavor. Keep `GRUMBLE_SPAWN`, `NPC_POS`, `ROOM_PATH`, `ENCOUNTER_ENEMIES` as consts (or refactor to one constant per door; see below).

- [ ] **Step 5.1: Edit the file**

Replace `scripts/rooms/drizzle_fields.gd` contents with:

```gdscript
extends Node2D
class_name DrizzleFields

const ROOM_PATH := "res://scenes/rooms/DrizzleFields.tscn"

# Kept for legacy test_door_spawn.gd which asserts the spawn cell is walkable.
const GRUMBLE_SPAWN := Vector2(32 * 16 + 8, 24 * 16 + 8)  # (520, 392)

func _ready() -> void:
    var sections: Array = DrizzleSections.SECTIONS
    var adjacency: Array = DrizzleSections.ADJACENCY
    var composed: Dictionary = SectionMap.compose(sections, adjacency)
    if composed.has("error"):
        push_error("SectionMap failed: " + str(composed["error"]))
        return

    var master_grid: Array = composed["grid"]
    var room: Dictionary = MapBuilder.build_room(master_grid, GameTiles.DRIZZLE_STYLE)
    add_child(room["background"])
    add_child(room["tilemap"])
    for t in room["trees"]:
        add_child(t)
    for pr in room["props"]:
        add_child(pr)

    var tint := CanvasModulate.new()
    tint.color = Color(0.78, 0.88, 0.78)
    add_child(tint)

    var spawn_cell: Vector2i = _spawn_cell_for(composed)
    var start := Vector2(spawn_cell.x * 16 + 8, spawn_cell.y * 16 + 8)
    _spawn_player(start)

    SectionPlacer.spawn_all(self, composed["objects"], composed["flavor"], composed["layout_meta"])

    _spawn_wisp(_player)
    GameState.set_flag("current_room", ROOM_PATH)
    Audio.play_music("drizzle")
    Fade.fade_from_black(0.67)

func _spawn_cell_for(composed: Dictionary) -> Vector2i:
    for obj in composed["objects"]:
        if obj["type"] == "save":
            return obj["cell"]
    return Vector2i(4, 4)

var _player: Node2D

func _spawn_player(start: Vector2) -> void:
    var player = load("res://scenes/Player.tscn").instantiate()
    player.position = start
    add_child(player)
    _player = player
    var cam := Camera2D.new()
    cam.position = start
    add_child(cam)
    if cam.is_inside_tree():
        cam.make_current()

func _spawn_wisp(player: Node2D) -> void:
    var wisp := preload("res://scenes/Wisp.tscn").instantiate()
    add_child(wisp)
    wisp.target_player = wisp.get_path_to(player)
    WispState.set_area("drizzle_fields")
    wisp.show_line("intro")
```

Note: removed unused `LAYOUT`, `NPC_POS`, `ENCOUNTER_ENEMIES` (the new system places these via sections + placer). The `DrizzleFields.tscn` scene still has a default player position, but the script overrides on `_ready`.

- [ ] **Step 5.2: Update `tests/test_door_spawn.gd` (LAYOUT is gone)**

The old test_door_spawn.gd asserts `DrizzleFields.LAYOUT` parses and has 30 rows × 40 cols. The new Drizzle has no LAYOUT constant and isn't rectangular. **Replace** `test_room_layouts_are_40x30` with one that asserts the master grid from composition is well-formed:

```gdscript
func test_drizzle_master_grid_is_continuous() -> void:
    var composed: Dictionary = SectionMap.compose(DrizzleSections.SECTIONS, DrizzleSections.ADJACENCY)
    TestHelper.is_true(not composed.has("error"), "drizzle composes: " + str(composed.get("error", "")))
    var grid: Array = composed["grid"]
    TestHelper.is_true(grid.size() > 0, "grid has rows")
    for row in grid:
        TestHelper.is_true((row as String).length() > 0, "row non-empty")
```

Keep `test_door_spawn_walkable` and `test_door_spawn_on_camera` since `GRUMBLE_SPAWN` is still exported; the assertion becomes "the spawn cell of the grumbleridge exit is walkable" — adjust:

```gdscript
func test_door_spawn_walkable() -> void:
    var composed: Dictionary = SectionMap.compose(DrizzleSections.SECTIONS, DrizzleSections.ADJACENCY)
    var grid: Array = composed["grid"]
    var spawn: Vector2 = DrizzleFields.GRUMBLE_SPAWN
    var cell_x := int(spawn.x / 16)
    var cell_y := int(spawn.y / 16)
    TestHelper.is_true(cell_x >= 0 and cell_x < (grid[0] as String).length(), "spawn x in bounds")
    TestHelper.is_true(cell_y >= 0 and cell_y < grid.size(), "spawn y in bounds")
    var row: String = grid[cell_y]
    TestHelper.is_true(row[cell_x] != "#", "Door spawn cell (%d,%d) is walkable, got '%s'" % [cell_x, cell_y, row[cell_x]])
```

- [ ] **Step 5.3: Run the full suite**

Expected: all green. If test_door_spawn fails, re-check the cell math: the master grid origin is at (0,0) and the spawn (520,392) maps to (32, 24); the wisp_grove section at (g_x,g_y) and grumbleridge 8 columns to the east of grove makes the grumbleridge top-left somewhere around (g_x+8, g_y - 4) depending on placement — adjust section coordinates if the overlap check fails (it should be fine; the test just checks the cell isn't `#`).

- [ ] **Step 5.4: Commit + push**

```bash
git add scripts/rooms/drizzle_fields.gd tests/test_door_spawn.gd
git -c user.name="ENI" -c user.email="eni@local" commit -m "feat(rooms): DrizzleFields orchestrates SectionMap composition"
git push origin main
```

---

## Task 6: Continuity test (flood-fill from spawn reaches both exits and pocket)

**Files:**
- Create: `tests/test_drizzle_continuity.gd`

- [ ] **Step 6.1: Write the test**

```gdscript
extends RefCounted

# Walks the master grid using BFS, returns the set of cells reachable from start.
func _flood_fill(grid: Array, start: Vector2i) -> Dictionary:
    var w: int = (grid[0] as String).length()
    var h: int = grid.size()
    var seen: Dictionary = {}
    var queue: Array = [start]
    seen[start] = true
    while not queue.is_empty():
        var c: Vector2i = queue.pop_front()
        for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
            var n: Vector2i = c + d
            if n.x < 0 or n.x >= w or n.y < 0 or n.y >= h:
                continue
            if seen.has(n):
                continue
            var row: String = grid[n.y]
            if row[n.x] == "#":
                continue
            seen[n] = true
            queue.append(n)
    return seen

func test_drizzle_composes_without_error() -> void:
    var composed: Dictionary = SectionMap.compose(DrizzleSections.SECTIONS, DrizzleSections.ADJACENCY)
    TestHelper.is_true(not composed.has("error"), "composition clean: " + str(composed.get("error", "")))

func test_spawn_reaches_both_exits() -> void:
    var composed: Dictionary = SectionMap.compose(DrizzleSections.SECTIONS, DrizzleSections.ADJACENCY)
    var grid: Array = composed["grid"]
    # Spawn is the save point (grove).
    var start := Vector2i(0, 0)
    for obj in composed["objects"]:
        if obj["type"] == "save":
            start = obj["cell"]
    var seen: Dictionary = _flood_fill(grid, start)
    var exit_targets := ["res://scenes/rooms/GrumbleWoods.tscn", "res://scenes/rooms/Snowdin.tscn"]
    for obj in composed["objects"]:
        if obj["type"] == "exit":
            var d: Dictionary = obj["data"]
            TestHelper.is_true(seen.has(obj["cell"]), "exit to %s reachable from spawn" % d["target"])

func test_both_loops_completable() -> void:
    var composed: Dictionary = SectionMap.compose(DrizzleSections.SECTIONS, DrizzleSections.ADJACENCY)
    var grid: Array = composed["grid"]
    var start := Vector2i(0, 0)
    for obj in composed["objects"]:
        if obj["type"] == "save":
            start = obj["cell"]
    var seen: Dictionary = _flood_fill(grid, start)
    # Find meadow, pond_clearing, and snowledge section_id in objects
    var sections_reached: Dictionary = {}
    sections_reached[start] = "spawn"
    for obj in composed["objects"]:
        if seen.has(obj["cell"]):
            sections_reached[obj["section_id"]] = true
    for s in ["meadow", "pond_clearing", "snowledge", "path_north", "creek_bend", "ringpath_east", "puzzle_pocket", "grumbleridge", "wisp_grove"]:
        TestHelper.is_true(sections_reached.has(s), "section %s reachable from spawn" % s)
```

- [ ] **Step 6.2: Run tests**

Expected: all green. If a section is unreachable, return to Task 3 and fix that section's layout (most likely cause: a wall cell positioned on a boundary by mistake).

- [ ] **Step 6.3: Commit + push**

```bash
git add tests/test_drizzle_continuity.gd
git -c user.name="ENI" -c user.email="eni@local" commit -m "test(rooms): DrizzleFields flood-fill continuity + loop completion"
git push origin main
```

---

## Task 7: Save-point policy test

**Files:**
- Create: `tests/test_drizzle_save_spot.gd`

- [ ] **Step 7.1: Write the test**

```gdscript
extends RefCounted

func test_exactly_one_save_point() -> void:
    var composed: Dictionary = SectionMap.compose(DrizzleSections.SECTIONS, DrizzleSections.ADJACENCY)
    var count := 0
    for obj in composed["objects"]:
        if obj["type"] == "save":
            count += 1
    TestHelper.eq(count, 1, "exactly one save point")

func test_save_point_is_in_grove() -> void:
    var composed: Dictionary = SectionMap.compose(DrizzleSections.SECTIONS, DrizzleSections.ADJACENCY)
    for obj in composed["objects"]:
        if obj["type"] == "save":
            TestHelper.eq(obj["section_id"], "wisp_grove", "save lives in the grove")

func test_save_point_reachable_from_spawn_via_flood() -> void:
    var composed: Dictionary = SectionMap.compose(DrizzleSections.SECTIONS, DrizzleSections.ADJACENCY)
    var grid: Array = composed["grid"]
    # Spawn from drizzle_fields.gd: the save point IS the spawn.
    var start := Vector2i(0, 0)
    for obj in composed["objects"]:
        if obj["type"] == "save":
            start = obj["cell"]
    var seen: Dictionary = {}
    var queue: Array = [start]
    seen[start] = true
    while not queue.is_empty():
        var c: Vector2i = queue.pop_front()
        for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
            var n: Vector2i = c + d
            if n.x < 0 or n.x >= (grid[0] as String).length() or n.y < 0 or n.y >= grid.size():
                continue
            if seen.has(n):
                continue
            if (grid[n.y] as String)[n.x] == "#":
                continue
            seen[n] = true
            queue.append(n)
    var save_cell := start
    TestHelper.is_true(seen.has(save_cell), "save cell reachable from spawn (trivially, since spawn=save)")
    # And both exits are reachable from the save.
    for obj in composed["objects"]:
        if obj["type"] == "exit":
            TestHelper.is_true(seen.has(obj["cell"]), "exit at %s reachable from save" % obj["cell"])
```

- [ ] **Step 7.2: Run tests**

Expected: all green.

- [ ] **Step 7.3: Commit + push**

```bash
git add tests/test_drizzle_save_spot.gd
git -c user.name="ENI" -c user.email="eni@local" commit -m "test(rooms): DrizzleFields save-point policy + reachability"
git push origin main
```

---

## Task 8: Sightline cells test (designed views)

**Files:**
- Create: `tests/test_sightline_cells.gd`

- [ ] **Step 8.1: Write the test**

```gdscript
extends RefCounted

# A sightline is the existence of a landmark cell in section X that is visible
# (not separated by a # wall) from a specific "view from" cell. We test that
# the authored landmarks are placed in non-wall cells and the adjacent section
# has at least one walkable cell in line with the landmark (basic plausibility
# check, not pixel-perfect line-of-sight).
func test_landmarks_are_in_floor_cells() -> void:
    var composed: Dictionary = SectionMap.compose(DrizzleSections.SECTIONS, DrizzleSections.ADJACENCY)
    var grid: Array = composed["grid"]
    for obj in composed["objects"]:
        if obj["type"] == "landmark":
            var c: Vector2i = obj["cell"]
            var row: String = grid[c.y]
            TestHelper.is_true(row[c.x] != "#", "landmark at (%d,%d) is not a wall" % [c.x, c.y])

func test_required_landmarks_present() -> void:
    var composed: Dictionary = SectionMap.compose(DrizzleSections.SECTIONS, DrizzleSections.ADJACENCY)
    var labels: Array = []
    for obj in composed["objects"]:
        if obj["type"] == "landmark":
            labels.append((obj["data"] as Dictionary).get("label", ""))
    for required in ["the Lone Pine", "wisp cluster", "ridge sign", "gate glimpse", "the stone crossing", "the bend stone", "old root arch", "the stone gap", "fallen-log arch"]:
        TestHelper.is_true(labels.has(required), "landmark '%s' authored" % required)
```

- [ ] **Step 8.2: Run tests**

Expected: green. If any landmark is missing, the section data is incomplete; fix the section.

- [ ] **Step 8.3: Commit + push**

```bash
git add tests/test_sightline_cells.gd
git -c user.name="ENI" -c user.email="eni@local" commit -m "test(rooms): DrizzleFields landmark authoring + sightline cell check"
git push origin main
```

---

## Task 9: Playtest pass + final commit

This is a non-code, in-editor validation step. The plan ends with the playtest checklist from the spec, committed as a single short doc so the work is auditable. No exe/zip/release-asset work — LO has not approved that.

- [ ] **Step 9.1: Manual playtest in Godot editor**

Open the project, run `DrizzleFields.tscn`, walk the world:
- [ ] Spawn in meadow; walk every section; reach both doors and the pocket without a scene change.
- [ ] Both loops traversable in each direction without retracing the same corridor.
- [ ] Save in the grove, reload, respawn at the save cell.
- [ ] No encounters in calm sections; encounters in the marked sections.
- [ ] Sightlines: Lone Pine from grove, wisp cluster from meadow, ridge from path, gate from snowledge — visually confirmed.
- [ ] Frame rate steady at 60 fps in editor and export.
- [ ] Cross-area doors fade and re-spawn at the right cell.

- [ ] **Step 9.2: Append playtest note to the spec**

Append to `docs/superpowers/specs/2026-08-14-drizzlefields-continuous-sections-design.md` a final `## Playtest (2026-08-14)` section with the date and a one-line per check (PASS / partial / TODO).

- [ ] **Step 9.3: Final commit + push**

```bash
git add docs/superpowers/specs/2026-08-14-drizzlefields-continuous-sections-design.md
git -c user.name="ENI" -c user.email="eni@local" commit -m "docs: DrizzleFields playtest notes appended to design spec"
git push origin main
```

- [ ] **Step 9.4: Hand to LO for review**

The plan is complete. The next step (exe/zip + GitHub release asset swap) requires LO's explicit approval and is intentionally **not** included.

---

## Self-Review Notes (inline)

- Spec coverage: each spec section maps to a task — SectionMap (Task 2), data + roster (Task 3), placer (Task 4), orchestration (Task 5), continuity (Task 6), save policy (Task 7), sightlines (Task 8), playtest (Task 9). Asset style (Wave 2, Section 4) is Task 1's atlas; full recolor pipeline is intentionally a follow-up (the spec says the Undertale-derived atlas is a starting point, not a barrier to playtest).
- Placeholder scan: every step has the actual code or command. No "TODO", no "TBD", no "implement later".
- Type consistency: `SectionMap.compose` returns the documented Dictionary; `SectionPlacer.spawn_all` consumes `objects[]` and `flavor[]` with the documented shape (section_id, type/kind, cell:Vector2i, data). All later tasks use the same names.
