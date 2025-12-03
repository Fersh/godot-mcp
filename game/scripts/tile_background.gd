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
@export var decoration_density: float = 0.06

# Random seed for reproducible generation (0 = random each time)
@export var generation_seed: int = 0

# Organic edge variation - how much the borders wobble (in tiles)
@export var edge_variation: int = 3

# Chance for random terrain patches in the center
@export var patch_chance: float = 0.03

# Stores the randomized border offsets for organic edges
var border_noise: Dictionary = {}

# Water pool settings
@export var water_pool_count: int = 3
@export var water_pool_min_size: int = 2
@export var water_pool_max_size: int = 4

# Tall grass overlay settings (these are OVERLAYS, not tile replacements)
@export var yellow_grass_cluster_count: int = 8
@export var green_grass_cluster_count: int = 12
@export var grass_cluster_min_size: int = 2
@export var grass_cluster_max_size: int = 5

# Dirt patch settings
@export var dirt_patch_count: int = 5
@export var dirt_patch_min_size: int = 1
@export var dirt_patch_max_size: int = 3

# Tree settings
@export var tree_count: int = 15
@export var tree_scale: float = 2.5

# Lamp settings
@export var lamp_count: int = 6
@export var lamp_scale: float = 2.0

# Clearing settings (open areas with no trees/tall grass)
@export var clearing_count: int = 3
@export var clearing_min_radius: int = 4
@export var clearing_max_radius: int = 7

# Stores feature positions
var water_positions: Array[Vector2i] = []
var dirt_positions: Array[Vector2i] = []
var clearing_positions: Array[Vector2] = []  # Center positions with radius
var clearing_radii: Array[float] = []
var water_collision_bodies: Array[StaticBody2D] = []

# Tile regions from forest_tileset.png
# Grid coordinates converted to pixels (* 32)

# ============================================
# LIGHT FIELD TILES (center area)
# ============================================
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
var dark_grass_tiles: Array[Rect2i] = [
	Rect2i(96, 128, 32, 32),   # (3,4) - grass center
	Rect2i(288, 128, 32, 32),  # (9,4) - dark grass (surrounded by light field)
]

# ============================================
# DIRT TILES
# ============================================
var dirt_grass_center: Rect2i = Rect2i(192, 32, 32, 32)  # (6,1)
var dirt_grass_edges: Dictionary = {
	"top": Rect2i(192, 0, 32, 32),
	"bottom": Rect2i(192, 64, 32, 32),
	"left": Rect2i(160, 32, 32, 32),
	"right": Rect2i(224, 32, 32, 32),
	"top_left": Rect2i(160, 0, 32, 32),
	"top_right": Rect2i(224, 0, 32, 32),
	"bottom_left": Rect2i(160, 64, 32, 32),
	"bottom_right": Rect2i(224, 64, 32, 32),
}

# ============================================
# TALL GRASS OVERLAYS (sit ON TOP of base tiles)
# ============================================
# Yellow grass cluster tiles (4,17-19) - these overlay on top of ground
var yellow_grass_tiles: Array[Rect2i] = [
	Rect2i(128, 576, 32, 32),  # (4,18) - center
	Rect2i(96, 576, 32, 32),   # (3,18) - left
	Rect2i(160, 576, 32, 32),  # (5,18) - right
	Rect2i(128, 544, 32, 32),  # (4,17) - top
	Rect2i(128, 608, 32, 32),  # (4,19) - bottom
	Rect2i(96, 544, 32, 32),   # (3,17) - top-left
	Rect2i(160, 544, 32, 32),  # (5,17) - top-right
	Rect2i(96, 608, 32, 32),   # (3,19) - bottom-left
	Rect2i(160, 608, 32, 32),  # (5,19) - bottom-right
]

# Green grass decoration (1,24) - single tall grass
var tall_green_grass: Rect2i = Rect2i(32, 768, 32, 32)  # (1,24)

# ============================================
# WATER TILES
# ============================================
var water_grass_center: Rect2i = Rect2i(192, 224, 32, 32)  # (6,7)
var water_grass_edges: Dictionary = {
	"top": Rect2i(192, 192, 32, 32),
	"bottom": Rect2i(192, 256, 32, 32),
	"left": Rect2i(160, 224, 32, 32),
	"right": Rect2i(224, 224, 32, 32),
	"top_left": Rect2i(160, 192, 32, 32),
	"top_right": Rect2i(224, 192, 32, 32),
	"bottom_left": Rect2i(160, 256, 32, 32),
	"bottom_right": Rect2i(224, 256, 32, 32),
}

# ============================================
# EDGE TILES FOR ARENA BOUNDARY
# ============================================
var outer_edge_tiles: Dictionary = {
	"top": Rect2i(96, 96, 32, 32),
	"bottom": Rect2i(96, 160, 32, 32),
	"left": Rect2i(64, 128, 32, 32),
	"right": Rect2i(128, 128, 32, 32),
	"top_left": Rect2i(64, 96, 32, 32),
	"top_right": Rect2i(128, 96, 32, 32),
	"bottom_left": Rect2i(64, 160, 32, 32),
	"bottom_right": Rect2i(128, 160, 32, 32),
}

var inner_edge_tiles: Dictionary = {
	"top": Rect2i(288, 96, 32, 32),
	"bottom": Rect2i(288, 160, 32, 32),
	"left": Rect2i(256, 128, 32, 32),
	"right": Rect2i(320, 128, 32, 32),
	"top_left": Rect2i(256, 96, 32, 32),
	"top_right": Rect2i(320, 96, 32, 32),
	"bottom_left": Rect2i(256, 160, 32, 32),
	"bottom_right": Rect2i(320, 160, 32, 32),
}

# Alias for backward compatibility
var light_grass_tiles: Array[Rect2i]:
	get: return light_field_tiles

# Small decorative objects from tileset
var decoration_tiles: Array[Dictionary] = [
	# Row 19-21 small objects
	{"rect": Rect2i(192, 608, 32, 32), "type": "small_object"},
	{"rect": Rect2i(224, 608, 32, 32), "type": "small_object"},
	{"rect": Rect2i(256, 608, 32, 32), "type": "small_object"},
	{"rect": Rect2i(288, 608, 32, 32), "type": "small_object"},
	{"rect": Rect2i(192, 640, 32, 32), "type": "small_object"},
	{"rect": Rect2i(224, 640, 32, 32), "type": "small_object"},
	{"rect": Rect2i(256, 640, 32, 32), "type": "small_object"},
	{"rect": Rect2i(192, 672, 32, 32), "type": "small_object"},
	# Row 22 logs
	{"rect": Rect2i(224, 704, 32, 32), "type": "log"},
	{"rect": Rect2i(256, 704, 32, 32), "type": "log"},
	{"rect": Rect2i(288, 704, 32, 32), "type": "log"},
	{"rect": Rect2i(320, 704, 32, 32), "type": "log"},
]

# External tree textures (from gowl folder)
var tree_textures: Array[String] = [
	"res://assets/enviro/gowl/Trees/Tree1.png",
	"res://assets/enviro/gowl/Trees/Tree2.png",
	"res://assets/enviro/gowl/Trees/Tree3.png",
]

# Lamp texture
const LAMP_TEXTURE_PATH: String = "res://assets/enviro/gowl/Wooden/Lamp.png"

var tileset_texture: Texture2D
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Store generated elements for cleanup
var generated_tiles: Array = []
var decoration_sprites: Array[Sprite2D] = []
var overlay_sprites: Array[Sprite2D] = []  # Tall grass overlays
var tree_sprites: Array[Sprite2D] = []
var lamp_nodes: Array[Node2D] = []

# Cached arena offset for external use
var arena_offset_x: float = 0.0
var arena_offset_y: float = 0.0

func _ready() -> void:
	z_index = -10
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

	# Clear existing elements
	_clear_tiles()

	# Calculate scaled tile size
	var scaled_tile_size = TILE_SIZE * tile_scale

	# Calculate arena offset to center it
	var arena_pixel_width = arena_width_tiles * scaled_tile_size
	var arena_pixel_height = arena_height_tiles * scaled_tile_size
	arena_offset_x = (1536 - arena_pixel_width) / 2
	arena_offset_y = 100

	# Generate terrain features first
	_generate_border_noise()
	_generate_clearings()
	_generate_water_pools()
	_generate_dirt_patches()

	# Generate floor tiles
	for y in range(arena_height_tiles):
		for x in range(arena_width_tiles):
			var tile_pos = Vector2(arena_offset_x + x * scaled_tile_size, arena_offset_y + y * scaled_tile_size)
			var tile_type = _determine_tile_type(x, y)
			var tile_rect = _get_tile_rect(tile_type, x, y)
			_create_tile_sprite(tile_pos, tile_rect, tile_type)

			# Create collision for water tiles
			if tile_type.begins_with("water"):
				_create_water_collision(tile_pos, scaled_tile_size)

	# Add overlays and decorations (after base tiles)
	_generate_tall_grass_overlays()
	_generate_trees()
	_generate_lamps()
	_generate_small_decorations()

func _generate_clearings() -> void:
	"""Generate open clearing areas where trees/tall grass won't spawn."""
	clearing_positions.clear()
	clearing_radii.clear()

	var safe_margin = border_thickness + edge_variation + 5
	var scaled_tile_size = TILE_SIZE * tile_scale

	for _i in range(clearing_count):
		var radius = rng.randf_range(clearing_min_radius, clearing_max_radius) * scaled_tile_size
		var center_x = rng.randf_range(safe_margin * scaled_tile_size, (arena_width_tiles - safe_margin) * scaled_tile_size)
		var center_y = rng.randf_range(safe_margin * scaled_tile_size, (arena_height_tiles - safe_margin) * scaled_tile_size)

		clearing_positions.append(Vector2(arena_offset_x + center_x, arena_offset_y + center_y))
		clearing_radii.append(radius)

func _is_in_clearing(pos: Vector2) -> bool:
	"""Check if a position is inside a clearing."""
	for i in range(clearing_positions.size()):
		if pos.distance_to(clearing_positions[i]) < clearing_radii[i]:
			return true
	return false

func _generate_water_pools() -> void:
	"""Generate random water pool positions in the playable area."""
	water_positions.clear()

	var safe_margin = border_thickness + edge_variation + 3
	var min_x = safe_margin
	var max_x = arena_width_tiles - safe_margin
	var min_y = safe_margin
	var max_y = arena_height_tiles - safe_margin

	for _pool in range(water_pool_count):
		var pool_width = rng.randi_range(water_pool_min_size, water_pool_max_size)
		var pool_height = rng.randi_range(water_pool_min_size, water_pool_max_size)

		var center_x = rng.randi_range(min_x + pool_width, max_x - pool_width)
		var center_y = rng.randi_range(min_y + pool_height, max_y - pool_height)

		# Elliptical shape for organic look
		for dy in range(-pool_height, pool_height + 1):
			for dx in range(-pool_width, pool_width + 1):
				var normalized_x = float(dx) / float(pool_width)
				var normalized_y = float(dy) / float(pool_height)
				if normalized_x * normalized_x + normalized_y * normalized_y <= 1.0:
					var pos = Vector2i(center_x + dx, center_y + dy)
					if not water_positions.has(pos):
						water_positions.append(pos)

func _is_water_tile(x: int, y: int) -> bool:
	return water_positions.has(Vector2i(x, y))

func _get_water_edge_type(x: int, y: int) -> String:
	var has_water_top = _is_water_tile(x, y - 1)
	var has_water_bottom = _is_water_tile(x, y + 1)
	var has_water_left = _is_water_tile(x - 1, y)
	var has_water_right = _is_water_tile(x + 1, y)

	var water_count = 0
	if has_water_top: water_count += 1
	if has_water_bottom: water_count += 1
	if has_water_left: water_count += 1
	if has_water_right: water_count += 1

	if water_count == 4:
		return "water"

	if not has_water_top and has_water_bottom and has_water_left and has_water_right:
		return "water_edge_top"
	if has_water_top and not has_water_bottom and has_water_left and has_water_right:
		return "water_edge_bottom"
	if has_water_top and has_water_bottom and not has_water_left and has_water_right:
		return "water_edge_left"
	if has_water_top and has_water_bottom and has_water_left and not has_water_right:
		return "water_edge_right"

	if not has_water_top and not has_water_left:
		return "water_edge_top_left"
	if not has_water_top and not has_water_right:
		return "water_edge_top_right"
	if not has_water_bottom and not has_water_left:
		return "water_edge_bottom_left"
	if not has_water_bottom and not has_water_right:
		return "water_edge_bottom_right"

	return "water"

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

		for dy in range(-patch_height, patch_height + 1):
			for dx in range(-patch_width, patch_width + 1):
				var normalized_x = float(dx) / float(max(patch_width, 1))
				var normalized_y = float(dy) / float(max(patch_height, 1))
				if normalized_x * normalized_x + normalized_y * normalized_y <= 1.0:
					var pos = Vector2i(center_x + dx, center_y + dy)
					if not water_positions.has(pos) and not dirt_positions.has(pos):
						dirt_positions.append(pos)

func _is_dirt_tile(x: int, y: int) -> bool:
	return dirt_positions.has(Vector2i(x, y))

func _get_dirt_edge_type(x: int, y: int) -> String:
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
	body.collision_layer = 2
	body.collision_mask = 0

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(size * 0.9, size * 0.9)
	collision.shape = shape

	body.add_child(collision)
	add_child(body)
	water_collision_bodies.append(body)

func _generate_border_noise() -> void:
	"""Generate randomized border offsets for organic-looking edges."""
	border_noise.clear()

	for x in range(arena_width_tiles):
		var base_noise_top = rng.randi_range(-edge_variation, edge_variation)
		var base_noise_bottom = rng.randi_range(-edge_variation, edge_variation)

		if x > 0:
			var prev_top = border_noise.get("top_" + str(x - 1), 0)
			var prev_bottom = border_noise.get("bottom_" + str(x - 1), 0)
			base_noise_top = int((base_noise_top + prev_top) / 2.0)
			base_noise_bottom = int((base_noise_bottom + prev_bottom) / 2.0)

		border_noise["top_" + str(x)] = base_noise_top
		border_noise["bottom_" + str(x)] = base_noise_bottom

	for y in range(arena_height_tiles):
		var base_noise_left = rng.randi_range(-edge_variation, edge_variation)
		var base_noise_right = rng.randi_range(-edge_variation, edge_variation)

		if y > 0:
			var prev_left = border_noise.get("left_" + str(y - 1), 0)
			var prev_right = border_noise.get("right_" + str(y - 1), 0)
			base_noise_left = int((base_noise_left + prev_left) / 2.0)
			base_noise_right = int((base_noise_right + prev_right) / 2.0)

		border_noise["left_" + str(y)] = base_noise_left
		border_noise["right_" + str(y)] = base_noise_right

func _determine_tile_type(x: int, y: int) -> String:
	"""Determine what type of tile should be at this position."""
	var max_x = arena_width_tiles - 1
	var max_y = arena_height_tiles - 1

	# Check special features first
	if _is_water_tile(x, y):
		return _get_water_edge_type(x, y)

	if _is_dirt_tile(x, y):
		return _get_dirt_edge_type(x, y)

	# Get noise offsets for organic borders
	var top_noise = border_noise.get("top_" + str(x), 0)
	var bottom_noise = border_noise.get("bottom_" + str(x), 0)
	var left_noise = border_noise.get("left_" + str(y), 0)
	var right_noise = border_noise.get("right_" + str(y), 0)

	var top_threshold = border_thickness + top_noise
	var bottom_threshold = max_y - border_thickness + bottom_noise
	var left_threshold = border_thickness + left_noise
	var right_threshold = max_x - border_thickness + right_noise

	top_threshold = clampi(top_threshold, 1, arena_height_tiles / 3)
	bottom_threshold = clampi(bottom_threshold, arena_height_tiles * 2 / 3, max_y - 1)
	left_threshold = clampi(left_threshold, 1, arena_width_tiles / 3)
	right_threshold = clampi(right_threshold, arena_width_tiles * 2 / 3, max_x - 1)

	# Outer edges
	var at_left_edge = x == 0
	var at_right_edge = x == max_x
	var at_top_edge = y == 0
	var at_bottom_edge = y == max_y

	if at_top_edge and at_left_edge:
		return "outer_top_left"
	elif at_top_edge and at_right_edge:
		return "outer_top_right"
	elif at_bottom_edge and at_left_edge:
		return "outer_bottom_left"
	elif at_bottom_edge and at_right_edge:
		return "outer_bottom_right"

	if at_top_edge:
		return "outer_top"
	elif at_bottom_edge:
		return "outer_bottom"
	elif at_left_edge:
		return "outer_left"
	elif at_right_edge:
		return "outer_right"

	# Border zones
	var in_top_border = y < top_threshold
	var in_bottom_border = y > bottom_threshold
	var in_left_border = x < left_threshold
	var in_right_border = x > right_threshold

	var at_inner_top = y == top_threshold
	var at_inner_bottom = y == bottom_threshold
	var at_inner_left = x == left_threshold
	var at_inner_right = x == right_threshold

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

	# Dark grass border
	if in_left_border or in_right_border or in_top_border or in_bottom_border:
		return "dark_grass"

	# Random patches
	if rng.randf() < patch_chance:
		return "dark_grass"

	return "light_grass"

func _get_tile_rect(tile_type: String, _x: int, _y: int) -> Rect2i:
	"""Get the tileset region for the given tile type."""
	match tile_type:
		"light_grass":
			var idx = rng.randi() % light_field_tiles.size()
			return light_field_tiles[idx]
		"dark_grass":
			var idx = rng.randi() % dark_grass_tiles.size()
			return dark_grass_tiles[idx]

		"outer_top": return outer_edge_tiles["top"]
		"outer_bottom": return outer_edge_tiles["bottom"]
		"outer_left": return outer_edge_tiles["left"]
		"outer_right": return outer_edge_tiles["right"]
		"outer_top_left": return outer_edge_tiles["top_left"]
		"outer_top_right": return outer_edge_tiles["top_right"]
		"outer_bottom_left": return outer_edge_tiles["bottom_left"]
		"outer_bottom_right": return outer_edge_tiles["bottom_right"]

		"inner_top": return inner_edge_tiles["top"]
		"inner_bottom": return inner_edge_tiles["bottom"]
		"inner_left": return inner_edge_tiles["left"]
		"inner_right": return inner_edge_tiles["right"]
		"inner_top_left": return inner_edge_tiles["top_left"]
		"inner_top_right": return inner_edge_tiles["top_right"]
		"inner_bottom_left": return inner_edge_tiles["bottom_left"]
		"inner_bottom_right": return inner_edge_tiles["bottom_right"]

		"water": return water_grass_center
		"water_edge_top": return water_grass_edges["top"]
		"water_edge_bottom": return water_grass_edges["bottom"]
		"water_edge_left": return water_grass_edges["left"]
		"water_edge_right": return water_grass_edges["right"]
		"water_edge_top_left": return water_grass_edges["top_left"]
		"water_edge_top_right": return water_grass_edges["top_right"]
		"water_edge_bottom_left": return water_grass_edges["bottom_left"]
		"water_edge_bottom_right": return water_grass_edges["bottom_right"]

		"dirt": return dirt_grass_center
		"dirt_edge_top": return dirt_grass_edges["top"]
		"dirt_edge_bottom": return dirt_grass_edges["bottom"]
		"dirt_edge_left": return dirt_grass_edges["left"]
		"dirt_edge_right": return dirt_grass_edges["right"]
		"dirt_edge_top_left": return dirt_grass_edges["top_left"]
		"dirt_edge_top_right": return dirt_grass_edges["top_right"]
		"dirt_edge_bottom_left": return dirt_grass_edges["bottom_left"]
		"dirt_edge_bottom_right": return dirt_grass_edges["bottom_right"]

	var idx = rng.randi() % light_field_tiles.size()
	return light_field_tiles[idx]

func _create_tile_sprite(pos: Vector2, region: Rect2i, _tile_type: String = "light_grass") -> void:
	"""Create a sprite for a single tile."""
	var scaled_tile_size = TILE_SIZE * tile_scale

	var sprite = Sprite2D.new()
	sprite.texture = tileset_texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.region_enabled = true
	sprite.region_rect = Rect2(region)
	sprite.scale = Vector2(tile_scale, tile_scale)
	sprite.position = pos + Vector2(scaled_tile_size / 2, scaled_tile_size / 2)
	sprite.z_index = -10
	add_child(sprite)
	generated_tiles.append(sprite)

# ============================================
# TALL GRASS OVERLAYS (sit on top of tiles, y-sorted)
# ============================================

func _generate_tall_grass_overlays() -> void:
	"""Generate tall grass clusters that OVERLAY on top of base tiles."""
	var scaled_tile_size = TILE_SIZE * tile_scale
	var safe_margin = border_thickness + edge_variation + 2

	# Generate yellow grass clusters
	for _cluster in range(yellow_grass_cluster_count):
		var cluster_size = rng.randi_range(grass_cluster_min_size, grass_cluster_max_size)
		var center_x = rng.randi_range(safe_margin, arena_width_tiles - safe_margin)
		var center_y = rng.randi_range(safe_margin, arena_height_tiles - safe_margin)

		var center_pos = Vector2(
			arena_offset_x + center_x * scaled_tile_size,
			arena_offset_y + center_y * scaled_tile_size
		)

		# Skip if in water or clearing
		if _is_in_clearing(center_pos):
			continue
		if _is_water_tile(center_x, center_y):
			continue

		# Create cluster of overlapping grass sprites
		for _i in range(cluster_size):
			var offset_x = rng.randf_range(-scaled_tile_size * 1.5, scaled_tile_size * 1.5)
			var offset_y = rng.randf_range(-scaled_tile_size * 1.5, scaled_tile_size * 1.5)
			var grass_pos = center_pos + Vector2(offset_x, offset_y)

			# Pick a random yellow grass tile
			var tile_rect = yellow_grass_tiles[rng.randi() % yellow_grass_tiles.size()]
			_create_grass_overlay(grass_pos, tile_rect, true)

	# Generate green grass clusters
	for _cluster in range(green_grass_cluster_count):
		var cluster_size = rng.randi_range(2, 4)
		var center_x = rng.randi_range(safe_margin, arena_width_tiles - safe_margin)
		var center_y = rng.randi_range(safe_margin, arena_height_tiles - safe_margin)

		var center_pos = Vector2(
			arena_offset_x + center_x * scaled_tile_size,
			arena_offset_y + center_y * scaled_tile_size
		)

		if _is_in_clearing(center_pos):
			continue
		if _is_water_tile(center_x, center_y):
			continue

		for _i in range(cluster_size):
			var offset_x = rng.randf_range(-scaled_tile_size, scaled_tile_size)
			var offset_y = rng.randf_range(-scaled_tile_size, scaled_tile_size)
			var grass_pos = center_pos + Vector2(offset_x, offset_y)

			_create_grass_overlay(grass_pos, tall_green_grass, false)

func _create_grass_overlay(pos: Vector2, region: Rect2i, is_yellow: bool) -> void:
	"""Create a tall grass overlay sprite with y-sorting."""
	var sprite = Sprite2D.new()
	sprite.texture = tileset_texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.region_enabled = true
	sprite.region_rect = Rect2(region)
	sprite.scale = Vector2(tile_scale * 1.2, tile_scale * 1.2)  # Slightly larger
	sprite.position = pos

	# Y-sorting: z_index based on Y position so players walk "through" grass
	# Grass renders above ground (-10) but uses y-position for depth
	sprite.z_index = 0  # Same layer as gameplay
	sprite.y_sort_enabled = false  # We'll set z manually based on y

	# Set z_index based on bottom of the grass sprite
	# This allows characters to appear in front when their feet are below the grass
	var grass_bottom_y = pos.y + (TILE_SIZE * tile_scale * 0.5)
	sprite.z_index = int(grass_bottom_y / 10)

	# Add slight transparency for visual effect
	if is_yellow:
		sprite.modulate = Color(1, 1, 1, 0.95)
	else:
		sprite.modulate = Color(1, 1, 1, 0.9)

	add_child(sprite)
	overlay_sprites.append(sprite)

# ============================================
# TREES (from gowl folder, y-sorted)
# ============================================

func _generate_trees() -> void:
	"""Generate trees from the gowl folder with y-sorting."""
	var scaled_tile_size = TILE_SIZE * tile_scale
	var safe_margin = border_thickness + edge_variation + 3

	# Load tree textures
	var loaded_trees: Array[Texture2D] = []
	for path in tree_textures:
		var tex = load(path)
		if tex:
			loaded_trees.append(tex)

	if loaded_trees.is_empty():
		return

	for _i in range(tree_count):
		var x = rng.randf_range(safe_margin * scaled_tile_size, (arena_width_tiles - safe_margin) * scaled_tile_size)
		var y = rng.randf_range(safe_margin * scaled_tile_size, (arena_height_tiles - safe_margin) * scaled_tile_size)
		var pos = Vector2(arena_offset_x + x, arena_offset_y + y)

		# Skip if in water or clearing
		var tile_x = int(x / scaled_tile_size)
		var tile_y = int(y / scaled_tile_size)
		if _is_water_tile(tile_x, tile_y):
			continue
		if _is_in_clearing(pos):
			continue

		# Pick a random tree
		var tree_tex = loaded_trees[rng.randi() % loaded_trees.size()]

		var sprite = Sprite2D.new()
		sprite.texture = tree_tex
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(tree_scale, tree_scale)
		sprite.position = pos

		# Trees are anchored at bottom center, so offset the position
		sprite.offset = Vector2(0, -tree_tex.get_height() / 2)

		# Y-sorting based on tree base position
		sprite.z_index = int(pos.y / 10)

		add_child(sprite)
		tree_sprites.append(sprite)

# ============================================
# LAMPS (with torch-like lighting)
# ============================================

func _generate_lamps() -> void:
	"""Generate lamps with PointLight2D similar to torches."""
	var scaled_tile_size = TILE_SIZE * tile_scale
	var safe_margin = border_thickness + edge_variation + 4

	var lamp_tex = load(LAMP_TEXTURE_PATH)
	if not lamp_tex:
		return

	for _i in range(lamp_count):
		var x = rng.randf_range(safe_margin * scaled_tile_size, (arena_width_tiles - safe_margin) * scaled_tile_size)
		var y = rng.randf_range(safe_margin * scaled_tile_size, (arena_height_tiles - safe_margin) * scaled_tile_size)
		var pos = Vector2(arena_offset_x + x, arena_offset_y + y)

		# Skip if in water
		var tile_x = int(x / scaled_tile_size)
		var tile_y = int(y / scaled_tile_size)
		if _is_water_tile(tile_x, tile_y):
			continue

		# Create lamp container
		var lamp_node = Node2D.new()
		lamp_node.position = pos

		# Create lamp sprite
		var sprite = Sprite2D.new()
		sprite.texture = lamp_tex
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(lamp_scale, lamp_scale)
		sprite.offset = Vector2(0, -lamp_tex.get_height() / 2)  # Anchor at bottom
		lamp_node.add_child(sprite)

		# Create point light (similar to torch)
		var light = PointLight2D.new()
		light.position = Vector2(0, -lamp_tex.get_height() * lamp_scale * 0.8)  # Near top of lamp
		light.color = Color(1.0, 0.8, 0.5, 1.0)  # Warm light
		light.energy = 0.4
		light.texture_scale = 3.0

		# Create gradient texture for light
		var gradient = Gradient.new()
		gradient.offsets = PackedFloat32Array([0, 0.3, 1])
		gradient.colors = PackedColorArray([
			Color(1, 1, 1, 1),
			Color(1, 0.9, 0.7, 0.8),
			Color(1, 0.6, 0.3, 0)
		])

		var grad_tex = GradientTexture2D.new()
		grad_tex.gradient = gradient
		grad_tex.width = 128
		grad_tex.height = 128
		grad_tex.fill = GradientTexture2D.FILL_RADIAL
		grad_tex.fill_from = Vector2(0.5, 0.5)
		grad_tex.fill_to = Vector2(1.0, 0.5)

		light.texture = grad_tex
		lamp_node.add_child(light)

		# Y-sorting
		lamp_node.z_index = int(pos.y / 10)

		add_child(lamp_node)
		lamp_nodes.append(lamp_node)

# ============================================
# SMALL DECORATIONS
# ============================================

func _generate_small_decorations() -> void:
	"""Place small decorative objects scattered across the arena."""
	if decoration_tiles.is_empty():
		return

	var scaled_tile_size = TILE_SIZE * tile_scale
	var center_start_x = border_thickness + 2
	var center_start_y = border_thickness + 2
	var center_end_x = arena_width_tiles - border_thickness - 2
	var center_end_y = arena_height_tiles - border_thickness - 2

	for y in range(center_start_y, center_end_y):
		for x in range(center_start_x, center_end_x):
			if rng.randf() > decoration_density:
				continue

			# Skip water tiles
			if _is_water_tile(x, y):
				continue

			var decoration = decoration_tiles[rng.randi() % decoration_tiles.size()]
			var sprite = Sprite2D.new()
			sprite.texture = tileset_texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.region_enabled = true
			sprite.region_rect = Rect2(decoration["rect"])
			sprite.scale = Vector2(tile_scale, tile_scale)

			var pos = Vector2(
				arena_offset_x + x * scaled_tile_size + scaled_tile_size / 2 + rng.randf_range(-4, 4) * tile_scale,
				arena_offset_y + y * scaled_tile_size + scaled_tile_size / 2 + rng.randf_range(-4, 4) * tile_scale
			)

			sprite.position = pos
			sprite.z_index = -9
			add_child(sprite)
			decoration_sprites.append(sprite)

func _clear_tiles() -> void:
	"""Remove all generated elements."""
	for tile in generated_tiles:
		if is_instance_valid(tile):
			tile.queue_free()
	generated_tiles.clear()

	for decoration in decoration_sprites:
		if is_instance_valid(decoration):
			decoration.queue_free()
	decoration_sprites.clear()

	for overlay in overlay_sprites:
		if is_instance_valid(overlay):
			overlay.queue_free()
	overlay_sprites.clear()

	for tree in tree_sprites:
		if is_instance_valid(tree):
			tree.queue_free()
	tree_sprites.clear()

	for lamp in lamp_nodes:
		if is_instance_valid(lamp):
			lamp.queue_free()
	lamp_nodes.clear()

	for body in water_collision_bodies:
		if is_instance_valid(body):
			body.queue_free()
	water_collision_bodies.clear()

	water_positions.clear()
	dirt_positions.clear()
	clearing_positions.clear()
	clearing_radii.clear()

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
	for overlay in overlay_sprites:
		if is_instance_valid(overlay):
			overlay.visible = visible
	for tree in tree_sprites:
		if is_instance_valid(tree):
			tree.visible = visible
	for lamp in lamp_nodes:
		if is_instance_valid(lamp):
			lamp.visible = visible
