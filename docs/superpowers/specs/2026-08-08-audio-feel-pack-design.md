# SoulHeart — Audio + Feel Pack Design Spec

- **Date:** 2026-08-08
- **Status:** Approved for planning (brainstorming complete)
- **Scope:** First gap-pack of the "make SoulHeart feel/look like a completed Undertale-style game" roadmap (LO's request: "tell me whats missing... sounds, gameplay, pixel letters, etc"). This spec covers AUDIO + FEEL only. UI/pixel-fonts and content/endings are separate future specs.
- **Sourcing decision (LO-approved):** Full original assets first (Undertale music + original game SFX from rips), my own chiptune synthesis only as fallback for anything unobtainable.

---

## 1. Background

SoulHeart is a complete playable slice (title card → Drizzle Fields + Grumble Woods → save points, doors, encounters → battle with FIGHT/ACT/ITEM/MERCY), but it has **zero audio**, default-font text, placeholder art, instant scene cuts, no death flow, diagonal movement, and no battle hurt feedback. The gap analysis (delivered to LO) organized missing pieces into: Sound, Pixel letters/UI, Gameplay/feel, Visuals, Content. This pack closes Sound + Gameplay/feel.

## 2. Goals

1. Original Undertale music for: title, both room themes, battle, death screen, door transitions.
2. Original Undertale SFX (blips, menu confirm/cancel/select, hurt, heal, save chime, encounter sting, item) where obtainable; faithful synth replacements otherwise.
3. Undertale-accurate feel: strict 4-directional movement, battle invincibility frames + flicker + knockback + stagger, "Stay determined!" death screen with respawn at last save, fade room transitions, "!" encounter sting + flash, chance-based flee.
4. Full test suite stays green; re-exported exe boots clean.

## 3. Non-Goals (YAGNI, deferred)

- No bitmap font / dialogue box restyle / battle HUD / damage numbers (Pixel letters + UI pack — next spec)
- No new rooms, enemies, endings, puzzles, shops (Content pack)
- No settings menu or volume sliders UI (AudioManager exposes volume API, nothing binds to it yet)
- No music ducking/ducking logic, no crossfade beds (hard-cut + short fade is Undertale-accurate)
- No new art assets (heart shadow, particles, tile texture) — Visuals pack

## 4. Audio System

### 4.1 Asset layout
- `assets/audio/music/*.ogg` — BGM (original `mus_*.ogg` from Toby Fox's official archive.org upload "Undertale MUS PORT", `https://archive.org/download/undertale-port/`)
- `assets/audio/sfx/*.wav` — original `snd_*.wav` rips where found; synth-generated `.wav` fallbacks otherwise
- `CREDITS.txt` at repo root: "Music by Toby Fox (UNDERTALE), used in a private, non-commercial fan project."

### 4.2 Track mapping (music)
| Slot | Track file | Notes |
|------|-----------|-------|
| title | `mus_t.ogg` | Title card / Press Enter screen |
| Drizzle Fields | `mus_room.ogg` | Gentle area theme; candidate confirmed against port file list at implementation; fallback `mus_anothermedium.ogg` if absent |
| Grumble Woods | `mus_snowdin.ogg` | Dark woods theme; candidate, confirm at implementation; fallback `mus_room.ogg` if absent |
| battle | `mus_battle1.ogg` | All encounters |
| death | `mus_dontgiveup.ogg` | "Stay determined!" screen |
| door | `mus_dooropen.ogg` / `mus_doorclose.ogg` | Room transition sounds (in-game music assets used for exactly this) |

### 4.3 SFX target list (original-first, synth fallback)
| ID | Purpose | Original candidate |
|----|---------|--------------------|
| blip | Dialogue typewriter blip | `snd_blip` variants (pitch jitter per character) |
| confirm | Menu confirm | `snd_confirm` |
| select | Menu move | `snd_select` |
| cancel | Menu cancel/back | `snd_cancel` |
| hurt | Heart takes damage | `snd_hurt` |
| heal | Item use / heal | `snd_heal` (or item-use sound) |
| save | Save point chime | save-point sound |
| sting | Encounter "!" sting | battle-intro sting |
| flee | Successful flee | flee sound |

Sources tried in order: archive.org game-file rips (e.g. UndertaleModTool-style exports hosted publicly), then any well-indexed mirror. **Every** SFX disposition (found file vs synthesized) is recorded in the implementation plan's asset table when the plan is written; the game never blocks on a missing file — `play_sfx` on an unresolvable ID is a no-op with a one-time push_warning, never a crash.

### 4.4 AudioManager (`scripts/autoload/audio.gd`, autoload name `Audio`)
- One `AudioStreamPlayer` on a `Music` bus: music playback; `loop = true` (+ `loop_offset` if the track needs it) set in code at load — no import-flag fiddling.
- SFX: 8 `AudioStreamPlayer` round-robin pool on an `SFX` bus (polyphonic; dialogue blips overlap).
- API:
  - `play_music(id: String)` — swaps current music (0.3s volume fade out / in)
  - `stop_music(fade: float = 0.3)`
  - `play_sfx(id: String, pitch: float = 1.0)`
  - `set_music_volume_db(db)`, `set_sfx_volume_db(db)` — reserved for future settings UI
- Registry: static map `id → preloaded stream`. Unknown id → push_warning once, no-op.
- Music resumption semantics: room themes restart from the beginning on entry (Undertale-accurate).

### 4.5 Hook points
| File | Hook |
|------|------|
| `scripts/title.gd` (title card) | Play `title` on show; `stop_music` when game starts |
| Room scripts (`drizzle_fields.gd`, `grumble_woods.gd`) | `Audio.play_music(room_theme)` in `_ready` |
| `scripts/rooms/door.gd` | Door sound + fade (see 5.4) |
| Encounter trigger | `sting` SFX + "!" (see 5.5) |
| `scripts/battle/battle.gd` | Battle music on start; restore room theme on battle end; `hurt`, `heal`, `flee` SFX; `death` music on game over |
| `scripts/dialogue/dialogue_ui.gd` | Typewriter blip: every 1-3 chars (skip whitespace), random pitch ±0.15 — the classic Undertale blip feel |
| Save point | `save` chime + existing "Game saved." |

## 5. Feel Mechanics

### 5.1 Strict 4-directional movement (`scripts/player/player.gd`)
- Replace `Input.get_vector(...)` with axis-locked input: track four directions via `is_action_pressed`; when both axes are held, the **last-pressed** direction wins (via `is_action_just_pressed` events) until released — Undertale's exact no-ghost-diagonal behavior.
- ACCEL applies only to the locked axis; the other axis velocity decays. SPEED/ACCEL constants unchanged.

### 5.2 Battle hurt feedback (`scripts/battle/battle.gd`)
- On hit: `invincible = true` for ~1.0s; heart flickers (visible toggle every 0.1s during the window); brief knockback away from the bullet; ~0.2s control-freeze stagger; `hurt` SFX.
- While invincible, subsequent bullet hits are ignored (no HP drain).
- Invincibility ends → heart renders solid again.

### 5.3 Death screen — "Stay determined!" (`scripts/battle/battle.gd` + `scripts/autoload/fade.gd`)
- Defeat flow: "You cannot give up just yet." → fade to black → **"Stay determined!"** centered white text, `death` music → ~2s hold → fade back in at the **last save point** (GameState.save_point) with HP restored to max and items restored.
- GameState: add restore-on-death behavior (reset HP to max_hp, restore consumables).
- No dead-end path remains; every defeat respawns.

### 5.4 Room fade transitions (`scripts/rooms/door.gd` + new `scripts/autoload/fade.gd`)
- New `Fade` autoload: CanvasLayer + ColorRect black overlay; `fade_to_black(duration)` / `fade_from_black(duration)` via tween; `fade_transition(cb)` helper.
- Door flow: door SFX → `fade_to_black(0.3)` → `change_scene_to_file` → on room `_ready`, `fade_from_black(0.3)`.
- Death screen reuses the same Fade autoload.

### 5.5 "!" encounter sting + flash (encounter trigger, room scripts or `scripts/battle/` entry point)
- On encounter activation: "!" label pops above the heart, white overlay flash ~0.15s, `sting` SFX, ~0.4s control freeze, then battle scene.
- If an existing "!" already exists in the encounter flow, keep it and add flash + sting + freeze around it.

### 5.6 Chance-based flee (`scripts/battle/battle.gd`)
- MERCY → Flee: ~50% success via RNG (seeded/injectable for tests). Success: current flee flow. Failure: "But it failed." and enemy turn continues.

## 6. Integration & Repo Plan

- `project.godot`: register autoloads `Audio` (audio.gd) and `Fade` (fade.gd).
- Commits (in order):
  1. `feat: undertale audio (music + sfx + AudioManager)` — assets, audio.gd, CREDITS.txt, hooks, `tests/test_audio.gd`
  2. `feat: undertale feel (4-dir, i-frames, death screen, fades, sting, flee)` — player/battle/door/fade changes + tests
- Asset acquisition steps (implementation phase): download 6 `mus_*.ogg` individually from archive.org; byte-size check against listing; SFX hunt per 4.3; synthesize missing SFX as 16-bit mono WAVs (44100 Hz) via a small headless Godot generator script; record every disposition.
- Cleanup: delete stray `tmp_probe.gd.uid` from project root (leftover from earlier debugging).
- Untracked files (`Play SoulHeart.bat`, `dist/`, `export_presets.cfg`) remain untracked — LO has not decided on committing them.

## 7. Testing & Verification Gate

New tests (pattern: existing `tests/test_*.gd`, run via `res://tests/run_all.gd`):
- `test_audio.gd` — every registry ID loads a non-null stream with duration > 0; unknown id is a safe no-op (push_warning only).
- `test_player_4dir.gd` — simulate diagonal input (`Input.action_press` on two axes) → velocity locked to single axis; last-pressed wins.
- `test_battle_feedback.gd` — hit sets invincible; second hit within window does not drain HP; flicker/knockback flags set.
- `test_death_respawn.gd` — defeat → respawn state: save_point room, HP == max_hp, items restored.
- `test_flee_chance.gd` — seeded RNG: both success and failure paths exercised; failure shows "But it failed." and preserves enemy state.

Gate (identical to previous builds):
- Full headless suite: `ALL TESTS PASSED`, exit 0, zero `SCRIPT ERROR:` lines, only permitted stderr line (`ERROR: Dialogue file not found: res://dialogue/nope.dlg` from test_dialogue_parser).
- Re-export `dist\SoulHeart.exe` (close any running instance first — locked-file export failure lesson), boot-check via `Start-Process -Wait -PassThru` → exit code 0.

## 8. Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| archive.org file download failures | Byte-size verification per file; synth fallback per track; nothing blocks on any single file |
| Original SFX rips unobtainable | Synth fallbacks in matching chiptune style; disposition recorded per item |
| OGG loop behavior | `loop = true` set in code at stream load |
| Export size growth (~15-25MB) | Acceptable for a private gift build |
| OGG import warnings in headless | Verify with suite; adjust import options if Godot complains |

## 9. Deferred (future specs, in priority order)

1. **Pixel letters + UI pack:** bitmap font (white + shadow), dialogue/menu box styling, heart cursor, battle HUD (HP box, enemy name), yellow damage numbers, ▼ advance arrow.
2. **Visuals pack:** tile texture variation, heart shadow, particles (room-entry dust), NPC portraits.
3. **Content pack:** more rooms/enemies/boss, puzzles, shops, three endings (earlier "Plan 2" offer).
