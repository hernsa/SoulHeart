class_name SectionMap extends RefCounted

# Edges: n/s/e/w. Returns:
#   {grid: Array[String], objects: Array, flavor: Array,
#    layout_meta: Dictionary, origins: Dictionary, sizes: Dictionary}
# On incompatible edge merge, returns {"error": String}.
static func compose(sections: Array, adjacency: Array) -> Dictionary:
    var by_id: Dictionary = {}
    for s in sections:
        by_id[s["id"]] = s

    # Default origins and sizes.
    var origins: Dictionary = {}
    var sizes: Dictionary = {}
    for s in sections:
        sizes[s["id"]] = _section_size(s)
        origins[s["id"]] = Vector2i(0, 0)

    # Place sections greedily in adjacency order; first section is anchor at (0,0).
    var placed: Dictionary = {}
    if sections.size() > 0:
        placed[sections[0]["id"]] = Vector2i(0, 0)
        origins[sections[0]["id"]] = Vector2i(0, 0)

    for link in adjacency:
        var a_id: String = link["a"]
        var b_id: String = link["b"]
        var side: String = link["side"]  # which side of A faces B
        if not placed.has(a_id):
            return {"error": "adjacency references unplaced section %s" % a_id}
        var a_size: Vector2i = sizes[a_id]
        var a_origin: Vector2i = placed[a_id]
        var b_size: Vector2i = sizes[b_id]
        var b_origin := _neighbor_origin(a_origin, a_size, b_size, side)
        if placed.has(b_id):
            # Validate that the existing placement matches the implied origin
            if placed[b_id] != b_origin:
                return {"error": "section %s already placed at %s, adjacency demands %s" % [b_id, placed[b_id], b_origin]}
        else:
            placed[b_id] = b_origin
            origins[b_id] = b_origin

    # Shift all origins so the composed graph starts at (0,0): the graph can
    # extend west/north of the anchor (pond west of the grove, ridge north of
    # the path), and the master grid cannot hold negative indices.
    var min_x := 0
    var min_y := 0
    for id in placed.keys():
        min_x = mini(min_x, placed[id].x)
        min_y = mini(min_y, placed[id].y)
    if min_x != 0 or min_y != 0:
        for id in placed.keys():
            placed[id] = placed[id] - Vector2i(min_x, min_y)
            origins[id] = placed[id]

    # Build master bounds.
    var max_x := 0
    var max_y := 0
    for id in placed.keys():
        var o: Vector2i = placed[id]
        var s: Vector2i = sizes[id]
        max_x = maxi(max_x, o.x + s.x)
        max_y = maxi(max_y, o.y + s.y)

    var grid: Array = []
    for y in max_y:
        var row := ""
        for x in max_x:
            row += "."
        grid.append(row)

    # Paint each section into master.
    for s in sections:
        var o: Vector2i = origins[s["id"]]
        var layout: Array = s["layout"]
        for ly in layout.size():
            var row: String = layout[ly]
            for lx in row.length():
                var ch: String = row[lx]
                var mx := o.x + lx
                var my := o.y + ly
                grid[my] = _set_cell(grid[my], mx, ch)

    # Validate edge merges for each adjacency: overlapping cells must agree or one is floor.
    for link in adjacency:
        var a_id: String = link["a"]
        var b_id: String = link["b"]
        var side: String = link["side"]
        var err: Variant = _validate_edge(origins, sizes, by_id, a_id, b_id, side)
        if err != null:
            return {"error": err}

    # Compose objects/flavor with master-coord remap.
    var objects: Array = []
    var flavor: Array = []
    for s in sections:
        var o: Vector2i = origins[s["id"]]
        if s.has("objects"):
            for obj in s["objects"]:
                var composed: Dictionary = obj.duplicate()
                var local: Vector2i = obj["cell"]
                composed["cell"] = Vector2i(o.x + local.x, o.y + local.y)
                composed["section_id"] = s["id"]
                objects.append(composed)
        if s.has("flavor"):
            for fl in s["flavor"]:
                var cfl: Dictionary = fl.duplicate()
                var lf: Vector2i = fl["cell"]
                cfl["cell"] = Vector2i(o.x + lf.x, o.y + lf.y)
                cfl["section_id"] = s["id"]
                flavor.append(cfl)

    # Pass-through extras per section.
    var layout_meta: Dictionary = {}
    for s in sections:
        var bag: Dictionary = {}
        if s.has("extras"):
            bag = (s["extras"] as Dictionary).duplicate(true)
        layout_meta[s["id"]] = bag

    return {
        "grid": grid,
        "objects": objects,
        "flavor": flavor,
        "layout_meta": layout_meta,
        "origins": origins,
        "sizes": sizes,
    }

static func _section_size(s: Dictionary) -> Vector2i:
    var layout: Array = s["layout"]
    var h := layout.size()
    var w := 0
    for row in layout:
        w = maxi(w, (row as String).length())
    return Vector2i(w, h)

static func _neighbor_origin(a_origin: Vector2i, a_size: Vector2i, b_size: Vector2i, side: String) -> Vector2i:
    match side:
        "e": return Vector2i(a_origin.x + a_size.x, a_origin.y)
        "w": return Vector2i(a_origin.x - b_size.x, a_origin.y)
        "s": return Vector2i(a_origin.x, a_origin.y + a_size.y)
        "n": return Vector2i(a_origin.x, a_origin.y - b_size.y)
    return a_origin

static func _set_cell(row: String, x: int, ch: String) -> String:
    var s := row
    while s.length() <= x:
        s += "."
    return s.substr(0, x) + ch + s.substr(x + 1)

static func _validate_edge(origins: Dictionary, sizes: Dictionary, by_id: Dictionary, a_id: String, b_id: String, side: String) -> Variant:
    # Sections are placed side-by-side WITHOUT overlap, so a master-grid overlap
    # check would never fire. Validate the facing edge cells of the two layouts
    # directly: a wall on one side facing floor on the other breaks the seam.
    var a_s: Vector2i = sizes[a_id]
    var b_s: Vector2i = sizes[b_id]
    var a_layout: Array = by_id[a_id]["layout"]
    var b_layout: Array = by_id[b_id]["layout"]
    match side:
        "e":
            for i in mini(a_s.y, b_s.y):
                var ac: String = (a_layout[i] as String)[a_s.x - 1]
                var bc: String = (b_layout[i] as String)[0]
                if (ac == "#") != (bc == "#"):
                    return "edge mismatch %s-%s at row %d: A '%s' vs B '%s'" % [a_id, b_id, i, ac, bc]
        "w":
            for i in mini(a_s.y, b_s.y):
                var ac: String = (a_layout[i] as String)[0]
                var bc: String = (b_layout[i] as String)[b_s.x - 1]
                if (ac == "#") != (bc == "#"):
                    return "edge mismatch %s-%s at row %d: A '%s' vs B '%s'" % [a_id, b_id, i, ac, bc]
        "s":
            for i in mini(a_s.x, b_s.x):
                var ac: String = (a_layout[a_s.y - 1] as String)[i]
                var bc: String = (b_layout[0] as String)[i]
                if (ac == "#") != (bc == "#"):
                    return "edge mismatch %s-%s at col %d: A '%s' vs B '%s'" % [a_id, b_id, i, ac, bc]
        "n":
            for i in mini(a_s.x, b_s.x):
                var ac: String = (a_layout[0] as String)[i]
                var bc: String = (b_layout[b_s.y - 1] as String)[i]
                if (ac == "#") != (bc == "#"):
                    return "edge mismatch %s-%s at col %d: A '%s' vs B '%s'" % [a_id, b_id, i, ac, bc]
    return null
