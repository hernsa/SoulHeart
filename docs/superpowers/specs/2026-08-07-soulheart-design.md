# SoulHeart — Design Specification

**Date:** 2026-08-07
**Status:** Approved (LO)
**Purpose:** A surprise gift game for LO's friend, built to look, feel, and play like it came from the same author as Undertale (Toby Fox) — original IP, wink-wink cameos, no ripping.

---

## 1. Overview

SoulHeart is a top-down turn-based RPG in the Undertale mold: bullet-hell dodge combat with a red heart SOUL, a mercy-vs-kill morality system, typewriter dialogue, humor woven through heartbreak, and three endings driven by player choices. It is a personal, non-commercial gift.

**Engine:** Godot 4.4 (GDScript). Free, exports real .exe, ideal for 2D pixel bullet-hell RPGs.

**Skill workflow:** brainstorming (done) → writing-plans (active) → test-driven-development + subagent-driven-development → verification-before-completion.

---

## 2. Story

You fall — not into the Underground, but into the **Dreamfalls**, a valley where discarded dreams drift like snow. Everyone there knows you. You don't remember them.

You were the **Dreamcatcher**: the one who gathered the dreams of the waking world and carried them here to be kept safe. Then you stopped coming. The dreams you abandoned turned into monsters — not evil ones, just lonely ones — and the valley began to fade.

Your guide, **Willowisp**, a small ball of light who hums the tunes you used to whistle, insists you can fix this: repair each broken dream, or shatter the ones too far gone. Every dream is a person's memory — of a first love, a lost pet, a home, a promise.

**The emotional engine:** mercy vs. shatter. Repair dreams and the valley remembers you as its keeper. Shatter them and you become the very thing that broke it.

### Endings

- **Pacifist ("The Keeper"):** Every dream repaired. The valley blooms; Willowisp tells you it always knew you'd come back. You wake — and leave a single dream behind, for your friend: the whole game was their memory, kept safe. (Bittersweet, warm.)
- **Neutral ("The Wanderer"):** Some saved, some shattered. The valley persists, half-lit. Willowisp hums alone. You wake with the feeling you forgot something.
- **Shatter ("The Hollow"):** Every dream destroyed. The valley is silent. The last dream is your own — and you shatter it too, waking with nothing. (Dark, brief, haunting.)

---

## 3. Characters

**Willowisp** — guide, mentor, comedian. A pale blue wisp the size of a candle flame. Speaks in gentle jokes that slowly curdle into sorrow as the truth about the Dreamcatcher emerges. Humming motif recurs across the soundtrack. Original (Flowey-energy but kind).

**Drizzle Toads** — tutorial monsters, small damp frogs with umbrellas made of leaf. They cry when it's sunny. Sparing them = listening to their worries.

**Bones** (cameo) — a skeleton silhouette in a blue jacket who appears exactly once, tells a ketchup joke, says "heya kid," and disappears through a door that wasn't there. No name spoken. No IP used.

**Fizz** — cat shopkeeper in Mothlight Town. Sells "puns" as items (they're just words; they heal anyway, because laughing counts). Says "myeow" instead of hello.

**The Mourning Knight** — area boss. An armor set holding itself together with nothing inside, mourning the dreamer who dreamed it (a kid who wanted to be brave). Its attacks are slow, sad, easy to dodge — it doesn't want to hurt you. Sparing it is the point.

**The Old Dreamer** — final NPC. The first dream ever caught. Knows everything. Delivers the ending choice.

**The Dreamcatcher (player)** — silent protagonist in a striped shirt (sweater stripes, not the same colors). Their SOUL is the red heart.

---

## 4. World & Areas

Five areas, room-based transitions (Undertale-style doors and stairway fades):

1. **The Drizzle Fields** — fall landing, tutorial area. Grey-green grass, rain that never lands. Drizzle Toads, first save point, first encounter, path out through a hollow tree.
2. **The Grumble Woods** — forest of trees that talk in their sleep. Puzzle: lull them back to sleep by walking the "hush" path.
3. **Mothlight Town** — the heart of the valley. Fizz's shop, dreaming houses (you can enter a dream and play a 30-second memory vignette), Bones' cameo, lore books.
4. **The Sleeping Canyon** — the Mourning Knight's domain. Echoes of past dreamers.
5. **The Shatter Gate** — the Old Dreamer, final choice, endings.

---

## 5. Core Gameplay Systems

### 5.1 Overworld
- Top-down, room-based, tile collision (CharacterBody2D + TileMapLayer).
- 8-direction movement, walk speed ~140 px/s, pixel-perfect 2x scale.
- Interact: talk to NPCs (auto-open dialogue on contact for the slice), doors, save points (star-shaped light → "Game saved.").

### 5.2 Dialogue
- Typewriter text, Z/Enter to advance, X to skip-to-full then close.
- Speaker names, faces later (Plan 5).
- Lines from `.dlg` files parsed by `DialogueParser`.

### 5.3 Battle — the heart of it
Undertale-faithful:
- **Enemy turn:** bullet-hell dodge — a red heart SOUL moves freely in a white-bordered box; bullets are the enemy's *emotion* (slow tears, wavering light, sad armor swings). Hit = 1 HP damage + 0.5s invuln.
- **Player turn menu:** FIGHT / ACT / ITEM / MERCY (2x2 grid, arrows + Z, X cancels).
  - **FIGHT:** scrolling bar + marker; Z to strike. Hit closeness = *intent to harm*, 0..1 multiplier on damage. Center = full damage.
  - **ACT:** per-enemy actions. Change mood → name turns yellow → spareable. "Check" reveals stats/lore.
  - **ITEM:** use consumables ("Dream Candy" heals 6). Consumed on use.
  - **MERCY:** Spare (only when enemy is spareable) or Flee (ends battle, no counters).
- **Rewards:** Gold on kill. EXP/LV only on kill — sparing gives nothing but story (Undertale thesis: pacifism is its own reward). Kill/spare counters tracked globally (drive endings + a "are you listening to yourself?" moment at the Shatter Gate).
- **Game over:** "You cannot give up just yet." → respawn at last save point, HP full.

### 5.4 Save system
- Save points write JSON to `user://save.json`: stats, inventory, flags, kills, spares, current room, save point.
- Flags drive story state (`hush_path_done`, `knight_spared`, `dreams_repaired` count, etc.).

---

## 6. Look & Feel Bible (researched from the real game)

Facts gathered from Undertale art/deconstruction research — these are the non-negotiables that make it *feel* like the same author:

| Aspect | Rule |
|---|---|
| Resolution | 640x480 internal, integer 2x scale, nearest-neighbor filtering (no blur, no fractional zoom) |
| Tiles | 16x16 |
| Sprites | Variable sizes (Toriel ≈ 49px, sans ≈ 30px). Overworld canvas often 64x64 |
| Silhouette rule | Every character readable blacked-out — unique shapes, huge personality |
| Heads | ~1/2 to full body height — emotion lives in the head |
| Outlines | Black outlines on almost everyone; partial/none for heroes |
| Backgrounds | Mostly black void, sparse, moody; single-source glow |
| UI | Minimal white 1px borders, no panels, no windows, no HUD clutter |
| Text | Typewriter with blip (placeholder for now), box = black with white 1px border at screen bottom |
| Battle box | White 1px border rect, heart SOUL = red heart sprite, black background |
| Spare state | Enemy name turns yellow when spareable |
| FIGHT bar | White scrolling bar, marker line, Z to press |
| Philosophy | Attacks = emotion expressed as magic; comedy of props (umbrellas, ketchup, puns); "bullet heaven" not hell — fewer, larger, fairer projectiles |
| DNA | EarthBound humor/heart, Touhou dodging, Shin Megami Tensei ACT/MERCY |
| Music | Chiptune-leaning, leitmotifs (Willowisp's hum recurs) — Plan 5 |

---

## 7. Tech Stack & Architecture

- Godot 4.4.1 stable (Windows), GDScript, GL Compatibility renderer.
- No engine addons; custom minimal headless test runner (`tests/run_all.gd`) for deterministic TDD.
- Autoload: `GameState` (stats, inventory, flags, kills/spares, save/load, runtime InputMap setup).
- Scene-per-system: `Player.tscn`, `rooms/*.tscn`, `Battle.tscn`; UI built in code (no .tscn authoring fragility).
- Procedural placeholder art in code (Image → ImageTexture): player, heart, bullets, wisp, tileset atlas. CC0 public assets replace in Plan 5.
- Layouts authored as ASCII strings, parsed by `MapBuilder` → deterministic, testable maps.

**File map (Plan 1):**

```
SoulHeart/
├─ project.godot
├─ README.md
├─ tools/  (godot.exe — gitignored)
├─ scripts/
│  ├─ autoload/game_state.gd
│  ├─ player/player.gd
│  ├─ rooms/{layout_parser,map_builder,door,save_point,encounter,npc,drizzle_fields}.gd
│  ├─ tiles/tiles.gd
│  ├─ dialogue/{dialogue_parser,typewriter,dialogue_ui}.gd
│  └─ battle/{battle_state,enemy_stats,enemy_library,fight_bar,combat_math,patterns,bullet,dodge_box,battle}.gd
├─ scenes/{Main,Player}.tscn, scenes/rooms/{DrizzleFields,GrumbleWoods}.tscn, scenes/Battle.tscn
├─ dialogue/*.dlg
└─ tests/ (run_all.gd, test_helper.gd, test_*.gd)
```

---

## 8. Roadmap (separate plans)

- **Plan 1 — Core Engine & Vertical Slice (this plan):** scaffolding, GameState+save, combat math, dialogue, tiles/map building, player, enemy library, battle state + fight bar, bullet patterns + dodge box, battle scene, Drizzle Fields + Grumble Woods stub, title card. Delivers a playable, testable slice: walk, talk, fight Willowisp, spare/kill, save.
- **Plan 2 — Story & Systems Depth:** full dialogue/cutscenes (faces, choices), items/equipment breadth, Grumble Woods puzzle, Mothlight Town, minigame vignettes.
- **Plan 3 — Battle Depth:** multi-enemy encounters, boss fights (Mourning Knight, final), soul-mode variants, EXP/LV, gold shop.
- **Plan 4 — World Completion:** Sleeping Canyon, Shatter Gate, all endings, all NPC content.
- **Plan 5 — Art & Audio:** CC0 asset integration (Kenney, finalbossblues OpenRTP CC0, wareya 255-tile CC0, OpenGameArt chiptune), generated-custom sprites, pixel font (Press Start 2P / m5x7), music, SFX blips.
- **Plan 6 — Polish & Delivery:** balance pass, game-over flow, export .exe, surprise delivery kit (how to run, fake cover art).

---

## 9. Risks & Constraints

- **Scope:** full game = months. Mitigated by plan-per-subsystem + vertical slice first.
- **IP:** zero ripped assets, original names — tribute energy only, same-*author* feel, not same-*content*.
- **Determinism:** all logic units are pure/testable; input/rendering verified by manual QA checklist per task.
- **Tooling:** Godot download required once (offline fallback: user installs manually).
