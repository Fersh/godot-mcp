extends Node2D
## Modular tile-based background system using forest_tileset.png
## Replaces the static arena background with procedurally generated tiles
## Can be easily swapped back to original background via toggle

const TILE_SIZE: int = 32
const TILESET_PATH: String = "res://assets/enviro/forest_tileset.png"

# Arena dimensions in tiles (matches original arena ~1536x1100 play area)
@export var arena_width_tiles: int = 48
@export var arena_height_tiles: int = 35

# Border thickness for darker grass (in tiles)
@export var border_thickness: int = 4

# Decoration density (0.0 to 1.0)
@export var decoration_density: float = 0.15

# Random seed for reproducible generation (0 = random each time)
@export var generation_seed: int = 0

# Tile regions from forest_tileset.png
# Grid coordinates provided by user, converted to pixels (* 32)
# (3,4) = grass center at (96, 128), (6,4) = field center at (192, 128)

# Light field tiles (center area) - grid (6,4) and surroundings
# Center tile
var light_grass_tiles: Array[Rect2i] = [
	Rect2i(192, 128, 32, 32),  # (6,4) - field center
]

# Dark grass tiles (border area) - grid (3,4)
var dark_grass_tiles: Array[Rect2i] = [
	Rect2i(96, 128, 32, 32),   # (3,4) - grass center
]

# Edge tiles for the OUTER border of the arena (grass edges)
# These go around (3,4) - the grass tile
var outer_edge_tiles: Dictionary = {
	"top": Rect2i(96, 96, 32, 32),         # (3,3) - top edge
	"bottom": Rect2i(96, 160, 32, 32),     # (3,5) - bottom edge
	"left": Rect2i(64, 128, 32, 32),       # (2,4) - left edge
	"right": Rect2i(128, 128, 32, 32),     # (4,4) - right edge
	"top_left": Rect2i(64, 96, 32, 32),    # (2,3) - top-left corner
	"top_right": Rect2i(128, 96, 32, 32),  # (4,3) - top-right corner
	"bottom_left": Rect2i(64, 160, 32, 32),    # (2,5) - bottom-left corner
	"bottom_right": Rect2i(128, 160, 32, 32),  # (4,5) - bottom-right corner
}

# Edge tiles for transition from dark grass to light field
# These go around (6,4) - the field tile (showing grass-to-field transition)
var inner_edge_tiles: Dictionary = {
	"top": Rect2i(192, 96, 32, 32),         # (6,3) - top edge of field
	"bottom": Rect2i(192, 160, 32, 32),     # (6,5) - bottom edge
	"left": Rect2i(160, 128, 32, 32),       # (5,4) - left edge
	"right": Rect2i(224, 128, 32, 32),      # (7,4) - right edge
	"top_left": Rect2i(160, 96, 32, 32),    # (5,3) - top-left corner
	"top_right": Rect2i(224, 96, 32, 32),   # (7,3) - top-right corner
	"bottom_left": Rect2i(160, 160, 32, 32),    # (5,5) - bottom-left corner
	"bottom_right": Rect2i(224, 160, 32, 32),   # (7,5) - bottom-right corner
}

# Decorative elements - these are scattered sprites in lower portion
# Approximate positions based on visual inspection
var decoration_tiles: Array[Dictionary] = [
	# Small rocks/stones (around y=512-544 area)
	{"rect": Rect2i(256, 512, 24, 16), "type": "rock_small"},
	{"rect": Rect2i(288, 512, 32, 24), "type": "rock_medium"},
	{"rect": Rect2i(336, 512, 40, 24), "type": "rock_large"},
	# Grass tufts/bushes
	{"rect": Rect2i(384, 512, 24, 24), "type": "grass_tuft"},
	{"rect": Rect2i(416, 512, 24, 24), "type": "bush_small"},
	{"rect": Rect2i(448, 512, 32, 24), "type": "bush_brown"},
]

# Tree decorations for corners
var tree_tiles: Array[Dictionary] = [
	{"rect": Rect2i(352, 384, 32, 56), "type": "pine_small"},
	{"rect": Rect2i(416, 384, 40, 56), "type": "tree_green"},
]

var tileset_texture: Texture2D
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Store generated tile data for potential regeneration
var generated_tiles: Array = []
var decoration_sprites: Array[Sprite2D] = []

func _ready() -> void:
	z_index = -10  # Same as original background
	_load_tileset()
	generate_arena()

func _load_tileset() -> void:
	tileset_texture = load(TILESET_PATH)
	if not tileset_texture:
		push_error("TileBackground: Failed to load tileset from " + TILESET_PATH)

func generate_arena() -> void:
	"""Generate the complete arena floor with tiles."""
	if not tileset_texture:
		return

	# Initialize RNG
	if generation_seed != 0:
		rng.seed = generation_seed
	else:
		rng.randomize()

	# Clear existing tiles
	_clear_tiles()

	# Calculate arena offset to center it (similar to original background position)
	var arena_pixel_width = arena_width_tiles * TILE_SIZE
	var arena_pixel_height = arena_height_tiles * TILE_SIZE
	var offset_x = (1536 - arena_pixel_width) / 2  # Center horizontally
	var offset_y = 285  # Start below the top wall area

	# Generate floor tiles
	for y in range(arena_height_tiles):
		for x in range(arena_width_tiles):
			var tile_pos = Vector2(offset_x + x * TILE_SIZE, offset_y + y * TILE_SIZE)
			var tile_type = _determine_tile_type(x, y)
			var tile_rect = _get_tile_rect(tile_type, x, y)
			_create_tile_sprite(tile_pos, tile_rect, tile_type)

	# Add decorations around edges
	_generate_decorations(offset_x, offset_y)

func _determine_tile_type(x: int, y: int) -> String:
	"""Determine what type of tile should be at this position."""
	var max_x = arena_width_tiles - 1
	var max_y = arena_height_tiles - 1

	# Outer edge (row/col 0 or last) - arena boundary
	var at_left_edge = x == 0
	var at_right_edge = x == max_x
	var at_top_edge = y == 0
	var at_bottom_edge = y == max_y

	# Outer corners
	if at_top_edge and at_left_edge:
		return "outer_top_left"
	elif at_top_edge and at_right_edge:
		return "outer_top_right"
	elif at_bottom_edge and at_left_edge:
		return "outer_bottom_left"
	elif at_bottom_edge and at_right_edge:
		return "outer_bottom_right"

	# Outer edges
	if at_top_edge:
		return "outer_top"
	elif at_bottom_edge:
		return "outer_bottom"
	elif at_left_edge:
		return "outer_left"
	elif at_right_edge:
		return "outer_right"

	# Check if in dark grass border zone (between outer edge and inner transition)
	var in_left_border = x < border_thickness
	var in_right_border = x > max_x - border_thickness
	var in_top_border = y < border_thickness
	var in_bottom_border = y > max_y - border_thickness

	# Inner transition edge (where dark grass meets light field)
	var at_inner_left = x == border_thickness
	var at_inner_right = x == max_x - border_thickness
	var at_inner_top = y == border_thickness
	var at_inner_bottom = y == max_y - border_thickness

	# Inner corners
	if at_inner_top and at_inner_left:
		return "inner_top_left"
	elif at_inner_top and at_inner_right:
		return "inner_top_right"
	elif at_inner_bottom and at_inner_left:
		return "inner_bottom_left"
	elif at_inner_bottom and at_inner_right:
		return "inner_bottom_right"

	# Inner edges
	if at_inner_top and not in_left_border and not in_right_border:
		return "inner_top"
	elif at_inner_bottom and not in_left_border and not in_right_border:
		return "inner_bottom"
	elif at_inner_left and not in_top_border and not in_bottom_border:
		return "inner_left"
	elif at_inner_right and not in_top_border and not in_bottom_border:
		return "inner_right"

	# Dark grass border (between outer edge and inner edge)
	if in_left_border or in_right_border or in_top_border or in_bottom_border:
		return "dark_grass"

	# Center (light field)
	return "light_grass"

func _get_tile_rect(tile_type: String, _x: int, _y: int) -> Rect2i:
	"""Get the tileset region for the given tile type."""
	match tile_type:
		# Center tiles
		"light_grass":
			return light_grass_tiles[0]
		"dark_grass":
			return dark_grass_tiles[0]

		# Outer edge tiles (arena boundary)
		"outer_top":
			return outer_edge_tiles["top"]
		"outer_bottom":
			return outer_edge_tiles["bottom"]
		"outer_left":
			return outer_edge_tiles["left"]
		"outer_right":
			return outer_edge_tiles["right"]
		"outer_top_left":
			return outer_edge_tiles["top_left"]
		"outer_top_right":
			return outer_edge_tiles["top_right"]
		"outer_bottom_left":
			return outer_edge_tiles["bottom_left"]
		"outer_bottom_right":
			return outer_edge_tiles["bottom_right"]

		# Inner edge tiles (dark grass to light field transition)
		"inner_top":
			return inner_edge_tiles["top"]
		"inner_bottom":
			return inner_edge_tiles["bottom"]
		"inner_left":
			return inner_edge_tiles["left"]
		"inner_right":
			return inner_edge_tiles["right"]
		"inner_top_left":
			return inner_edge_tiles["top_left"]
		"inner_top_right":
			return inner_edge_tiles["top_right"]
		"inner_bottom_left":
			return inner_edge_tiles["bottom_left"]
		"inner_bottom_right":
			return inner_edge_tiles["bottom_right"]

	# Default to light grass
	return light_grass_tiles[0]

func _create_tile_sprite(pos: Vector2, region: Rect2i, _tile_type: String = "light_grass") -> void:
	"""Create a sprite for a single tile."""
	var sprite = Sprite2D.new()
	sprite.texture = tileset_texture
	sprite.region_enabled = true
	sprite.region_rect = Rect2(region)
	sprite.position = pos + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)  # Center the sprite
	sprite.z_index = -10
	add_child(sprite)
	generated_tiles.append(sprite)

func _generate_decorations(offset_x: float, offset_y: float) -> void:
	"""Add decorative elements around the arena edges."""
	var decoration_zone = border_thickness - 1  # Place decorations in outer border area

	# Top edge decorations
	_place_edge_decorations(offset_x, offset_y, arena_width_tiles, decoration_zone, "horizontal")

	# Bottom edge decorations
	var bottom_y = offset_y + (arena_height_tiles - decoration_zone) * TILE_SIZE
	_place_edge_decorations(offset_x, bottom_y, arena_width_tiles, decoration_zone, "horizontal")

	# Left edge decorations
	_place_edge_decorations(offset_x, offset_y + border_thickness * TILE_SIZE, decoration_zone, arena_height_tiles - border_thickness * 2, "vertical")

	# Right edge decorations
	var right_x = offset_x + (arena_width_tiles - decoration_zone) * TILE_SIZE
	_place_edge_decorations(right_x, offset_y + border_thickness * TILE_SIZE, decoration_zone, arena_height_tiles - border_thickness * 2, "vertical")

	# Corner trees
	_place_corner_decorations(offset_x, offset_y)

func _place_edge_decorations(start_x: float, start_y: float, width_tiles: int, height_tiles: int, orientation: String) -> void:
	"""Place random decorations along an edge."""
	var tiles_to_check = width_tiles if orientation == "horizontal" else height_tiles

	for i in range(tiles_to_check):
		if rng.randf() > decoration_density:
			continue

		var decoration = decoration_tiles[rng.randi() % decoration_tiles.size()]
		var sprite = Sprite2D.new()
		sprite.texture = tileset_texture
		sprite.region_enabled = true
		sprite.region_rect = Rect2(decoration["rect"])

		var pos: Vector2
		if orientation == "horizontal":
			pos = Vector2(
				start_x + i * TILE_SIZE + rng.randf_range(0, TILE_SIZE),
				start_y + rng.randf_range(0, height_tiles * TILE_SIZE)
			)
		else:
			pos = Vector2(
				start_x + rng.randf_range(0, width_tiles * TILE_SIZE),
				start_y + i * TILE_SIZE + rng.randf_range(0, TILE_SIZE)
			)

		sprite.position = pos
		sprite.z_index = -9  # Slightly above floor tiles
		add_child(sprite)
		decoration_sprites.append(sprite)

func _place_corner_decorations(offset_x: float, offset_y: float) -> void:
	"""Place larger decorations (trees) in corners."""
	var corners = [
		Vector2(offset_x + TILE_SIZE, offset_y + TILE_SIZE),  # Top-left
		Vector2(offset_x + (arena_width_tiles - 2) * TILE_SIZE, offset_y + TILE_SIZE),  # Top-right
		Vector2(offset_x + TILE_SIZE, offset_y + (arena_height_tiles - 3) * TILE_SIZE),  # Bottom-left
		Vector2(offset_x + (arena_width_tiles - 2) * TILE_SIZE, offset_y + (arena_height_tiles - 3) * TILE_SIZE),  # Bottom-right
	]

	for corner_pos in corners:
		if rng.randf() < 0.7:  # 70% chance for corner tree
			var tree = tree_tiles[rng.randi() % tree_tiles.size()]
			var sprite = Sprite2D.new()
			sprite.texture = tileset_texture
			sprite.region_enabled = true
			sprite.region_rect = Rect2(tree["rect"])
			sprite.position = corner_pos + Vector2(rng.randf_range(-16, 16), rng.randf_range(-16, 16))
			sprite.z_index = -8  # Above decorations
			add_child(sprite)
			decoration_sprites.append(sprite)

func _clear_tiles() -> void:
	"""Remove all generated tiles and decorations."""
	for tile in generated_tiles:
		if is_instance_valid(tile):
			tile.queue_free()
	generated_tiles.clear()

	for decoration in decoration_sprites:
		if is_instance_valid(decoration):
			decoration.queue_free()
	decoration_sprites.clear()

func regenerate(new_seed: int = 0) -> void:
	"""Regenerate the arena with a new seed."""
	generation_seed = new_seed
	generate_arena()

func set_visible_tiles(visible: bool) -> void:
	"""Toggle visibility of the tile background."""
	for tile in generated_tiles:
		if is_instance_valid(tile):
			tile.visible = visible
	for decoration in decoration_sprites:
		if is_instance_valid(decoration):
			decoration.visible = visible
