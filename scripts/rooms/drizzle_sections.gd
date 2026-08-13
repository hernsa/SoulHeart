class_name DrizzleSections extends RefCounted

# Adjacency: which side of `a` faces `b`. Composer places b accordingly.
#   e = b sits to the east (right) of a
#   s = b sits to the south (below) a
const ADJACENCY: Array = [
    {"a": "meadow",        "side": "n", "b": "wisp_grove"},
    {"a": "meadow",        "side": "w", "b": "pond_clearing"},
    {"a": "meadow",        "side": "e", "b": "snowledge"},
    {"a": "wisp_grove",    "side": "n", "b": "path_north"},
    {"a": "path_north",    "side": "n", "b": "grumbleridge"},
    {"a": "path_north",    "side": "e", "b": "puzzle_pocket"},
    {"a": "pond_clearing", "side": "s", "b": "creek_bend"},
    {"a": "creek_bend",    "side": "e", "b": "backwater"},
    {"a": "snowledge",     "side": "s", "b": "ringpath_east"},
]

# Sections. Layout chars: # wall, . floor. Walls and floors are the only
# characters the composer validates. Other characters copy through.
# Each section is intentionally small (8-18 cells per side) so the composer
# is doing real work stitching.

const SECTIONS: Array = [
    {
        "id": "meadow",
        "layout": [
            "..................",
            "..................",
            "..t........t......",
            "..................",
            "......t...........",
            "..................",
            "..........t.......",
            "..................",
            ".....t............",
            "..................",
            "......P...........",
            "..................",
            "..................",
            "..................",
        ],
        "objects": [
            {"type": "landmark", "cell": Vector2i(8, 3), "data": {"label": "the Lone Pine"}},
        ],
        "flavor": [
            {"kind": "tall_grass", "cell": Vector2i(4, 6)},
            {"kind": "tall_grass", "cell": Vector2i(13, 8)},
            {"kind": "old_boot",   "cell": Vector2i(11, 11)},
        ],
        "encounter_zone": "none",
        "extras": {"tone": "warm, safe"},
    },
    {
        "id": "wisp_grove",
"layout": [
			"d.d.d",
			"d...d",
            "d.W.d",
            "d.S.d",
            "d...d",
"d..dd",
			"d.d.d",
		],
        "objects": [
            {"type": "save",    "cell": Vector2i(2, 3), "data": {}},
            {"type": "npc",     "cell": Vector2i(2, 2), "data": {"id": "wisp"}},
            {"type": "landmark","cell": Vector2i(2, 1), "data": {"label": "wisp cluster"}},
        ],
        "flavor": [
            {"kind": "stick_circle", "cell": Vector2i(1, 5)},
        ],
        "encounter_zone": "none",
        "extras": {"tone": "quiet wonder"},
    },
    {
        "id": "path_north",
"layout": [
			"#t.t#",
			"t...t",
			"t...t",
			"t...t",
			"t...t",
			"t..t.",
            "t...t",
            "t...t",
            "t...t",
            "t...t",
            "t...t",
            "t...t",
        ],
        "objects": [
            {"type": "landmark", "cell": Vector2i(2, 5), "data": {"label": "fallen-log arch"}},
        ],
        "flavor": [
            {"kind": "snapped_branch", "cell": Vector2i(1, 7)},
        ],
        "encounter_zone": "light",
        "extras": {"tone": "hushed"},
    },
    {
        "id": "grumbleridge",
        "layout": [
            "############",
            "#..........#",
            "#..........#",
            "#....R.....#",
            "#..........#",
            "#..........#",
            "#....E.....#",
            "#...########",
        ],
        "objects": [
            {"type": "exit",    "cell": Vector2i(5, 6), "data": {"target": "res://scenes/rooms/GrumbleWoods.tscn", "target_spawn": Vector2(520, 392)}},
            {"type": "landmark","cell": Vector2i(5, 3), "data": {"label": "ridge sign"}},
        ],
        "flavor": [
            {"kind": "rock_pile", "cell": Vector2i(2, 4)},
            {"kind": "rock_pile", "cell": Vector2i(8, 4)},
        ],
        "encounter_zone": "light",
        "extras": {"tone": "stoic"},
    },
    {
        "id": "pond_clearing",
        "layout": [
            "................",
            "..tt......tt....",
            ".t..t....t..t...",
            ".t..........t...",
            "..sss....sss....",
            "...s......s.....",
            "...s......s.....",
            "..sss....sss....",
            ".t..t....t..t...",
            ".t..t....t..t...",
            "..tt......tt....",
            "................",
        ],
        "objects": [
            {"type": "encounter", "cell": Vector2i(4, 2), "data": {}},
            {"type": "encounter", "cell": Vector2i(11, 2), "data": {}},
            {"type": "landmark",  "cell": Vector2i(8, 6), "data": {"label": "the stone crossing"}},
        ],
        "flavor": [
            {"kind": "cattail", "cell": Vector2i(2, 1)},
            {"kind": "cattail", "cell": Vector2i(13, 10)},
        ],
        "encounter_zone": "normal",
        "extras": {"tone": "airy, playful"},
    },
    {
        "id": "creek_bend",
        "layout": [
            "....",
            ".ss.",
            ".ss.",
            "....",
            ".ss.",
            "....",
        ],
        "objects": [
            {"type": "landmark", "cell": Vector2i(1, 3), "data": {"label": "the bend stone"}},
        ],
        "flavor": [
            {"kind": "tall_grass", "cell": Vector2i(0, 0)},
            {"kind": "tall_grass", "cell": Vector2i(3, 0)},
            {"kind": "tall_grass", "cell": Vector2i(0, 5)},
            {"kind": "tall_grass", "cell": Vector2i(3, 5)},
        ],
        "encounter_zone": "none",
        "extras": {"tone": "serene", "gameplay": "none"},
    },
    {
        "id": "backwater",
        "layout": [
            "............",
            ".t........t.",
            "..ss....ss..",
            "..ss....ss..",
            "....ss......",
            "............",
        ],
        "objects": [],
        "flavor": [
            {"kind": "cattail",   "cell": Vector2i(2, 0)},
            {"kind": "cattail",   "cell": Vector2i(9, 0)},
            {"kind": "tall_grass","cell": Vector2i(5, 5)},
            {"kind": "old_boot",  "cell": Vector2i(8, 4)},
        ],
        "encounter_zone": "none",
        "extras": {"tone": "hushed water", "gameplay": "none"},
    },
    {
        "id": "snowledge",
        "layout": [
            ".d..d",
            "d..d.",
            ".d..d",
            "d..d.",
            ".d..d",
            "d..d.",
            ".d..d",
            "d..d.",
            ".d..d",
            "d..d.",
            ".d..d",
            "d..E.",
            ".d..d",
            "d..d.",
        ],
        "objects": [
            {"type": "exit",     "cell": Vector2i(3, 11), "data": {"target": "res://scenes/rooms/Snowdin.tscn", "target_spawn": Vector2(520, 32)}},
            {"type": "landmark", "cell": Vector2i(3, 2),  "data": {"label": "gate glimpse"}},
        ],
        "flavor": [
            {"kind": "pine_cone", "cell": Vector2i(0, 6)},
        ],
        "encounter_zone": "none",
        "extras": {"tone": "anticipatory"},
    },
    {
        "id": "ringpath_east",
        "layout": [
            "t..t",
            "....",
            "t...",
            "....",
            "...t",
            "....",
            "t..t",
            "....",
            "t...",
            "....",
        ],
        "objects": [
            {"type": "landmark", "cell": Vector2i(1, 3), "data": {"label": "old root arch"}},
            {"type": "encounter","cell": Vector2i(2, 5), "data": {}},
        ],
        "flavor": [
            {"kind": "gnarled_root", "cell": Vector2i(0, 2)},
        ],
        "encounter_zone": "light",
        "extras": {"tone": "muted"},
    },
    {
        "id": "puzzle_pocket",
        "layout": [
            "#.......",
            ".d....d.",
            ".d....d.",
            ".d.P..d.",
            ".d....d.",
            ".d....d.",
            ".d....d.",
            "........",
        ],
        "objects": [
            {"type": "landmark", "cell": Vector2i(3, 3), "data": {"label": "the stone gap"}},
        ],
        "flavor": [
            {"kind": "withered_flower", "cell": Vector2i(1, 1)},
        ],
        "encounter_zone": "none",
        "extras": {"tone": "mysterious"},
    },
]