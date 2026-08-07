# SoulHeart Audio + Feel Pack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give SoulHeart the full Undertale audio treatment (original Toby Fox music + original/synth SFX) and the Undertale feel mechanics (4-dir movement, hurt feedback, "Stay determined!" death screen, room fades, encounter sting, chance-based flee).

**Architecture:** Three new systems — an `Audio` autoload (music player + SFX pool + id→stream registry), a `Fade` autoload (persistent black/white overlay on CanvasLayer layer 100), and targeted edits to player/dodge_box/battle/encounter/door/save_point/dialogue_ui/main/rooms. Rooms fade in from black in `_ready`; every scene change goes through `Fade.fade_to_black` first. Death flow lives in battle.gd's defeat branch.

**Tech Stack:** Godot 4.4.1 (GDScript), headless test suite (`res://tests/run_all.gd`), original `mus_*.ogg` from archive.org, synthesized 16-bit PCM WAVs for SFX fallbacks. Windows/PowerShell 5.1 only.

## Global Constraints (verbatim from spec 2026-08-08-audio-feel-pack-design.md)

1. **Worktree:** All work happens in `C:\Users\Admin\Downloads\SoulHeart\.worktrees\audio-feel-pack` (branch `audio-feel-pack`). `tools\godot.exe` + console exe already copied there; `.godot` import cache exists. If a script fails to parse with "Identifier not declared", re-run `cmd /c "tools\godot.exe --headless --import > .superpowers\import.txt 2>&1 & echo DONE"`.
2. **Test gate:** Suite command (worktree root): `cmd /c "tools\godot.exe --headless -s res://tests/run_all.gd > .superpowers\out.txt 2>&1 & echo DONE"` then read `.superpowers\out.txt`. MUST print `ALL TESTS PASSED`; ANY `SCRIPT ERROR:` line = FAIL. Only permitted stderr line: `ERROR: Dialogue file not found: res://dialogue/nope.dlg` (from test_dialogue_parser).
3. **Test infra:** Tests are `RefCounted` classes in `tests/`, auto-discovered by `run_all.gd` (dir scan, sorted, excludes run_all.gd/test_helper.gd). Assertions ONLY: `TestHelper.eq(got, expected, msg)` and `TestHelper.is_true(cond, msg)`. Existing tests do NOT add autoloads to a tree — they call `_ready()` manually (see test_dodge_box.gd `_make_box()`). Autoload singletons are NOT present under `-s`; code referencing `GameState`/`Audio`/`Fade` at RUNTIME only fails if executed without a stub — tests that merely `load()` scripts (test_room_scripts.gd) are safe. If a test must execute code that calls an autoload, stub by adding an instance named exactly like the autoload to `(Engine.get_main_loop() as SceneTree).root`.
4. **Asset file names are contract:** After Task 1 these MUST exist with exactly these names — `assets/audio/music/mus_t.ogg, mus_room.ogg, mus_snowdin.ogg, mus_battle1.ogg, mus_dontgiveup.ogg, mus_dooropen.ogg, mus_doorclose.ogg`; `assets/audio/sfx/blip.wav, confirm.wav, select.wav, cancel.wav, hurt.wav, heal.wav, save.wav, sting.wav, flee.wav` (originals renamed to canonical names; synth for anything not found).
5. **CREDITS.txt** at repo root with EXACT text: `SoulHeart is a private, non-commercial fan project. Music by Toby Fox (UNDERTALE, copyright Toby Fox / Materia Music Publishing), from the original game files.`
6. **API contracts (produced by Tasks 2 & 4, consumed by later tasks):**
   - `Audio.play_music(id: String)`, `Audio.stop_music(fade: float = 0.3)`, `Audio.play_sfx(id: String, pitch: float = 1.0)`; registry consts `MUSIC`/`SFX` (id → preloaded stream); unknown id → `push_warning` once, never crash.
   - `Fade.fade_to_black(dur := 0.3)`, `Fade.fade_from_black(dur := 0.3)` (no-op if not black), `Fade.flash(dur := 0.15)`, `Fade.is_black() -> bool`, `Fade.set_black(alpha: float)` (public, used by tests).
   - `Player.resolve_direction4(just_pressed: PackedStringArray, held: PackedStringArray, last: String) -> Array` — static, returns `[Vector2, String]` (`[dir, new_last]`).
   - `DodgeBox`: `const INVULN_TIME := 1.0`, `const STAGGER_TIME := 0.2`, `const KNOCKBACK := 6.0`.
   - `battle.gd`: `const FLEE_CHANCE := 0.5`; `static func flee_roll(roll: float) -> bool`.
7. **Music loop:** set `stream.loop = true` in code when loading music streams (no import-flag fiddling).
8. **Commit discipline:** one commit per task, English message, `git add` only the task's files (never `.superpowers/`, never `dist/`, never `tools/`).
9. **Deferred (do NOT build):** bitmap fonts, dialogue box restyle, battle HUD, damage numbers, new rooms/enemies/endings, settings UI, particles, heart shadow.
10. **Death semantics (deviation from spec 5.3, decided):** on death, HP restored to max, inventory KEPT (Undertale-accurate — heal_full() only restores HP and never touches inventory).

---

### Task 1: Acquire audio assets (music download + SFX hunt/synth + CREDITS.txt)

**Files:**
- Create: `assets/audio/music/mus_t.ogg`, `mus_room.ogg`, `mus_snowdin.ogg`, `mus_battle1.ogg`, `mus_dontgiveup.ogg`, `mus_dooropen.ogg`, `mus_doorclose.ogg` (downloaded)
- Create: `assets/audio/sfx/blip.wav`, `confirm.wav`, `select.wav`, `cancel.wav`, `hurt.wav`, `heal.wav`, `save.wav`, `sting.wav`, `flee.wav` (original rips OR synth)
- Create: `CREDITS.txt`
- Create: `scripts/tools/gen_sfx.gd` (synth generator — commit it; it documents the synth recipes)

**Interfaces:**
- Consumes: nothing (first task).
- Produces: exact file names per constraint 4; CREDITS.txt per constraint 5.

- [ ] **Step 1: Download the 7 music files** (all original `mus_*.ogg` from Toby Fox's official archive.org upload "Undertale MUS PORT")

PowerShell (worktree root):
```powershell
New-Item -ItemType Directory -Force -Path "assets\audio\music", "assets\audio\sfx" | Out-Null
$files = @("mus_t","mus_room","mus_snowdin","mus_battle1","mus_dontgiveup","mus_dooropen","mus_doorclose")
foreach ($f in $files) {
  Invoke-WebRequest -Uri "https://archive.org/download/undertale-port/$f.ogg" -OutFile "assets/audio/music/$f.ogg"
}
```
If `mus_snowdin.ogg` does not exist in the port (metadata check, Step 2), substitute `mus_room.ogg` copy for Grumble Woods by downloading `mus_room.ogg` twice (note it in the report). Use a per-request timeout of 300s (archive.org can be slow); retry once on failure.

- [ ] **Step 2: Verify downloads against archive metadata** (byte sizes must match)
```powershell
$meta = Invoke-RestMethod "https://archive.org/metadata/undertale-port"
$meta.files | Where-Object { $_.name -match "^mus_(t|room|snowdin|battle1|dontgiveup|dooropen|doorclose)\.ogg$" } | Select-Object name, size | Format-Table
Get-ChildItem "assets\audio\music" | Select-Object Name, Length | Format-Table
```
Any file whose local size differs from the listing: delete, re-download once. Still failing: keep a placeholder note in the report (Task 2 will preload it and the suite will catch it). Do NOT proceed with a corrupt file (suite check in Task 2 catches bad loads).

- [ ] **Step 3: Hunt original SFX.** Query the archive.org advancedsearch API for game-file rips, inspect candidate items' file lists for `snd_*.wav`:
```powershell
(Invoke-RestMethod "https://archive.org/advancedsearch.php?q=undertale+game+files&fl[]=identifier&rows=20&output=json").response.docs
```
Try queries: `undertale game files`, `undertale sfx`, `undertale sounds`, `undertale extracted`. For each candidate identifier, `(Invoke-RestMethod "https://archive.org/metadata/<id>").files` and look for `snd_*.wav`. For each of the 9 canonical SFX ids, if a usable original is found (non-zero size, downloads cleanly), save it under its canonical name (e.g. found `snd_blip3.wav` → `assets/audio/sfx/blip.wav`). Record disposition (found-original with source id+filename, or MISSING) for all 9 ids in the task report.

- [ ] **Step 4: Synthesize the missing SFX.** Write `scripts/tools/gen_sfx.gd`:

```gdscript
extends SceneTree

const OUT_DIR := "res://assets/audio/sfx/"
const RATE := 44100

func _initialize() -> void:
	gen("blip", 0.12, 0.5, 0.4, [
		{"freq": 880.0, "dur": 0.04, "vol": 1.0},
		{"freq": 1318.0, "dur": 0.04, "vol": 0.8},
		{"freq": 1760.0, "dur": 0.04, "vol": 0.6},
	], "square")
	gen("confirm", 0.08, 0.5, 0.3, [{"freq": 660.0, "dur": 0.08, "vol": 1.0}], "square")
	gen("select", 0.07, 0.5, 0.3, [{"freq": 440.0, "dur": 0.035, "vol": 1.0}, {"freq": 880.0, "dur": 0.035, "vol": 1.0}], "square")
	gen("cancel", 0.1, 0.5, 0.3, [{"freq": 330.0, "dur": 0.05, "vol": 1.0}, {"freq": 247.0, "dur": 0.05, "vol": 0.9}], "square")
	gen("hurt", 0.22, 0.7, 0.25, [{"freq": 300.0, "dur": 0.22, "vol": 1.0}], "saw", 120.0)
	gen("heal", 0.24, 0.5, 0.35, [
		{"freq": 523.0, "dur": 0.08, "vol": 1.0},
		{"freq": 659.0, "dur": 0.08, "vol": 1.0},
		{"freq": 784.0, "dur": 0.08, "vol": 1.0},
	], "square")
	gen("save", 0.3, 0.5, 0.3, [
		{"freq": 784.0, "dur": 0.1, "vol": 1.0},
		{"freq": 988.0, "dur": 0.1, "vol": 1.0},
		{"freq": 1175.0, "dur": 0.1, "vol": 1.0},
	], "triangle")
	gen("sting", 0.3, 0.8, 0.4, [{"freq": 120.0, "dur": 0.3, "vol": 1.0}], "saw", 60.0)
	gen("flee", 0.18, 0.6, 0.3, [{"freq": 440.0, "dur": 0.09, "vol": 1.0}, {"freq": 880.0, "dur": 0.09, "vol": 1.0}], "square")
	quit(0)

func gen(id: String, total: float, attack: float, decay: float, notes: Array, wave: String, glide := 0.0) -> void:
	var samples := PackedFloat32Array()
	for note in notes:
		var note_n := int(note["dur"] * RATE)
		var start_freq: float = note["freq"]
		var end_freq := start_freq + glide
		for i in note_n:
			var t := float(i) / RATE
			var freq := lerpf(start_freq, end_freq, t / note["dur"])
			var phase := fmod(t * freq, 1.0)
			var v: float
			match wave:
				"square": v = 1.0 if phase < 0.5 else -1.0
				"saw": v = phase * 2.0 - 1.0
				"triangle": v = 4.0 * absf(phase - 0.5) - 1.0
			var env := minf(1.0, t / attack)
			if t > note["dur"] * (1.0 - decay):
				env *= 1.0 - (t - note["dur"] * (1.0 - decay)) / (note["dur"] * decay)
			samples.append(v * env * note["vol"])
	_write_wav(OUT_DIR + id + ".wav", samples)

func _write_wav(path: String, samples: PackedFloat32Array) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	var data_size := samples.size() * 2
	f.store_buffer("RIFF".to_ascii_buffer())
	f.store_32(36 + data_size)
	f.store_buffer("WAVEfmt ".to_ascii_buffer())
	f.store_32(16)
	f.store_16(1)
	f.store_16(1)
	f.store_32(RATE)
	f.store_32(RATE * 2)
	f.store_16(2)
	f.store_16(16)
	f.store_buffer("data".to_ascii_buffer())
	f.store_32(data_size)
	for s in samples:
		f.store_16(clampi(int(s * 32767.0), -32768, 32767))
	f.close()
```

Run: `cmd /c "tools\godot.exe --headless -s res://scripts/tools/gen_sfx.gd > .superpowers\gen.txt 2>&1 & echo DONE"` — then confirm the 9 `.wav` files exist, size > 1000 bytes each. Originals found in Step 3 REPLACE generated ones (only run gen for ids still missing).

- [ ] **Step 5: Write CREDITS.txt** (exact text from constraint 5).
- [ ] **Step 6: Re-run import** — `cmd /c "tools\godot.exe --headless --import > .superpowers\import2.txt 2>&1 & echo DONE"` — scan for asset-related `ERROR:` lines (harmless `rcedit`-style warnings fine; any asset import ERROR = fix before continuing).
- [ ] **Step 7: Run the full suite** (constraint 2) — must stay ALL TESTS PASSED (assets alone change nothing).
- [ ] **Step 8: Commit**
```powershell
git add assets/audio scripts/tools/gen_sfx.gd CREDITS.txt
git commit -m "feat: acquire undertale music + sfx assets (synth fallbacks for missing)"
```
- [ ] **Step 9: Report** — per-music-file: downloaded size vs archive size, and any substitution; per-SFX-id: disposition (original source identifier + file name, or SYNTH).

---

### Task 2: AudioManager autoload + registry tests

**Files:**
- Create: `scripts/autoload/audio.gd`
- Modify: `project.godot` (autoload section)
- Create: `tests/test_audio.gd`

**Interfaces:**
- Consumes: asset names from Task 1 (constraint 4).
- Produces: `Audio` autoload per constraint 6. ALL later tasks reference `Audio.play_music/play_sfx`.

- [ ] **Step 1: Write the failing test** `tests/test_audio.gd`:

```gdscript
extends RefCounted

const AUDIO_SCRIPT := "res://scripts/autoload/audio.gd"

func test_music_registry_loaded() -> void:
	var S := load(AUDIO_SCRIPT)
	for id in ["title", "drizzle", "grumble", "battle", "death", "door_open", "door_close"]:
		var stream: AudioStream = S.MUSIC.get(id)
		TestHelper.is_true(stream != null, "music stream exists for " + id)
		if stream:
			TestHelper.is_true(stream.get_length() > 0.0, "music stream has duration for " + id)

func test_sfx_registry_loaded() -> void:
	var S := load(AUDIO_SCRIPT)
	for id in ["blip", "confirm", "select", "cancel", "hurt", "heal", "save", "sting", "flee"]:
		var stream: AudioStream = S.SFX.get(id)
		TestHelper.is_true(stream != null, "sfx stream exists for " + id)
		if stream:
			TestHelper.is_true(stream.get_length() > 0.0, "sfx stream has duration for " + id)

func test_unknown_id_is_safe() -> void:
	var a = load(AUDIO_SCRIPT).new()
	var before := TestHelper.failures
	a.play_sfx("does_not_exist", 1.0)
	a.play_music("does_not_exist")
	a.stop_music(0.1)
	TestHelper.eq(TestHelper.failures, before, "unknown ids never crash or assert")
```

- [ ] **Step 2: Run it — must FAIL** (audio.gd missing → script load error). Run the suite (constraint 2) and confirm the new file shows FAIL.
- [ ] **Step 3: Write `scripts/autoload/audio.gd`**:

```gdscript
extends Node

const MUSIC := {
	"title": preload("res://assets/audio/music/mus_t.ogg"),
	"drizzle": preload("res://assets/audio/music/mus_room.ogg"),
	"grumble": preload("res://assets/audio/music/mus_snowdin.ogg"),
	"battle": preload("res://assets/audio/music/mus_battle1.ogg"),
	"death": preload("res://assets/audio/music/mus_dontgiveup.ogg"),
	"door_open": preload("res://assets/audio/music/mus_dooropen.ogg"),
	"door_close": preload("res://assets/audio/music/mus_doorclose.ogg"),
}

const SFX := {
	"blip": preload("res://assets/audio/sfx/blip.wav"),
	"confirm": preload("res://assets/audio/sfx/confirm.wav"),
	"select": preload("res://assets/audio/sfx/select.wav"),
	"cancel": preload("res://assets/audio/sfx/cancel.wav"),
	"hurt": preload("res://assets/audio/sfx/hurt.wav"),
	"heal": preload("res://assets/audio/sfx/heal.wav"),
	"save": preload("res://assets/audio/sfx/save.wav"),
	"sting": preload("res://assets/audio/sfx/sting.wav"),
	"flee": preload("res://assets/audio/sfx/flee.wav"),
}

const SFX_POOL_SIZE := 8
const MUSIC_FADE := 0.3

var _music: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index := 0
var _warned: Dictionary = {}

func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)

func _ensure_bus(name: String) -> void:
	for i in AudioServer.bus_count:
		if AudioServer.get_bus_name(i) == name:
			return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, name)

func play_music(id: String) -> void:
	var stream: AudioStream = MUSIC.get(id)
	if stream == null:
		_warn_once("play_music", id)
		return
	if _music == null or _music.stream == stream:
		return
	_music_swap_prev(_music.stream)
	_music.stream = stream
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_music.volume_db = 0.0
	_music.play()

func _music_swap_prev(prev: AudioStream) -> void:
	if prev == null:
		return
	var fade_node := AudioStreamPlayer.new()
	fade_node.bus = "Music"
	fade_node.stream = prev
	fade_node.volume_db = 0.0
	add_child(fade_node)
	fade_node.play()
	var tw := create_tween()
	tw.tween_property(fade_node, "volume_db", -60.0, MUSIC_FADE)
	tw.tween_callback(fade_node.queue_free)

func stop_music(fade: float = MUSIC_FADE) -> void:
	if _music == null or _music.stream == null:
		return
	_music_swap_prev(_music.stream)
	_music.stop()
	_music.stream = null

func play_sfx(id: String, pitch: float = 1.0) -> void:
	var stream: AudioStream = SFX.get(id)
	if stream == null:
		_warn_once("play_sfx", id)
		return
	if _sfx_pool.is_empty():
		return
	var p := _sfx_pool[_sfx_index % _sfx_pool.size()]
	_sfx_index += 1
	p.stream = stream
	p.pitch_scale = pitch
	p.play()

func _warn_once(what: String, id: String) -> void:
	var key := what + ":" + id
	if _warned.has(key):
		return
	_warned[key] = true
	push_warning("Audio: unknown id %s for %s" % [id, what])
```

Note: `fade` param of `stop_music` is intentionally unused (single fade constant) — keep the parameter for API stability.

- [ ] **Step 4: Register the autoload** in `project.godot`, so the `[autoload]` section reads:
```ini
[autoload]

GameState="*res://scripts/autoload/game_state.gd"
Audio="*res://scripts/autoload/audio.gd"
```
- [ ] **Step 5: Run the test** — must PASS (all 3 test functions green; suite prints ALL TESTS PASSED).
- [ ] **Step 6: Run full suite** — ALL TESTS PASSED, no new SCRIPT ERRORs.
- [ ] **Step 7: Commit**
```powershell
git add scripts/autoload/audio.gd project.godot tests/test_audio.gd
git commit -m "feat: AudioManager autoload with music + sfx registry"
```
- [ ] **Step 8: Report** — test output summary; note any stream length == 0 (corrupt asset — must NOT happen after Task 1).

---

### Task 3: Audio hook points (music + sfx across the game)

**Files:**
- Modify: `scripts/main.gd` (title music)
- Modify: `scripts/rooms/drizzle_fields.gd` (room theme + door_close in `_ready`)
- Modify: `scripts/rooms/grumble_woods.gd` (room theme + door_close in `_ready`)
- Modify: `scripts/battle/battle.gd` (battle theme in `_ready`; hurt sfx in `_on_player_hit`)
- Modify: `scripts/rooms/save_point.gd` (save chime)
- Modify: `scripts/dialogue/dialogue_ui.gd` (typewriter blip)
- Modify: `scripts/rooms/door.gd` (door_open sfx)

**Interfaces:**
- Consumes: `Audio` autoload (Task 2).
- Produces: music/sfx wired; no new unit tests (audio not assertable headless) — the full suite is the gate.

- [ ] **Step 1: Title music** — in `scripts/main.gd` `_ready()`, after `GameState.load_game()` add:
```gdscript
	Audio.play_music("title")
```
- [ ] **Step 2: Room themes + door_close** — `drizzle_fields.gd` `_ready()`: append at the end (after `GameState.set_flag("current_room", ROOM_PATH)`):
```gdscript
	Audio.play_music("drizzle")
	Audio.play_sfx("door_close")
```
Same in `grumble_woods.gd` (after its `set_flag` line): `Audio.play_music("grumble")` + `Audio.play_sfx("door_close")`.
- [ ] **Step 3: Battle theme + hurt sfx** — `battle.gd` `_ready()`: add `Audio.play_music("battle")` as the first line. In `_on_player_hit()` (line ~308) add before `GameState.change_hp(-1)`:
```gdscript
	Audio.play_sfx("hurt")
```
- [ ] **Step 4: Save chime** — `save_point.gd` `_on_body_entered`: inside `if GameState.save_game():` add `Audio.play_sfx("save")` before `_show_banner(...)`.
- [ ] **Step 5: Door open sound** — `door.gd` `_on_body_entered`: inside the player branch add `Audio.play_sfx("door_open")` before `get_tree().change_scene_to_file(target_room)`. (No fade yet — Task 4 owns the transition.)
- [ ] **Step 6: Dialogue blip** — `dialogue_ui.gd`: add `var _prev_chars := 0` to the member vars; set `_prev_chars = 0` in `_show_current()`; in `_process`, replace the two lines `_tw.advance(delta)` + `_label.text = ...` with:
```gdscript
	_tw.advance(delta)
	var vis := _tw.visible_chars()
	if vis > _prev_chars and _prev_chars < _tw.text.length():
		var ch := _tw.text.substr(_prev_chars, 1)
		if not ch.is_space():
			Audio.play_sfx("blip", randf_range(0.9, 1.1))
	_prev_chars = vis
	_label.text = str(line.get("text", "")).substr(0, vis)
```
- [ ] **Step 7: Run full suite** — ALL TESTS PASSED, zero SCRIPT ERROR. (Existing tests only `load()` the modified scripts or exercise pure classes, so no stubs needed — if a SCRIPT ERROR or null-singleton error appears in a specific test, that test must be executing autoload-referencing code; add a stub instance named `Audio` to `(Engine.get_main_loop() as SceneTree).root` in that test's setup and note it in the report.)
- [ ] **Step 8: Commit**
```powershell
git add scripts/main.gd scripts/rooms/drizzle_fields.gd scripts/rooms/grumble_woods.gd scripts/battle/battle.gd scripts/rooms/save_point.gd scripts/dialogue/dialogue_ui.gd scripts/rooms/door.gd
git commit -m "feat: wire music and sfx hooks into title, rooms, battle, save, dialogue"
```
- [ ] **Step 9: Report** — any test stub additions and why.

---

### Task 4: Fade autoload + room transitions

**Files:**
- Create: `scripts/autoload/fade.gd`
- Modify: `project.godot` (register `Fade`)
- Modify: `scripts/rooms/door.gd` (fade + await before scene change)
- Modify: `scripts/main.gd` (fade to black before first room)
- Modify: `scripts/rooms/drizzle_fields.gd` + `grumble_woods.gd` (`Fade.fade_from_black(0.3)` in `_ready`)
- Create: `tests/test_fade.gd`

**Interfaces:**
- Consumes: `Audio` (door sfx already wired in Task 3).
- Produces: `Fade` autoload per constraint 6. Tasks 7 & 8 use `Fade.fade_to_black / fade_from_black / flash`.

- [ ] **Step 1: Write the failing test** `tests/test_fade.gd` (state-based — no tree needed, matching the project's direct-invocation style):

```gdscript
extends RefCounted

func test_initial_state_and_noop() -> void:
	var fade = load("res://scripts/autoload/fade.gd").new()
	fade._ready()
	TestHelper.is_true(not fade.is_black(), "starts transparent")
	fade.fade_from_black(0.1)
	TestHelper.is_true(not fade.is_black(), "fade_from_black no-ops when transparent")
	fade.free()

func test_set_black_drives_state() -> void:
	var fade = load("res://scripts/autoload/fade.gd").new()
	fade._ready()
	fade.set_black(1.0)
	TestHelper.is_true(fade.is_black(), "black after set_black(1)")
	fade.set_black(0.0)
	TestHelper.is_true(not fade.is_black(), "transparent after set_black(0)")
	fade.free()
```

- [ ] **Step 2: Run — must FAIL** (fade.gd missing).
- [ ] **Step 3: Write `scripts/autoload/fade.gd`**:

```gdscript
extends Node

const VIEW := Vector2(640, 480)

var _layer: CanvasLayer
var _black: ColorRect
var _white: ColorRect
var _tween: Tween

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_black = ColorRect.new()
	_black.color = Color(0, 0, 0, 0)
	_black.size = VIEW
	_layer.add_child(_black)
	_white = ColorRect.new()
	_white.color = Color(1, 1, 1, 0)
	_white.size = VIEW
	_layer.add_child(_white)

func is_black() -> bool:
	return _black != null and _black.color.a > 0.01

func set_black(alpha: float) -> void:
	_black.color.a = alpha

func fade_to_black(dur: float = 0.3) -> void:
	_tween_alpha(_black, 1.0, dur)

func fade_from_black(dur: float = 0.3) -> void:
	if not is_black():
		return
	_tween_alpha(_black, 0.0, dur)

func flash(dur: float = 0.15) -> void:
	_tween_alpha(_white, 1.0, dur * 0.5, dur)

func _tween_alpha(rect: ColorRect, target: float, dur: float, hold: float = 0.0) -> void:
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

- [ ] **Step 4: Register autoload** in `project.godot` — `[autoload]` section becomes:
```ini
[autoload]

GameState="*res://scripts/autoload/game_state.gd"
Audio="*res://scripts/autoload/audio.gd"
Fade="*res://scripts/autoload/fade.gd"
```
- [ ] **Step 5: Door transition** — `door.gd` `_on_body_entered` becomes:
```gdscript
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameState.set_flag("current_room", target_room)
		GameState.set_flag("save_point", [int(target_spawn.x), int(target_spawn.y)])
		Audio.play_sfx("door_open")
		Fade.fade_to_black(0.3)
		await get_tree().create_timer(0.3).timeout
		get_tree().change_scene_to_file(target_room)
```
- [ ] **Step 6: Title fade-out** — `main.gd` `_process` start branch becomes:
```gdscript
	if not _started and Input.is_action_just_pressed("confirm"):
		_started = true
		Fade.fade_to_black(0.3)
		await get_tree().create_timer(0.3).timeout
		get_tree().change_scene_to_file("res://scenes/rooms/DrizzleFields.tscn")
```
- [ ] **Step 7: Room fade-ins** — in both room scripts' `_ready()`, after the Task 3 music/sfx lines, add:
```gdscript
	Fade.fade_from_black(0.3)
```
- [ ] **Step 8: Run full suite** — ALL TESTS PASSED, including test_fade. If any test now errors on a null `Fade`, stub an instance named `Fade` in that test (same pattern as constraint 3).
- [ ] **Step 9: Commit**
```powershell
git add scripts/autoload/fade.gd project.godot scripts/rooms/door.gd scripts/main.gd scripts/rooms/drizzle_fields.gd scripts/rooms/grumble_woods.gd tests/test_fade.gd
git commit -m "feat: fade autoload + fade room transitions and title fade-in"
```
- [ ] **Step 10: Report** — suite output tail + any stub additions.

---

### Task 5: Strict 4-directional movement

**Files:**
- Modify: `scripts/player/player.gd`
- Create: `tests/test_player_4dir.gd`

**Interfaces:**
- Consumes: nothing new.
- Produces: `Player.resolve_direction4(...)` static per constraint 6; `_physics_process` uses it. `set_movement_input` stays UNCHANGED (existing test_player.gd depends on it).

- [ ] **Step 1: Write the failing test** `tests/test_player_4dir.gd`:

```gdscript
extends RefCounted

const P := "res://scripts/player/player.gd"

func test_no_input() -> void:
	var r: Array = load(P).resolve_direction4(PackedStringArray(), PackedStringArray(), "")
	TestHelper.eq(r[0], Vector2.ZERO, "no input = zero")
	TestHelper.eq(r[1], "", "no input keeps last empty")

func test_single_axis() -> void:
	var r: Array = load(P).resolve_direction4(PackedStringArray(), PackedStringArray(["move_right"]), "")
	TestHelper.eq(r[0], Vector2.RIGHT, "held right -> right")

func test_last_pressed_wins() -> void:
	var held := PackedStringArray(["move_up", "move_right"])
	var r: Array = load(P).resolve_direction4(PackedStringArray(["move_right"]), held, "move_up")
	TestHelper.eq(r[0], Vector2.RIGHT, "last pressed right beats up")
	TestHelper.eq(r[1], "move_right", "last updated")

func test_last_released_falls_back() -> void:
	var r: Array = load(P).resolve_direction4(PackedStringArray(), PackedStringArray(["move_left", "move_down"]), "move_up")
	TestHelper.eq(r[0], Vector2.LEFT, "falls back to first held when last released")

func test_never_diagonal() -> void:
	var held := PackedStringArray(["move_left", "move_up", "move_right", "move_down"])
	var r: Array = load(P).resolve_direction4(PackedStringArray(), held, "move_down")
	var d: Vector2 = r[0]
	TestHelper.is_true(d.x == 0.0 or d.y == 0.0, "result is single-axis")
```

- [ ] **Step 2: Run — must FAIL** (no such static function).
- [ ] **Step 3: Add to `scripts/player/player.gd`**:

```gdscript
static func resolve_direction4(just_pressed: PackedStringArray, held: PackedStringArray, last: String) -> Array:
	var new_last := last
	for action in just_pressed:
		if action in ["move_up", "move_down", "move_left", "move_right"]:
			new_last = action
	var chosen := new_last
	if chosen == "" or not held.has(chosen):
		chosen = ""
		for action in ["move_up", "move_down", "move_left", "move_right"]:
			if held.has(action):
				chosen = action
				break
	match chosen:
		"move_up": return [Vector2.UP, new_last]
		"move_down": return [Vector2.DOWN, new_last]
		"move_left": return [Vector2.LEFT, new_last]
		"move_right": return [Vector2.RIGHT, new_last]
	return [Vector2.ZERO, new_last]
```

- [ ] **Step 4: Rewire `_physics_process`** in the same file:

```gdscript
func _physics_process(delta: float) -> void:
	var just := PackedStringArray()
	var held := PackedStringArray()
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		if Input.is_action_pressed(action):
			held.append(action)
		if Input.is_action_just_pressed(action):
			just.append(action)
	var res: Array = resolve_direction4(just, held, _last_dir)
	_last_dir = str(res[1])
	set_movement_input(res[0])
	move_and_slide()
```

and add `var _last_dir := ""` to the member vars.

- [ ] **Step 5: Run tests** — test_player_4dir passes; test_player (existing) still passes; full suite ALL TESTS PASSED.
- [ ] **Step 6: Commit**
```powershell
git add scripts/player/player.gd tests/test_player_4dir.gd
git commit -m "feat: strict 4-directional movement (last-pressed wins, no diagonals)"
```
- [ ] **Step 7: Report** — suite tail.

---

### Task 6: DodgeBox hurt feedback (longer i-frames, flicker, knockback, stagger)

**Files:**
- Modify: `scripts/battle/dodge_box.gd`
- Create: `tests/test_hurt_feedback.gd`

**Interfaces:**
- Consumes: nothing new (hurt sfx lives in battle.gd `_on_player_hit`, already wired in Task 3).
- Produces: `INVULN_TIME := 1.0`, `STAGGER_TIME := 0.2`, `KNOCKBACK := 6.0`; `invuln` var stays public (existing test sets it directly).

**Existing dodge_box.gd `_process` (current behavior, lines ~47-64):** if not active → return; `invuln = maxf(0, invuln - delta)`; heart moves by input clamped to BOX_RECT; bullets advance; if circle_hit and invuln <= 0 → `invuln = 0.5` + `player_hit.emit()`. Existing tests (test_dodge_box.gd) drive `_process(delta)` directly with no tree — this must keep working: heart movement via `Input.get_vector` uses runtime-created actions (`_ensure_actions` helper in that test file).

- [ ] **Step 1: Write the failing test** `tests/test_hurt_feedback.gd`:

```gdscript
extends RefCounted

func _ensure_actions() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		if not InputMap.has_action(a):
			InputMap.add_action(a)

func _make_box() -> DodgeBox:
	var box: DodgeBox = preload("res://scripts/battle/dodge_box.gd").new()
	box._ready()
	return box

func test_invuln_time_is_one_second() -> void:
	var box := _make_box()
	box.set_active(true)
	box.spawn_patterns([{"pos": Vector2(320, 170), "vel": Vector2.ZERO, "life": 4.0}])
	box._process(0.016)
	TestHelper.is_true(box.invuln > 0.9, "hit grants ~1s invuln")
	box.free()

func test_heart_flickers_during_invuln() -> void:
	_ensure_actions()
	var box := _make_box()
	box.set_active(true)
	box.spawn_patterns([{"pos": Vector2(320, 170), "vel": Vector2.ZERO, "life": 4.0}])
	box.heart.visible = true
	box._process(0.016)
	TestHelper.is_true(box.invuln > 0.0, "hit happened")
	var saw_hidden := false
	for i in 20:
		box._process(0.05)
		if not box.heart.visible:
			saw_hidden = true
			break
	TestHelper.is_true(saw_hidden, "heart hides at least once during invuln")
	box.free()

func test_knockback_moves_heart_away_from_bullet() -> void:
	_ensure_actions()
	var box := _make_box()
	box.set_active(true)
	box.spawn_patterns([{"pos": Vector2(318, 170), "vel": Vector2.ZERO, "life": 4.0}])
	box._process(0.016)
	TestHelper.is_true(box.heart.position.x > 318.0, "heart pushed away from bullet")
	box.free()

func test_stagger_freezes_heart_input() -> void:
	_ensure_actions()
	var box := _make_box()
	box.set_active(true)
	box.spawn_patterns([{"pos": Vector2(320, 170), "vel": Vector2.ZERO, "life": 4.0}])
	box._process(0.016)
	var before_pos := box.heart.position
	Input.action_press("move_right")
	box._process(0.1)
	Input.action_release("move_right")
	TestHelper.eq(box.heart.position, before_pos, "heart frozen during stagger")
	box.free()

func test_no_double_hit_during_full_invuln() -> void:
	_ensure_actions()
	var box := _make_box()
	box.set_active(true)
	box.spawn_patterns([{"pos": Vector2(320, 170), "vel": Vector2.ZERO, "life": 4.0}])
	var counter := {"hits": 0}
	box.player_hit.connect(func() -> void: counter["hits"] += 1)
	for i in 15:
		box._process(0.05)
	TestHelper.eq(counter["hits"], 1, "one hit total during full invuln window")
	box.free()
```

- [ ] **Step 2: Run — must FAIL** (INVULN_TIME missing → parse error, or 0.5s behavior fails the 0.9 assertion).
- [ ] **Step 3: Modify `dodge_box.gd`** — replace the constants block (add below existing consts):
```gdscript
const INVULN_TIME := 1.0
const STAGGER_TIME := 0.2
const KNOCKBACK := 6.0
```
and add `var _stagger := 0.0` to the vars. Replace the whole `_process` body with:

```gdscript
func _process(delta: float) -> void:
	if not active:
		return
	invuln = maxf(0.0, invuln - delta)
	_stagger = maxf(0.0, _stagger - delta)
	heart.visible = (invuln <= 0.0) or (int(invuln * 10.0) % 2 == 0)
	for b in bullets:
		b.position += b.vel * delta
		b.life -= delta
	if _stagger > 0.0:
		_remove_dead()
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	heart.position = CombatMath.clamp_to_box(heart.position + input * HEART_SPEED * delta, BOX_RECT)
	var hit := false
	var hit_bullet: Bullet = null
	for b in bullets:
		if CombatMath.circle_hit(heart.position, 4.0, b.position, b.size):
			hit = true
			hit_bullet = b
			break
	if hit and invuln <= 0.0:
		invuln = INVULN_TIME
		_stagger = STAGGER_TIME
		if hit_bullet:
			var away := (heart.position - hit_bullet.position).normalized()
			heart.position = CombatMath.clamp_to_box(heart.position + away * KNOCKBACK, BOX_RECT)
		player_hit.emit()
	_remove_dead()
```

(Behavior notes: bullets keep moving during stagger; the heart only freezes. Flicker toggles visibility every 0.1s while invulnerable. Knockback is away from the hitting bullet, clamped to the box.)

- [ ] **Step 4: Run tests** — test_hurt_feedback AND the pre-existing test_dodge_box.gd must ALL pass (verify the existing invuln test still holds: it drives `invuln` directly and expects exactly one emit per window — new 1.0s window satisfies it).
- [ ] **Step 5: Full suite** — ALL TESTS PASSED.
- [ ] **Step 6: Commit**
```powershell
git add scripts/battle/dodge_box.gd tests/test_hurt_feedback.gd
git commit -m "feat: battle hurt feedback - 1s invuln, flicker, knockback, stagger"
```
- [ ] **Step 7: Report** — note any existing-test adjustments (should be none).

---

### Task 7: Death screen — "Stay determined!" + respawn

**Files:**
- Modify: `scripts/battle/battle.gd` (defeat branch)
- Create: `tests/test_death_respawn.gd`

**Interfaces:**
- Consumes: `Audio` (death music), `Fade` (to black / from black).
- Produces: defeat flow per constraint 10 (HP restored, inventory kept, respawn at last save point via existing `_spawn_point` reading `flags["save_point"]`).

- [ ] **Step 1: Write the failing test** `tests/test_death_respawn.gd` (GameState-level respawn contract; battle flow itself is smoke-tested by the suite + manual QA):

```gdscript
extends RefCounted

func test_respawn_state_after_death() -> void:
	var gs = load("res://scripts/autoload/game_state.gd").new()
	gs._ready()
	gs.reset()
	gs.set_flag("save_point", [128, 224])
	gs.change_hp(-20)
	TestHelper.eq(int(gs.player_stats["hp"]), 0, "hp zeroed by damage")
	var items_before: int = gs.inventory.size()
	gs.heal_full()
	TestHelper.eq(int(gs.player_stats["hp"]), int(gs.player_stats["max_hp"]), "hp restored to max")
	TestHelper.eq(gs.inventory.size(), items_before, "inventory kept on death")
	TestHelper.eq(gs.flags.get("save_point"), [128, 224], "save point preserved")
```

- [ ] **Step 2: Run — must FAIL** (hp stays 0 → heal_full assertion fails).
- [ ] **Step 3: Modify `battle.gd` defeat branch** — the current code is:

```gdscript
	if int(GameState.player_stats["hp"]) <= 0:
		_state.transition(BattleState.Phase.LOSE)
		await _say([{"speaker": "", "text": "You cannot give up just yet."}])
		GameState.heal_full()
		_end_battle()
```

Replace with:

```gdscript
	if int(GameState.player_stats["hp"]) <= 0:
		_state.transition(BattleState.Phase.LOSE)
		await _say([{"speaker": "", "text": "You cannot give up just yet."}])
		Audio.play_music("death")
		Fade.fade_to_black(0.8)
		await get_tree().create_timer(0.9).timeout
		_show_stay_determined()
		await get_tree().create_timer(2.2).timeout
		GameState.heal_full()
		_end_battle()
```

and add the helper function:

```gdscript
func _show_stay_determined() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	var label := Label.new()
	label.text = "Stay determined!"
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(640, 40)
	label.position = Vector2(0, 220)
	layer.add_child(label)
```

(The room's `_ready` plays its theme over the black and calls `Fade.fade_from_black(0.3)` after `_end_battle`'s scene change — fade-in happens on the respawned room.)

- [ ] **Step 4: Run tests** — test_death_respawn passes; full suite ALL TESTS PASSED.
- [ ] **Step 5: Commit**
```powershell
git add scripts/battle/battle.gd tests/test_death_respawn.gd
git commit -m "feat: stay determined death screen with respawn at last save"
```
- [ ] **Step 6: Report** — suite tail.

---

### Task 8: Encounter sting + "!" flash + chance-based flee

**Files:**
- Modify: `scripts/rooms/encounter.gd` (sting, flash, "!", freeze)
- Modify: `scripts/battle/battle.gd` (flee chance)
- Create: `tests/test_flee_chance.gd`

**Interfaces:**
- Consumes: `Audio` (sting/flee sfx), `Fade` (flash).
- Produces: `FLEE_CHANCE` + `flee_roll` per constraint 6; encounter ambush beat.

- [ ] **Step 1: Write the failing test** `tests/test_flee_chance.gd`:

```gdscript
extends RefCounted

func test_flee_roll_threshold() -> void:
	var S := load("res://scripts/battle/battle.gd")
	TestHelper.is_true(S.flee_roll(0.2), "roll below chance succeeds")
	TestHelper.is_true(not S.flee_roll(0.5), "roll at threshold fails")
	TestHelper.is_true(not S.flee_roll(0.99), "roll above chance fails")
	TestHelper.is_true(S.flee_roll(0.0), "roll 0 succeeds")
```

- [ ] **Step 2: Run — must FAIL** (no such static).
- [ ] **Step 3: Add to `battle.gd`** — a const at the top of the file:
```gdscript
const FLEE_CHANCE := 0.5
```
and the static:
```gdscript
static func flee_roll(roll: float) -> bool:
	return roll < FLEE_CHANCE
```
- [ ] **Step 4: Rework the MERCY Flee branch** — current code (battle.gd ~241-244):
```gdscript
			else:
				await _say([{"speaker": "", "text": "You flee, heart pounding."}])
				_end_battle()
				return
```
Replace with:
```gdscript
			else:
				if flee_roll(randf()):
					Audio.play_sfx("flee")
					await _say([{"speaker": "", "text": "You flee, heart pounding."}])
					_end_battle()
					return
				await _say([{"speaker": "", "text": "But it failed."}])
```
- [ ] **Step 5: Rework `encounter.gd`** — current `_on_body_entered` sets flags then immediately changes scene. Replace with:
```gdscript
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not used:
		used = true
		GameState.set_flag("pending_enemy", enemy_id)
		GameState.set_flag("from_room", str(GameState.flags.get("current_room", "res://scenes/rooms/DrizzleFields.tscn")))
		_show_bang()
		Audio.play_sfx("sting")
		Fade.flash(0.15)
		await get_tree().create_timer(0.4).timeout
		get_tree().change_scene_to_file("res://scenes/Battle.tscn")

func _show_bang() -> void:
	var label := Label.new()
	label.text = "!"
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	var player := get_tree().get_first_node_in_group("player")
	if player:
		label.global_position = player.global_position + Vector2(6, -30)
	get_tree().current_scene.add_child(label)
```
- [ ] **Step 6: Run tests** — test_flee_chance passes; full suite ALL TESTS PASSED (encounter.gd is only `load()`ed in tests — safe).
- [ ] **Step 7: Commit**
```powershell
git add scripts/battle/battle.gd scripts/rooms/encounter.gd tests/test_flee_chance.gd
git commit -m "feat: encounter bang sting + flash, chance-based flee"
```
- [ ] **Step 8: Report** — suite tail.

---

### Task 9: Final verification, export, and delivery prep

**Files:**
- Copy in (untracked, do NOT commit): `export_presets.cfg` and `Play SoulHeart.bat` from `C:\Users\Admin\Downloads\SoulHeart\` into the worktree root so the export preset is available.
- Deliverable: `dist\SoulHeart.exe` in the worktree.

- [ ] **Step 1: Full suite** (constraint 2) — ALL TESTS PASSED, exit 0, only the permitted dialogue error line.
- [ ] **Step 2: Copy export files**
```powershell
Copy-Item "C:\Users\Admin\Downloads\SoulHeart\export_presets.cfg" -Destination "export_presets.cfg"
Copy-Item "C:\Users\Admin\Downloads\SoulHeart\Play SoulHeart.bat" -Destination "Play SoulHeart.bat"
```
- [ ] **Step 3: Export**
```powershell
cmd /c "tools\godot.exe --headless --export-debug ""Windows Desktop"" ""dist/SoulHeart.exe"" > .superpowers\export.txt 2>&1 & echo DONE"
```
(If the export fails with "Failed to rename temporary file", a SoulHeart.exe process is holding the old file — stop it first: `Stop-Process -Name SoulHeart -Force -ErrorAction SilentlyContinue`.) Ignore the harmless `rcedit` warning (no icon/version resources configured — pre-existing).
- [ ] **Step 4: Boot check** — GUI exe cannot be verified with `&`; use:
```powershell
Start-Process -FilePath ".\dist\SoulHeart.exe" -ArgumentList "--headless","--quit-after","60" -Wait -PassThru | Select-Object ExitCode
```
ExitCode 0 = clean boot. Confirm `dist\SoulHeart.exe` size > 90MB (audio assets add ~15-25MB over the old ~97MB).
- [ ] **Step 5: Report** — final suite tail, export log tail, boot exit code, exe size, and the full per-asset disposition table.
