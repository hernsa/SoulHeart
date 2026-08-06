# SoulHeart

An Undertale-style gift RPG for LO's friend. Top-down, bullet-hell dodge combat,
mercy-vs-kill morality, typewriter dialogue, humor and heartbreak.

## Controls

- WASD / Arrows — move
- Z / Enter — confirm, advance text
- X / Shift — cancel, skip text

## Run

- Game: `powershell -File tools\run_game.ps1` (or `& .\tools\godot.exe --path .`)
- Tests: `powershell -File tools\run_tests.ps1`

## Structure

- `scripts/` — all game code (autoload, player, rooms, dialogue, battle)
- `scenes/` — scene roots (thin; UI is built in code)
- `tests/` — headless unit tests (`run_all.gd`)
- `docs/superpowers/` — design spec and implementation plans

## Roadmap

See `docs/superpowers/specs/2026-08-07-soulheart-design.md` — Plans 2-6 add
story depth, battle depth, full world, art/audio, and delivery.
