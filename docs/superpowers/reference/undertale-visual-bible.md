# Undertale Visual & UX Bible (source-verified reference for SoulHeart)

**Purpose:** authoritative reference of Undertale (v1.0/1.08) visual, typographic, and UX conventions so SoulHeart (Godot 4.4, 640x480, pixel art, Undertale-style fangame) can replicate the look and feel with exact numbers instead of vibes.

**Tag legend**
- `[VERIFIED]` — extracted directly from decompiled game scripts (code.undertale.wiki) or confirmed by an authoritative article. Exact numbers are trustworthy.
- `[RECALLED]` — from gameplay knowledge / screenshots; values approximate; verify against footage before finalizing.

**Canonical render context** `[VERIFIED]`: GameMaker room 640x480, 30 FPS, `view 0 = 0,0,640,480`, `application_surface` default (640x480). All coordinates below are room coordinates. All "frame" values assume 30fps.

---

## 1. Fonts & Typography

- **Battle/overworld dialog font** = **8-Bit Operator JVE** by Jayvee Enaguas (nipcen). `[VERIFIED]` — Fonts In Use article + community consensus; released via Dafont 2011; also used for Deltarune.
  - No smoothing / crisp edges; drawn at 1:1 pixel scale, no subpixel AA. `[RECALLED]`
- **Community clone for fan projects:** "Determination" family by Haley Wakamatsu (JapanYoshi) — `Determination Mono` (`DMT-Mono`) is the accepted 8-Bit Operator JVE stand-in. `[VERIFIED]` (Behance + community usage); GitHub `ThetaApps/font-undertale` hosts a Determination variant. SourceForge ffont.ru mirrors confirm. For SoulHeart, **DMT-Mono is the safest licensing-legal drop-in.**
- **Font slots in code** `[VERIFIED]` (SCR_TEXTTYPE):
  - `fnt_main` — big dialog font, **16px char pitch, 32px line height** (battle text, typer 1).
  - `fnt_maintext` — overworld dialog font, **8px pitch, 18px line height** (typer 4). Overworld text is visibly smaller than battle text.
  - `fnt_plain` — 9px pitch / 20px lines; narration, Flowey, young voices (typer 2).
  - `fnt_curs` — small UI font for player name / LV / HP numbers (scr_binfowrite). `[VERIFIED]`
  - `fnt_small` — tiny font for version/copyright text. `[VERIFIED]`
  - `fnt_comicsans` — Sans' speech (literally Comic Sans). `[VERIFIED]`
  - `fnt_papyrus` — Papyrus' speech (literally Papyrus font). `[VERIFIED]`
  - `fnt_wingdings` — Gaster's speech (Wingdings). `[VERIFIED]`
  - `fnt_plainbig` — 25px pitch / 20px lines (Flowey boss shouts, typer 20). `[VERIFIED]`
- **Text colors** `[VERIFIED]`: default `c_white`; typer 3 = `c_teal` (curs font); typer 22 = Papyrus black; Gaster followers plain black/white variants. Special named dialogue (Undyne, Mettaton, Asgore...) uses the same white maintext font with distinct blip sounds — color carries meaning only for Flowey (red/white) `[RECALLED]`.
- Character-specific dialogue = font swap, not color swap. `[VERIFIED]`
- Max name length = **6 characters** `[VERIFIED]` (scr_namingscreen).

**SoulHeart application note:** Use DMT-Mono for fnt_main-equivalent; define two sizes: Battle (16px pitch / 32px line) and Overworld (8px pitch / 18px line). Ship separate font resources for any "voice" characters. Keep pixel snapping on (nearest-neighbor, integer scale) — no AA.

---

## 2. Battle Screen Layout (geometry)

`[VERIFIED]` — SCR_BORDERSETUP, battlecontroller Draw_0/Step_0, scr_binfowrite.

Default battle (border 0) uses the **full-width board**:

| Element | Rect (x1, y1, x2, y2) | Notes |
|---|---|---|
| Bullet board (dodge box) | `32, 250, 602, 385` | 570px wide, 135px tall |
| Enemy stand area | ~x 116–418, y 16–156 | enemies spawn per-encounter, e.g. single at `(216,136)` |
| Battle text box | ~x 30–320, y 390–465 | bottom-left, sprite `spr_blconwdshrt_l` |
| Battle menu box (FIGHT/ACT/ITEM/MERCY) | ~x 400–602, y 385–465 | bottom-right; heart cursor lives here |
| Player info (name/LV/HP) | x 30–~500, y 400–420 | top-left of the lower strip, drawn every frame in battle |

- Enemy singles: `(216,136)` center-ish (Froggit, Loox 218,124, dummy); triples spread at `(14/116/320/418, 136/156)`. `[VERIFIED]` (scr_battlegroup)
- Enemies always stand ABOVE the board (board top = 250); text and menus BELOW the board (board bottom = 385).

**SoulHeart application note:** Replicate the four-zone layout verbatim: enemy row above y=250, board y250–385, player box + text box + menu box below y=385. This vertical stack IS the Undertale silhouette. Board inset `+4` from edges (left/top) and `-16` right/bottom for heart bounds (see §8).

---

## 3. The Bullet Board (dodge box) — look & motion

- Edges are **stretched sprites** driven by `obj_uborder/rborder/dborder`; edge slides at **15px/frame** toward `global.idealborder[]` (snap within 15px). `[VERIFIED]` (uborder/dborder Step_0, rborder Step_2)
  - The famous "box slides open/closed" is this 15px/frame easing (≈0.9s to open a 570px box).
  - Width stretch: `image_xscale = width/5` (native sprite unit = 5px), lerped at 6 units/frame. `[VERIFIED]`
  - `instaborder` = instant snap (boss quick-open). `[VERIFIED]`
- Box interior is transparent; during enemy attacks the area outside the box is **filled black** (`drawrect==1` → black fill between uborder+5 and rborder/dborder). `[VERIFIED]` (battlecontroller Draw_0)
- 52 border presets exist (bosses use custom rects: border 1 `217,180,417,385`, border 26 `295,250,345,385` tiny, border 31 full-width tall, border 51 = tracks the heart's y, etc.). `[VERIFIED]` (SCR_BORDERSETUP)
- Border lines are white-ish `[RECALLED]` (edge sprites); the board itself shows the battle background through it.
- Board resize during special fights re-triggers via `scr_moveideal` (lerp of idealborder). `[VERIFIED]`

**SoulHeart application note:** Implement the box as 4 stretched edge sprites with 15px/frame positional easing — don't tween the whole box; tween the edges. Keep the black-outside-during-attack fill; it reads as "safety zone." Provide the `border` preset list as data for boss fights.

---

## 4. Dialog Text System

- **Typewriter styles** (SCR_TEXTTYPE): typer 1 = battle text `fnt_main` white, **inset x+20/y+20, wrap at idealborder[1]-55, spacing 16, vspacing 32, blip SND_TXT2**; typer 4 = overworld `fnt_maintext`, inset +20/+20, wrap at view_x+290, spacing 8, vspacing 18, blip snd_txttor. `[VERIFIED]`
- **Blip sounds per character** `[VERIFIED]`: `SND_TXT2` (standard dialog blip), `SND_TXT1` (plain), `snd_txttor`/`snd_txttor2` (Toriel), `snd_txtpap` (Papyrus), `snd_txtsans`/`snd_txtsans2` (Sans), `snd_txtund`/`snd_txtund2..4` (Undyne), `snd_txtasg`/`snd_txtasr`/`snd_txtasr2` (Asgore/Asriel), `snd_floweytalk1/2`, `snd_wngdng1` (Gaster), `snd_tem` (Temmie), `snd_mtt1` (Mettaton), `snd_nosound` (silence). Map voices → blips; this is a huge part of the feel.
- **Text skip:** pressing confirm while typing sets `stringpos = string_length(originalstring)` — instant fill, no flash. `[VERIFIED]` (battlecontroller Step_0 + scr_textskip)
- Box sprites: `spr_blconwdshrt_l` (bottom-left, standard), `spr_blconabove` (y-offset -20, x-offset -20), `spr_blconwdshrt`, `spr_blconbelow` (x-offset -10). `[VERIFIED]` (scr_blcon/scr_blcon_ofs)
- Writer object spawns at `(idealborder[0], idealborder[2])` for battle lines; box slave offset +30/+10 then -30/-10 → box sits to the left-bottom of the writer's text origin. `[VERIFIED]`
- Message plumbing: `global.msg[]` strings + `global.msc` id; `OBJ_WRITER` (slow) vs `OBJ_INSTAWRITER` (instant). `[VERIFIED]`
- Per-char speed: battle text ≈ 2–3 chars/frame at 30fps, overworld ≈ 3–5 chars/frame; both feel snappy. `[RECALLED]` — tune to feel; the blip cadence matters more than the number.
- Line-start `*` (the classic star bullet) is part of the string data (`scr_gettext`), rendered as the star glyph in font. `[RECALLED]`

**SoulHeart application note:** Build a `Typer` node: font/color/spacing/blip/inset/wrap config per "voice," instant-skip on confirm, box sprite + slave positioning, and a `writingxend` wrap. Reuse for battle + overworld with the two typer presets above.

---

## 5. Battle Menu (FIGHT / ACT / ITEM / MERCY)

- The **heart is the cursor**; it teleports to menu slots. `[VERIFIED]`
- Slot Y: `idealborder[2] + 28 + (line * 32)` (EN; JA = +27 + line*36). `[VERIFIED]` (scr_battlemenu_cursor_y)
- **Main menu:** 4 columns; slot X = `idealborder[0] + 32`; lines 0–3 = FIGHT, ACT, ITEM, MERCY. `[VERIFIED]` (battlecontroller Step_0)
- **FIGHT target pick (multi-enemy):** same 32px line rows; up to 3 enemies (`bmenucoord[1]`); enemy names + **HP bars** drawn top-right of board at `y=280`, bar w=100 h=16, red outline + lime fill, name width = 16px/char. `[VERIFIED]` (battlecontroller Draw_0)
- **ACT (talk) menu:** up to 6 choices, **2 columns**: left col x = `idealborder[0]+32`, right col x = `idealborder[0]+292`; y = cursor_y(0..2) / cursor_y(0..2) for rows. `[VERIFIED]`
- **ITEM menu:** **4x2 grid** — x = `+32` (cols 0,2) / `+280` (cols 1,3); y = `idealborder[2]+28` (rows 0–1) / `+60` (rows 2–3). `[VERIFIED]`
- **MERCY:** 2 options (Spare/Flee): x = +32, y = cursor_y(0..1). `[VERIFIED]`
- Cursor move sound = `snd_squeak`; confirm = `snd_select`. `[VERIFIED]`
- Cancel (X) returns to main menu; back to dialog. `[VERIFIED]` (KeyPress/Step_0)
- The main menu box is a sprite-drawn box bottom-right `[RECALLED]` (box art not in decompiled draw code; layout verified by cursor coords).

**SoulHeart application note:** Model `bmenuno` state machine (0=main, 1=FIGHT target, 2=ACT, 3=ITEM, 4=MERCY, 10=ACT choices) and `bmenucoord[]` per state. The 4x2 ITEM grid + 2-col ACT list + 32px rows are the exact spacing rules.

---

## 6. Enemy Presentation & Feedback

- **Entrance:** encounter trigger (`obj_battler`) → `snd_noise` ("!" sting) + exclamation sprite (`spr_exc_f` at high LV), then soul is pulled out of the body at `(mainchara.x+5, mainchara.y+17)` via `obj_transheart`; camera follows. `[VERIFIED]` (obj_battler Create/Alarm_4/Draw)
- **Enemy HP bar (under enemy, on hit):** `obj_dmgwriter` — black outline rect, `c_dkgray` inner, **`c_lime` fill**; bar width = **enemy sprite width** (`stretchfactor = sprite_width/maxhp`), drawn at enemy bottom `ystart`. Drains with lag via `apparenthp`. `[VERIFIED]` (obj_dmgwriter)
- **Damage numbers:** red digit sprites (`spr_dmgnum_o` frames 0–9), pitch **32px**, centered on enemy, float up (`vspeed=-4`, gravity 0.5) then fall back to bar; `MISS` = `spr_dmgmiss_o` tinted `c_ltgray` at (x-10, y-16); special damage = red text line `fnt_main`. `[VERIFIED]`
- **Hit flash:** enemy flashes white on hit; screen shakes on player damage (`global.hshake=2; shakespeed=2`). `[VERIFIED]` (damagestandard + recall of flash)
- **Defeat:** enemy poofs into dust — `obj_vaporized_new` created at enemy pos with per-enemy vaporize data; spared → `obj_spared` puff. `[VERIFIED]` (scr_monsterdefeat)
- **Battle intro flash:** red fullscreen flash tied to `global.turntimer` in Draw_0. `[VERIFIED]` (battlecontroller Draw_0)

**SoulHeart application note:** three layers of feedback: (1) under-enemy lime bar at enemy width with lag-drain, (2) red 32px-pitch damage digits with float-gravity, (3) vaporize/spare poofs. White hit-flash + red screen flash on player hit (shake 2px).

---

## 7. Player Info (bottom-left)

`[VERIFIED]` (scr_binfowrite):
- Name (fnt_curs) at `(30,400)`; LV appended after name: `"   LV " + lv`.
- HP bar: **yellow** fill (`c_yellow`) over **red** underlay (`c_red`), rect `(275,400)`–`(275+maxhp*1.2, 420)` → **1.2px per HP**; text `"XX / XX"` zero-padded, fnt_curs white at `(290+maxhp*1.2, 400)`.
- Karma variant (flag 271): maroon underlay, fuchsia KR drain bar, `spr_krmeter` at `(265+maxhp*1.2, 405)`, `spr_hpname` at `(220,400)`.
- Player maxHP formula: `maxhp = 16 + lv*4`; AT `= 8 + lv*2`. `[VERIFIED]` (battlecontroller Create / scr_levelup)

**SoulHeart application note:** HP bar = 1.2px per HP, yellow-on-red, 20px tall, numbers to the right. This exact ratio is what makes the UT HP bar recognizable.

---

## 8. Heart & Bullet Phase

- Heart = `obj_heart`; **board bounds**: clamp to `idealborder[0]+4` (left), `idealborder[2]+4` (top), `idealborder[1]-16` (right), `idealborder[3]-16` (bottom) — fires wall-hit event + zeroes speed. `[VERIFIED]` (heart Step_0)
- Movement speed `global.sp` (default ~5 `[RECALLED]`, tunable); `global.asp` shoot speed.
- Invulnerability blink: `image_speed 0.5` while `global.invc>0`; i-frames `global.inv` default **30 frames (~1s)** scaled by `/20` per damage arg (i.e., arg4=20 → full 30f; Torn Note etc. scale it). `[VERIFIED]` (heart Step_0, damagestandard)
- Shooting (if weapon allows): heartshot every **14 frames** (`charge=14`) spawned at `(x+4, y+2)`, `snd_heartshot`. `[VERIFIED]`
- Confusion: heart sprite `spr_confuseheart` rotates `image_angle += 6`/frame. `[VERIFIED]`
- Damage formula: `dmgamt = round(dmg - (df+adef)/5)`, clamp [arg1..arg2], forced arg3, min 1; `global.hp -= dmgamt`; `snd_hurt1`; shake. `[VERIFIED]` (scr_damagestandard)
- Enemy turn flow: `mnfight=3` attack phase → turn++ when box fully open. `[VERIFIED]` (battlecontroller Step_0)

**SoulHeart application note:** clamp is +4/-16, blink at half-speed anim during i-frames (~1s), heartshot 14f cooldown. Keep these — they define dodge feel.

---

## 9. Overworld & Room Transitions

- Walk speed **3px/frame** (2px on alternating frames for stairs — the `xprevious==(x±3)` trick); anim `image_speed 0.2`; 4 facing sprites `dsprite/rsprite/usprite/lsprite`. `[VERIFIED]` (obj_mainchara Step_0)
- Depth sort by Y (`scr_depth`). `[VERIFIED]`
- Encounter: `obj_battler` triggers — `snd_noise`, `!` blcon, pause music, `obj_fader` → `room_battle`. `[VERIFIED]`
- Door exit: `obj_persistentfader` (fade) then `room_goto` next. `[VERIFIED]` (doorA/doorC Alarm_2)
- **Fade-out:** black fullscreen sprite scaled room×3/×2, alpha tspeed **-0.08/frame** (~13f to black). **Fade-in:** `obj_unfader` tspeed **+0.05** (~20f). `[VERIFIED]` (obj_fader Create/Step)
- **Flash:** `obj_flasher` = fullscreen white (scaled 99999) flash, alpha `amt`, fade 0.1/frame — battle intro sting. `[VERIFIED]`
- Intro fall: `obj_introlast` scrolls a tall sprite part upward 1px/frame (the drop), alarm 150 then moves. `[VERIFIED]`
- Camera is fixed 640x480 with per-room camera snapping (no smooth scroll). `[RECALLED]`

**SoulHeart application note:** 3px/frame walk, 0.2 anim speed, depth-by-y, ~13f fade-out / ~20f fade-in, white flash for sting moments.

---

## 10. Title Screen & Name Entry

- Title phase (`naming==3`): draws "memories" silhouettes (Toriel/chairiel sleep, Papyrus, Sans, etc.) per story progress; version line `"UNDERTALE v1.08 (C) Toby Fox 2015-2017"` in `fnt_small` gray, **centered at (160, 232)**. `[VERIFIED]` (intromenu Draw_0)
- With a save: CONTINUE (x=85, y=105), RESET/TRUE RESET (x=195, y=105), SETTINGS (y=125); selected = `c_yellow`; save info: name (70,62), LV, time `time/1800 → MM:SS`, room name (70,80). `[VERIFIED]` (scr_namingscreen naming==3)
- Fresh game: instructions screen; "BEGIN" + SETTINGS at (85, 160/180), lines 18px apart, keys "Z - confirm / X - cancel / C - menu". `[VERIFIED]`
- **Name entry grid (EN):** 8 rows × 7 cols; x = `60 + col*32` (**32px pitch**), rows 0–3 at `75 + row*14`, rows 4–7 at `135 + (row-4)*14` (**14px line height**, two 4-row blocks); uppercase top block, lowercase bottom; selected char `c_yellow`, others white, drawn with ±0.5px jitter (`random(r)`). `[VERIFIED]` (scr_namingscreen_setup)
- Bottom row: QUIT/BACKSPACE/DONE at (60/120/220, 200); name preview at (140, 55); title "CHOOSE A NAME" centered y=30. `[VERIFIED]`
- Confirm dialog: "No/Yes" centered at (80,200) & (240,200), yellow selection. `[VERIFIED]`
- On confirm, name floats up & scales (scale `1 + q/50`, rotation jitter `random_ranger`) over ~180 frames → fades to game. `[VERIFIED]`
- Logo art sits at top of title screen `[RECALLED]`; heart/soul does not appear on title (Deltarune's does).

**SoulHeart application note:** name grid = 32px pitch × 14px lines in two blocks; 6-char limit; yellow selection + ±0.5px jitter; the float-up name transition. Title = memories + version text pattern.

---

## 11. Save Points

- `obj_savepoint` = the star, `image_speed 0.2` (gentle spin); interacting opens save menu (`global.menuno=4`). `[VERIFIED]`
- Save writes: name, LV ("Love"), total playtime `obj_time.time`, kills, room; `time/1800` → `MM:SS` for display. `[VERIFIED]` (scr_save, scr_namingscreen)
- Star has an idle "glow pulse" baked into its animation `[RECALLED]`; interacts show "SAVE" prompt text in yellow `[RECALLED]`.

**SoulHeart application note:** star anim at 0.2 speed; playtime in 1/1800 units (2 min = 1 unit) displayed as MM:SS.

---

## 12. Game Over

- On HP<=0: `audio_stop_all()`, `caster_stop/all` (music cut), capture heart position, `room_goto(room_gameover)`. `[VERIFIED]` (scr_gameoverb)
- Heart shatters (heartdefeated), messages vary by death count: first death fixed, subsequent: `100+floor(random(8))` (pacifist pool) or `200+floor(random(5))`, special 300 pool for a specific flag. `[VERIFIED]` (heartdefeated Alarm_3)
- "STAY DETERMINED" / "You can't give up just yet!" patterns `[RECALLED]` — message pools referenced by ids.

**SoulHeart application note:** hard music cut + heart-break anim + randomized message pools; keep the quiet after cut.

---

## 13. Sound → UI Mapping (verified names)

| Moment | Sound |
|---|---|
| Menu cursor move (battle + menus) | `snd_squeak` |
| Menu confirm / select | `snd_select` |
| Encounter "!" | `snd_noise` + `snd_b` |
| Text blip (battle) | `SND_TXT2` |
| Text blip (overworld) | `snd_txttor` |
| Player hurt | `snd_hurt1` |
| Heartshot | `snd_heartshot` |
| Level up | `snd_levelup` |
| Heal tick (armor) | `snd_power` |
| Impact (heart container) | `snd_impact` |

All `[VERIFIED]` from battlecontroller/dmgwriter/heart/battler/SCR_TEXTTYPE.

**SoulHeart application note:** the squeak/select pair IS the Undertale menu feel — keep them low-bitrate and short.

---

## 14. Deltarune Differences (brief)

- Same font family (8-Bit Operator) and same box/typing conventions. `[VERIFIED]` (Fonts In Use)
- Title screen shows the heart + "PRESS Z TO CONTINUE" `[RECALLED]`
- No FIGHT bars in chapter battles (bullets only), text box bottom-left, same 640x480. `[RECALLED]`
- Save points are glowing "SOUL" fountains; menu uses red/black theme. `[RECALLED]`

---

## 15. Area Background Tints (approximate, verify in-engine)

`[RECALLED]` — verify against screenshots; rooms tint via background color:
- Ruins: deep purple/magenta ~`#3f0b3f`–`#2b0a3a`
- Snowdin: cold blue ~`#1b2f45`–`#244766`
- Waterfall: teal-blue ~`#0f4a52`–`#115d74`
- Hotland: hot red-orange ~`#8f1313`–`#b22222`
- Core: violet ~`#3d0b8f`–`#5c1a99`
- New Home / Castle: dark gray-purple ~`#3b3b3b`–`#2e2a3a`

---

## 16. SoulHeart Implementation Checklist

1. **Fonts:** DMT-Mono (8-Bit Operator JVE clone) in two sizes (16/32 battle, 8/18 overworld) + tiny UI font; pixel snap on.
2. **Layout:** four battle zones with the exact rects from §2; enemies above y=250.
3. **Board:** edge sprites, 15px/frame edge easing, black-outside fill during enemy turns, border preset data.
4. **Dialog:** Typer node with voice→blip map (§4/§13), instant-skip on confirm, +20/+20 inset, wrap at right-55.
5. **Menu:** heart-cursor state machine, 32px rows, 2-col ACT, 4x2 ITEM, squeak/select.
6. **Feedback:** lime under-enemy bar at enemy width w/ lag drain; red 32px damage digits w/ float-gravity; vaporize/spare poofs; white hit flash; red screen flash + 2px shake on hurt.
7. **Player HUD:** yellow-on-red HP bar, 1.2px/HP, `XX / XX` padded, fnt_curs.
8. **Heart:** board clamp +4/-16, ~1s blink i-frames at 0.5 anim speed, 14f heartshot cooldown.
9. **Overworld:** 3px/frame walk, 0.2 anim speed, Y-depth sort, 13f/20f fades, white sting flash.
10. **Meta screens:** name grid 32x14 two blocks, 6-char limit, float-up name transition, save star at 0.2 anim, version-text pattern, game-over hard music cut + message pools.

---

*Primary sources: `code.undertale.wiki` decompiled v1.0 scripts (SCR_BORDERSETUP, SCR_TEXTTYPE, battlecontroller Step_0/Draw_0/KeyPress, scr_binfowrite, obj_dmgwriter, obj_heart Step_0, obj_bouncer, obj_uborder/dborder, scr_namingscreen(_setup), scr_monstersetup/battlegroup/monsterdefeat, obj_savepoint, obj_fader/flasher, scr_gameoverb); Fonts In Use (8-Bit Operator JVE attribution); Behance (Determination family). RECALLED items = gameplay knowledge to verify visually.*
