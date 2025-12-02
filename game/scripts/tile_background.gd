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

# Tile regions from forest_tileset.png (x, y, width, height in pixels)
# Tileset is 672x864 pixels = 21x27 tiles at 32x32 each
# These define which parts of the tileset to use for each tile type

# Light green grass variants (center area) - plain light green from top-left
var light_grass_tiles: Array[Rect2i] = [
	Rect2i(0, 0, 32, 32),      # Plain light grass
	Rect2i(32, 0, 32, 32),     # Light grass variant
	Rect2i(0, 288, 32, 32),    # Light grass from mid section
	Rect2i(32, 288, 32, 32),   # Light grass variant 2
]

# Dark green grass variants (border area) - from the large detailed grass at bottom
var dark_grass_tiles: Array[Rect2i] = [
	Rect2i(0, 544, 32, 32),    # Dark detailed grass 1
	Rect2i(32, 544, 32, 32),   # Dark detailed grass 2
	Rect2i(0, 576, 32, 32),    # Dark detailed grass 3
	Rect2i(32, 576, 32, 32),   # Dark detailed grass 4
	Rect2i(0, 704, 32, 32),    # Dark grass from bottom
	Rect2i(32, 704, 32, 32),   # Dark grass variant
	Rect2i(64, 704, 32, 32),   # Dark grass variant 2
	Rect2i(96, 704, 32, 32),   # Dark grass variant 3
]

# Transition tiles (light to dark grass) - grass-dirt transitions repurposed
# Using the grass corner tiles from row 1-2
var transition_tiles: Dictionary = {
	"top": Rect2i(32, 64, 32, 32),       # Top edge
	"bottom": Rect2i(32, 128, 32, 32),   # Bottom edge
	"left": Rect2i(0, 96, 32, 32),       # Left edge
	"right": Rect2i(64, 96, 32, 32),     # Right edge
	"top_left": Rect2i(0, 64, 32, 32),   # Top-left corner
	"top_right": Rect2i(64, 64, 32, 32), # Top-right corner
	"bottom_left": Rect2i(0, 128, 32, 32),   # Bottom-left corner
	"bottom_right": Rect2i(64, 128, 32, 32), # Bottom-right corner
}

# Decorative elements (placed on edges) - mushrooms, rocks, bushes
var decoration_tiles: Array[Dictionary] = [
	# Mushrooms (row ~15, y=480)
	{"rect": Rect2i(192, 480, 16, 16), "type": "mushroom_small"},
	{"rect": Rect2i(208, 480, 16, 16), "type": "mushroom_red"},
	{"rect": Rect2i(224, 480, 32, 16), "type": "mushroom_group"},
	{"rect": Rect2i(288, 480, 32, 16), "type": "mushroom_tall"},
	# Rocks (row ~16, y=512)
	{"rect": Rect2i(224, 512, 32, 32), "type": "rock_small"},
	{"rect": Rect2i(256, 512, 32, 32), "type": "rock_medium"},
	{"rect": Rect2i(288, 512, 48, 32), "type": "rock_large"},
	{"rect": Rect2i(352, 512, 32, 32), "type": "rock_grey"},
	# Bushes and grass tufts
	{"rect": Rect2i(384, 512, 32, 32), "type": "bush_small"},
	{"rect": Rect2i(416, 512, 32, 32), "type": "bush_brown"},
	{"rect": Rect2i(448, 512, 32, 32), "type": "grass_tuft"},
	{"rect": Rect2i(480, 512, 32, 32), "type": "grass_tall"},
	# Small stumps/logs
	{"rect": Rect2i(192, 544, 32, 32), "type": "stump"},
	{"rect": Rect2i(224, 544, 32, 32), "type": "log"},
]

# Tree decorations for corners (larger elements)
var tree_tiles: Array[Dictionary] = [
	# Trees from row ~12 (y=384)
	{"rect": Rect2i(352, 384, 32, 64), "type": "pine_small"},
	{"rect": Rect2i(384, 384, 32, 64), "type": "pine_medium"},
	{"rect": Rect2i(416, 384, 48, 64), "type": "tree_green"},
	{"rect": Rect2i(480, 384, 48, 64), "type": "tree_round"},
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
			_create_tile_sprite(tile_pos, tile_rect)

	# Add decorations around edges
	_generate_decorations(offset_x, offset_y)

func _determine_tile_type(x: int, y: int) -> String:
	"""Determine what type of tile should be at this position."""
	var in_left_border = x < border_thickness
	var in_right_border = x >= arena_width_tiles - border_thickness
	var in_top_border = y < border_thickness
	var in_bottom_border = y >= arena_height_tiles - border_thickness

	# Check for transition zones (one tile inside the border)
	var at_left_transition = x == border_thickness
	var at_right_transition = x == arena_width_tiles - border_thickness - 1
	var at_top_transition = y == border_thickness
	var at_bottom_transition = y == arena_height_tiles - border_thickness - 1

	# Corner transitions
	if at_top_transition and at_left_transition:
		return "transition_top_left"
	elif at_top_transition and at_right_transition:
		return "transition_top_right"
	elif at_bottom_transition and at_left_transition:
		return "transition_bottom_left"
	elif at_bottom_transition and at_right_transition:
		return "transition_bottom_right"

	# Edge transitions
	if at_top_transition and not in_left_border and not in_right_border:
		return "transition_top"
	elif at_bottom_transition and not in_left_border and not in_right_border:
		return "transition_bottom"
	elif at_left_transition and not in_top_border and not in_bottom_border:
		return "transition_left"
	elif at_right_transition and not in_top_border and not in_bottom_border:
		return "transition_right"

	# Border (dark grass)
	if in_left_border or in_right_border or in_top_border or in_bottom_border:
		return "dark_grass"

	# Center (light grass)
	return "light_grass"

func _get_tile_rect(tile_type: String, x: int, y: int) -> Rect2i:
	"""Get the tileset region for the given tile type with randomization."""
	match tile_type:
		"light_grass":
			# Random variation of light grass
			var idx = rng.randi() % light_grass_tiles.size()
			return light_grass_tiles[idx]
		"dark_grass":
			# Random variation of dark grass
			var idx = rng.randi() % dark_grass_tiles.size()
			return dark_grass_tiles[idx]
		"transition_top":
			return transition_tiles["top"]
		"transition_bottom":
			return transition_tiles["bottom"]
		"transition_left":
			return transition_tiles["left"]
		"transition_right":
			return transition_tiles["right"]
		"transition_top_left":
			return transition_tiles["top_left"]
		"transition_top_right":
			return transition_tiles["top_right"]
		"transition_bottom_left":
			return transition_tiles["bottom_left"]
		"transition_bottom_right":
			return transition_tiles["bottom_right"]

	# Default to light grass
	return light_grass_tiles[0]

func _create_tile_sprite(pos: Vector2, region: Rect2i) -> void:
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
