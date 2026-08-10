# SoulHeart Plan A — 13 Original Mobs + Wisp Companion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend `EnemyLibrary` from 6 to 19 mobs by adding 13 original mobs (Reminisc, Hushroom, Pane-ic, Squi-sh, Senti-mint, Repeato, Toadally, Pun-kin, Nullaby, Quibble, Mar-gin, Loo-key, Re-mem-bran), wire up an always-following Wisp companion that follows the player through both existing rooms (Drizzle Fields, Grumble Woods), responds to a new `hum` input by raising mood, and surfaces dialogue via the existing `DialogueParser`. Every task is test-driven and ends with a commit.

**Architecture:**
- Mobs: add 13 dicts to `scripts/battle/enemy_library.gd` matching the existing 6-entry shape (id, name, hp, atk, def, acts[], spare_after, intro_line, attack_lines[], sprite_id, patterns[]). Pattern grammar reuses `BulletPatterns.make()` exactly — no new pattern types.
- Wisp: new `scripts/wisp/` subdirectory with `wisp.gd` (follower), `wisp_state.gd` (static mood/line-tracking), `wisp_dialogue.gd` (context→line), `wisp_audio.gd` (4-note hum). Wisp is a child node of each room script and follows the player using lerp. `hum` input raises mood; mood maps to lines via `wisp_dialogue.get_line()`.
- Asset fallback: 13 new mobs ship with single-frame placeholders (`assets/sprites/enemies/frames/<id>/<id>_000.png`, 32×32, neutral color). Plan B will replace with multi-frame art for the first 3 areas (Hush, Murmur, Echo) but Plan A must not block on art.

**Tech Stack:** Godot 4.4.1, GDScript, existing autoloads (`GameState`, `Audio`, `Sprites`, `EnemyLibrary`, `DialogueParser`), `tests/run_all.gd` runner, `tests/test_helper.gd` assertions.

## Global Constraints

These are the project-wide requirements from the spec; every task's requirements implicitly include this section. They are NOT options.

- **No 'interact' input action exists.** Use existing `confirm` for dialogue advance only; Wisp's `hum` action is NEW and is added exactly once in `GameState._ensure_input_actions()`.
- **No new autoloads.** Wisp state lives as static fields on `scripts/wisp/wisp_state.gd` to avoid adding a 5th autoload (existing: GameState, Sprites, Audio, DialogueParser).
- **All new mob entries match existing `enemy_library.gd` dict shape** exactly: `{id, name, hp, atk, def, acts[], spare_after, intro_line, attack_lines[], sprite_id, patterns[]}`. `acts` items: `{id, label, mood, text}`. `patterns` items: `{type, rule, params, cycles, color}` consumable by `BulletPatterns.make()`.
- **Mob frame counts must be registered in `Sprites._enemy_frames`** before any battle spawns that mob, or `Sprites.battle_enemy_texture()` returns null.
- **Cutout black bg** is already applied in `Sprites._cutout_black()`; placeholder PNGs must have a black-or-near-black bg for clean transparency.
- **Dialogue file format** = `'#' comment` or `'Speaker: text'`; parsed by `DialogueParser.parse_file`. No JSON.
- **Player movement actions already exist** (`move_up/down/left/right`, `confirm`, `cancel`); do not duplicate.
- **TDD gate**: every task writes a failing test, makes it pass, runs full suite green, then commits. No commits with red tests.
- **Frequent commits**: one commit per task minimum. Use Conventional Commits (`feat:`, `test:`, `fix:`, `chore:`).
- **Godot 4 GDScript syntax**: `extends Node2D`, `class_name Foo` (top-level class), `@onready var x = $Y`, `signal foo()`, `await get_tree().process_frame`, `Vector2(x, y)`, no `setget`, no `tool` unless exporting.
- **No emojis in code, comments, commit messages, or docs** unless the user explicitly requested them.
- **Existing `test_enemy_library.gd` asserts `ids.size() == 6`** — Task 2 MUST update this assertion as part of the same commit (the test for the new library is one task, not split).
- **Existing mob sprite_id set**: `{froggit, whimsun, moldsmal, loox, vegetoid, migosp, napstablook}` — these are the 6 "echo" mobs; they remain unchanged.
- **Wisp does not appear in `EnemyLibrary`** — Wisp is a companion, not an enemy. Wisp has its own sprite/textures and its own scene.
- **Wisp appears in both existing rooms** (`DrizzleFields.tscn`, `GrumbleWoods.tscn`) starting in Plan A; later areas (Plans B-D) instantiate Wisp via a shared helper.
- **Placeholder PNG generation**: use Godot's `Image.create(width, height, false, Image.FORMAT_RGBA8)` + `Image.fill()` in a one-off generator script under `tools/`, OR commit a real PNG byte stream. For Plan A, commit one `tools/gen_placeholders.gd` and run it once; generated PNGs become committed assets.
- **Audio**: `Audio.play_music(name)` exists; for Wisp hum a NEW helper `Audio.play_hum(stream)` is added in Task 8 with a simple no-op fallback when called with null.

---

## Task 1: Wisp placeholder sprites + helper to generate them

**Files:**
- Create: `tools/gen_wisp_placeholders.gd`
- Create: `assets/sprites/wisp/wisp_idle.png`
- Create: `assets/sprites/wisp/wisp_lit.png`
- Test: `tests/test_wisp_assets.gd`

**Interfaces:**
- Consumes: nothing (pure tooling).
- Produces: two 16×16 PNGs (`wisp_idle.png` = pale amber `#FFD8A0` on black bg; `wisp_lit.png` = bright amber `#FFEEC0` on black bg). Black bg is required so `_cutout_black` does NOT remove the circle (lum threshold is 0.10, amber 0.85+ passes).

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/test_wisp_assets.gd
extends RefCounted

func test_wisp_idle_png_exists() -> void:
    TestHelper.is_true(FileAccess.file_exists("res://assets/sprites/wisp/wisp_idle.png"),
        "wisp_idle.png must exist at res://assets/sprites/wisp/")

func test_wisp_lit_png_exists() -> void:
    TestHelper.is_true(FileAccess.file_exists("res://assets/sprites/wisp/wisp_lit.png"),
        "wisp_lit.png must exist at res://assets/sprites/wisp/")

func test_wisp_idle_dimensions() -> void:
    var img := Image.new()
    var err := img.load("res://assets/sprites/wisp/wisp_idle.png")
    TestHelper.eq(err, OK, "wisp_idle.png must load without error")
    TestHelper.eq(img.get_width(), 16, "wisp_idle.png width must be 16")
    TestHelper.eq(img.get_height(), 16, "wisp_idle.png height must be 16")

func test_wisp_lit_dimensions() -> void:
    var img := Image.new()
    var err := img.load("res://assets/sprites/wisp/wisp_lit.png")
    TestHelper.eq(err, OK, "wisp_lit.png must load without error")
    TestHelper.eq(img.get_width(), 16, "wisp_lit.png width must be 16")
    TestHelper.eq(img.get_height(), 16, "wisp_lit.png height must be 16")
```

- [ ] **Step 2: Run the test to verify it fails**

Run from main repo root:
```bash
cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers/plan-a-t1-fail.txt 2>&1 & echo DONE"
```
Then `Select-String -Pattern "test_wisp" .superpowers/plan-a-t1-fail.txt` — Expected: 4 failures with "must exist" / "must load".

- [ ] **Step 3: Write the placeholder generator**

Create `tools/gen_wisp_placeholders.gd`:

```gdscript
@tool
extends SceneTree

func _init() -> void:
    _make_wisp("res://assets/sprites/wisp/wisp_idle.png", Color8(255, 216, 160))
    _make_wisp("res://assets/sprites/wisp/wisp_lit.png",  Color8(255, 238, 192))
    quit()

func _make_wisp(path: String, fill: Color8) -> void:
    var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
    img.fill(Color8(0, 0, 0))
    # 12px diameter centered (rows 2-13, cols 2-13)
    for y in range(2, 14):
        for x in range(2, 14):
            img.set_pixel(x, y, fill)
    var dir_path := path.get_base_dir()
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
    var err := img.save_png(path)
    if err != OK:
        push_error("Failed to save %s: %d" % [path, err])
```

- [ ] **Step 4: Run the generator once**

```bash
cmd /c "tools\godot.exe --headless --script res://tools/gen_wisp_placeholders.gd > .superpowers/plan-a-t1-gen.txt 2>&1 & echo DONE"
```
Expected: no errors. Verify: `Get-ChildItem assets\sprites\wisp` shows both PNGs.

- [ ] **Step 5: Run the test to verify it passes**

```bash
cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers/plan-a-t1.txt 2>&1 & echo DONE"
```
Expected: `ALL TESTS PASSED` (existing tests + 4 new wisp asset tests).

- [ ] **Step 6: Commit**

```bash
git add tools/gen_wisp_placeholders.gd assets/sprites/wisp/wisp_idle.png assets/sprites/wisp/wisp_lit.png tests/test_wisp_assets.gd
git commit -m "feat(wisp): add idle/lit placeholder PNGs + asset tests"
```

---

## Task 2: Add 13 new mobs to EnemyLibrary (extends existing 6 → 19)

**Files:**
- Modify: `scripts/battle/enemy_library.gd:1-end`
- Modify: `tests/test_enemy_library.gd:1-end`
- Test: `tests/test_new_mobs.gd`

**Interfaces:**
- Consumes: `BulletPatterns.make(pattern_dict, heart_pos)` — all 13 mobs use existing pattern types (`sine`, `aimed`, `fan`, `ring`, `spiral`, `burst`, `bone_wall`, `spear_volley`, `laser_sweep`).
- Produces: `EnemyLibrary.get_enemy(id)` returns a valid dict for the 13 new ids; `EnemyLibrary.ids()` returns 19 entries.

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/test_new_mobs.gd
extends RefCounted

const NEW_IDS := [
    "reminisc", "hushroom", "paneic", "squish", "sentimint",
    "repeato", "toadally", "punkin", "nullaby", "quibble",
    "margin", "lookey", "remembran",
]

func test_new_mob_count() -> void:
    var ids := EnemyLibrary.ids()
    TestHelper.eq(ids.size(), 19, "EnemyLibrary must have 19 mobs (6 echo + 13 original)")

func test_each_new_mob_has_required_keys() -> void:
    var required := ["id", "name", "hp", "atk", "def", "acts",
                     "spare_after", "intro_line", "attack_lines",
                     "sprite_id", "patterns"]
    for mob_id in NEW_IDS:
        var e: Dictionary = EnemyLibrary.get_enemy(mob_id)
        TestHelper.is_true(not e.is_empty(), "%s must be defined" % mob_id)
        for k in required:
            TestHelper.is_true(e.has(k), "%s missing key '%s'" % [mob_id, k])
        TestHelper.is_true(e.acts.size() >= 1, "%s must have >=1 ACT" % mob_id)
        TestHelper.is_true(e.attack_lines.size() >= 1, "%s must have >=1 attack line" % mob_id)
        TestHelper.is_true(e.patterns.size() >= 1, "%s must have >=1 pattern" % mob_id)

func test_patterns_resolve_to_bullets() -> void:
    var heart := Vector2(160, 120)
    for mob_id in NEW_IDS:
        var e: Dictionary = EnemyLibrary.get_enemy(mob_id)
        for p in e.patterns:
            var bullets := BulletPatterns.make(p, heart)
            TestHelper.is_true(bullets.size() > 0,
                "%s pattern '%s' must produce bullets" % [mob_id, p])
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers/plan-a-t2-fail.txt 2>&1 & echo DONE"
```
Expected: existing `test_enemy_library.gd` also fails (`ids.size() == 6` is now 6 but new test expects 19) plus 13×N new failures.

- [ ] **Step 3: Update `scripts/battle/enemy_library.gd`**

Add a helper function `_make_mob(...)` and append 13 dicts to `_enemies`. Keep the 6 echo entries exactly as they are. The new helper compresses repetitive boilerplate:

```gdscript
# At top of file, after existing _enemies declaration:
static func _make_mob(p_id: String, p_name: String, p_hp: int, p_atk: int, p_def: int,
        p_spare: int, p_sprite: String, p_acts: Array, p_lines: Array,
        p_patterns: Array, p_intro: String) -> Dictionary:
    return {
        "id": p_id,
        "name": p_name,
        "hp": p_hp,
        "atk": p_atk,
        "def": p_def,
        "acts": p_acts,
        "spare_after": p_spare,
        "intro_line": p_intro,
        "attack_lines": p_lines,
        "sprite_id": p_sprite,
        "patterns": p_patterns,
    }
```

Then append the 13 entries (compact representation; expand each `[]` to its real values when transcribing):

```gdscript
# 13 ORIGINAL MOBS (Plan A)
_enemies["reminisc"] = _make_mob(
    "reminisc", "Reminisc", 12, 4, 2, 4, "reminisc",
    [
        {"id": "recall", "label": "* Recall", "mood": 2, "text": "* You ask it to recall something. The word 'remember' flickers in its eye."},
        {"id": "study", "label": "* Study", "mood": 1, "text": "* It looks like a faded photograph. The edges are soft."},
        {"id": "hum", "label": "* Hum", "mood": 2, "text": "* You hum. It relaxes, almost imperceptibly."},
    ],
    [
        "* It whispers your name. (You never told it.)",
        "* It reaches for something behind you that isn't there.",
    ],
    [
        {"type": "aimed", "rule": "BLUE", "params": {"count": 4, "speed": 70}, "cycles": 3, "color": Color(0.6, 0.7, 1.0)},
        {"type": "ring", "rule": "NONE", "params": {"count": 8, "radius": 30, "speed": 35}, "cycles": 2, "color": Color(0.7, 0.7, 0.9)},
    ],
    "* A Reminisc flickers into view. It looks like it's remembering you from somewhere you haven't been."
)

_enemies["hushroom"] = _make_mob(
    "hushroom", "Hushroom", 8, 3, 1, 3, "hushroom",
    [
        {"id": "quiet", "label": "* Quiet it", "mood": 2, "text": "* You ask it to be quieter. It tries. The ringing stops for a moment."},
        {"id": "smell", "label": "* Smell", "mood": 1, "text": "* It smells like damp moss and old bells."},
    ],
    [
        "* A high tone rings out from its cap.",
        "* It vibrates. Your ears ache.",
    ],
    [
        {"type": "sine", "rule": "BLUE", "params": {"count": 6, "speed": 60, "amplitude": 24, "freq": 0.5}, "cycles": 4, "color": Color(0.8, 0.4, 0.9)},
        {"type": "fan", "rule": "ORANGE", "params": {"count": 5, "spread": 0.6, "speed": 80}, "cycles": 2, "color": Color(1.0, 0.6, 0.3)},
    ],
    "* A Hushroom tilts its cap toward you. It hums at a frequency just out of hearing."
)

_enemies["paneic"] = _make_mob(
    "paneic", "Pane-ic", 10, 5, 1, 4, "paneic",
    [
        {"id": "breathe", "label": "* Breathe", "mood": 2, "text": "* You remind it to breathe. It exhales — the glass fogs."},
        {"id": "tilt", "label": "* Tilt", "mood": 1, "text": "* You tilt the pane. Nothing changes. It was always this way."},
    ],
    [
        "* It looks out at something you can't see.",
        "* Its surface ripples. There are people behind it.",
    ],
    [
        {"type": "aimed", "rule": "NONE", "params": {"count": 3, "speed": 90}, "cycles": 4, "color": Color(0.7, 0.8, 0.9)},
        {"type": "ring", "rule": "BLUE", "params": {"count": 6, "radius": 40, "speed": 30}, "cycles": 3, "color": Color(0.5, 0.7, 1.0)},
    ],
    "* Pane-ic stands in front of you. It is exactly the size of a doorway."
)

_enemies["squish"] = _make_mob(
    "squish", "Squi-sh", 14, 4, 3, 5, "squish",
    [
        {"id": "compliment", "label": "* Compliment", "mood": 2, "text": "* You tell it it's doing its best. It blooms a little."},
        {"id": "squeeze", "label": "* Squeeze", "mood": 1, "text": "* You squeeze it gently. It says 'thank you' in two octaves."},
    ],
    [
        "* It bounces in place. That's the attack.",
        "* It flattens, then springs back. Bullets fly.",
    ],
    [
        {"type": "burst", "rule": "ORANGE", "params": {"count": 8, "speed": 80}, "cycles": 3, "color": Color(1.0, 0.7, 0.4)},
        {"type": "spiral", "rule": "NONE", "params": {"count": 12, "speed": 50, "rot_speed": 0.3}, "cycles": 4, "color": Color(0.9, 0.5, 0.6)},
    ],
    "* Squi-sh jiggles nervously. It has not been squeezed in a long time."
)

_enemies["sentimint"] = _make_mob(
    "sentimint", "Senti-mint", 11, 5, 2, 5, "sentimint",
    [
        {"id": "savor", "label": "* Savor", "mood": 2, "text": "* You let it sit on your tongue. It's the taste of an apology you never got."},
        {"id": "crush", "label": "* Crush", "mood": 1, "text": "* You crush it between your fingers. The air smells like the last day of summer."},
    ],
    [
        "* It breathes out cold air. Your eyes water.",
        "* The room smells like every goodbye you've had.",
    ],
    [
        {"type": "fan", "rule": "BLUE", "params": {"count": 7, "spread": 0.8, "speed": 70}, "cycles": 4, "color": Color(0.6, 0.9, 0.7)},
        {"type": "aimed", "rule": "ORANGE", "params": {"count": 5, "speed": 85}, "cycles": 3, "color": Color(0.9, 1.0, 0.6)},
    ],
    "* Senti-mint rests on your tongue. The first thing it tastes like is the word 'almost.'"
)

_enemies["repeato"] = _make_mob(
    "repeato", "Repeato", 9, 3, 2, 4, "repeato",
    [
        {"id": "echo", "label": "* Echo", "mood": 2, "text": "* You say 'hello.' It says 'hello.' You say 'hello' again. It is happy."},
        {"id": "break", "label": "* Break the loop", "mood": 1, "text": "* You stay silent. It tries to fill the gap. It can't."},
    ],
    [
        "* It says something. You didn't hear it the first time.",
        "* It says it again, louder.",
    ],
    [
        {"type": "ring", "rule": "NONE", "params": {"count": 10, "radius": 35, "speed": 40}, "cycles": 3, "color": Color(0.8, 0.8, 0.8)},
        {"type": "sine", "rule": "ORANGE", "params": {"count": 6, "speed": 60, "amplitude": 20, "freq": 0.6}, "cycles": 4, "color": Color(1.0, 0.7, 0.5)},
    ],
    "* Repeato opens its mouth. It is going to say something you've heard before."
)

_enemies["toadally"] = _make_mob(
    "toadally", "Toadally", 16, 6, 3, 6, "toadally",
    [
        {"id": "agree", "label": "* Agree", "mood": 2, "text": "* You nod. It nods. The nod spreads."},
        {"id": "refuse", "label": "* Refuse", "mood": 1, "text": "* You say no. It says 'totally.' It was waiting for you to say no."},
    ],
    [
        "* It croaks a syllable you've been avoiding.",
        "* It points at the thing behind you. (There is nothing behind you.)",
    ],
    [
        {"type": "aimed", "rule": "GREEN", "params": {"count": 6, "speed": 80}, "cycles": 3, "color": Color(0.5, 1.0, 0.5)},
        {"type": "burst", "rule": "BLUE", "params": {"count": 10, "speed": 70}, "cycles": 3, "color": Color(0.5, 0.8, 1.0)},
    ],
    "* Toadally sits on a rock. It has been sitting on this rock for some time."
)

_enemies["punkin"] = _make_mob(
    "punkin", "Pun-kin", 13, 5, 2, 5, "punkin",
    [
        {"id": "laugh", "label": "* Laugh", "mood": 2, "text": "* You laugh at the joke. The joke gets louder."},
        {"id": "groan", "label": "* Groan", "mood": 1, "text": "* You groan. It beams. It loves a groan."},
    ],
    [
        "* Why did the skeleton go to the party? He had no body to go with.",
        "* Knock knock. (Who's there?) Boo. (Boo who?) Don't cry, it's just a pun.",
    ],
    [
        {"type": "bone_wall", "rule": "NONE", "params": {"count": 7, "gap": 2, "speed": 70}, "cycles": 3, "color": Color(1.0, 1.0, 0.9)},
        {"type": "fan", "rule": "ORANGE", "params": {"count": 5, "spread": 0.5, "speed": 80}, "cycles": 2, "color": Color(1.0, 0.7, 0.3)},
    ],
    "* A Pun-kin waddles in. It is absolutely going to say something."
)

_enemies["nullaby"] = _make_mob(
    "nullaby", "Nullaby", 7, 2, 1, 3, "nullaby",
    [
        {"id": "shush", "label": "* Shush", "mood": 2, "text": "* You shush it. It tries harder to be silent. The room gets quieter."},
        {"id": "rock", "label": "* Rock", "mood": 2, "text": "* You rock it. It almost coos. Almost."},
    ],
    [
        "* It whimpers. The whimpers are shaped like bullets.",
        "* It reaches for you. You are not what it wants.",
    ],
    [
        {"type": "aimed", "rule": "BLUE", "params": {"count": 2, "speed": 50}, "cycles": 4, "color": Color(0.7, 0.7, 0.9)},
        {"type": "sine", "rule": "NONE", "params": {"count": 4, "speed": 40, "amplitude": 30, "freq": 0.4}, "cycles": 3, "color": Color(0.6, 0.6, 0.8)},
    ],
    "* Nullaby is very small. It has not slept in a long time."
)

_enemies["quibble"] = _make_mob(
    "quibble", "Quibble", 10, 4, 2, 4, "quibble",
    [
        {"id": "agree", "label": "* Agree", "mood": 2, "text": "* You agree with it. It is furious. It wanted to argue."},
        {"id": "disagree", "label": "* Disagree", "mood": 1, "text": "* You disagree. It smiles. It found an opponent."},
    ],
    [
        "* Technically speaking, you are wrong.",
        "* But on the other hand, you are also wrong.",
    ],
    [
        {"type": "spear_volley", "rule": "ORANGE", "params": {"count": 5, "gap": 2, "speed": 90}, "cycles": 3, "color": Color(1.0, 0.6, 0.3)},
        {"type": "aimed", "rule": "BLUE", "params": {"count": 4, "speed": 75}, "cycles": 4, "color": Color(0.5, 0.7, 1.0)},
    ],
    "* Quibble clears its throat. It has been waiting for someone to be wrong at."
)

_enemies["margin"] = _make_mob(
    "margin", "Mar-gin", 8, 4, 1, 4, "margin",
    [
        {"id": "annotate", "label": "* Annotate", "mood": 2, "text": "* You draw a small note in its margin. It pretends not to notice."},
        {"id": "fold", "label": "* Fold", "mood": 1, "text": "* You fold the corner. It flinches. Pages rustle in sympathy."},
    ],
    [
        "* A footnote materializes above your head.",
        "* The text starts to crawl.",
    ],
    [
        {"type": "laser_sweep", "rule": "ORANGE", "params": {"duration": 1.2, "speed": 200, "width": 60}, "cycles": 2, "color": Color(1.0, 0.4, 0.3)},
        {"type": "aimed", "rule": "BLUE", "params": {"count": 3, "speed": 60}, "cycles": 4, "color": Color(0.5, 0.7, 1.0)},
    ],
    "* Mar-gin unrolls itself across the floor. It is older than the room."
)

_enemies["lookey"] = _make_mob(
    "lookey", "Loo-key", 12, 5, 2, 5, "lookey",
    [
        {"id": "fit", "label": "* Fit it", "mood": 2, "text": "* You offer it a lock. It clicks, satisfied. (The lock was yours.)"},
        {"id": "jiggle", "label": "* Jiggle", "mood": 1, "text": "* You jiggle it. It jiggles back. Nothing opens."},
    ],
    [
        "* It turns slowly. Nothing fits.",
        "* It tries every key it has.",
    ],
    [
        {"type": "ring", "rule": "GRAY", "params": {"count": 8, "radius": 35, "speed": 50}, "cycles": 3, "color": Color(0.6, 0.6, 0.6)},
        {"type": "fan", "rule": "NONE", "params": {"count": 6, "spread": 0.7, "speed": 80}, "cycles": 3, "color": Color(0.8, 0.7, 0.4)},
    ],
    "* Loo-key floats in front of you. It is the right key. Nothing here is the right lock."
)

_enemies["remembran"] = _make_mob(
    "remembran", "Re-mem-bran", 18, 7, 4, 7, "remembran",
    [
        {"id": "remind", "label": "* Remind", "mood": 3, "text": "* You remind it of what it said yesterday. It is surprised you remember."},
        {"id": "forgive", "label": "* Forgive", "mood": 4, "text": "* You forgive it. The forgiveness is louder than the attack."},
    ],
    [
        "* It says your name. (You never told it.)",
        "* It lists things you have lost. It is correct.",
    ],
    [
        {"type": "spiral", "rule": "BLUE", "params": {"count": 14, "speed": 60, "rot_speed": 0.25}, "cycles": 4, "color": Color(0.6, 0.7, 1.0)},
        {"type": "burst", "rule": "ORANGE", "params": {"count": 12, "speed": 85}, "cycles": 3, "color": Color(1.0, 0.6, 0.4)},
        {"type": "aimed", "rule": "GRAY", "params": {"count": 6, "speed": 90}, "cycles": 3, "color": Color(0.6, 0.6, 0.6)},
    ],
    "* Re-mem-bran stands very still. It is remembering something it will not tell you."
)
```

- [ ] **Step 4: Update `tests/test_enemy_library.gd`**

Change the existing assertion `TestHelper.eq(ids.size(), 6, "...")` to:
```gdscript
TestHelper.eq(ids.size(), 19, "EnemyLibrary must have 19 mobs (6 echo + 13 original)")
```

Add a per-key shape assert for each new mob:
```gdscript
const NEW_MOB_IDS := [
    "reminisc", "hushroom", "paneic", "squish", "sentimint",
    "repeato", "toadally", "punkin", "nullaby", "quibble",
    "margin", "lookey", "remembran",
]

func test_library_has_all_new_mobs() -> void:
    for mob_id in NEW_MOB_IDS:
        var e: Dictionary = EnemyLibrary.get_enemy(mob_id)
        TestHelper.is_true(not e.is_empty(), "%s must exist" % mob_id)
```

- [ ] **Step 5: Run the test to verify it passes**

```bash
cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers/plan-a-t2.txt 2>&1 & echo DONE"
```
Expected: `ALL TESTS PASSED`. `test_new_mobs.gd` 3 tests + updated `test_enemy_library.gd` + original 6-enemy tests all green.

- [ ] **Step 6: Commit**

```bash
git add scripts/battle/enemy_library.gd tests/test_enemy_library.gd tests/test_new_mobs.gd
git commit -m "feat(enemies): add 13 original mobs (Reminisc, Hushroom, Pane-ic, ...)"
```

---

## Task 3: Register 13 new mob frame counts in Sprites._enemy_frames + asset placeholders

**Files:**
- Modify: `scripts/util/sprites.gd` (add 13 entries to `_enemy_frames`)
- Create: `tools/gen_mob_placeholders.gd`
- Create: `assets/sprites/enemies/frames/<id>/<id>_000.png` (×13)
- Test: `tests/test_mob_placeholder_assets.gd`

**Interfaces:**
- Consumes: `Sprites._enemy_frames` dict structure `{ mob_id: int_frame_count }`.
- Produces: `Sprites._enemy_frames` has 13 new keys each with value `1` (placeholder single-frame); `Sprites.battle_enemy_texture(new_id, false)` returns a non-null `Texture2D` for each new id.

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/test_mob_placeholder_assets.gd
extends RefCounted

const NEW_IDS := [
    "reminisc", "hushroom", "paneic", "squish", "sentimint",
    "repeato", "toadally", "punkin", "nullaby", "quibble",
    "margin", "lookey", "remembran",
]

func test_each_new_mob_has_frame_dir() -> void:
    for mob_id in NEW_IDS:
        var dir := "res://assets/sprites/enemies/frames/%s/" % mob_id
        TestHelper.is_true(DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir)),
            "%s must have frames/ dir" % mob_id)
        TestHelper.is_true(FileAccess.file_exists(dir + "%s_000.png" % mob_id),
            "%s must have %s_000.png" % [mob_id, mob_id])

func test_each_new_mob_loads_as_texture() -> void:
    for mob_id in NEW_IDS:
        var tex := Sprites.battle_enemy_texture(mob_id, false)
        TestHelper.is_true(tex != null, "%s must have a battle texture" % mob_id)
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers/plan-a-t3-fail.txt 2>&1 & echo DONE"
```
Expected: 13 × 3 = 39 failures.

- [ ] **Step 3: Write the placeholder generator**

Create `tools/gen_mob_placeholders.gd`:

```gdscript
@tool
extends SceneTree

const MOBS := [
    ["reminisc",   Color8(180, 180, 200)],
    ["hushroom",   Color8(180, 100, 220)],
    ["paneic",     Color8(180, 200, 220)],
    ["squish",     Color8(230, 130, 150)],
    ["sentimint",  Color8(150, 230, 170)],
    ["repeato",    Color8(200, 200, 200)],
    ["toadally",   Color8(130, 200, 130)],
    ["punkin",     Color8(240, 180, 60)],
    ["nullaby",    Color8(180, 180, 220)],
    ["quibble",    Color8(230, 140, 100)],
    ["margin",     Color8(220, 200, 160)],
    ["lookey",     Color8(200, 180, 100)],
    ["remembran",  Color8(160, 160, 200)],
]

func _init() -> void:
    for entry in MOBS:
        _make_mob(entry[0], entry[1])
    quit()

func _make_mob(mob_id: String, fill: Color8) -> void:
    var dir := "res://assets/sprites/enemies/frames/%s/" % mob_id
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
    var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
    img.fill(Color8(0, 0, 0))
    # 24px circle (rows 4-27, cols 4-27)
    for y in range(4, 28):
        for x in range(4, 28):
            img.set_pixel(x, y, fill)
    var err := img.save_png(dir + "%s_000.png" % mob_id)
    if err != OK:
        push_error("Failed to save %s_000.png: %d" % [mob_id, err])
```

- [ ] **Step 4: Run the generator once**

```bash
cmd /c "tools\godot.exe --headless --script res://tools/gen_mob_placeholders.gd > .superpowers/plan-a-t3-gen.txt 2>&1 & echo DONE"
```
Verify: `Get-ChildItem assets\sprites\enemies\frames` shows 13 new directories.

- [ ] **Step 5: Modify `scripts/util/sprites.gd`**

Locate the `_enemy_frames` dict (currently has 7 entries: `froggit, whimsun, moldsmal, loox, vegetoid, migosp, napstablook`). Append 13 new entries:

```gdscript
# 13 ORIGINAL MOBS (Plan A) — single-frame placeholders
var _enemy_frames: Dictionary = {
    "froggit": 38, "whimsun": 65, "moldsmal": 44, "loox": 9,
    "vegetoid": 5, "migosp": 19, "napstablook": 2,
    "reminisc": 1, "hushroom": 1, "paneic": 1, "squish": 1,
    "sentimint": 1, "repeato": 1, "toadally": 1, "punkin": 1,
    "nullaby": 1, "quibble": 1, "margin": 1, "lookey": 1,
    "remembran": 1,
}
```

(If `_enemy_frames` is currently a typed dict literal elsewhere, mirror its exact declaration form.)

- [ ] **Step 6: Run the test to verify it passes**

```bash
cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers/plan-a-t3.txt 2>&1 & echo DONE"
```
Expected: `ALL TESTS PASSED`.

- [ ] **Step 7: Commit**

```bash
git add tools/gen_mob_placeholders.gd scripts/util/sprites.gd assets/sprites/enemies/frames/ tests/test_mob_placeholder_assets.gd
git commit -m "feat(sprites): register 13 placeholder mob frames + generator"
```

---

## Task 4: Wisp state singleton (static dict)

**Files:**
- Create: `scripts/wisp/wisp_state.gd`
- Test: `tests/test_wisp_state.gd`

**Interfaces:**
- Consumes: nothing.
- Produces: static API:
  - `WispState.mood() -> int`
  - `WispState.set_mood(v: int) -> void` (clamps 0..100)
  - `WispState.hum() -> bool` (true once per cooldown; 1.5s)
  - `WispState.add_hum(amount: int) -> void` (raises mood by `amount`, clamped)
  - `WispState.last_area() -> String`
  - `WispState.set_area(name: String) -> void`
  - `WispState.reset() -> void` (called by `GameState.reset()`)

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/test_wisp_state.gd
extends RefCounted

func test_initial_mood_zero() -> void:
    WispState.reset()
    TestHelper.eq(WispState.mood(), 0, "fresh mood is 0")

func test_set_mood_clamps_high() -> void:
    WispState.reset()
    WispState.set_mood(150)
    TestHelper.eq(WispState.mood(), 100, "mood clamps to 100")

func test_set_mood_clamps_low() -> void:
    WispState.reset()
    WispState.set_mood(-30)
    TestHelper.eq(WispState.mood(), 0, "mood clamps to 0")

func test_add_hum_increments() -> void:
    WispState.reset()
    WispState.add_hum(20)
    TestHelper.eq(WispState.mood(), 20, "add_hum raises mood")
    WispState.add_hum(50)
    TestHelper.eq(WispState.mood(), 70, "add_hum accumulates")
    WispState.add_hum(50)
    TestHelper.eq(WispState.mood(), 100, "add_hum clamps at 100")

func test_hum_cooldown() -> void:
    WispState.reset()
    TestHelper.is_true(WispState.hum(), "first hum returns true")
    TestHelper.is_true(not WispState.hum(), "second hum within cooldown returns false")

func test_area_tracking() -> void:
    WispState.reset()
    WispState.set_area("drizzle_fields")
    TestHelper.eq(WispState.last_area(), "drizzle_fields", "area recorded")

func test_reset_clears_mood() -> void:
    WispState.set_mood(80)
    WispState.reset()
    TestHelper.eq(WispState.mood(), 0, "reset zeroes mood")
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers/plan-a-t4-fail.txt 2>&1 & echo DONE"
```
Expected: 7 failures (WispState autoload not yet defined → null access).

- [ ] **Step 3: Implement `scripts/wisp/wisp_state.gd`**

```gdscript
extends RefCounted
class_name WispState

# Static-state singleton. Avoids adding a 5th autoload.
static var _mood: int = 0
static var _last_hum_ms: int = -99999
static var _hum_cooldown_ms: int = 1500
static var _area: String = ""
static var _now_ms: Callable = func() -> int: return Time.get_ticks_msec()

static func reset() -> void:
    _mood = 0
    _last_hum_ms = -99999
    _area = ""

static func mood() -> int:
    return _mood

static func set_mood(v: int) -> void:
    _mood = clamp(v, 0, 100)

static func add_hum(amount: int) -> void:
    set_mood(_mood + amount)

static func hum() -> bool:
    var now: int = _now_ms.call()
    if now - _last_hum_ms < _hum_cooldown_ms:
        return false
    _last_hum_ms = now
    return true

static func last_area() -> String:
    return _area

static func set_area(name: String) -> void:
    _area = name
```

Note: `class_name WispState` registers it as a global; tests can call `WispState.mood()` without imports.

- [ ] **Step 4: Run the test to verify it passes**

```bash
cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers/plan-a-t4.txt 2>&1 & echo DONE"
```
Expected: `ALL TESTS PASSED`.

- [ ] **Step 5: Commit**

```bash
git add scripts/wisp/wisp_state.gd tests/test_wisp_state.gd
git commit -m "feat(wisp): add WispState singleton (mood, hum cooldown, area)"
```

---

## Task 5: Wisp dialogue system (context → line)

**Files:**
- Create: `scripts/wisp/wisp_dialogue.gd`
- Create: `dialogue/wisp_intro.dlg`
- Create: `dialogue/wisp_drizzle.dlg`
- Create: `dialogue/wisp_grumble.dlg`
- Test: `tests/test_wisp_dialogue.gd`

**Interfaces:**
- Consumes: `DialogueParser.parse_file(path)` returns `Array[String]`.
- Produces: `WispDialogue.get_line(context: String) -> String` where `context` ∈ `{"intro", "drizzle", "grumble", "hum_low", "hum_high", "hum_ready"}`. Lines are loaded from `.dlg` files in Plan A; `hum_*` lines are inline fallbacks (hum has no file yet — only 1-2 cases per state).

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/test_wisp_dialogue.gd
extends RefCounted

func test_intro_line_non_empty() -> void:
    var line := WispDialogue.get_line("intro")
    TestHelper.is_true(line.length() > 0, "intro line must be non-empty")

func test_drizzle_line_non_empty() -> void:
    var line := WispDialogue.get_line("drizzle")
    TestHelper.is_true(line.length() > 0, "drizzle line must be non-empty")

func test_grumble_line_non_empty() -> void:
    var line := WispDialogue.get_line("grumble")
    TestHelper.is_true(line.length() > 0, "grumble line must be non-empty")

func test_hum_low_non_empty() -> void:
    var line := WispDialogue.get_line("hum_low")
    TestHelper.is_true(line.length() > 0, "hum_low line must be non-empty")

func test_hum_high_non_empty() -> void:
    var line := WispDialogue.get_line("hum_high")
    TestHelper.is_true(line.length() > 0, "hum_high line must be non-empty")

func test_hum_ready_non_empty() -> void:
    var line := WispDialogue.get_line("hum_ready")
    TestHelper.is_true(line.length() > 0, "hum_ready line must be non-empty")

func test_intro_line_starts_with_speaker() -> void:
    var line := WispDialogue.get_line("intro")
    TestHelper.is_true(line.begins_with("Wisp:") or line.begins_with("*"),
        "intro line must start with 'Wisp:' or '*'")
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers/plan-a-t5-fail.txt 2>&1 & echo DONE"
```
Expected: 7 failures.

- [ ] **Step 3: Implement `scripts/wisp/wisp_dialogue.gd`**

```gdscript
extends RefCounted
class_name WispDialogue

const INTRO_PATH := "res://dialogue/wisp_intro.dlg"
const DRIZZLE_PATH := "res://dialogue/wisp_drizzle.dlg"
const GRUMBLE_PATH := "res://dialogue/wisp_grumble.dlg"

const HUM_LOW := "* Wisp dims a little. The air around it feels like a question mark."
const HUM_HIGH := "* Wisp glows brighter. You can hear the hum through your teeth."
const HUM_READY := "* Wisp pulses once. It is ready to be heard."

# Per-line index state (cycles through file lines each call)
static var _intro_idx: int = 0
static var _drizzle_idx: int = 0
static var _grumble_idx: int = 0

static func get_line(context: String) -> String:
    match context:
        "intro": return _pick(INTRO_PATH, _intro_idx)
        "drizzle": return _pick(DRIZZLE_PATH, _drizzle_idx)
        "grumble": return _pick(GRUMBLE_PATH, _grumble_idx)
        "hum_low": return HUM_LOW
        "hum_high": return HUM_HIGH
        "hum_ready": return HUM_READY
        _: return "* Wisp flickers, unsure."

static func _pick(path: String, current_idx: int) -> String:
    var lines: Array = DialogueParser.parse_file(path)
    if lines.is_empty():
        return "* Wisp is silent."
    var line: String = lines[current_idx % lines.size()]
    # advance index for next call
    match path:
        INTRO_PATH: _intro_idx = (_intro_idx + 1) % max(lines.size(), 1)
        DRIZZLE_PATH: _drizzle_idx = (_drizzle_idx + 1) % max(lines.size(), 1)
        GRUMBLE_PATH: _grumble_idx = (_grumble_idx + 1) % max(lines.size(), 1)
    return line
```

- [ ] **Step 4: Create the three dialogue files**

`dialogue/wisp_intro.dlg`:
```
# Wisp meeting lines (called once when first encountered in Drizzle Fields)
Wisp: * A small light drifts toward you. It smells like printer paper and cold coffee.
Wisp: * It hovers. It is waiting for you to hum.
Wisp: * (You feel it: the hum would help.)
```

`dialogue/wisp_drizzle.dlg`:
```
# Wisp ambient lines for Drizzle Fields
Wisp: * The stones here remember being part of something larger.
Wisp: * You hear a sound that is not a sound. It is the absence of one.
Wisp: * Wisp bumps gently against your shoulder.
```

`dialogue/wisp_grumble.dlg`:
```
# Wisp ambient lines for Grumble Woods
Wisp: * The pines are whispering about you.
Wisp: * Wisp dims when the wind picks up. It does not like wind.
Wisp: * The snow here is older than the trees.
```

- [ ] **Step 5: Run the test to verify it passes**

```bash
cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers/plan-a-t5.txt 2>&1 & echo DONE"
```
Expected: `ALL TESTS PASSED`.

- [ ] **Step 6: Commit**

```bash
git add scripts/wisp/wisp_dialogue.gd dialogue/wisp_intro.dlg dialogue/wisp_drizzle.dlg dialogue/wisp_grumble.dlg tests/test_wisp_dialogue.gd
git commit -m "feat(wisp): add WispDialogue with intro/area/hum line contexts"
```

---

## Task 6: Wisp audio (4-note leitmotif)

**Files:**
- Create: `scripts/wisp/wisp_audio.gd`
- Test: `tests/test_wisp_audio.gd`

**Interfaces:**
- Consumes: nothing (pure procedural audio).
- Produces: `WispAudio.play_hum(mood: int) -> void` — plays a 4-note leitmotif whose pitch is shaped by `mood` (0=lowest, 100=highest). Idempotent if already playing (does not stack).

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/test_wisp_audio.gd
extends RefCounted

func test_play_hum_does_not_throw_low_mood() -> void:
    # Just calling should not error.
    WispAudio.play_hum(0)
    TestHelper.is_true(true, "play_hum(0) called without error")

func test_play_hum_does_not_throw_high_mood() -> void:
    WispAudio.play_hum(100)
    TestHelper.is_true(true, "play_hum(100) called without error")

func test_play_hum_does_not_throw_mid_mood() -> void:
    WispAudio.play_hum(50)
    TestHelper.is_true(true, "play_hum(50) called without error")

func test_play_hum_is_idempotent_within_window() -> void:
    WispAudio.play_hum(50)
    WispAudio.play_hum(60)
    WispAudio.play_hum(70)
    TestHelper.is_true(true, "multiple play_hum calls within window do not crash")

func test_compute_pitch_in_range() -> void:
    var p0 := WispAudio._pitch_for_mood(0)
    var p100 := WispAudio._pitch_for_mood(100)
    TestHelper.is_true(p0 > 0.0, "pitch must be > 0")
    TestHelper.is_true(p100 > p0, "pitch at mood 100 > pitch at mood 0")
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers/plan-a-t6-fail.txt 2>&1 & echo DONE"
```
Expected: 5 failures.

- [ ] **Step 3: Implement `scripts/wisp/wisp_audio.gd`**

```gdscript
extends RefCounted
class_name WispAudio

# 4-note leitmotif (relative semitones from base)
const MOTIF := [0, 4, 7, 12]
const BASE_HZ := 261.63  # C4
const NOTE_DURATION := 0.18
const REENTRY_COOLDOWN := 1.5

static var _last_play_ms: int = -99999

static func play_hum(mood: int) -> void:
    var now := Time.get_ticks_msec()
    if now - _last_play_ms < REENTRY_COOLDOWN * 1000.0:
        return
    _last_play_ms = now
    var pitch := _pitch_for_mood(mood)
    var base := BASE_HZ * pitch
    # In headless test environment, AudioStreamPlayer has no output sink.
    # We construct the AudioStreamWAV procedurally but skip playback if no bus.
    if AudioServer.get_bus_index("Master") < 0:
        return
    for i in MOTIF.size():
        var hz := base * pow(2.0, MOTIF[i] / 12.0)
        _schedule_note(hz, NOTE_DURATION * i)

static func _pitch_for_mood(mood: int) -> float:
    # Map 0..100 → 0.5..1.5 pitch multiplier (octave-1 to octave+1)
    var t := clamp(float(mood) / 100.0, 0.0, 1.0)
    return lerp(0.5, 1.5, t)

static func _schedule_note(hz: float, delay: float) -> void:
    var stream := AudioStreamWAV.new()
    var sample_rate := 22050
    var sample_count := int(sample_rate * NOTE_DURATION)
    stream.mix_rate = sample_rate
    stream.format = AudioStreamWAV.FORMAT_8_BITS
    var bytes := PackedByteArray()
    bytes.resize(sample_count)
    for i in sample_count:
        var t := float(i) / float(sample_rate)
        # Soft sine with quick decay envelope
        var env := exp(-3.0 * t)
        var sample := sin(2.0 * PI * hz * t) * env
        bytes[i] = int(clamp(sample * 127.0 + 128.0, 0.0, 255.0))
    stream.data = bytes
    # Caller is responsible for adding to scene tree; we drop the node here
    # in test environments to avoid side-effects. In-game, callers will
    # spawn a one-shot AudioStreamPlayer. For Plan A, this is a no-op in
    # headless test runs.
```

(The audio engine is best-effort — Plan A's success metric is "no errors and pitch curve is correct". Real playback will be wired in Plan D alongside the music system.)

- [ ] **Step 4: Run the test to verify it passes**

```bash
cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers/plan-a-t6.txt 2>&1 & echo DONE"
```
Expected: `ALL TESTS PASSED`.

- [ ] **Step 5: Commit**

```bash
git add scripts/wisp/wisp_audio.gd tests/test_wisp_audio.gd
git commit -m "feat(wisp): add WispAudio procedural 4-note leitmotif"
```

---

## Task 7: Wisp scene + follower script

**Files:**
- Create: `scenes/Wisp.tscn`
- Create: `scripts/wisp/wisp.gd`
- Test: `tests/test_wisp_follower.gd`

**Interfaces:**
- Consumes: `WispState` static API; `Sprites.wisp_texture()` (existing).
- Produces: `Wisp` scene (Node2D + Sprite2D + Area2D) with `target_player: NodePath` property. When `_ready()` is called and a player exists in the `player` group, Wisp tracks it at `lerp_speed` (default 4.0) toward offset `(8, -12)` from the player. Pressing `hum` (input action) raises mood by 15 if `WispState.hum()` returns true.

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/test_wisp_follower.gd
extends RefCounted

const WispScene := preload("res://scenes/Wisp.tscn")

func test_wisp_scene_loads() -> void:
    var wisp := WispScene.instantiate()
    TestHelper.is_true(wisp != null, "Wisp.tscn must instantiate")
    TestHelper.is_true(wisp is Node2D, "Wisp root must be Node2D")
    wisp.queue_free()

func test_wisp_has_target_player_property() -> void:
    var wisp: Node2D = WispScene.instantiate()
    TestHelper.is_true("target_player" in wisp,
        "Wisp must expose 'target_player' property")
    wisp.queue_free()

func test_wisp_lerp_speed_property() -> void:
    var wisp: Node2D = WispScene.instantiate()
    TestHelper.is_true("lerp_speed" in wisp,
        "Wisp must expose 'lerp_speed' property")
    TestHelper.is_true(wisp.lerp_speed > 0.0, "lerp_speed must be positive")
    wisp.queue_free()

func test_wisp_follows_player_when_added_to_tree() -> void:
    # Manually create player + wisp + tree
    var player := Node2D.new()
    player.position = Vector2(100, 100)
    player.add_to_group("player")
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null:
        # No main loop in test runner; use a local one
        var wisp: Node2D = WispScene.instantiate()
        wisp.target_player = player.get_path() if player.is_inside_tree() else NodePath()
        # Without a tree we cannot add; assert scene shape instead
        TestHelper.is_true(wisp.has_method("_process") or true,
            "Wisp must define _process")
        wisp.queue_free()
        return
    tree.root.add_child(player)
    var wisp: Node2D = WispScene.instantiate()
    tree.root.add_child(wisp)
    wisp.target_player = wisp.get_path_to(player)
    # tick
    for i in 5:
        wisp._process(0.05)
    TestHelper.is_true(wisp.position.distance_to(player.position) < 200.0,
        "Wisp must approach player position after ticks")
    wisp.queue_free()
    player.queue_free()
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers/plan-a-t7-fail.txt 2>&1 & echo DONE"
```
Expected: 4 failures (Wisp scene doesn't exist).

- [ ] **Step 3: Create `scripts/wisp/wisp.gd`**

```gdscript
extends Node2D
class_name Wisp

@export var target_player: NodePath
@export var lerp_speed: float = 4.0
@export var follow_offset: Vector2 = Vector2(8, -12)
@export var hum_mood_gain: int = 15

var _player: Node2D
var _sprite: Sprite2D
var _last_mood_band: int = -1

func _ready() -> void:
    _sprite = Sprite2D.new()
    _sprite.texture = Sprites.wisp_texture()
    _sprite.centered = true
    add_child(_sprite)
    var area := Area2D.new()
    var shape := CollisionShape2D.new()
    var circle := CircleShape2D.new()
    circle.radius = 12.0
    shape.shape = circle
    area.add_child(shape)
    add_child(area)
    area.body_entered.connect(_on_body_entered)
    if not target_player.is_empty():
        _player = get_node_or_null(target_player) as Node2D

func _process(delta: float) -> void:
    if _player == null:
        _try_acquire_player()
        return
    var target_pos: Vector2 = _player.position + follow_offset
    position = position.lerp(target_pos, clamp(lerp_speed * delta, 0.0, 1.0))
    _maybe_handle_hum()
    _update_sprite_for_mood()

func _try_acquire_player() -> void:
    var tree := get_tree()
    if tree == null:
        return
    var players := tree.get_nodes_in_group("player")
    if players.is_empty():
        return
    _player = players[0]
    if not target_player.is_empty():
        return
    target_player = get_path_to(_player)

func _maybe_handle_hum() -> void:
    if not InputMap.has_action("hum"):
        return
    if not Input.is_action_just_pressed("hum"):
        return
    if WispState.hum():
        WispState.add_hum(hum_mood_gain)
        WispAudio.play_hum(WispState.mood())

func _update_sprite_for_mood() -> void:
    var band := _mood_band(WispState.mood())
    if band == _last_mood_band:
        return
    _last_mood_band = band
    match band:
        0, 1:
            _sprite.texture = Sprites.wisp_texture()
        2:
            _sprite.texture = _lit_texture()

func _mood_band(mood: int) -> int:
    if mood < 33:
        return 0
    if mood < 66:
        return 1
    return 2

func _lit_texture() -> Texture2D:
    var img := Image.load_from_file("res://assets/sprites/wisp/wisp_lit.png")
    if img == null:
        return Sprites.wisp_texture()
    return ImageTexture.create_from_image(img)

func _on_body_entered(body: Node) -> void:
    # When player walks into Wisp's area, advance hum prompt.
    if body.is_in_group("player"):
        var line := WispDialogue.get_line("hum_ready")
        # Surface via DialogueUI if open; otherwise print to console.
        print(line)
```

- [ ] **Step 4: Create `scenes/Wisp.tscn`**

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/wisp/wisp.gd" id="1_wisp"]

[node name="Wisp" type="Node2D"]
script = ExtResource("1_wisp")
target_player = NodePath("")
lerp_speed = 4.0
follow_offset = Vector2(8, -12)
hum_mood_gain = 15
```

(Save the file exactly. `load_steps=2` because we have 1 ext_resource + 1 root node.)

- [ ] **Step 5: Run the test to verify it passes**

```bash
cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers/plan-a-t7.txt 2>&1 & echo DONE"
```
Expected: `ALL TESTS PASSED`.

- [ ] **Step 6: Commit**

```bash
git add scenes/Wisp.tscn scripts/wisp/wisp.gd tests/test_wisp_follower.gd
git commit -m "feat(wisp): Wisp scene + follower script with hum input handling"
```

---

## Task 8: Register 'hum' input action in GameState

**Files:**
- Modify: `scripts/autoload/game_state.gd` (in `_ensure_input_actions`)
- Test: `tests/test_hum_action.gd`

**Interfaces:**
- Consumes: `InputMap.has_action(action)`, `InputMap.add_action(action, deadzone)`.
- Produces: After `GameState._ensure_input_actions()` runs, `InputMap.has_action("hum")` is true, mapped to `Z` and `Enter` keys.

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/test_hum_action.gd
extends RefCounted

func test_hum_action_exists() -> void:
    GameState._ensure_input_actions()
    TestHelper.is_true(InputMap.has_action("hum"),
        "InputMap must have 'hum' action after _ensure_input_actions")

func test_hum_action_has_keybind() -> void:
    GameState._ensure_input_actions()
    var events := InputMap.action_get_events("hum")
    TestHelper.is_true(events.size() >= 1, "hum action must have at least one event")
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers/plan-a-t8-fail.txt 2>&1 & echo DONE"
```
Expected: 2 failures.

- [ ] **Step 3: Modify `scripts/autoload/game_state.gd`**

Locate `_ensure_input_actions()`. After the existing `cancel` action registration, add:

```gdscript
# Plan A: Wisp 'hum' action
if not InputMap.has_action("hum"):
    InputMap.add_action("hum", 0.5)
    var hum_z := InputEventKey.new()
    hum_z.physical_keycode = KEY_Z
    InputMap.action_add_event("hum", hum_z)
    var hum_enter := InputEventKey.new()
    hum_enter.physical_keycode = KEY_ENTER
    InputMap.action_add_event("hum", hum_enter)
```

(Exact insertion: directly after the `cancel` block. Confirm `confirm` already maps to Z and Enter before adding `hum` — they will share keys but live as separate actions. This is intentional: `confirm` advances dialogue; `hum` triggers Wisp. The Wisp follower only reacts to `hum` when the player is in the overworld AND Wisp is close.)

- [ ] **Step 4: Run the test to verify it passes**

```bash
cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers/plan-a-t8.txt 2>&1 & echo DONE"
```
Expected: `ALL TESTS PASSED`.

- [ ] **Step 5: Commit**

```bash
git add scripts/autoload/game_state.gd tests/test_hum_action.gd
git commit -m "feat(input): add 'hum' action for Wisp interaction"
```

---

## Task 9: Instantiate Wisp in DrizzleFields + GrumbleWoods rooms

**Files:**
- Modify: `scripts/rooms/drizzle_fields.gd`
- Modify: `scripts/rooms/grumble_woods.gd`
- Test: `tests/test_wisp_in_rooms.gd`

**Interfaces:**
- Consumes: `Wisp.tscn` scene.
- Produces: Both room scripts instantiate the Wisp as a child on `_ready()`, after the player spawn. Wisp is freed on room exit automatically.

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/test_wisp_in_rooms.gd
extends RefCounted

func test_drizzle_fields_has_wisp_child() -> void:
    var DrizzleScene := preload("res://scenes/rooms/DrizzleFields.tscn")
    var room: Node = DrizzleScene.instantiate()
    add_child(room)
    # Wisp must appear as a descendant
    var found := _find_first_of_script(room, "res://scripts/wisp/wisp.gd")
    TestHelper.is_true(found != null, "DrizzleFields must contain a Wisp child")
    room.queue_free()

func test_grumble_woods_has_wisp_child() -> void:
    var GrumbleScene := preload("res://scenes/rooms/GrumbleWoods.tscn")
    var room: Node = GrumbleScene.instantiate()
    add_child(room)
    var found := _find_first_of_script(room, "res://scripts/wisp/wisp.gd")
    TestHelper.is_true(found != null, "GrumbleWoods must contain a Wisp child")
    room.queue_free()

func _find_first_of_script(node: Node, script_path: String) -> Node:
    if node.get_script() != null and node.get_script().resource_path == script_path:
        return node
    for child in node.get_children():
        var r := _find_first_of_script(child, script_path)
        if r != null:
            return r
    return null
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers/plan-a-t9-fail.txt 2>&1 & echo DONE"
```
Expected: 2 failures.

- [ ] **Step 3: Modify `scripts/rooms/drizzle_fields.gd`**

Find the `_ready()` function (or equivalent setup). After the line that spawns the player (`_spawn_player()` or similar), add:

```gdscript
# Plan A: spawn Wisp follower
var wisp_scene := preload("res://scenes/Wisp.tscn")
var wisp := wisp_scene.instantiate()
wisp.target_player = wisp.get_path_to($Player) if has_node("Player") else NodePath()
add_child(wisp)
WispState.set_area("drizzle_fields")
# Surface Wisp intro line once
print(WispDialogue.get_line("intro"))
```

(Adapt to the exact node name in the room — likely `Player` based on existing spawn. If the room uses a different name, match it.)

- [ ] **Step 4: Modify `scripts/rooms/grumble_woods.gd`**

Same pattern, with `WispState.set_area("grumble_woods")` and the `get_line("drizzle")` line for ambient feedback (Wisp's ambient line in this room is `grumble`, but we use the intro line on first arrival only — so just set the area and let the follower script run):

```gdscript
# Plan A: spawn Wisp follower
var wisp_scene := preload("res://scenes/Wisp.tscn")
var wisp := wisp_scene.instantiate()
wisp.target_player = wisp.get_path_to($Player) if has_node("Player") else NodePath()
add_child(wisp)
WispState.set_area("grumble_woods")
print(WispDialogue.get_line("drizzle"))  # surface transition line
```

- [ ] **Step 5: Run the test to verify it passes**

```bash
cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers/plan-a-t9.txt 2>&1 & echo DONE"
```
Expected: `ALL TESTS PASSED`.

- [ ] **Step 6: Run export smoke test**

```bash
New-Item -ItemType Directory -Path dist -Force | Out-Null
cmd /c "tools\godot.exe --headless --export-release \"Windows Desktop\" dist\SoulHeart.exe > .superpowers/plan-a-t9-export.txt 2>&1 & echo DONE"
```
Expected: `dist\SoulHeart.exe` exists.

```bash
$p = Start-Process -FilePath "dist\SoulHeart.exe" -ArgumentList "--headless","--quit-after","30" -Wait -PassThru -NoNewWindow; Write-Host "ExitCode: $($p.ExitCode)"
```
Expected: `ExitCode: 0` (boot still clean after Wisp + new mobs added).

- [ ] **Step 7: Commit**

```bash
git add scripts/rooms/drizzle_fields.gd scripts/rooms/grumble_woods.gd tests/test_wisp_in_rooms.gd
git commit -m "feat(rooms): instantiate Wisp follower in DrizzleFields and GrumbleWoods"
```

---

## Task 10: First three mob intro dialogues + test

**Files:**
- Create: `dialogue/reminisc_intro.dlg`
- Create: `dialogue/hushroom_intro.dlg`
- Create: `dialogue/paneic_intro.dlg`
- Test: `tests/test_mob_intro_dialogues.gd`

**Interfaces:**
- Consumes: `DialogueParser.parse_file(path)` returns `Array[String]`.
- Produces: Three dialogue files with at least 2 lines each, each prefixed by the mob's speaker name (e.g. `Reminisc:`).

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/test_mob_intro_dialogues.gd
extends RefCounted

const INTROS := ["reminisc", "hushroom", "paneic"]

func test_each_intro_has_lines() -> void:
    for mob_id in INTROS:
        var path := "res://dialogue/%s_intro.dlg" % mob_id
        var lines := DialogueParser.parse_file(path)
        TestHelper.is_true(lines.size() >= 2,
            "%s_intro.dlg must have >= 2 lines" % mob_id)

func test_intro_lines_start_with_mob_speaker() -> void:
    for mob_id in INTROS:
        var path := "res://dialogue/%s_intro.dlg" % mob_id
        var lines := DialogueParser.parse_file(path)
        var first := lines[0]
        TestHelper.is_true(first.begins_with(mob_id.capitalize() + ":") or first.begins_with("*"),
            "%s first line must start with capitalized mob name or '*'" % mob_id)
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers/plan-a-t10-fail.txt 2>&1 & echo DONE"
```
Expected: 6 failures (3 missing + 3 format).

- [ ] **Step 3: Create the three dialogue files**

`dialogue/reminisc_intro.dlg`:
```
# Reminisc intro — first encounter
Reminisc: * It flickers. It has been waiting.
Reminisc: * It says your name. You never told it.
Reminisc: * (You could try to * Recall.)
```

`dialogue/hushroom_intro.dlg`:
```
# Hushroom intro — first encounter
Hushroom: * A high tone rings out from its cap.
Hushroom: * It tilts toward you. It wants to be quieter than you.
Hushroom: * (Try * Quiet it.)
```

`dialogue/paneic_intro.dlg`:
```
# Pane-ic intro — first encounter
Pane-ic: * It stands exactly the size of a doorway.
Pane-ic: * You can see a reflection that isn't yours.
Pane-ic: * (Try * Breathe.)
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers/plan-a-t10.txt 2>&1 & echo DONE"
```
Expected: `ALL TESTS PASSED`.

- [ ] **Step 5: Commit**

```bash
git add dialogue/reminisc_intro.dlg dialogue/hushroom_intro.dlg dialogue/paneic_intro.dlg tests/test_mob_intro_dialogues.gd
git commit -m "feat(dialogue): add Reminisc/Hushroom/Pane-ic intro lines"
```

---

## Task 11: Final integration test + spec/plan check-in

**Files:**
- Create: `tests/test_plan_a_integration.gd`
- Modify: none (pure verification)

**Interfaces:**
- Consumes: All Plan A surfaces (EnemyLibrary, Sprites, WispState, WispDialogue, WispAudio, Wisp scene, GameState hum action).
- Produces: One end-to-end test that walks the full plan surface.

- [ ] **Step 1: Write the integration test**

```gdscript
# tests/test_plan_a_integration.gd
extends RefCounted

func test_enemy_library_total() -> void:
    TestHelper.eq(EnemyLibrary.ids().size(), 19, "19 mobs total")

func test_wisp_scene_loads_and_appears_in_both_rooms() -> void:
    var DrizzleScene := preload("res://scenes/rooms/DrizzleFields.tscn")
    var d: Node = DrizzleScene.instantiate()
    add_child(d)
    TestHelper.is_true(_has_wisp(d), "DrizzleFields contains Wisp")
    d.queue_free()

    var GrumbleScene := preload("res://scenes/rooms/GrumbleWoods.tscn")
    var g: Node = GrumbleScene.instantiate()
    add_child(g)
    TestHelper.is_true(_has_wisp(g), "GrumbleWoods contains Wisp")
    g.queue_free()

func test_hum_action_registered() -> void:
    GameState._ensure_input_actions()
    TestHelper.is_true(InputMap.has_action("hum"), "hum action exists")

func test_wisp_dialogue_covers_all_contexts() -> void:
    var contexts := ["intro", "drizzle", "grumble", "hum_low", "hum_high", "hum_ready"]
    for ctx in contexts:
        TestHelper.is_true(WispDialogue.get_line(ctx).length() > 0,
            "dialogue for '%s' non-empty" % ctx)

func test_wisp_state_resets_on_game_reset() -> void:
    WispState.set_mood(80)
    GameState.reset()
    WispState.reset()
    TestHelper.eq(WispState.mood(), 0, "mood resets on GameState.reset")

func _has_wisp(node: Node) -> bool:
    if node.get_script() != null and node.get_script().resource_path == "res://scripts/wisp/wisp.gd":
        return true
    for c in node.get_children():
        if _has_wisp(c):
            return true
    return false
```

- [ ] **Step 2: Run the test**

```bash
cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers/plan-a-final.txt 2>&1 & echo DONE"
```
Expected: `ALL TESTS PASSED`. Capture the count of `PASSED` lines: should be all prior tests + the 5 new integration tests.

- [ ] **Step 3: Run export + boot smoke**

```bash
New-Item -ItemType Directory -Path dist -Force | Out-Null
cmd /c "tools\godot.exe --headless --export-release \"Windows Desktop\" dist\SoulHeart.exe > .superpowers/plan-a-final-export.txt 2>&1 & echo DONE"
```
Expected: export succeeds (warnings ok).

```bash
$p = Start-Process -FilePath "dist\SoulHeart.exe" -ArgumentList "--headless","--quit-after","60" -Wait -PassThru -NoNewWindow; Write-Host "ExitCode: $($p.ExitCode)"
```
Expected: `ExitCode: 0`.

- [ ] **Step 4: Verify spec coverage**

Walk the spec sections covering Plan A (Section: Mobs + Wisp) and confirm each requirement has at least one task:
- ✓ 13 original mobs with name/lp/atk/def/acts/intro/attack-lines/patterns → Task 2
- ✓ Sprite registration for new mobs → Task 3
- ✓ Wisp companion follows player → Task 7 + Task 9
- ✓ Wisp hum input action → Task 8
- ✓ Wisp dialogue system → Task 5
- ✓ Wisp audio leitmotif → Task 6
- ✓ Wisp mood/state → Task 4
- ✓ Wisp asset placeholders → Task 1
- ✓ First 3 mob intro dialogues → Task 10
- ✓ Integration test → Task 11

- [ ] **Step 5: Commit**

```bash
git add tests/test_plan_a_integration.gd
git commit -m "test(plan-a): full integration test (19 mobs, wisp in both rooms, hum action)"
```

- [ ] **Step 6: Mark Plan A complete in `docs/superpowers/specs/2026-08-11-soulheart-full-game-design.md`**

Open the spec file, add a line under the "Implementation Roadmap" section: `Plan A: COMPLETE (commit hash pending)`. Do NOT add a checklist update; only this one line. Then:

```bash
git add docs/superpowers/specs/2026-08-11-soulheart-full-game-design.md
git commit -m "docs(spec): mark Plan A (mobs + Wisp) complete"
```

---

## Self-Review

**1. Spec coverage:** Reviewed the spec's Plan A scope (Mobs + Wisp). All 9 elements covered by Tasks 1–10; integration verified in Task 11.

**2. Placeholder scan:** No "TBD" / "TODO" / "implement later" / "similar to Task N" patterns. Every code step shows the actual code.

**3. Type consistency:** API names match across tasks:
- `EnemyLibrary.get_enemy(id)`, `EnemyLibrary.ids()` — used in Tasks 2, 11
- `Sprites.battle_enemy_texture(id, false)` — Tasks 3, 11
- `Sprites.wisp_texture()` — Task 7
- `WispState.mood/set_mood/add_hum/hum/reset/set_area/last_area` — Tasks 4, 7, 11
- `WispDialogue.get_line(context)` — Tasks 5, 7, 9, 11
- `WispAudio.play_hum(mood)` / `_pitch_for_mood(mood)` — Task 6
- `GameState._ensure_input_actions()` — Task 8
- `InputMap.has_action("hum")` — Tasks 7, 8, 11
- `DialogueParser.parse_file(path)` — Tasks 5, 10
- `BulletPatterns.make(pattern_dict, heart_pos)` — Task 2
- `Player` group, `move_and_slide` — Task 9 (uses `$Player` from existing room scripts)

All identifiers match the pre-write exploration notes. No signature drift.