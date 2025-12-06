extends Node2D
## Modular tile-based background system using forest_tileset.png
## Creates a structured arena with roads, clearings, and natural vegetation

const TILE_SIZE: int = 32
const TILESET_PATH: String = "res://assets/enviro/forest_tileset.png"

@export var tile_scale: float = 2.0
@export var arena_width_tiles: int = 48
@export var arena_height_tiles: int = 36
@export var border_thickness: int = 4
@export var decoration_density: float = 0.04
@export var generation_seed: int = 0
@export var edge_variation: int = 3

# Road settings
@export var road_width: int = 2  # Width of roads in tiles

# Water pool settings
@export var water_pool_count: int = 2
@export var water_pool_min_size: int = 2
@export var water_pool_max_size: int = 4

# Tree settings
@export var tree_count: int = 20
@export var tree_scale: float = 2.5

# Lamp settings
@export var lamp_count: int = 8
@export var lamp_scale: float = 2.0

# Tall grass settings
@export var grass_cluster_count: int = 15

# Stores terrain data
var border_noise: Dictionary = {}
var water_positions: Array[Vector2i] = []
var dirt_positions: Array[Vector2i] = []  # Road tiles
var water_collision_bodies: Array[StaticBody2D] = []

# Map structure - zones
var central_clearing_center: Vector2i
var central_clearing_radius: int = 8

# Road waypoints for connected paths
var road_waypoints: Array[Vector2i] = []

# ============================================
# TILE DEFINITIONS
# ============================================
var light_field_tiles: Array[Rect2i] = [
	Rect2i(192, 128, 32, 32),
	Rect2i(192, 448, 32, 32),
	Rect2i(224, 448, 32, 32),
	Rect2i(256, 448, 32, 32),
	Rect2i(192, 480, 32, 32),
	Rect2i(224, 480, 32, 32),
]

# Dark grass tiles removed - no longer used

# Dirt/road tiles (6,1 area - dirt surrounded by grass)
var dirt_grass_center: Rect2i = Rect2i(192, 32, 32, 32)
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

# Yellow grass - center tall tile and surrounding base tiles
var tall_yellow_grass_center: Rect2i = Rect2i(128, 576, 32, 32)  # (4, 18) - the tall center
var yellow_grass_base_tiles: Array[Rect2i] = [
	Rect2i(96, 544, 32, 32),   # (3, 17) - top-left base
	Rect2i(128, 544, 32, 32),  # (4, 17) - top base
	Rect2i(160, 544, 32, 32),  # (5, 17) - top-right base
	Rect2i(96, 576, 32, 32),   # (3, 18) - left base
	Rect2i(160, 576, 32, 32),  # (5, 18) - right base
	Rect2i(96, 608, 32, 32),   # (3, 19) - bottom-left base
	Rect2i(128, 608, 32, 32),  # (4, 19) - bottom base
	Rect2i(160, 608, 32, 32),  # (5, 19) - bottom-right base
]

# Green grass - center tall tile and surrounding base tiles
var tall_green_grass_center: Rect2i = Rect2i(32, 768, 32, 32)  # (1, 24) - the tall center
var green_grass_base_tiles: Array[Rect2i] = [
	Rect2i(0, 736, 32, 32),    # (0, 23) - top-left base
	Rect2i(32, 736, 32, 32),   # (1, 23) - top base
	Rect2i(64, 736, 32, 32),   # (2, 23) - top-right base
	Rect2i(0, 768, 32, 32),    # (0, 24) - left base
	Rect2i(64, 768, 32, 32),   # (2, 24) - right base
	Rect2i(0, 800, 32, 32),    # (0, 25) - bottom-left base
	Rect2i(32, 800, 32, 32),   # (1, 25) - bottom base
	Rect2i(64, 800, 32, 32),   # (2, 25) - bottom-right base
]

# Water tiles
var water_grass_center: Rect2i = Rect2i(192, 224, 32, 32)
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

# Outer edge tiles - using new tile positions
# (2,6) = top-left corner, (3,6) = top, (4,6) = top-right corner
# (2,7) = left, (4,7) = right
# (2,8) = bottom-left corner, (3,8) = bottom, (4,8) = bottom-right corner
var outer_edge_tiles: Dictionary = {
	"top": Rect2i(96, 192, 32, 32),        # (3, 6)
	"bottom": Rect2i(96, 256, 32, 32),     # (3, 8)
	"left": Rect2i(64, 224, 32, 32),       # (2, 7)
	"right": Rect2i(128, 224, 32, 32),     # (4, 7)
	"top_left": Rect2i(64, 192, 32, 32),   # (2, 6)
	"top_right": Rect2i(128, 192, 32, 32), # (4, 6)
	"bottom_left": Rect2i(64, 256, 32, 32),  # (2, 8)
	"bottom_right": Rect2i(128, 256, 32, 32), # (4, 8)
}

# Top border extension tiles (above the playable area)
# (2,11) for main top border, (2,10) for tiles above that
var top_border_tile: Rect2i = Rect2i(64, 352, 32, 32)      # (2, 11)
var top_border_above_tile: Rect2i = Rect2i(64, 320, 32, 32) # (2, 10)

# Inner edge tiles removed - no longer used

# Small decorations
var decoration_tiles: Array[Dictionary] = [
	{"rect": Rect2i(192, 608, 32, 32), "type": "small"},
	{"rect": Rect2i(224, 608, 32, 32), "type": "small"},
	{"rect": Rect2i(256, 608, 32, 32), "type": "small"},
	{"rect": Rect2i(224, 704, 32, 32), "type": "log"},
	{"rect": Rect2i(256, 704, 32, 32), "type": "log"},
	{"rect": Rect2i(288, 704, 32, 32), "type": "log"},
]

# Tree textures
var tree_textures: Array[String] = [
	"res://assets/enviro/gowl/Trees/Tree1.png",
	"res://assets/enviro/gowl/Trees/Tree2.png",
	"res://assets/enviro/gowl/Trees/Tree3.png",
]

const LAMP_TEXTURE_PATH: String = "res://assets/enviro/gowl/Wooden/Lamp.png"

var tileset_texture: Texture2D
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Generated elements
var generated_tiles: Array = []
var decoration_sprites: Array[Sprite2D] = []
var overlay_sprites: Array[Sprite2D] = []
var tree_sprites: Array[Sprite2D] = []
var lamp_nodes: Array[Node2D] = []

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
	if not tileset_texture:
		return

	if generation_seed != 0:
		rng.seed = generation_seed
	else:
		rng.randomize()

	_clear_tiles()

	var scaled_tile_size = TILE_SIZE * tile_scale
	var arena_pixel_width = arena_width_tiles * scaled_tile_size
	var arena_pixel_height = arena_height_tiles * scaled_tile_size
	arena_offset_x = (1536 - arena_pixel_width) / 2
	arena_offset_y = 100

	# Step 1: Generate map structure
	_generate_border_noise()
	_define_central_clearing()
	_generate_road_network()
	_generate_water_pools()

	# Step 2: Generate floor tiles
	for y in range(arena_height_tiles):
		for x in range(arena_width_tiles):
			var tile_pos = Vector2(arena_offset_x + x * scaled_tile_size, arena_offset_y + y * scaled_tile_size)
			var tile_type = _determine_tile_type(x, y)
			var tile_rect = _get_tile_rect(tile_type, x, y)
			_create_tile_sprite(tile_pos, tile_rect, tile_type)

			if tile_type.begins_with("water"):
				_create_water_collision(tile_pos, scaled_tile_size)

	# Step 2.5: Generate top border extension (above playable area)
	_generate_top_border_extension(scaled_tile_size)

	# Step 3: Add overlays and objects (respecting structure)
	_generate_trees_structured()
	_generate_lamps_along_roads()
	# Tall grass disabled - not using yellow or green grass overlays
	# _generate_tall_grass_clusters()
	_generate_small_decorations()

func _define_central_clearing() -> void:
	"""Define the central open area where combat happens."""
	central_clearing_center = Vector2i(arena_width_tiles / 2, arena_height_tiles / 2)
	central_clearing_radius = 8

func _is_in_central_clearing(x: int, y: int) -> bool:
	"""Check if tile is in the main open combat area."""
	var dx = x - central_clearing_center.x
	var dy = y - central_clearing_center.y
	return sqrt(dx * dx + dy * dy) < central_clearing_radius

func _generate_road_network() -> void:
	"""Generate connected dirt roads forming a cross pattern through the arena."""
	dirt_positions.clear()
	road_waypoints.clear()

	var center_x = arena_width_tiles / 2
	var center_y = arena_height_tiles / 2

	# Create main crossroads through center
	# Horizontal road
	var road_y_offset = rng.randi_range(-2, 2)
	_create_road_segment(
		Vector2i(border_thickness + 2, center_y + road_y_offset),
		Vector2i(arena_width_tiles - border_thickness - 2, center_y + road_y_offset)
	)

	# Vertical road
	var road_x_offset = rng.randi_range(-2, 2)
	_create_road_segment(
		Vector2i(center_x + road_x_offset, border_thickness + 2),
		Vector2i(center_x + road_x_offset, arena_height_tiles - border_thickness - 2)
	)

	# Add a curved path to one corner for variety
	var corner = rng.randi() % 4
	match corner:
		0:  # Top-left curve
			_create_road_segment(
				Vector2i(center_x + road_x_offset, center_y + road_y_offset),
				Vector2i(border_thickness + 4, border_thickness + 4)
			)
		1:  # Top-right curve
			_create_road_segment(
				Vector2i(center_x + road_x_offset, center_y + road_y_offset),
				Vector2i(arena_width_tiles - border_thickness - 4, border_thickness + 4)
			)
		2:  # Bottom-left curve
			_create_road_segment(
				Vector2i(center_x + road_x_offset, center_y + road_y_offset),
				Vector2i(border_thickness + 4, arena_height_tiles - border_thickness - 4)
			)
		3:  # Bottom-right curve
			_create_road_segment(
				Vector2i(center_x + road_x_offset, center_y + road_y_offset),
				Vector2i(arena_width_tiles - border_thickness - 4, arena_height_tiles - border_thickness - 4)
			)

	# Store waypoints for lamp placement
	road_waypoints.append(Vector2i(center_x + road_x_offset, center_y + road_y_offset))
	road_waypoints.append(Vector2i(border_thickness + 4, center_y + road_y_offset))
	road_waypoints.append(Vector2i(arena_width_tiles - border_thickness - 4, center_y + road_y_offset))
	road_waypoints.append(Vector2i(center_x + road_x_offset, border_thickness + 4))
	road_waypoints.append(Vector2i(center_x + road_x_offset, arena_height_tiles - border_thickness - 4))

func _create_road_segment(start: Vector2i, end: Vector2i) -> void:
	"""Create a road segment between two points using Bresenham-style line with width."""
	var dx = abs(end.x - start.x)
	var dy = abs(end.y - start.y)
	var sx = 1 if start.x < end.x else -1
	var sy = 1 if start.y < end.y else -1
	var err = dx - dy

	var x = start.x
	var y = start.y

	while true:
		# Add road tiles with width
		for wy in range(-road_width / 2, road_width / 2 + 1):
			for wx in range(-road_width / 2, road_width / 2 + 1):
				var pos = Vector2i(x + wx, y + wy)
				if _is_valid_tile(pos.x, pos.y) and not dirt_positions.has(pos):
					dirt_positions.append(pos)

		if x == end.x and y == end.y:
			break

		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy

func _is_valid_tile(x: int, y: int) -> bool:
	"""Check if tile coordinates are within valid bounds."""
	return x >= 1 and x < arena_width_tiles - 1 and y >= 1 and y < arena_height_tiles - 1

func _generate_water_pools() -> void:
	"""Generate water pools away from roads and clearing."""
	water_positions.clear()

	var safe_margin = border_thickness + edge_variation + 3
	var attempts = 0
	var max_attempts = 50

	for _pool in range(water_pool_count):
		attempts = 0
		while attempts < max_attempts:
			attempts += 1

			var pool_width = rng.randi_range(water_pool_min_size, water_pool_max_size)
			var pool_height = rng.randi_range(water_pool_min_size, water_pool_max_size)

			var center_x = rng.randi_range(safe_margin + pool_width, arena_width_tiles - safe_margin - pool_width)
			var center_y = rng.randi_range(safe_margin + pool_height, arena_height_tiles - safe_margin - pool_height)

			# Check if pool overlaps with roads or central clearing
			var valid = true
			if _is_in_central_clearing(center_x, center_y):
				valid = false

			# Check distance from roads
			for road_pos in dirt_positions:
				if abs(road_pos.x - center_x) < pool_width + 2 and abs(road_pos.y - center_y) < pool_height + 2:
					valid = false
					break

			if valid:
				# Create elliptical pool
				for dy in range(-pool_height, pool_height + 1):
					for dx in range(-pool_width, pool_width + 1):
						var nx = float(dx) / float(pool_width)
						var ny = float(dy) / float(pool_height)
						if nx * nx + ny * ny <= 1.0:
							var pos = Vector2i(center_x + dx, center_y + dy)
							if not water_positions.has(pos) and not dirt_positions.has(pos):
								water_positions.append(pos)
				break

func _is_water_tile(x: int, y: int) -> bool:
	return water_positions.has(Vector2i(x, y))

func _is_dirt_tile(x: int, y: int) -> bool:
	return dirt_positions.has(Vector2i(x, y))

func _get_water_edge_type(x: int, y: int) -> String:
	var has_top = _is_water_tile(x, y - 1)
	var has_bottom = _is_water_tile(x, y + 1)
	var has_left = _is_water_tile(x - 1, y)
	var has_right = _is_water_tile(x + 1, y)

	var count = int(has_top) + int(has_bottom) + int(has_left) + int(has_right)

	if count == 4:
		return "water"

	if not has_top and has_bottom and has_left and has_right:
		return "water_edge_top"
	if has_top and not has_bottom and has_left and has_right:
		return "water_edge_bottom"
	if has_top and has_bottom and not has_left and has_right:
		return "water_edge_left"
	if has_top and has_bottom and has_left and not has_right:
		return "water_edge_right"

	if not has_top and not has_left:
		return "water_edge_top_left"
	if not has_top and not has_right:
		return "water_edge_top_right"
	if not has_bottom and not has_left:
		return "water_edge_bottom_left"
	if not has_bottom and not has_right:
		return "water_edge_bottom_right"

	return "water"

func _get_dirt_edge_type(x: int, y: int) -> String:
	var has_top = _is_dirt_tile(x, y - 1)
	var has_bottom = _is_dirt_tile(x, y + 1)
	var has_left = _is_dirt_tile(x - 1, y)
	var has_right = _is_dirt_tile(x + 1, y)

	var count = int(has_top) + int(has_bottom) + int(has_left) + int(has_right)

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
	var body = StaticBody2D.new()
	body.position = pos + Vector2(size / 2, size / 2)
	# Layer 1 = terrain that blocks player/enemies, Layer 2 = water (for player detection)
	body.collision_layer = 3  # Layers 1 and 2 (binary 11)
	body.collision_mask = 0

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(size * 0.85, size * 0.85)
	collision.shape = shape

	body.add_child(collision)
	add_child(body)
	water_collision_bodies.append(body)

func _generate_border_noise() -> void:
	border_noise.clear()

	for x in range(arena_width_tiles):
		var noise_top = rng.randi_range(-edge_variation, edge_variation)
		var noise_bottom = rng.randi_range(-edge_variation, edge_variation)

		if x > 0:
			noise_top = int((noise_top + border_noise.get("top_" + str(x - 1), 0)) / 2.0)
			noise_bottom = int((noise_bottom + border_noise.get("bottom_" + str(x - 1), 0)) / 2.0)

		border_noise["top_" + str(x)] = noise_top
		border_noise["bottom_" + str(x)] = noise_bottom

	for y in range(arena_height_tiles):
		var noise_left = rng.randi_range(-edge_variation, edge_variation)
		var noise_right = rng.randi_range(-edge_variation, edge_variation)

		if y > 0:
			noise_left = int((noise_left + border_noise.get("left_" + str(y - 1), 0)) / 2.0)
			noise_right = int((noise_right + border_noise.get("right_" + str(y - 1), 0)) / 2.0)

		border_noise["left_" + str(y)] = noise_left
		border_noise["right_" + str(y)] = noise_right

func _generate_top_border_extension(scaled_tile_size: float) -> void:
	"""Generate top border tiles above the playable area so camera doesn't show void."""
	# Number of rows to extend above the arena
	const TOP_EXTENSION_ROWS = 6

	for row in range(TOP_EXTENSION_ROWS):
		var y_offset = -(row + 1)  # -1, -2, -3, -4, -5, -6
		var tile_y = arena_offset_y + y_offset * scaled_tile_size

		for x in range(arena_width_tiles):
			var tile_x = arena_offset_x + x * scaled_tile_size
			var tile_pos = Vector2(tile_x, tile_y)

			# First row uses (2,11), subsequent rows use (2,10)
			var tile_rect: Rect2i
			if row == 0:
				tile_rect = top_border_tile  # (2, 11)
			else:
				tile_rect = top_border_above_tile  # (2, 10)

			_create_tile_sprite(tile_pos, tile_rect, "top_border")

func _determine_tile_type(x: int, y: int) -> String:
	var max_x = arena_width_tiles - 1
	var max_y = arena_height_tiles - 1

	# Priority: Water > Dirt/Roads > Normal terrain
	if _is_water_tile(x, y):
		return _get_water_edge_type(x, y)

	if _is_dirt_tile(x, y):
		return _get_dirt_edge_type(x, y)

	# Border logic with noise
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
	if y == 0 and x == 0: return "outer_top_left"
	if y == 0 and x == max_x: return "outer_top_right"
	if y == max_y and x == 0: return "outer_bottom_left"
	if y == max_y and x == max_x: return "outer_bottom_right"
	if y == 0: return "outer_top"
	if y == max_y: return "outer_bottom"
	if x == 0: return "outer_left"
	if x == max_x: return "outer_right"

	# Border zones
	var in_top = y < top_threshold
	var in_bottom = y > bottom_threshold
	var in_left = x < left_threshold
	var in_right = x > right_threshold

	# Inner edge tiles removed - all non-outer areas use light grass
	return "light_grass"

func _get_tile_rect(tile_type: String, _x: int, _y: int) -> Rect2i:
	match tile_type:
		"light_grass":
			return light_field_tiles[rng.randi() % light_field_tiles.size()]

		"outer_top": return outer_edge_tiles["top"]
		"outer_bottom": return outer_edge_tiles["bottom"]
		"outer_left": return outer_edge_tiles["left"]
		"outer_right": return outer_edge_tiles["right"]
		"outer_top_left": return outer_edge_tiles["top_left"]
		"outer_top_right": return outer_edge_tiles["top_right"]
		"outer_bottom_left": return outer_edge_tiles["bottom_left"]
		"outer_bottom_right": return outer_edge_tiles["bottom_right"]

		# Inner edge tiles removed - no longer used

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

	return light_field_tiles[rng.randi() % light_field_tiles.size()]

func _create_tile_sprite(pos: Vector2, region: Rect2i, _tile_type: String = "light_grass") -> void:
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
# STRUCTURED OBJECT PLACEMENT
# ============================================

func _generate_trees_structured() -> void:
	"""Generate trees in border areas and corners, avoiding roads and central clearing."""
	var scaled_tile_size = TILE_SIZE * tile_scale

	var loaded_trees: Array[Texture2D] = []
	for path in tree_textures:
		var tex = load(path)
		if tex:
			loaded_trees.append(tex)

	if loaded_trees.is_empty():
		return

	# Place trees primarily in border regions (forested edges)
	var trees_placed = 0
	var attempts = 0
	var max_attempts = tree_count * 5

	while trees_placed < tree_count and attempts < max_attempts:
		attempts += 1

		# Bias toward edges
		var x: int
		var y: int

		if rng.randf() < 0.7:  # 70% chance to place in border
			var edge = rng.randi() % 4
			match edge:
				0:  # Top border
					x = rng.randi_range(2, arena_width_tiles - 2)
					y = rng.randi_range(2, border_thickness + edge_variation)
				1:  # Bottom border
					x = rng.randi_range(2, arena_width_tiles - 2)
					y = rng.randi_range(arena_height_tiles - border_thickness - edge_variation, arena_height_tiles - 2)
				2:  # Left border
					x = rng.randi_range(2, border_thickness + edge_variation)
					y = rng.randi_range(2, arena_height_tiles - 2)
				3:  # Right border
					x = rng.randi_range(arena_width_tiles - border_thickness - edge_variation, arena_width_tiles - 2)
					y = rng.randi_range(2, arena_height_tiles - 2)
		else:  # 30% can be in playable area but not in clearing or on roads
			x = rng.randi_range(border_thickness + 2, arena_width_tiles - border_thickness - 2)
			y = rng.randi_range(border_thickness + 2, arena_height_tiles - border_thickness - 2)

		# Check exclusions
		if _is_in_central_clearing(x, y):
			continue
		if _is_dirt_tile(x, y):
			continue
		if _is_water_tile(x, y):
			continue

		# Check distance from roads (wider exclusion zone)
		var too_close_to_road = false
		for road_pos in dirt_positions:
			if abs(road_pos.x - x) <= 2 and abs(road_pos.y - y) <= 2:
				too_close_to_road = true
				break
		if too_close_to_road:
			continue

		var pos = Vector2(
			arena_offset_x + x * scaled_tile_size + rng.randf_range(-10, 10),
			arena_offset_y + y * scaled_tile_size + rng.randf_range(-10, 10)
		)

		var tree_tex = loaded_trees[rng.randi() % loaded_trees.size()]

		var sprite = Sprite2D.new()
		sprite.texture = tree_tex
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(tree_scale, tree_scale)
		sprite.position = pos
		sprite.offset = Vector2(0, -tree_tex.get_height() / 2)
		sprite.z_index = int(pos.y / 10)

		add_child(sprite)
		tree_sprites.append(sprite)
		trees_placed += 1

func _generate_lamps_along_roads() -> void:
	"""Place lamps on grass tiles beside roads, not on the roads themselves."""
	var scaled_tile_size = TILE_SIZE * tile_scale

	var lamp_tex = load(LAMP_TEXTURE_PATH)
	if not lamp_tex:
		return

	var placed_positions: Array[Vector2] = []
	var min_lamp_distance = scaled_tile_size * 6

	# Find all grass tiles that are adjacent to dirt roads
	var roadside_grass: Array[Vector2i] = []
	for road_pos in dirt_positions:
		# Check all 4 cardinal directions for grass tiles
		var offsets = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
		for offset in offsets:
			var adjacent = road_pos + offset
			# Must be valid, not dirt, not water, not in central clearing
			if _is_valid_tile(adjacent.x, adjacent.y) and \
			   not _is_dirt_tile(adjacent.x, adjacent.y) and \
			   not _is_water_tile(adjacent.x, adjacent.y) and \
			   not _is_in_central_clearing(adjacent.x, adjacent.y) and \
			   not roadside_grass.has(adjacent):
				roadside_grass.append(adjacent)

	# Shuffle the roadside positions for variety
	roadside_grass.shuffle()

	# Place lamps on roadside grass tiles
	for grass_pos in roadside_grass:
		if placed_positions.size() >= lamp_count:
			break

		var pos = Vector2(
			arena_offset_x + grass_pos.x * scaled_tile_size,
			arena_offset_y + grass_pos.y * scaled_tile_size
		)

		# Check minimum distance from other lamps
		var too_close = false
		for existing in placed_positions:
			if pos.distance_to(existing) < min_lamp_distance:
				too_close = true
				break
		if too_close:
			continue

		_create_lamp_at(pos, lamp_tex)
		placed_positions.append(pos)

func _create_lamp_at(pos: Vector2, lamp_tex: Texture2D) -> void:
	"""Create a lamp with light at the given position."""
	var lamp_node = Node2D.new()
	lamp_node.position = pos

	var sprite = Sprite2D.new()
	sprite.texture = lamp_tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(lamp_scale, lamp_scale)
	sprite.offset = Vector2(0, -lamp_tex.get_height() / 2)
	lamp_node.add_child(sprite)

	var light = PointLight2D.new()
	light.position = Vector2(0, -lamp_tex.get_height() * lamp_scale * 0.7)
	light.color = Color(1.0, 0.85, 0.6, 1.0)
	light.energy = 0.5
	light.texture_scale = 2.5

	var gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0, 0.4, 1])
	gradient.colors = PackedColorArray([
		Color(1, 1, 1, 1),
		Color(1, 0.9, 0.7, 0.7),
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

	lamp_node.z_index = int(pos.y / 10)

	add_child(lamp_node)
	lamp_nodes.append(lamp_node)

func _generate_tall_grass_clusters() -> void:
	"""Generate tall grass clusters with proper base tiles and overlay z-index."""
	var scaled_tile_size = TILE_SIZE * tile_scale

	for _cluster in range(grass_cluster_count):
		var x = rng.randi_range(border_thickness + 3, arena_width_tiles - border_thickness - 3)
		var y = rng.randi_range(border_thickness + 3, arena_height_tiles - border_thickness - 3)

		# Skip bad locations
		if _is_in_central_clearing(x, y):
			continue
		if _is_dirt_tile(x, y):
			continue
		if _is_water_tile(x, y):
			continue

		# Check if any surrounding tiles (for base grass) would be on water
		var has_water_nearby = false
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if _is_water_tile(x + dx, y + dy):
					has_water_nearby = true
					break
			if has_water_nearby:
				break
		if has_water_nearby:
			continue

		var center_pos = Vector2(
			arena_offset_x + x * scaled_tile_size + scaled_tile_size / 2,
			arena_offset_y + y * scaled_tile_size + scaled_tile_size / 2
		)

		var use_yellow = rng.randf() < 0.4
		_create_grass_cluster(center_pos, use_yellow)

func _create_grass_cluster(center_pos: Vector2, use_yellow: bool) -> void:
	"""Create a grass cluster with surrounding base tiles and tall center."""
	var scaled_tile_size = TILE_SIZE * tile_scale

	var center_tile: Rect2i
	var base_tiles: Array[Rect2i]

	if use_yellow:
		center_tile = tall_yellow_grass_center
		base_tiles = yellow_grass_base_tiles
	else:
		center_tile = tall_green_grass_center
		base_tiles = green_grass_base_tiles

	# Place surrounding base tiles first (lower z-index)
	var base_offsets = [
		Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1),  # top row
		Vector2(-1, 0),                  Vector2(1, 0),   # middle sides
		Vector2(-1, 1),  Vector2(0, 1),  Vector2(1, 1),   # bottom row
	]

	for i in range(base_offsets.size()):
		var offset = base_offsets[i] * scaled_tile_size
		var base_pos = center_pos + offset
		var base_tile = base_tiles[i]
		_create_grass_sprite(base_pos, base_tile, false)

	# Place tall center tile with high z-index to overlay characters
	_create_grass_sprite(center_pos, center_tile, true)

func _create_grass_sprite(pos: Vector2, region: Rect2i, is_tall: bool) -> void:
	"""Create a grass sprite. Tall grass overlays characters."""
	var sprite = Sprite2D.new()
	sprite.texture = tileset_texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.region_enabled = true
	sprite.region_rect = Rect2(region)
	sprite.scale = Vector2(tile_scale, tile_scale)
	sprite.position = pos

	if is_tall:
		# Very high z-index to render on top of characters/enemies
		# Use z_as_relative = false to ensure absolute z ordering
		sprite.z_as_relative = false
		sprite.z_index = 1000
	else:
		# Base tiles render below characters
		sprite.z_index = -5

	add_child(sprite)
	overlay_sprites.append(sprite)

func _generate_small_decorations() -> void:
	if decoration_tiles.is_empty():
		return

	var scaled_tile_size = TILE_SIZE * tile_scale

	for y in range(border_thickness + 2, arena_height_tiles - border_thickness - 2):
		for x in range(border_thickness + 2, arena_width_tiles - border_thickness - 2):
			if rng.randf() > decoration_density:
				continue

			if _is_water_tile(x, y) or _is_dirt_tile(x, y):
				continue

			var decoration = decoration_tiles[rng.randi() % decoration_tiles.size()]
			var sprite = Sprite2D.new()
			sprite.texture = tileset_texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.region_enabled = true
			sprite.region_rect = Rect2(decoration["rect"])
			sprite.scale = Vector2(tile_scale, tile_scale)

			var pos = Vector2(
				arena_offset_x + x * scaled_tile_size + scaled_tile_size / 2,
				arena_offset_y + y * scaled_tile_size + scaled_tile_size / 2
			)

			sprite.position = pos
			sprite.z_index = -9
			add_child(sprite)
			decoration_sprites.append(sprite)

func _clear_tiles() -> void:
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
	road_waypoints.clear()

func regenerate(new_seed: int = 0) -> void:
	generation_seed = new_seed
	generate_arena()

func set_visible_tiles(visible: bool) -> void:
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
