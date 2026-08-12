class_name GameTiles

enum Tile { FLOOR = 0, WALL = 1, TREE = 2, PINE2 = 3, BIRCH = 4, DEAD = 5, BUSH = 6, MUSHROOM = 7, GRASS = 8 }

const RUINS_STYLE := "ruins"
const SNOWDIN_STYLE := "snowdin"
const ECHO_STYLE := "echo"
const HOMETOWN_STYLE := "hometown"
const CANON_STYLE := "canon"
const CRACKS_STYLE := "cracks"

const AREA_STYLES: Array[String] = [
	RUINS_STYLE, SNOWDIN_STYLE, ECHO_STYLE, HOMETOWN_STYLE, CANON_STYLE, CRACKS_STYLE,
]

const FLOOR_A := Vector2i(0, 0)
const FLOOR_B := Vector2i(1, 0)
const WALL_TILE := Vector2i(2, 0)

static func build_tileset(style: String) -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	var src := TileSetAtlasSource.new()
	src.texture = _atlas_texture(style)
	src.texture_region_size = Vector2i(16, 16)
	src.create_tile(FLOOR_A)
	src.create_tile(FLOOR_B)
	src.create_tile(WALL_TILE)
	ts.add_source(src, 0)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 1)
	var wall_data := src.get_tile_data(WALL_TILE, 0)
	wall_data.add_collision_polygon(0)
	wall_data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(0, 0), Vector2(16, 0), Vector2(16, 16), Vector2(0, 16)]))
	return ts

static func _atlas_texture(style: String) -> Texture2D:
	var img := Image.create(48, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var a := load("res://assets/sprites/tiles/%s_floor.png" % style) as Texture2D
	if a != null:
		var a_img := a.get_image()
		a_img.convert(Image.FORMAT_RGBA8)
		img.blit_rect(a_img, Rect2i(0, 0, 16, 16), Vector2i.ZERO)
	var b := load("res://assets/sprites/tiles/%s_floor_b.png" % style) as Texture2D
	if b != null:
		var b_img := b.get_image()
		b_img.convert(Image.FORMAT_RGBA8)
		img.blit_rect(b_img, Rect2i(0, 0, 16, 16), Vector2i(16, 0))
	return ImageTexture.create_from_image(img)
