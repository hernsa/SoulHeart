# Plan C — Bosses + Mini-boss + Final Fight

**Status:** draft → commit → execute in worktree `plan-c-bosses`
**Branch:** `plan-c-bosses` (off `main` @ `14182c5`)
**Spec source:** `docs/superpowers/specs/2026-08-11-soulheart-full-game-design.md` lines 257-262 (Plan C scope) + §3.5 (Mourning Knight), §3.6 (Index), §8 (dialog files), §2 (Canon true form — Cracks true final, Keeper-only).

## Goal

Ship **boss fights** so the full game is walkable and beatable end-to-end:

- **Mourning Knight** — Canon area mini-boss. Armor holding together with nothing inside; mourns a dreamer; attacks slow and sad; spare with the ACT `* Mourn`.
- **The Index** — Cracks final boss, 3 forms. Carries a quill; "attacks are edits — bullets that change what they were as they cross the box." 3 endings branch here (Plan D — placeholder for now).
- **Canon true form** — Cracks optional true final, Keeper-only encounter. Boss ACT menu Accept / Refuse.
- Boss ACT menus, multi-phase fight bar, save-before-boss flow, form transitions, monologue lines at HP thresholds, edit-bullet behavior.

**Spec literal scope (lines 257-262):**

> Plan C — Bosses + Mini-boss + Final fight: Mourning Knight (mini-boss), Index (final boss, 3 forms), Canon true form (Keeper-only). Boss ACT menus, multi-phase fight bar, save-before-boss flow.
>
> Shippable: walk whole game, beat bosses, ending choice has no consequences yet (Plan D).

---

## Engine Reality (verified ground truth)

| File | Lines | Key hooks |
|------|-------|-----------|
| `scripts/battle/battle.gd` | 544 | `_ready` (sets `_enemy=EnemyLibrary.get_enemy`, `_enemy_max_hp=int(_enemy['hp'])`, `_spawn_enemy_sprite` at (216,136) scale 0.8 bob). `_resolve_fight` hp<=0 → WIN. `_resolve_submenu` MERCY → Spare/Flee; `static flee_roll(0.5)`. `_refresh_enemy_ui` names YELLOW if mood>=spare_after. `_enemy_turn` picks attack_line, telegraphs 0.6s, `BulletPatterns.make(pattern, _dodge_box.heart_position())`. MERCY submenu `['Spare','Flee']`. `_say(lines)` opens DialogueUI awaits `finished`. `_end_battle` returns to `from_room`. |
| `scripts/battle/enemy_library.gd` | 378 | `_enemies` static dict; `_make_mob(id,name,hp,atk,def,spare,sprite,acts,lines,patterns,intro)`. `get_enemy(id)` returns `.duplicate(true)` (deep copy per battle — form templates stay safe). `act_labels`/`act_by_label` helpers. |
| `scripts/battle/bullet.gd` | 32 | enum `Type{PELLET,BONE,SPEAR,RING,LASER,ARROW}`, `Rule{NONE,BLUE,ORANGE,GRAY,GREEN}`. `setup(d)` reads pos/vel/life/size/type/rule/behavior/phase/orbit_center; creates `Sprite2D spr` `Sprites.bullet_texture_for(btype)`; **does NOT store sprite ref**. `dead()` = `life<=0`. |
| `scripts/battle/dodge_box.gd` | 158 | HEART_SPEED 160, BOX_RECT (162,220,315,170), HEART_START (319,305). `spawn_patterns` → Bullet.setup + add_child. `_process` movement match `behavior`: `sine/homing/gravity/orbit` + default straight. **NEW `edit` arm slots in:** if not `edited and phase>=edit_at: b.apply_edit(); then straight move`. circle_hit r=4+size. _bullet_damages by rule (GRAY/GREEN no; BLUE if |heart_vel|>8; ORANGE if |heart_vel|<=8; default yes). `set_active(false)` clears bullets. |
| `scripts/battle/fight_bar.gd` | 17 | marker 0..1, _dir 1.0; tick swaps dir at bounds. press() = 1.0 - |marker-0.5|*2. |
| `scripts/battle/combat_math.gd` | 25 | `calculate_damage(atk,def,intent)` = max(1, max(1,atk-def) * clamp(intent,0,1)). `drain_toward(cur,tgt,delta,rate=40)` linear approach. |
| `scripts/battle/encounter.gd` | 47 | Area2D, @export `enemy_id` (default 'froggit'), `used:bool`. _ready: CollisionShape2D CircleShape2D r=8; body_entered wired; Sprite2D 'EnemySprite' (0,-26) scale 0.5 bob tween. _on_body_entered: player group + !used → used=true → set flags `pending_enemy`+`from_room` → _show_bang (Label '!' pop at player+Vector2(6,-30)) → sting → Fade.flash(0.15) → await 0.4 → `change_scene_to_file Battle.tscn`. **ADD** `@export boss:bool=false` + boss branch auto-save. |
| `scripts/rooms/{canon,cracks}.gd` | (Plan B) | Room scripts; Canon/Cracks host bosses. `_spawn_encounters_from_layout` populates E markers. **ADD** `_spawn_boss(id,pos)` helper to canon.gd + cracks.gd. |
| `scripts/util/sprites.gd` | (Plan A) | `_enemy_frames` dict; `Sprites.battle_enemy_texture(id, false)`. **ADD** 5 new entries: `mourning_knight`, `index_f1/f2/f3`, `canon_true`. |
| `scripts/autoload/game_state.gd` | (autoload) | `save_game()` writes to user://. **VERIFY** save signature stable. |

---

## Design

### Boss entry shape

**Mourning Knight (single form, monologues):**

```
{
  "id": "mourning_knight", "name": "Mourning Knight",
  "hp": 60, "atk": 5, "def": 2, "spare_after": 6,
  "acts": [{"id": "mourn", "label": "* Mourn", "mood": 3,
            "text": "* You kneel beside the empty armor. It sighs like a bell. The clank is smaller now."}],
  "attack_lines": ["* It kneels. The grief is the attack.", "* It raises its visor. There is no one inside."],
  "patterns": [{"type": "fan", "count": 4, "spread": 60.0, "speed": 50.0, "rule": Bullet.Rule.BLUE},
               {"type": "aimed", "count": 2, "speed": 70.0, "rule": Bullet.Rule.ORANGE}],
  "intro_line": "* Mourning Knight. The armor remembers someone.",
  "sprite_id": "mourning_knight",
  "boss": true, "no_flee": true,
  "monologue": [
    {"at": 0.75, "speaker": "Knight", "text": "* I do not know if I am mourning them, or if they are mourning me."},
    {"at": 0.50, "speaker": "Knight", "text": "* Every room I walk through, I ruin."},
    {"at": 0.25, "speaker": "Knight", "text": "* ... if you would remember me, I would not have to."},
  ],
}
```

**The Index (3 forms):** top-level entry holds form-1 fields plus `forms: Array` of 3 form dicts; `apply_form(_enemy, _forms[i+1])` mutates `_enemy` in place at form transition.

```
{
  "id": "index", "name": "The Index — Cross-Out",
  "hp": 40, "atk": 7, "def": 3, "spare_after": 5,
  "acts": [{"id": "read", "label": "* Read", "mood": 2,
            "text": "* You read aloud. The page tears itself before you finish."}],
  "attack_lines": ["* It crosses out a word. The word obeys."],
  "patterns": [{"type": "edit", "count": 5, "speed": 90.0, "rule": Bullet.Rule.ORANGE, "edit_at": 0.5},
               {"type": "aimed", "count": 4, "speed": 80.0, "rule": Bullet.Rule.BLUE}],
  "intro_line": "* The Index — Page One. It opens itself to a blank.",
  "sprite_id": "index_f1",
  "boss": true, "no_flee": true,
  "forms": [
    {"name": "The Index — Cross-Out", "hp": 40, "def": 3,
     "spare_after": 5,
     "acts": [{"id": "read", "label": "* Read", "mood": 2,
               "text": "* You read aloud. The page tears itself before you finish."}],
     "attack_lines": ["* It crosses out a word. The word obeys."],
     "patterns": [{"type": "edit", "count": 5, "speed": 90.0, "rule": Bullet.Rule.ORANGE, "edit_at": 0.5},
                  {"type": "aimed", "count": 4, "speed": 80.0, "rule": Bullet.Rule.BLUE}],
     "intro_line": "* The Index — Page One. It opens itself to a blank.",
     "sprite_id": "index_f1"},
    {"name": "The Index — Edit", "hp": 50, "def": 4,
     "spare_after": 4,
     "acts": [{"id": "edit", "label": "* Edit", "mood": 2,
               "text": "* You write in the margin. It writes back."}],
     "attack_lines": ["* It edits a memory. The memory stands corrected."],
     "patterns": [{"type": "edit", "count": 7, "speed": 100.0, "rule": Bullet.Rule.BLUE, "edit_at": 0.4},
                  {"type": "ring", "count": 6, "speed": 70.0, "rule": Bullet.Rule.ORANGE}],
     "intro_line": "* The Index — Page Two. It edits what was.",
     "sprite_id": "index_f2"},
    {"name": "The Index — Accept", "hp": 60, "def": 5,
     "spare_after": 3,
     "acts": [{"id": "accept", "label": "* Accept", "mood": 3,
               "text": "* You accept the corrections. The page is quiet."}],
     "attack_lines": ["* It offers you a final reading. There is no choice in accepting it."],
     "patterns": [{"type": "edit", "count": 9, "speed": 110.0, "rule": Bullet.Rule.ORANGE, "edit_at": 0.35},
                  {"type": "spiral", "count": 8, "speed": 90.0, "rule": Bullet.Rule.BLUE}],
     "intro_line": "* The Index — Page Three. It opens itself to you.",
     "sprite_id": "index_f3"},
  ],
}
```

**Canon true form (Keeper-only):**

```
{
  "id": "canon_true", "name": "Canon",
  "hp": 120, "atk": 9, "def": 6, "spare_after": 6,
  "acts": [{"id": "accept", "label": "* Accept", "mood": 3,
            "text": "* You accept what was. The Canon softens."},
           {"id": "refuse", "label": "* Refuse", "mood": 3,
            "text": "* You refuse the Canon. It is impressed."}],
  "attack_lines": ["* The Canon rewrites a wall. The wall remembers.",
                   "* The Canon speaks a name that does not exist anymore."],
  "patterns": [{"type": "burst", "count": 12, "speed": 100.0, "rule": Bullet.Rule.ORANGE},
               {"type": "spiral", "count": 14, "speed": 110.0, "rule": Bullet.Rule.BLUE}],
  "intro_line": "* Canon. The shape of what was, if what was had a shape.",
  "sprite_id": "canon_true",
  "boss": true, "no_flee": true,
}
```

### Boss infrastructure in battle.gd

1. **`_forms: Array`** initialized in `_ready`: `_forms = _enemy.get("forms", [])`; `_form_index := 0`; `_monologue_done: Array[float] = []`.
2. **`_form_label: Label`** built in `_build_ui` (right under enemy name), hidden unless `_forms.size() > 0`; text = `"— FORM %d/%d —"` (1-based); shown after a `_swap_boss_sprite()`.
3. **`_swap_boss_sprite()`**: `_enemy_sprite.texture = Sprites.battle_enemy_texture(str(_enemy['sprite_id']), false)`; modulate flash white→default over 0.3s.
4. **`_resolve_fight` hp<=0 branch restructured:**
   - if `_forms.size() > 0 and _form_index < _forms.size() - 1`:
     - `_form_index += 1`
     - `EnemyLibrary.apply_form(_enemy, _forms[_form_index])`
     - `_enemy_max_hp = int(_enemy['hp'])`; reset `_enemy_hp_display = float(_enemy_max_hp)`
     - `_mood = 0` (fresh fight mood)
     - `_swap_boss_sprite()` + update `_form_label.text`
     - `_refresh_enemy_ui()`
     - `await _say([{speaker: str(_enemy.get("name","")), text: str(_enemy['intro_line'])}])`
     - `await get_tree().create_timer(0.4).timeout`
     - fall through into `_enemy_turn()` to continue
   - else: existing WIN path (vaporize + `_end_battle`).
5. **`_choose` MERCY submenu:** `["Spare"]` if `_enemy.get("no_flee", false)` else `["Spare", "Flee"]`.
6. **`_resolve_submenu` Flee:** if `_enemy.get("no_flee", false)`: `_say([{speaker:"", text:"* There is nowhere to flee."}])`; skip `flee_roll`; don't `_end_battle`.
7. **`_enemy_turn` monologue:** before `BulletPatterns.make`, compute `hp_frac = _enemy_hp_display / float(_enemy_max_hp)`; lines = `EnemyLibrary.monologue_lines(_enemy.get("monologue", []), hp_frac, _monologue_done)`; for each: `await _say([{speaker: str(l["speaker"]), text: str(l["text"])}])`; append `at` to `_monologue_done`.
8. **WIN only on last form:** existing WIN path requires `_forms.empty()` or `_form_index == _forms.size() - 1` (or simply: the hp<=0 branch we restructured already only reaches WIN when forms are exhausted).

### `EnemyLibrary.apply_form(target: Dictionary, form: Dictionary) -> Dictionary`

Pure static helper. Mutates and returns `target`. Replaces keys: `name`, `hp`, `def`, `spare_after`, `acts`, `attack_lines`, `patterns`, `intro_line`, `sprite_id`. Leaves `id`, `boss`, `no_flee`, `monologue` untouched (so top-level boss flags persist across forms). Headless-testable.

### `EnemyLibrary.monologue_lines(monologue: Array, hp_frac: float, shown: Array) -> Array`

Pure static. Returns entries from `monologue` whose `at >= hp_frac` AND whose `at` not already in `shown`. Battle appends each returned `at` to `_monologue_done` after saying it.

### Edit bullets

**`bullet.gd`** new fields + method:
```
var _sprite: Sprite2D
var edit_at := -1.0
var edit_btype := Type.PELLET
var edit_rule := Rule.NONE
var edit_vel := Vector2.ZERO
var edited := false

func setup(d: Dictionary) -> void:
    (existing reads ...)
    var spr := Sprite2D.new()
    spr.texture = Sprites.bullet_texture_for(btype)
    add_child(spr)
    _sprite = spr  # NEW
    if behavior == "edit":
        edit_at = float(d.get("edit_at", 0.5))
        edit_btype = int(d.get("edit_btype", btype))
        edit_rule = int(d.get("edit_rule", Rule.NONE))
        edit_vel = d.get("edit_vel", vel)
        edited = false

func _apply_edit() -> void:
    if edited: return
    edited = true
    btype = edit_btype
    rule = edit_rule
    vel = edit_vel
    if _sprite != null:
        _sprite.texture = Sprites.bullet_texture_for(btype)
```

**`dodge_box.gd` _process** new arm in the `match b.behavior` switch (insert before default `_`):
```
"edit":
    if not b.edited and b.phase >= b.edit_at:
        b._apply_edit()
    b.position += b.vel * delta
    b.life -= delta
    b.phase += delta
```

**`bullet_patterns.gd` `make`** new branch:
```
"edit":
    var n := int(d.get("count", 6))
    var speed := float(d.get("speed", 90.0))
    var rule := int(d.get("rule", Bullet.Rule.NONE))
    var edit_at := float(d.get("edit_at", 0.5))
    var btype := int(d.get("type_override", Bullet.Type.PELLET))
    for i in n:
        var angle := (TAU / n) * i + d.get("phase_offset", 0.0)
        var vel := Vector2.from_angle(angle) * speed
        var origin := heart_pos
        out.append({
            "pos": origin, "vel": vel, "life": 4.0, "size": 3.0,
            "type": btype, "rule": rule,
            "behavior": "edit",
            "edit_at": edit_at + i * 0.08,
            "edit_btype": btype,
            "edit_rule": Bullet.Rule.ORANGE if rule == Bullet.Rule.BLUE else Bullet.Rule.BLUE,
            "edit_vel": vel.rotated(PI * 0.5),
            "phase": 0.0,
        })
    return out
```

`type_override` lets `Mourning Knight` keep an `aimed`-style pattern but tag it as edit-bullet-family later if needed. The Index's edit-fan toggles ORANGE↔BLUE and rotates velocity 90° at the midpoint — visually "bullets that change what they were as they cross the box."

### Save-before-boss flow

**`encounter.gd`** new export + branch:
```
@export var boss: bool = false

func _on_body_entered(body):
    if not body.is_in_group("player"): return
    if used: return
    used = true
    GameState.set_flag("pending_enemy", enemy_id)
    GameState.set_flag("from_room", get_parent().name)
    if boss:
        GameState.set_flag("last_boss_save_%s" % enemy_id, true)
        GameState.save_game()  # pre-boss snapshot
    (existing _show_bang → sting → Fade.flash(0.15) → await 0.4 → change_scene_to_file)
```

**`canon.gd` + `cracks.gd` boss spawn helpers:**
```
func _spawn_boss(id: String, pos: Vector2) -> void:
    var scene := EncounterScene if exists else load(...)  # use encounter.gd script directly
    var node := Area2D.new()
    node.set_script(encounter_script)
    node.enemy_id = id
    node.boss = true
    add_child(node)
    node.position = pos
```
Easiest: instantiate `Encounter.tscn` (already authored scene — verify it exists from Plan B; if not, build it as a minimal Area2D+CollisionShape2D+Sprite2D with encounter.gd attached). Set `enemy_id` + `boss = true`. Floor-tile validation done in test (parse layout, check tile at position is FLOOR).

**Placements** (validated floor-tile in test; adjust if needed):
- Canon → `mourning_knight` at `(320, 240)` (room center 40x30 grid → tile col 20 row 15)
- Cracks → `index` at `(320, 240)` (room center)
- Cracks → `canon_true` at `(96, 368)` (Keeper-only — gated by Plan D flag once available; for Plan C, spawn unconditionally, but only reachable after beating Index? Simplest: spawn at fixed position regardless; tests assert presence. Reaching canon_true without beating Index is a soft lock — flag-gate belongs to Plan D.)

### Boss sprites

**`tools/gen_boss_sprites.gd`** (sibling to `tools/gen_mob_placeholders.gd`):

| Sprite | Size | Design |
|--------|------|--------|
| `mourning_knight` | 32x32 | Steel-gray silhouette of plate armor kneeling; visor slit empty; visor half-height slate `#5a5e66`; shoulders slate `#6e7280`; sword pommel dark. Single frame. |
| `index_f1` | 32x32 | Tall thin figure holding quill; ink-black robe `#1a1a22`; quill silver-white `#e8e8ee`; index page tilted. |
| `index_f2` | 32x32 | Same silhouette, robe tinted deep blue `#1a2244`; quill tilted lower (editing). |
| `index_f3` | 32x32 | Same silhouette, robe tinted ink-red `#441a22`; quill raised (accepting). |
| `canon_true` | 40x40 | Tall figure in dark coat; wide brim hat; coat `#222028`; brim `#0e0c12`; one eye glints `#f0e8d0`. |

Written to `assets/sprites/enemies/frames/{id}/000.png` via `Image.save_png`. Sprites.gd `_enemy_frames` extended:

```
_enemy_frames["mourning_knight"] = _load_frame("res://assets/sprites/enemies/frames/mourning_knight/000.png")
_enemy_frames["index_f1"] = _load_frame("res://assets/sprites/enemies/frames/index_f1/000.png")
_enemy_frames["index_f2"] = _load_frame("res://assets/sprites/enemies/frames/index_f2/000.png")
_enemy_frames["index_f3"] = _load_frame("res://assets/sprites/enemies/frames/index_f3/000.png")
_enemy_frames["canon_true"] = _load_frame("res://assets/sprites/enemies/frames/canon_true/000.png")
```

(Verify exact helper signature for `_load_frame` in Plan A sprites.gd — likely `static func _load_frame(path: String) -> ImageTexture`; matches if so.)

### Dialog files (spec §8 lines 230-231)

`dialogue/mourning_knight.dlg`:
```
* I do not know if I am mourning them, or if they are mourning me.
* Every room I walk through, I ruin.
* ... if you would remember me, I would not have to.
* The armor holds its shape because you are watching.
* (Silence. The Knight kneels.)
```

`dialogue/index.dlg`:
```
* The page does not know it is a page.
* The word obeys. The reader does not.
* I edit what was. You edit what will be.
* Page Three is blank on purpose.
* (The quill rests.)
```

Format: one line per entry, asterisk prefix per spec convention.

---

## Tasks (TDD ordered)

### T1 — EnemyLibrary boss helpers [INLINE]
**Files:** `scripts/battle/enemy_library.gd`, `tests/test_boss_helpers.gd`
- Add `static func apply_form(target: Dictionary, form: Dictionary) -> Dictionary` — mutates `target` keys (`name/hp/def/spare_after/acts/attack_lines/patterns/intro_line/sprite_id`), returns target. Keeps `id/boss/no_flee/monologue`.
- Add `static func monologue_lines(monologue: Array, hp_frac: float, shown: Array) -> Array` — returns entries with `at >= hp_frac and at not in shown`.
- Tests: target mutated with new hp/def/patterns/sprite_id; id/boss/no_flee/monologue preserved; monologue_lines returns expected slice; hp_frac > all → empty; `at` already shown → skipped.

### T2 — Boss entries in enemy_library + dialog files [SUBAGENT]
**Files:** `scripts/battle/enemy_library.gd` (append 3 entries to `_enemies`), `dialogue/mourning_knight.dlg`, `dialogue/index.dlg`, `tests/test_boss_library.gd`
- Mourning Knight entry (shape above).
- Index entry with 3 forms (shape above; top-level mirrors form1).
- Canon true entry (shape above).
- Tests: all 3 entries exist; required keys (boss/no_flee); Index has 3 forms, each with hp/patterns/sprite_id/name/intro_line/acts; canon_true has acts Accept+Refuse; each `patterns` entry resolves via `BulletPatterns.make(...)` returning a non-empty Array[Dictionary]; dlgs exist + parse (load each as text, assert >= 4 lines starting with `*`).

### T3 — Edit bullets [INLINE]
**Files:** `scripts/battle/bullet.gd`, `scripts/battle/dodge_box.gd`, `scripts/battle/bullet_patterns.gd`, `tests/test_edit_bullets.gd`
- bullet.gd: new fields `_sprite/edit_at/edit_btype/edit_rule/edit_vel/edited`, store `_sprite` in `setup`, read edit_* if behavior=="edit", `_apply_edit()` swaps + re-textures.
- dodge_box.gd: new `match` arm `"edit"` (pre-default): apply edit then straight move.
- bullet_patterns.gd: new `make` branch `"edit"`.
- Tests: BulletPatterns.make edit returns N bullets with behavior 'edit' and edit_at>0; bullet.setup with behavior='edit' populates edit_*; manual `_apply_edit()` swaps rule/btype/vel and re-textures `_sprite`; dodge_box `_process` delta advance flips edited at edit_at and moves straight after.

### T4 — Boss sprites [INLINE]
**Files:** `tools/gen_boss_sprites.gd`, `scripts/util/sprites.gd`, `assets/sprites/enemies/frames/{mourning_knight,index_f1,index_f2,index_f3,canon_true}/000.png`, `tests/test_boss_assets.gd`
- gen script writes 5 placeholder PNGs.
- sprites.gd registers 5 entries in `_enemy_frames`.
- Tests: each PNG exists + loadable + non-empty image; `Sprites.battle_enemy_texture('mourning_knight', false)` non-null for all 5.

### T5 — Battle infrastructure [INLINE]
**Files:** `scripts/battle/battle.gd`, `tests/test_battle_boss_orchestration.gd`
- `_form_index`, `_forms`, `_monologue_done` member vars.
- `_form_label: Label` built in `_build_ui` (hidden by default).
- `_swap_boss_sprite()` helper.
- `_resolve_fight` hp<=0 branch restructured (form advance vs WIN).
- `_choose` MERCY submenu respects `no_flee`.
- `_resolve_submenu` Flee branch short-circuits on `no_flee`.
- `_enemy_turn` says monologue lines.
- Tests: parse-clean (script loads via `load("res://scripts/battle/battle.gd")`); fields in `_enemy` covered by apply_form (asserted via T1 test — orchestration verified by parse + suite boot).

### T6 — Save-before-boss + room spawns [INLINE]
**Files:** `scripts/battle/encounter.gd`, `scripts/rooms/canon.gd`, `scripts/rooms/cracks.gd`, `tests/test_boss_save_flow.gd`
- encounter.gd: `@export boss:bool=false`; `_on_body_entered` boss branch sets `last_boss_save_<id>` flag + `GameState.save_game()`.
- canon.gd: add `_spawn_boss(id, pos)` + call with `("mourning_knight", Vector2(320, 240))` (only if `LayoutParser` placed no encounter there — verified in test).
- cracks.gd: `_spawn_boss("index", Vector2(320, 240))` + `_spawn_boss("canon_true", Vector2(96, 368))`.
- Tests: encounter with boss=true body_entered sets flag + calls save_game (mock or real — verify `last_boss_save_<id>` flag exists in GameState); boss encounter nodes exist in canon/cracks scenes; tiles at spawn positions are FLOOR per LayoutParser.

### T7 — Integration + ship [INLINE]
**Files:** `tests/test_plan_c_integration.gd`, spec mark, export + boot
- Test: full chain — boss library resolvable, edit bullets spawn+edit, boss sprites load, save-before-boss flow flags, rooms have boss encounters, integration test asserts end-to-end shape (no fights actually played).
- `--import` pass on worktree (new PNGs/dialog files).
- Suite green: `ALL TESTS PASSED`.
- Export `dist\SoulHeart.exe`.
- Boot `--headless --quit-after 60` → ExitCode 0.
- Spec §7 mark `Plan C: COMPLETE` (update line 268-ish).

---

## Files Touched

| Path | New/Edit | Owner |
|------|----------|-------|
| `scripts/battle/enemy_library.gd` | edit (helpers + 3 boss entries) | T1 inline / T2 subagent |
| `scripts/battle/bullet.gd` | edit | T3 inline |
| `scripts/battle/dodge_box.gd` | edit | T3 inline |
| `scripts/battle/bullet_patterns.gd` | edit | T3 inline |
| `scripts/battle/battle.gd` | edit | T5 inline |
| `scripts/battle/encounter.gd` | edit | T6 inline |
| `scripts/rooms/canon.gd` | edit | T6 inline |
| `scripts/rooms/cracks.gd` | edit | T6 inline |
| `scripts/util/sprites.gd` | edit | T4 inline |
| `scripts/autoload/game_state.gd` | edit (verify save_game API only) | T6 inline |
| `tools/gen_boss_sprites.gd` | new | T4 inline |
| `tools/run_boss_gen.gd` | new (scaffold to run gen from CLI) | T4 inline |
| `assets/sprites/enemies/frames/mourning_knight/000.png` | new | T4 inline |
| `assets/sprites/enemies/frames/index_f1/000.png` | new | T4 inline |
| `assets/sprites/enemies/frames/index_f2/000.png` | new | T4 inline |
| `assets/sprites/enemies/frames/index_f3/000.png` | new | T4 inline |
| `assets/sprites/enemies/frames/canon_true/000.png` | new | T4 inline |
| `dialogue/mourning_knight.dlg` | new | T2 subagent |
| `dialogue/index.dlg` | new | T2 subagent |
| `tests/test_boss_helpers.gd` | new | T1 inline |
| `tests/test_boss_library.gd` | new | T2 subagent |
| `tests/test_edit_bullets.gd` | new | T3 inline |
| `tests/test_boss_assets.gd` | new | T4 inline |
| `tests/test_battle_boss_orchestration.gd` | new | T5 inline |
| `tests/test_boss_save_flow.gd` | new | T6 inline |
| `tests/test_plan_c_integration.gd` | new | T7 inline |
| `docs/superpowers/specs/2026-08-11-soulheart-full-game-design.md` | edit (§7 line "Plan C: COMPLETE") | T7 inline |
| `dist/SoulHeart.exe` | rebuilt | T7 inline |

---

## Execution Order

1. **Commit plan doc** to `main`.
2. **Create worktree** `plan-c-bosses` from main HEAD `14182c5`.
3. **Copy gitignored** `tools/godot.exe` + `export_presets.cfg` from main repo.
4. **Baseline**: `--import` then suite (must be green).
5. **T1 inline** (helpers) → `--import` → suite (parse-only OK).
6. **T2 subagent** (entries + dialog + tests) — bulk data task; subagent gets full plan snippet + verified ground truth + write-to-disk instructions; reports back file diffs + suite result.
7. **T3 inline** (edit bullets + tests) → suite.
8. **T4 inline** (sprites + test_boss_assets) → run `tools/run_boss_gen.gd` to write PNGs → `--import` → suite.
9. **T5 inline** (battle.gd infra + orchestration test) → suite.
10. **T6 inline** (encounter boss + canon/cracks spawns + test_boss_save_flow) → suite.
11. **T7 inline** (integration test + spec mark + export + boot) → suite green → export `dist\SoulHeart.exe` → boot `--quit-after 60` ExitCode 0.
12. **Commit** each milestone (T1, T2, T3, T4, T5, T6, T7) separately for clean history.
13. **finishing-a-development-branch**: merge to main (handle untracked spec copy: `Remove-Item` it pre-merge), `--import` on main, suite green, export, boot, worktree remove + prune + branch -d, report.

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| `Sprite2D` not stored in `Bullet` → edit can't re-texture | Add `_sprite` member in T3 (Bullet.setup already creates the sprite; assign it). |
| `get_enemy()` `.duplicate(true)` deep-copies form list → mutating `_forms[i+1]` in place would mutate the library | `apply_form` mutates `_enemy` only, never `_forms[i+1]`. `_forms` array entries themselves are not modified — they are read-only templates. |
| `encounter.gd` floor spawn at (320,240) may be inside Canon wall | Test parses Canon layout via LayoutParser; asserts tile FLOOR. If wall, fallback to nearest floor neighbor (e.g. row 14 col 20). |
| GameState.save_game path is `user://` (headless) → test pollutes real saves | Test asserts flag set; doesn't require real save file. Optional: backup+restore user://save before/after test. |
| Subagent may introduce incompatible patterns (e.g. snake_case, different test helper) | Subagent prompt locks to: tests use `extends RefCounted`, `run_all.gd` dispatches `test_*` with zero args, `TestHelper.eq/is_true`, explicit types over `:=` on `get_script_constant_map()` and `load()` results. |
| Battle.gd parse error hangs suite (Plan A/B lesson) | After T5 edit: invoke `run_all.gd` IMMEDIATELY; if hangs, `Get-Process godot | Stop-Process -Force` + read log + fix. |
| `Color8` is a constructor not a type (Plan A/B lesson) | gen_boss_sprites uses `Color8(...)` only in expressions; type annotations use `Color`. |
| Per-repo `.godot` import cache needs new PNGs/dialog files | Run `--import` after T4 + after T2 dialog writes; per-repo (not just worktree) on merge. |
| canon_true spawn at (96, 368) on cracks layout may be wall | Test asserts floor; fallback to nearest floor; or move to second chamber via layout inspection. |

---

## Definition of Done

- All 7 tasks completed.
- `dist\SoulHeart.exe` rebuilt; boots ExitCode 0; walkable Canon→Cracks→beat Knight→beat Index (3 forms)→canon_true encounter reachable.
- Suite: `ALL TESTS PASSED` on worktree and main.
- Spec §7 marked `Plan C: COMPLETE`.
- Worktree removed; branch deleted; final report sent to LO.