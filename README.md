# SoulHeart

An Undertale-style gift RPG. Top-down, bullet-hell dodge combat, mercy-vs-kill
morality, typewriter dialogue, humor and heartbreak. A small game about a red
heart and the edits of a dream.

## Story

You fall into a quiet world that was never quite finished. Six edits are waiting
to be made at The Canon. The save points remember more than they say. At the end
of the road, the Old Dreamer watches over three doors — and the ending you reach
depends on what you did with the edits you were given.

Three endings — the doors at the end of the world react to what you did with
the edits:

- **The Keeper** — refuse at least 4 of the 6 edits. The world stays as it is;
  the armor remembers someone, and so do you.
- **The Wanderer** — accept some, refuse some. Half-changed, half-remembered;
  this door is always open.
- **The Hollow** — accept all 6 edits at The Canon. Perfect quiet. No going
  back.

## Areas

- **Echo** — the first fields, tall grass and low light.
- **Grumble Woods** — trees with opinions, and a sign that knows your name.
- **Drizzle Fields** — long grass under a sky that never quite stops drizzling.
- **Hometown** — quiet houses and doors that move when you blink.
- **The Cracks** — a floor that remembers being whole.
- **The Canon** — six edits, each waiting on its own page.

Edit events hide in these rooms — each one offers a choice, and the world
remembers which way you leaned.

## Controls

- WASD / Arrows — move
- Z / Enter — confirm, advance text, and hum to the Wisp
- X / Shift — cancel, skip text

Tap Z near the Wisp to hum to it — its mood grows, and it follows a little
closer. Hold nothing; a tap is enough.

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