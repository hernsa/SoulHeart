extends RefCounted

const REQUIRED_LABELS := [
	"the Lone Pine",
	"wisp cluster",
	"fallen-log arch",
	"ridge sign",
	"the stone crossing",
	"the bend stone",
	"gate glimpse",
	"old root arch",
	"the stone gap",
]

func test_all_nine_landmarks_present() -> void:
	var composed: Dictionary = SectionMap.compose(DrizzleSections.SECTIONS, DrizzleSections.ADJACENCY)
	var labels: Dictionary = {}
	for obj in composed["objects"]:
		if obj["type"] == "landmark":
			labels[obj["data"]["label"]] = true
	for label in REQUIRED_LABELS:
		TestHelper.is_true(labels.has(label), "landmark label present: %s" % label)

func test_landmark_cells_not_solid() -> void:
	var composed: Dictionary = SectionMap.compose(DrizzleSections.SECTIONS, DrizzleSections.ADJACENCY)
	var grid: Array = composed["grid"]
	for obj in composed["objects"]:
		if obj["type"] == "landmark":
			var c: Vector2i = obj["cell"]
			var ch: String = (grid[c.y] as String)[c.x]
			var msg := "landmark '%s' at %s on non-solid cell, got '%s'" % [obj["data"]["label"], c, ch]
			TestHelper.is_true(ch != "#" and ch != "t" and ch != "T" and ch != "b" and ch != "d", msg)