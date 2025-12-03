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
# Grid coordinates converted to pixels (* 32)

# ============================================
# LIGHT FIELD TILES (center area)
# ============================================
# Main: (6,4) and variants with smidges for diversity
var light_field_tiles: Array[Rect2i] = [
	Rect2i(192, 128, 32, 32),  # (6,4) - field center (clean)
	Rect2i(192, 448, 32, 32),  # (6,14) - field with smidge
	Rect2i(224, 448, 32, 32),  # (7,14) - field variant
	Rect2i(256, 448, 32, 32),  # (8,14) - field variant
	Rect2i(288, 448, 32, 32),  # (9,14) - field variant
	Rect2i(192, 480, 32, 32),  # (6,15) - field variant
	Rect2i(224, 480, 32, 32),  # (7,15) - field variant
	Rect2i(256, 480, 32, 32),  # (8,15) - field variant
]

# ============================================
# DARK GRASS TILES (border area)
# ============================================
# Main: (3,4) grass and (9,4) dark grass surrounded by light field
var dark_grass_tiles: Array[Rect2i] = [
	Rect2i(96, 128, 32, 32),   # (3,4) - grass center
	Rect2i(288, 128, 32, 32),  # (9,4) - dark grass (surrounded by light field)
]

# ============================================
# SPECIAL ACCENT TILES
# ============================================
# (3,1) = grass surrounded by dirt - for occasional dirt patches
var grass_dirt_center: Rect2i = Rect2i(96, 32, 32, 32)  # (3,1)
var grass_dirt_edges: Dictionary = {
	"top": Rect2i(96, 0, 32, 32),       # (3,0)
	"bottom": Rect2i(96, 64, 32, 32),   # (3,2)
	"left": Rect2i(64, 32, 32, 32),     # (2,1)
	"right": Rect2i(128, 32, 32, 32),   # (4,1)
	"top_left": Rect2i(64, 0, 32, 32),      # (2,0)
	"top_right": Rect2i(128, 0, 32, 32),    # (4,0)
	"bottom_left": Rect2i(64, 64, 32, 32),  # (2,2)
	"bottom_right": Rect2i(128, 64, 32, 32), # (4,2)
}

# (6,1) = dirt surrounded by grass - for dirt patches in grass
var dirt_grass_center: Rect2i = Rect2i(192, 32, 32, 32)  # (6,1)
var dirt_grass_edges: Dictionary = {
	"top": Rect2i(192, 0, 32, 32),       # (6,0)
	"bottom": Rect2i(192, 64, 32, 32),   # (6,2)
	"left": Rect2i(160, 32, 32, 32),     # (5,1)
	"right": Rect2i(224, 32, 32, 32),    # (7,1)
	"top_left": Rect2i(160, 0, 32, 32),      # (5,0)
	"top_right": Rect2i(224, 0, 32, 32),     # (7,0)
	"bottom_left": Rect2i(160, 64, 32, 32),  # (5,2)
	"bottom_right": Rect2i(224, 64, 32, 32), # (7,2)
}

# (4,18) = tall yellow grass with corners
var yellow_grass_center: Rect2i = Rect2i(128, 576, 32, 32)  # (4,18)
var yellow_grass_edges: Dictionary = {
	"top": Rect2i(128, 544, 32, 32),      # (4,17)
	"bottom": Rect2i(128, 608, 32, 32),   # (4,19)
	"left": Rect2i(96, 576, 32, 32),      # (3,18)
	"right": Rect2i(160, 576, 32, 32),    # (5,18)
	"top_left": Rect2i(96, 544, 32, 32),      # (3,17)
	"top_right": Rect2i(160, 544, 32, 32),    # (5,17)
	"bottom_left": Rect2i(96, 608, 32, 32),   # (3,19)
	"bottom_right": Rect2i(160, 608, 32, 32), # (5,19)
}

# (1,24) = tall green grass - decoration that can go anywhere
var tall_green_grass: Rect2i = Rect2i(32, 768, 32, 32)  # (1,24)

# ============================================
# EDGE TILES FOR ARENA BOUNDARY
# ============================================
# Outer edges around (3,4) - the grass tile boundary
var outer_edge_tiles: Dictionary = {
	"top": Rect2i(96, 96, 32, 32),         # (3,3)
	"bottom": Rect2i(96, 160, 32, 32),     # (3,5)
	"left": Rect2i(64, 128, 32, 32),       # (2,4)
	"right": Rect2i(128, 128, 32, 32),     # (4,4)
	"top_left": Rect2i(64, 96, 32, 32),    # (2,3)
	"top_right": Rect2i(128, 96, 32, 32),  # (4,3)
	"bottom_left": Rect2i(64, 160, 32, 32),    # (2,5)
	"bottom_right": Rect2i(128, 160, 32, 32),  # (4,5)
}

# Inner edges around (9,4) - dark grass to light field transition
var inner_edge_tiles: Dictionary = {
	"top": Rect2i(288, 96, 32, 32),         # (9,3)
	"bottom": Rect2i(288, 160, 32, 32),     # (9,5)
	"left": Rect2i(256, 128, 32, 32),       # (8,4)
	"right": Rect2i(320, 128, 32, 32),      # (10,4)
	"top_left": Rect2i(256, 96, 32, 32),    # (8,3)
	"top_right": Rect2i(320, 96, 32, 32),   # (10,3)
	"bottom_left": Rect2i(256, 160, 32, 32),    # (8,5)
	"bottom_right": Rect2i(320, 160, 32, 32),   # (10,5)
}

# Alias for backward compatibility
var light_grass_tiles: Array[Rect2i]:
	get: return light_field_tiles

# Decorative elements - scattered in the arena for visual interest
var decoration_tiles: Array[Dictionary] = [
	# Tall green grass (1,24) - can go anywhere
	{"rect": Rect2i(32, 768, 32, 32), "type": "tall_green_grass"},

	# Small objects starting at (6,19), 2 rows down, 8 tiles right
	# Row 19 (y=608)
	{"rect": Rect2i(192, 608, 32, 32), "type": "object_6_19"},
	{"rect": Rect2i(224, 608, 32, 32), "type": "object_7_19"},
	{"rect": Rect2i(256, 608, 32, 32), "type": "object_8_19"},
	{"rect": Rect2i(288, 608, 32, 32), "type": "object_9_19"},
	{"rect": Rect2i(320, 608, 32, 32), "type": "object_10_19"},
	{"rect": Rect2i(352, 608, 32, 32), "type": "object_11_19"},
	{"rect": Rect2i(384, 608, 32, 32), "type": "object_12_19"},
	{"rect": Rect2i(416, 608, 32, 32), "type": "object_13_19"},
	# Row 20 (y=640)
	{"rect": Rect2i(192, 640, 32, 32), "type": "object_6_20"},
	{"rect": Rect2i(224, 640, 32, 32), "type": "object_7_20"},
	{"rect": Rect2i(256, 640, 32, 32), "type": "object_8_20"},
	{"rect": Rect2i(288, 640, 32, 32), "type": "object_9_20"},
	{"rect": Rect2i(320, 640, 32, 32), "type": "object_10_20"},
	{"rect": Rect2i(352, 640, 32, 32), "type": "object_11_20"},
	{"rect": Rect2i(384, 640, 32, 32), "type": "object_12_20"},
	{"rect": Rect2i(416, 640, 32, 32), "type": "object_13_20"},
	# Row 21 (y=672)
	{"rect": Rect2i(192, 672, 32, 32), "type": "object_6_21"},
	{"rect": Rect2i(224, 672, 32, 32), "type": "object_7_21"},
	{"rect": Rect2i(256, 672, 32, 32), "type": "object_8_21"},
	{"rect": Rect2i(288, 672, 32, 32), "type": "object_9_21"},
	{"rect": Rect2i(320, 672, 32, 32), "type": "object_10_21"},
	{"rect": Rect2i(352, 672, 32, 32), "type": "object_11_21"},
	{"rect": Rect2i(384, 672, 32, 32), "type": "object_12_21"},
	{"rect": Rect2i(416, 672, 32, 32), "type": "object_13_21"},

	# Logs and similar objects starting at (7,22), 6 tiles right
	# Row 22 (y=704)
	{"rect": Rect2i(224, 704, 32, 32), "type": "log_7_22"},
	{"rect": Rect2i(256, 704, 32, 32), "type": "log_8_22"},
	{"rect": Rect2i(288, 704, 32, 32), "type": "log_9_22"},
	{"rect": Rect2i(320, 704, 32, 32), "type": "log_10_22"},
	{"rect": Rect2i(352, 704, 32, 32), "type": "log_11_22"},
	{"rect": Rect2i(384, 704, 32, 32), "type": "log_12_22"},
]

# Tree decorations for corners (currently disabled - can enable if needed)
var tree_tiles: Array[Dictionary] = []

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
	"""Get the tileset region for the given tile type with random variation."""
	match tile_type:
		# Center tiles - randomly pick from variants for diversity
		"light_grass":
			var idx = rng.randi() % light_field_tiles.size()
			return light_field_tiles[idx]
		"dark_grass":
			var idx = rng.randi() % dark_grass_tiles.size()
			return dark_grass_tiles[idx]

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

	# Default to random light field tile
	var idx = rng.randi() % light_field_tiles.size()
	return light_field_tiles[idx]

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
	"""Add decorative elements throughout the arena."""
	# Place decorations scattered across the light field center area
	_place_center_decorations(offset_x, offset_y)

	# Corner trees (if any defined)
	if not tree_tiles.is_empty():
		_place_corner_decorations(offset_x, offset_y)

func _place_center_decorations(offset_x: float, offset_y: float) -> void:
	"""Place decorative objects scattered across the light field center area."""
	if decoration_tiles.is_empty():
		return

	# Calculate the center area bounds (inside the border + inner edge)
	var center_start_x = border_thickness + 1
	var center_start_y = border_thickness + 1
	var center_end_x = arena_width_tiles - border_thickness - 1
	var center_end_y = arena_height_tiles - border_thickness - 1

	# Iterate through center tiles and randomly place decorations
	for y in range(center_start_y, center_end_y):
		for x in range(center_start_x, center_end_x):
			# Use decoration_density to determine if we place something
			if rng.randf() > decoration_density:
				continue

			# Pick a random decoration
			if decoration_tiles.size() == 0:
				continue
			var decoration = decoration_tiles[rng.randi() % decoration_tiles.size()]
			var sprite = Sprite2D.new()
			sprite.texture = tileset_texture
			sprite.region_enabled = true
			sprite.region_rect = Rect2(decoration["rect"])

			# Position at tile center with slight random offset for natural look
			var pos = Vector2(
				offset_x + x * TILE_SIZE + TILE_SIZE / 2 + rng.randf_range(-4, 4),
				offset_y + y * TILE_SIZE + TILE_SIZE / 2 + rng.randf_range(-4, 4)
			)

			sprite.position = pos
			sprite.z_index = -9  # Slightly above floor tiles, below gameplay
			add_child(sprite)
			decoration_sprites.append(sprite)

func _place_edge_decorations(start_x: float, start_y: float, width_tiles: int, height_tiles: int, orientation: String) -> void:
	"""Place random decorations along an edge."""
	if decoration_tiles.size() == 0:
		return

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
