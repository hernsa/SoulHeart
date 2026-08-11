# SoulHeart

An Undertale-style gift RPG. Top-down, bullet-hell dodge combat, mercy-vs-kill
morality, typewriter dialogue, humor and heartbreak. A small game about a red
heart and the edits of a dream.

## Story

You fall into a quiet world that was never quite finished. Six edits are waiting
to be made at The Canon. The save points remember more than they say. At the end
of the road, the Old Dreamer watches over three doors — and the ending you reach
depends on what you did with the edits you were given.

Three endings:

- **The Keeper** — refuse the edit. Keep the world from being changed.
- **The Wanderer** — walk through with the world half-changed, half-remembered.
- **The Hollow** — accept the edit completely. Perfect quiet. No going back.

## Controls

- WASD / Arrows — move
- Z / Enter — confirm, advance text
- X / Shift — cancel, skip text

## Run

- Game: `powershell -File tools\run_game.ps1` (or `& .\tools\godot.exe --path .`)
- Tests: `powershell -File tools\run_tests.ps1` (also runnable as
  `& .\tools\godot.exe --headless -s res://tests\run_all.gd`)

## Structure

- `scripts/` — all game code (autoload, player, rooms, dialogue, battle, world)
- `scenes/` — scene roots (thin; UI is built in code)
- `assets/audio/` — music and sfx; Plan D area themes are synthesized in-engine
  by `tools/gen_area_music.gd`
- `tests/` — headless unit tests (`run_all.gd`, sorted, `test_*.gd`)
- `docs/superpowers/` — design spec and implementation plans

## Music

Area themes are 8-note leitmotifs synthesized to 8-bit WAVs by
`tools/gen_area_music.gd` (Echo, Hometown, Canon, Cracks, Credits, Hollow, Wisp).
Battle and title music are from UNDERTALE (see CREDITS.txt).