from PIL import Image
import sys, os

CHECKS = [
    ("assets/sprites/overworld/frisk_sheet.png", (57, 116), True),  # transparent
    ("assets/sprites/tiles/ruins_floor.png", (16, 16), False),
    ("assets/sprites/tiles/ruins_floor_b.png", (16, 16), False),
    ("assets/sprites/tiles/snowdin_floor.png", (16, 16), False),
    ("assets/sprites/tiles/snowdin_floor_b.png", (16, 16), False),
    ("assets/sprites/overworld/tree_pine.png", None, True),  # any size, transparent
    ("assets/sprites/shadow_ellipse.png", (16, 4), True),
]

failed = False
for path, expected_size, must_be_transparent in CHECKS:
    if not os.path.exists(path):
        print(f"MISSING: {path}")
        failed = True
        continue
    img = Image.open(path).convert("RGBA")
    if expected_size and img.size != expected_size:
        print(f"WRONG SIZE: {path} got {img.size}, expected {expected_size}")
        failed = True
        continue
    if must_be_transparent:
        # Check corners are transparent
        w, h = img.size
        corners = [(0,0), (w-1,0), (0,h-1), (w-1,h-1)]
        for x, y in corners:
            if img.getpixel((x,y))[3] != 0:
                print(f"OPAQUE CORNER: {path} at ({x},{y})")
                failed = True
                break

# ---- frisk_sheet content gates: 4 rows x 3 cols of 19x29, body pixels per cell ----
FRISK = "assets/sprites/overworld/frisk_sheet.png"
if os.path.exists(FRISK):
    img = Image.open(FRISK).convert("RGBA")
    w, h = img.size
    if (w, h) != (57, 116):
        print(f"FRISK SHEET SIZE: got {(w, h)}, expected (57, 116)")
        failed = True
    else:
        for row in range(4):
            for col in range(3):
                x0, y0 = col * 19, row * 29
                found = False
                # body pixels must exist in the lower 2/3 (rows 10-28) so a
                # head-only or quartered sprite fails
                for y in range(10, 29):
                    if found:
                        break
                    for x in range(x0, x0 + 19):
                        if img.getpixel((x, y0 + y))[3] > 0:
                            found = True
                            break
                if not found:
                    print(f"FRISK CELL EMPTY: row {row} col {col} has no body pixels")
                    failed = True

# ---- floor seamless gates (left==right && top==bottom, pixel-exact) ----
for path in [
    "assets/sprites/tiles/ruins_floor.png",
    "assets/sprites/tiles/ruins_floor_b.png",
    "assets/sprites/tiles/snowdin_floor.png",
    "assets/sprites/tiles/snowdin_floor_b.png",
]:
    if not os.path.exists(path):
        continue
    img = Image.open(path).convert("RGBA")
    if img.size != (16, 16):
        continue
    px = img.load()
    for y in range(16):
        if px[0, y] != px[15, y]:
            print(f"FLOOR SEAM X: {path} row {y} left != right")
            failed = True
            break
    for x in range(16):
        if px[x, 0] != px[x, 15]:
            print(f"FLOOR SEAM Y: {path} col {x} top != bottom")
            failed = True
            break

# ---- tree_pine structure: brown trunk at bottom center, dark-green canopy ----
TREE = "assets/sprites/overworld/tree_pine.png"
if os.path.exists(TREE):
    img = Image.open(TREE).convert("RGBA")
    w, h = img.size
    px = img.load()
    trunk = False
    canopy = False
    for x in range(w):
        for y in range(h):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if r > g and r > b and 40 < r < 160:  # brownish
                trunk = True
            if g > r and g > b and g < 200:        # greenish
                canopy = True
    if not trunk:
        print("TREE MISSING TRUNK: no brown trunk pixels")
        failed = True
    if not canopy:
        print("TREE MISSING CANOPY: no green canopy pixels")
        failed = True

# ---- shadow_ellipse: black with center alpha ~40-70% and transparent corners ----
SHADOW = "assets/sprites/shadow_ellipse.png"
if os.path.exists(SHADOW):
    img = Image.open(SHADOW).convert("RGBA")
    px = img.load()
    center_alpha = [px[7, y][3] for y in (1, 2)]
    if not (40 <= max(center_alpha) <= 70):
        print(f"SHADOW ALPHA: center alpha {center_alpha}, expected ~40-70")
        failed = True

# Enemy frame opaque-black-bg check (kept for B2 verification)
ENEMY_FRAMES_DIR = "assets/sprites/enemies/frames"
if os.path.isdir(ENEMY_FRAMES_DIR):
    for enemy_id in os.listdir(ENEMY_FRAMES_DIR):
        edir = os.path.join(ENEMY_FRAMES_DIR, enemy_id)
        if not os.path.isdir(edir): continue
        for fname in os.listdir(edir):
            if not fname.endswith(".png"): continue
            fpath = os.path.join(edir, fname)
            img = Image.open(fpath).convert("RGBA")
            corner = img.getpixel((0,0))
            if corner[:3] != (0,0,0) or corner[3] != 255:
                print(f"ENEMY FRAME NOT BLACK-BG: {fpath}")
                failed = True

print("PASS" if not failed else "FAIL")
sys.exit(1 if failed else 0)
