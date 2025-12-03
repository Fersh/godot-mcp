extends Node2D
## Modular tile-based background system using forest_tileset.png
## Replaces the static arena background with procedurally generated tiles
## Can be easily swapped back to original background via toggle

const TILE_SIZE: int = 32
const TILESET_PATH: String = "res://assets/enviro/forest_tileset.png"

# Scale factor for tiles (1.0 = native 32x32, 2.0 = 64x64 on screen)
@export var tile_scale: float = 2.0

# Arena dimensions in tiles (doubled from original)
# Note: with tile_scale=2.0, actual pixel size is tiles * 32 * 2
@export var arena_width_tiles: int = 48
@export var arena_height_tiles: int = 36

# Border thickness for darker grass (in tiles) - base thickness, will vary
@export var border_thickness: int = 4

# Decoration density (0.0 to 1.0)
@export var decoration_density: float = 0.08

# Random seed for reproducible generation (0 = random each time)
@export var generation_seed: int = 0

# Organic edge variation - how much the borders wobble (in tiles)
@export var edge_variation: int = 3

# Chance for random terrain patches in the center
@export var patch_chance: float = 0.04

# Stores the randomized border offsets for organic edges
var border_noise: Dictionary = {}

# Water pool settings
@export var water_pool_count: int = 4  # Number of water pools to generate
@export var water_pool_min_size: int = 2  # Minimum pool size in tiles
@export var water_pool_max_size: int = 5  # Maximum pool size in tiles

# Yellow grass field settings
@export var yellow_grass_field_count: int = 5  # Number of yellow grass fields
@export var yellow_grass_min_size: int = 2
@export var yellow_grass_max_size: int = 4

# Dirt patch settings
@export var dirt_patch_count: int = 6  # Number of dirt patches
@export var dirt_patch_min_size: int = 1
@export var dirt_patch_max_size: int = 3

# Stores feature positions
var water_positions: Array[Vector2i] = []
var yellow_grass_positions: Array[Vector2i] = []
var dirt_positions: Array[Vector2i] = []
var water_collision_bodies: Array[StaticBody2D] = []

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
# WATER TILES
# ============================================
# (3,7) = grass surrounded by water (grass island in water)
var grass_water_center: Rect2i = Rect2i(96, 224, 32, 32)  # (3,7)
var grass_water_edges: Dictionary = {
	"top": Rect2i(96, 192, 32, 32),         # (3,6)
	"bottom": Rect2i(96, 256, 32, 32),      # (3,8)
	"left": Rect2i(64, 224, 32, 32),        # (2,7)
	"right": Rect2i(128, 224, 32, 32),      # (4,7)
	"top_left": Rect2i(64, 192, 32, 32),    # (2,6)
	"top_right": Rect2i(128, 192, 32, 32),  # (4,6)
	"bottom_left": Rect2i(64, 256, 32, 32), # (2,8)
	"bottom_right": Rect2i(128, 256, 32, 32), # (4,8)
}

# (6,7) = water surrounded by grass (water pool in grass)
var water_grass_center: Rect2i = Rect2i(192, 224, 32, 32)  # (6,7)
var water_grass_edges: Dictionary = {
	"top": Rect2i(192, 192, 32, 32),         # (6,6)
	"bottom": Rect2i(192, 256, 32, 32),      # (6,8)
	"left": Rect2i(160, 224, 32, 32),        # (5,7)
	"right": Rect2i(224, 224, 32, 32),       # (7,7)
	"top_left": Rect2i(160, 192, 32, 32),    # (5,6)
	"top_right": Rect2i(224, 192, 32, 32),   # (7,6)
	"bottom_left": Rect2i(160, 256, 32, 32), # (5,8)
	"bottom_right": Rect2i(224, 256, 32, 32), # (7,8)
}

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
# Note: Tall yellow grass now spawns as fields with proper edges, not as individual decorations
var decoration_tiles: Array[Dictionary] = [
	# Tall green grass (1,24) - scattered as decorations
	{"rect": Rect2i(32, 768, 32, 32), "type": "tall_green_grass"},
	{"rect": Rect2i(32, 768, 32, 32), "type": "tall_green_grass"},
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

	# Generate organic border noise for natural-looking edges
	_generate_border_noise()

	# Generate feature positions
	_generate_water_pools()
	_generate_yellow_grass_fields()
	_generate_dirt_patches()

	# Calculate scaled tile size
	var scaled_tile_size = TILE_SIZE * tile_scale

	# Calculate arena offset to center it
	var arena_pixel_width = arena_width_tiles * scaled_tile_size
	var arena_pixel_height = arena_height_tiles * scaled_tile_size
	var offset_x = (1536 - arena_pixel_width) / 2  # Center horizontally
	var offset_y = 100  # Moved up since map is bigger

	# Generate floor tiles
	for y in range(arena_height_tiles):
		for x in range(arena_width_tiles):
			var tile_pos = Vector2(offset_x + x * scaled_tile_size, offset_y + y * scaled_tile_size)
			var tile_type = _determine_tile_type(x, y)
			var tile_rect = _get_tile_rect(tile_type, x, y)
			_create_tile_sprite(tile_pos, tile_rect, tile_type)

			# Create collision for water tiles (any water type)
			if tile_type.begins_with("water"):
				_create_water_collision(tile_pos, scaled_tile_size)

	# Add decorations
	_generate_decorations(offset_x, offset_y)

func _generate_water_pools() -> void:
	"""Generate random water pool positions in the playable area."""
	water_positions.clear()

	# Define safe zone (away from borders)
	var safe_margin = border_thickness + edge_variation + 3
	var min_x = safe_margin
	var max_x = arena_width_tiles - safe_margin
	var min_y = safe_margin
	var max_y = arena_height_tiles - safe_margin

	for _pool in range(water_pool_count):
		# Random pool size
		var pool_width = rng.randi_range(water_pool_min_size, water_pool_max_size)
		var pool_height = rng.randi_range(water_pool_min_size, water_pool_max_size)

		# Random position for pool center
		var center_x = rng.randi_range(min_x + pool_width, max_x - pool_width)
		var center_y = rng.randi_range(min_y + pool_height, max_y - pool_height)

		# Add tiles for this pool (elliptical shape for organic look)
		for dy in range(-pool_height, pool_height + 1):
			for dx in range(-pool_width, pool_width + 1):
				# Ellipse check for organic shape
				var normalized_x = float(dx) / float(pool_width)
				var normalized_y = float(dy) / float(pool_height)
				if normalized_x * normalized_x + normalized_y * normalized_y <= 1.0:
					var pos = Vector2i(center_x + dx, center_y + dy)
					if not water_positions.has(pos):
						water_positions.append(pos)

func _is_water_tile(x: int, y: int) -> bool:
	"""Check if a position is a water tile."""
	return water_positions.has(Vector2i(x, y))

func _get_water_edge_type(x: int, y: int) -> String:
	"""Determine what type of water edge tile this should be."""
	var has_water_top = _is_water_tile(x, y - 1)
	var has_water_bottom = _is_water_tile(x, y + 1)
	var has_water_left = _is_water_tile(x - 1, y)
	var has_water_right = _is_water_tile(x + 1, y)

	# Count adjacent water tiles
	var water_count = 0
	if has_water_top: water_count += 1
	if has_water_bottom: water_count += 1
	if has_water_left: water_count += 1
	if has_water_right: water_count += 1

	# If surrounded by water on all sides, it's center water
	if water_count == 4:
		return "water"

	# Edge tiles (water pool edges looking into grass)
	if not has_water_top and has_water_bottom and has_water_left and has_water_right:
		return "water_edge_top"
	if has_water_top and not has_water_bottom and has_water_left and has_water_right:
		return "water_edge_bottom"
	if has_water_top and has_water_bottom and not has_water_left and has_water_right:
		return "water_edge_left"
	if has_water_top and has_water_bottom and has_water_left and not has_water_right:
		return "water_edge_right"

	# Corner tiles
	if not has_water_top and not has_water_left:
		return "water_edge_top_left"
	if not has_water_top and not has_water_right:
		return "water_edge_top_right"
	if not has_water_bottom and not has_water_left:
		return "water_edge_bottom_left"
	if not has_water_bottom and not has_water_right:
		return "water_edge_bottom_right"

	return "water"

func _generate_yellow_grass_fields() -> void:
	"""Generate random yellow grass field positions."""
	yellow_grass_positions.clear()

	var safe_margin = border_thickness + edge_variation + 3
	var min_x = safe_margin
	var max_x = arena_width_tiles - safe_margin
	var min_y = safe_margin
	var max_y = arena_height_tiles - safe_margin

	for _field in range(yellow_grass_field_count):
		var field_width = rng.randi_range(yellow_grass_min_size, yellow_grass_max_size)
		var field_height = rng.randi_range(yellow_grass_min_size, yellow_grass_max_size)

		var center_x = rng.randi_range(min_x + field_width, max_x - field_width)
		var center_y = rng.randi_range(min_y + field_height, max_y - field_height)

		# Elliptical shape
		for dy in range(-field_height, field_height + 1):
			for dx in range(-field_width, field_width + 1):
				var normalized_x = float(dx) / float(field_width)
				var normalized_y = float(dy) / float(field_height)
				if normalized_x * normalized_x + normalized_y * normalized_y <= 1.0:
					var pos = Vector2i(center_x + dx, center_y + dy)
					# Don't overlap with water
					if not water_positions.has(pos) and not yellow_grass_positions.has(pos):
						yellow_grass_positions.append(pos)

func _is_yellow_grass_tile(x: int, y: int) -> bool:
	return yellow_grass_positions.has(Vector2i(x, y))

func _get_yellow_grass_edge_type(x: int, y: int) -> String:
	"""Determine what type of yellow grass edge tile this should be."""
	var has_top = _is_yellow_grass_tile(x, y - 1)
	var has_bottom = _is_yellow_grass_tile(x, y + 1)
	var has_left = _is_yellow_grass_tile(x - 1, y)
	var has_right = _is_yellow_grass_tile(x + 1, y)

	var count = 0
	if has_top: count += 1
	if has_bottom: count += 1
	if has_left: count += 1
	if has_right: count += 1

	if count == 4:
		return "yellow_grass"

	if not has_top and has_bottom and has_left and has_right:
		return "yellow_grass_edge_top"
	if has_top and not has_bottom and has_left and has_right:
		return "yellow_grass_edge_bottom"
	if has_top and has_bottom and not has_left and has_right:
		return "yellow_grass_edge_left"
	if has_top and has_bottom and has_left and not has_right:
		return "yellow_grass_edge_right"

	if not has_top and not has_left:
		return "yellow_grass_edge_top_left"
	if not has_top and not has_right:
		return "yellow_grass_edge_top_right"
	if not has_bottom and not has_left:
		return "yellow_grass_edge_bottom_left"
	if not has_bottom and not has_right:
		return "yellow_grass_edge_bottom_right"

	return "yellow_grass"

func _generate_dirt_patches() -> void:
	"""Generate random dirt patch positions."""
	dirt_positions.clear()

	var safe_margin = border_thickness + edge_variation + 2
	var min_x = safe_margin
	var max_x = arena_width_tiles - safe_margin
	var min_y = safe_margin
	var max_y = arena_height_tiles - safe_margin

	for _patch in range(dirt_patch_count):
		var patch_width = rng.randi_range(dirt_patch_min_size, dirt_patch_max_size)
		var patch_height = rng.randi_range(dirt_patch_min_size, dirt_patch_max_size)

		var center_x = rng.randi_range(min_x + patch_width, max_x - patch_width)
		var center_y = rng.randi_range(min_y + patch_height, max_y - patch_height)

		# Elliptical shape
		for dy in range(-patch_height, patch_height + 1):
			for dx in range(-patch_width, patch_width + 1):
				var normalized_x = float(dx) / float(max(patch_width, 1))
				var normalized_y = float(dy) / float(max(patch_height, 1))
				if normalized_x * normalized_x + normalized_y * normalized_y <= 1.0:
					var pos = Vector2i(center_x + dx, center_y + dy)
					# Don't overlap with water or yellow grass
					if not water_positions.has(pos) and not yellow_grass_positions.has(pos) and not dirt_positions.has(pos):
						dirt_positions.append(pos)

func _is_dirt_tile(x: int, y: int) -> bool:
	return dirt_positions.has(Vector2i(x, y))

func _get_dirt_edge_type(x: int, y: int) -> String:
	"""Determine what type of dirt edge tile this should be."""
	var has_top = _is_dirt_tile(x, y - 1)
	var has_bottom = _is_dirt_tile(x, y + 1)
	var has_left = _is_dirt_tile(x - 1, y)
	var has_right = _is_dirt_tile(x + 1, y)

	var count = 0
	if has_top: count += 1
	if has_bottom: count += 1
	if has_left: count += 1
	if has_right: count += 1

	if count == 4:
		return "dirt"

	if not has_top and has_bottom and has_left and has_right:
		return "dirt_edge_top"
	if has_top and not has_bottom and has_left and has_right:
		return "dirt_edge_bottom"
	if has_top and has_bottom and not has_left and has_right:
		return "dirt_edge_left"
	if has_top and has_bottom and has_left and not has_right:
		return "dirt_edge_right"

	if not has_top and not has_left:
		return "dirt_edge_top_left"
	if not has_top and not has_right:
		return "dirt_edge_top_right"
	if not has_bottom and not has_left:
		return "dirt_edge_bottom_left"
	if not has_bottom and not has_right:
		return "dirt_edge_bottom_right"

	return "dirt"

func _create_water_collision(pos: Vector2, size: float) -> void:
	"""Create a collision body for a water tile to block player movement."""
	var body = StaticBody2D.new()
	body.position = pos + Vector2(size / 2, size / 2)
	body.collision_layer = 2  # Same as walls
	body.collision_mask = 0

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(size * 0.9, size * 0.9)  # Slightly smaller for smoother navigation
	collision.shape = shape

	body.add_child(collision)
	add_child(body)
	water_collision_bodies.append(body)

func _generate_border_noise() -> void:
	"""Generate randomized border offsets for organic-looking edges."""
	border_noise.clear()

	# Generate noise for each edge
	# Top and bottom edges - vary the y threshold
	for x in range(arena_width_tiles):
		# Use smooth noise by averaging nearby values
		var base_noise_top = rng.randi_range(-edge_variation, edge_variation)
		var base_noise_bottom = rng.randi_range(-edge_variation, edge_variation)

		# Smooth with neighbors
		if x > 0:
			var prev_top = border_noise.get("top_" + str(x - 1), 0)
			var prev_bottom = border_noise.get("bottom_" + str(x - 1), 0)
			base_noise_top = int((base_noise_top + prev_top) / 2.0)
			base_noise_bottom = int((base_noise_bottom + prev_bottom) / 2.0)

		border_noise["top_" + str(x)] = base_noise_top
		border_noise["bottom_" + str(x)] = base_noise_bottom

	# Left and right edges - vary the x threshold
	for y in range(arena_height_tiles):
		var base_noise_left = rng.randi_range(-edge_variation, edge_variation)
		var base_noise_right = rng.randi_range(-edge_variation, edge_variation)

		# Smooth with neighbors
		if y > 0:
			var prev_left = border_noise.get("left_" + str(y - 1), 0)
			var prev_right = border_noise.get("right_" + str(y - 1), 0)
			base_noise_left = int((base_noise_left + prev_left) / 2.0)
			base_noise_right = int((base_noise_right + prev_right) / 2.0)

		border_noise["left_" + str(y)] = base_noise_left
		border_noise["right_" + str(y)] = base_noise_right

func _determine_tile_type(x: int, y: int) -> String:
	"""Determine what type of tile should be at this position with organic edges."""
	var max_x = arena_width_tiles - 1
	var max_y = arena_height_tiles - 1

	# Check for special features first (in order of priority)
	if _is_water_tile(x, y):
		return _get_water_edge_type(x, y)

	if _is_yellow_grass_tile(x, y):
		return _get_yellow_grass_edge_type(x, y)

	if _is_dirt_tile(x, y):
		return _get_dirt_edge_type(x, y)

	# Get noise offsets for organic borders
	var top_noise = border_noise.get("top_" + str(x), 0)
	var bottom_noise = border_noise.get("bottom_" + str(x), 0)
	var left_noise = border_noise.get("left_" + str(y), 0)
	var right_noise = border_noise.get("right_" + str(y), 0)

	# Calculate organic border thresholds
	var top_threshold = border_thickness + top_noise
	var bottom_threshold = max_y - border_thickness + bottom_noise
	var left_threshold = border_thickness + left_noise
	var right_threshold = max_x - border_thickness + right_noise

	# Clamp thresholds to valid ranges
	top_threshold = clampi(top_threshold, 1, arena_height_tiles / 3)
	bottom_threshold = clampi(bottom_threshold, arena_height_tiles * 2 / 3, max_y - 1)
	left_threshold = clampi(left_threshold, 1, arena_width_tiles / 3)
	right_threshold = clampi(right_threshold, arena_width_tiles * 2 / 3, max_x - 1)

	# Check if at absolute edge (always outer edge tiles)
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

	# Check if in organic dark grass border zone
	var in_top_border = y < top_threshold
	var in_bottom_border = y > bottom_threshold
	var in_left_border = x < left_threshold
	var in_right_border = x > right_threshold

	# Check for inner edge (transition zone) - one tile inside the organic border
	var at_inner_top = y == top_threshold
	var at_inner_bottom = y == bottom_threshold
	var at_inner_left = x == left_threshold
	var at_inner_right = x == right_threshold

	# Inner corners (only at actual corner intersections)
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

	# Dark grass border
	if in_left_border or in_right_border or in_top_border or in_bottom_border:
		return "dark_grass"

	# Random patches in the center for variety
	if rng.randf() < patch_chance:
		# Small chance for a dark grass patch in light field
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

		# Water tiles - water surrounded by grass
		"water":
			return water_grass_center
		"water_edge_top":
			return water_grass_edges["top"]
		"water_edge_bottom":
			return water_grass_edges["bottom"]
		"water_edge_left":
			return water_grass_edges["left"]
		"water_edge_right":
			return water_grass_edges["right"]
		"water_edge_top_left":
			return water_grass_edges["top_left"]
		"water_edge_top_right":
			return water_grass_edges["top_right"]
		"water_edge_bottom_left":
			return water_grass_edges["bottom_left"]
		"water_edge_bottom_right":
			return water_grass_edges["bottom_right"]

		# Yellow grass tiles (tall yellow grass field)
		"yellow_grass":
			return yellow_grass_center
		"yellow_grass_edge_top":
			return yellow_grass_edges["top"]
		"yellow_grass_edge_bottom":
			return yellow_grass_edges["bottom"]
		"yellow_grass_edge_left":
			return yellow_grass_edges["left"]
		"yellow_grass_edge_right":
			return yellow_grass_edges["right"]
		"yellow_grass_edge_top_left":
			return yellow_grass_edges["top_left"]
		"yellow_grass_edge_top_right":
			return yellow_grass_edges["top_right"]
		"yellow_grass_edge_bottom_left":
			return yellow_grass_edges["bottom_left"]
		"yellow_grass_edge_bottom_right":
			return yellow_grass_edges["bottom_right"]

		# Dirt tiles (dirt surrounded by grass)
		"dirt":
			return dirt_grass_center
		"dirt_edge_top":
			return dirt_grass_edges["top"]
		"dirt_edge_bottom":
			return dirt_grass_edges["bottom"]
		"dirt_edge_left":
			return dirt_grass_edges["left"]
		"dirt_edge_right":
			return dirt_grass_edges["right"]
		"dirt_edge_top_left":
			return dirt_grass_edges["top_left"]
		"dirt_edge_top_right":
			return dirt_grass_edges["top_right"]
		"dirt_edge_bottom_left":
			return dirt_grass_edges["bottom_left"]
		"dirt_edge_bottom_right":
			return dirt_grass_edges["bottom_right"]

	# Default to random light field tile
	var idx = rng.randi() % light_field_tiles.size()
	return light_field_tiles[idx]

func _create_tile_sprite(pos: Vector2, region: Rect2i, _tile_type: String = "light_grass") -> void:
	"""Create a sprite for a single tile."""
	var scaled_tile_size = TILE_SIZE * tile_scale

	var sprite = Sprite2D.new()
	sprite.texture = tileset_texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # Pixel-perfect, no filtering
	sprite.region_enabled = true
	sprite.region_rect = Rect2(region)
	sprite.scale = Vector2(tile_scale, tile_scale)
	sprite.position = pos + Vector2(scaled_tile_size / 2, scaled_tile_size / 2)  # Center the sprite
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

	var scaled_tile_size = TILE_SIZE * tile_scale

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
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.region_enabled = true
			sprite.region_rect = Rect2(decoration["rect"])
			sprite.scale = Vector2(tile_scale, tile_scale)

			# Position at tile center with slight random offset for natural look
			var pos = Vector2(
				offset_x + x * scaled_tile_size + scaled_tile_size / 2 + rng.randf_range(-4, 4) * tile_scale,
				offset_y + y * scaled_tile_size + scaled_tile_size / 2 + rng.randf_range(-4, 4) * tile_scale
			)

			sprite.position = pos
			sprite.z_index = -9  # Slightly above floor tiles, below gameplay
			add_child(sprite)
			decoration_sprites.append(sprite)

func _place_edge_decorations(start_x: float, start_y: float, width_tiles: int, height_tiles: int, orientation: String) -> void:
	"""Place random decorations along an edge."""
	if decoration_tiles.size() == 0:
		return

	var scaled_tile_size = TILE_SIZE * tile_scale
	var tiles_to_check = width_tiles if orientation == "horizontal" else height_tiles

	for i in range(tiles_to_check):
		if rng.randf() > decoration_density:
			continue

		var decoration = decoration_tiles[rng.randi() % decoration_tiles.size()]
		var sprite = Sprite2D.new()
		sprite.texture = tileset_texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.region_enabled = true
		sprite.region_rect = Rect2(decoration["rect"])
		sprite.scale = Vector2(tile_scale, tile_scale)

		var pos: Vector2
		if orientation == "horizontal":
			pos = Vector2(
				start_x + i * scaled_tile_size + rng.randf_range(0, scaled_tile_size),
				start_y + rng.randf_range(0, height_tiles * scaled_tile_size)
			)
		else:
			pos = Vector2(
				start_x + rng.randf_range(0, width_tiles * scaled_tile_size),
				start_y + i * scaled_tile_size + rng.randf_range(0, scaled_tile_size)
			)

		sprite.position = pos
		sprite.z_index = -9  # Slightly above floor tiles
		add_child(sprite)
		decoration_sprites.append(sprite)

func _place_corner_decorations(offset_x: float, offset_y: float) -> void:
	"""Place larger decorations (trees) in corners."""
	var scaled_tile_size = TILE_SIZE * tile_scale
	var corners = [
		Vector2(offset_x + scaled_tile_size, offset_y + scaled_tile_size),  # Top-left
		Vector2(offset_x + (arena_width_tiles - 2) * scaled_tile_size, offset_y + scaled_tile_size),  # Top-right
		Vector2(offset_x + scaled_tile_size, offset_y + (arena_height_tiles - 3) * scaled_tile_size),  # Bottom-left
		Vector2(offset_x + (arena_width_tiles - 2) * scaled_tile_size, offset_y + (arena_height_tiles - 3) * scaled_tile_size),  # Bottom-right
	]

	for corner_pos in corners:
		if rng.randf() < 0.7:  # 70% chance for corner tree
			if tree_tiles.size() == 0:
				continue
			var tree = tree_tiles[rng.randi() % tree_tiles.size()]
			var sprite = Sprite2D.new()
			sprite.texture = tileset_texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.region_enabled = true
			sprite.region_rect = Rect2(tree["rect"])
			sprite.scale = Vector2(tile_scale, tile_scale)
			sprite.position = corner_pos + Vector2(rng.randf_range(-16, 16) * tile_scale, rng.randf_range(-16, 16) * tile_scale)
			sprite.z_index = -8  # Above decorations
			add_child(sprite)
			decoration_sprites.append(sprite)

func _clear_tiles() -> void:
	"""Remove all generated tiles, decorations, and water collisions."""
	for tile in generated_tiles:
		if is_instance_valid(tile):
			tile.queue_free()
	generated_tiles.clear()

	for decoration in decoration_sprites:
		if is_instance_valid(decoration):
			decoration.queue_free()
	decoration_sprites.clear()

	for body in water_collision_bodies:
		if is_instance_valid(body):
			body.queue_free()
	water_collision_bodies.clear()
	water_positions.clear()
	yellow_grass_positions.clear()
	dirt_positions.clear()

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
