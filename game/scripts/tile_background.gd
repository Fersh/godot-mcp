extends Node2D
## Modular tile-based background system
## Creates a structured arena with roads, clearings, and natural vegetation
## Uses forest_tileset.png for Pitiful, RA_Jungle.png for Easy+

const TILE_SIZE: int = 32
const TILESET_PATH_PITIFUL: String = "res://assets/enviro/forest_tileset.png"
const TILESET_PATH_JUNGLE: String = "res://assets/enviro/adv/jungle/Godot/RA_Jungle.png"
const JUNGLE_TILE_SIZE: int = 16  # Jungle tileset uses 16px tiles

var use_jungle_theme: bool = false
var current_tileset_path: String = TILESET_PATH_PITIFUL

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

# Tree textures - Pitiful theme (forest)
var tree_textures_forest: Array[String] = [
	"res://assets/enviro/gowl/Trees/Tree1.png",
	"res://assets/enviro/gowl/Trees/Tree2.png",
	"res://assets/enviro/gowl/Trees/Tree3.png",
]

# Tree textures - Jungle theme
var tree_textures_jungle: Array[String] = [
	"res://assets/enviro/adv/jungle/Godot/tree01_s_01_animation.png",
	"res://assets/enviro/adv/jungle/Godot/tree02_s_01_animation.png",
	"res://assets/enviro/adv/jungle/Godot/tree03_s_01_animation.png",
	"res://assets/enviro/adv/jungle/Godot/tree04_s_01_animation.png",
	"res://assets/enviro/adv/jungle/Godot/tree05_s_01_animation.png",
	"res://assets/enviro/adv/jungle/Godot/tree06_s_01_animation.png",
]

# Returns the appropriate tree textures based on theme
func get_tree_textures() -> Array[String]:
	return tree_textures_jungle if use_jungle_theme else tree_textures_forest

# ============================================
# JUNGLE TILE DEFINITIONS (16px tiles in RA_Jungle.png)
# ============================================
# Edge offsets from center tile - standard 3x3 pattern (same for all tilesets)
const EDGE_OFFSETS := {
	"center": Vector2i(0, 0),
	"top": Vector2i(0, -1),
	"bottom": Vector2i(0, 1),
	"left": Vector2i(-1, 0),
	"right": Vector2i(1, 0),
	"top_left": Vector2i(-1, -1),
	"top_right": Vector2i(1, -1),
	"bottom_left": Vector2i(-1, 1),
	"bottom_right": Vector2i(1, 1),
}

# Jungle grass - just store centers, edges are auto-calculated via offsets
# Light grass center at tile (1, 34), Dark at (6, 34), Darkest at (11, 34)
const JUNGLE_GRASS_CENTERS := [Vector2i(1, 34), Vector2i(6, 34), Vector2i(11, 34)]
const JUNGLE_TALL_GRASS_CENTERS := [Vector2i(1, 37), Vector2i(6, 37), Vector2i(11, 37)]

# Jungle dirt/path center at tile (1, 31) - 3x3 pattern like grass
const JUNGLE_DIRT_CENTER := Vector2i(1, 31)

# Jungle water center at tile (6, 31) - 3x3 pattern
const JUNGLE_WATER_CENTER := Vector2i(6, 31)

# Jungle outer border uses darkest grass edges
const JUNGLE_BORDER_CENTER := Vector2i(11, 34)

# Jungle decorations - rows 35-36, columns 15-31 (17 decorations per row)
var jungle_decoration_tiles: Array[Rect2i] = []

func _get_jungle_tile(center: Vector2i, edge_type: String) -> Rect2i:
	"""Get a jungle tile rect by center + edge offset. Tiles are 16px."""
	var offset = EDGE_OFFSETS.get(edge_type, Vector2i(0, 0))
	var tile_coord = center + offset
	return Rect2i(tile_coord.x * JUNGLE_TILE_SIZE, tile_coord.y * JUNGLE_TILE_SIZE, JUNGLE_TILE_SIZE, JUNGLE_TILE_SIZE)

func _init_jungle_decorations() -> void:
	jungle_decoration_tiles.clear()
	# Row 35: y = 35 * 16 = 560 (columns 15-31)
	for x in range(15, 32):
		jungle_decoration_tiles.append(Rect2i(x * JUNGLE_TILE_SIZE, 35 * JUNGLE_TILE_SIZE, JUNGLE_TILE_SIZE, JUNGLE_TILE_SIZE))
	# Row 36: y = 36 * 16 = 576 (columns 15-31)
	for x in range(15, 32):
		jungle_decoration_tiles.append(Rect2i(x * JUNGLE_TILE_SIZE, 36 * JUNGLE_TILE_SIZE, JUNGLE_TILE_SIZE, JUNGLE_TILE_SIZE))
	print("TileBackground: Initialized %d jungle decoration tiles" % jungle_decoration_tiles.size())

const LAMP_TEXTURE_PATH: String = "res://assets/enviro/gowl/Wooden/Lamp.png"

var tileset_texture: Texture2D
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Generated elements
var generated_tiles: Array = []
var decoration_sprites: Array[Sprite2D] = []
var overlay_sprites: Array[Sprite2D] = []
var tree_sprites: Array[Sprite2D] = []
var lamp_nodes: Array[Node2D] = []
var chest_node: Node2D = null

# Track placed tree positions for chest spawn check
var placed_tree_positions: Array[Vector2] = []

var arena_offset_x: float = 0.0
var arena_offset_y: float = 0.0

func _ready() -> void:
	z_index = -10
	_determine_theme()
	_init_jungle_decorations()
	_load_tileset()
	generate_arena()

func _determine_theme() -> void:
	# TODO: Re-enable jungle theme once tile coordinates are verified
	# For now, use Pitiful/forest theme for all difficulties
	use_jungle_theme = false
	current_tileset_path = TILESET_PATH_PITIFUL
	print("TileBackground: Using forest theme for all difficulties")

func _load_tileset() -> void:
	tileset_texture = load(current_tileset_path)
	if not tileset_texture:
		push_error("TileBackground: Failed to load tileset from " + current_tileset_path)

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

	# Step 2: Generate floor
	if use_jungle_theme:
		# Jungle uses solid color background + decorations
		_create_jungle_background(scaled_tile_size, arena_pixel_width, arena_pixel_height)
	else:
		# Forest uses tile-based floor
		for y in range(arena_height_tiles):
			for x in range(arena_width_tiles):
				var tile_pos = Vector2(arena_offset_x + x * scaled_tile_size, arena_offset_y + y * scaled_tile_size)
				var tile_type = _determine_tile_type(x, y)
				var tile_rect = _get_tile_rect(tile_type, x, y)
				_create_tile_sprite(tile_pos, tile_rect, tile_type)

				if tile_type.begins_with("water"):
					_create_water_collision(tile_pos, scaled_tile_size)

	# Step 2.5: Generate border extensions (forest theme only)
	if not use_jungle_theme:
		_generate_top_border_extension(scaled_tile_size)
		_generate_water_borders(scaled_tile_size)
	else:
		# Jungle uses simple colored borders
		_generate_jungle_borders(scaled_tile_size, arena_pixel_width, arena_pixel_height)

	# Step 3: Add overlays and objects (respecting structure)
	_generate_trees_structured()
	_generate_lamps_along_roads()
	_generate_small_decorations()

	# Generate tall grass for jungle theme
	if use_jungle_theme:
		_generate_jungle_tall_grass(scaled_tile_size)

	# Step 4: Spawn one treasure chest in a valid location
	_spawn_treasure_chest(scaled_tile_size)

	# Step 5: Apply nightfall lighting effect
	_apply_nightfall_effect()

func _apply_nightfall_effect() -> void:
	# Add a CanvasModulate to darken the scene for a nightfall look
	var modulate = CanvasModulate.new()
	modulate.name = "NightfallModulate"
	# Slight blue tint with darkening - adjust RGB values to control darkness
	# Lower values = darker, blue tint gives evening feel
	modulate.color = Color(0.7, 0.7, 0.85)  # Subtle darkening with slight blue
	add_child(modulate)
	generated_tiles.append(modulate)

func _create_jungle_background(scaled_tile_size: float, width: float, height: float) -> void:
	# Create solid grass background
	var bg = ColorRect.new()
	bg.name = "JungleBackground"
	bg.color = Color(0.267, 0.412, 0.220)  # Dark jungle green
	bg.position = Vector2(arena_offset_x, arena_offset_y)
	bg.size = Vector2(width, height)
	bg.z_index = -11
	add_child(bg)
	generated_tiles.append(bg)

func _generate_jungle_borders(scaled_tile_size: float, width: float, height: float) -> void:
	var water_color = Color(0.247, 0.463, 0.580)  # Blue water
	var border_depth = 10 * scaled_tile_size

	# Top border (darker area)
	var top_border = ColorRect.new()
	top_border.color = Color(0.15, 0.25, 0.12)  # Darker green
	top_border.position = Vector2(arena_offset_x - border_depth, arena_offset_y - border_depth)
	top_border.size = Vector2(width + border_depth * 2, border_depth)
	top_border.z_index = -10
	add_child(top_border)
	generated_tiles.append(top_border)

	# Left water border
	var left_water = ColorRect.new()
	left_water.color = water_color
	left_water.position = Vector2(arena_offset_x - border_depth, arena_offset_y)
	left_water.size = Vector2(border_depth, height + border_depth)
	left_water.z_index = -10
	add_child(left_water)
	generated_tiles.append(left_water)
	_create_water_collision(left_water.position, border_depth)

	# Right water border
	var right_water = ColorRect.new()
	right_water.color = water_color
	right_water.position = Vector2(arena_offset_x + width, arena_offset_y)
	right_water.size = Vector2(border_depth, height + border_depth)
	right_water.z_index = -10
	add_child(right_water)
	generated_tiles.append(right_water)
	_create_water_collision(right_water.position, border_depth)

	# Bottom water border
	var bottom_water = ColorRect.new()
	bottom_water.color = water_color
	bottom_water.position = Vector2(arena_offset_x - border_depth, arena_offset_y + height)
	bottom_water.size = Vector2(width + border_depth * 2, border_depth)
	bottom_water.z_index = -10
	add_child(bottom_water)
	generated_tiles.append(bottom_water)
	_create_water_collision(bottom_water.position, border_depth)

func _generate_jungle_tall_grass(scaled_tile_size: float) -> void:
	# Add clusters of tall grass using jungle tall grass tiles (16px, scaled up)
	# Scale factor to make 16px jungle tiles match 32px forest tile visual size
	var jungle_scale = tile_scale * 2.0  # 16px * 2 * tile_scale = same visual size as 32px * tile_scale

	for _cluster in range(grass_cluster_count):
		var x = rng.randi_range(border_thickness + 3, arena_width_tiles - border_thickness - 3)
		var y = rng.randi_range(border_thickness + 3, arena_height_tiles - border_thickness - 3)

		if _is_in_central_clearing(x, y):
			continue
		if _is_dirt_tile(x, y):
			continue
		if _is_water_tile(x, y):
			continue

		var pos = Vector2(
			arena_offset_x + x * scaled_tile_size + scaled_tile_size / 2,
			arena_offset_y + y * scaled_tile_size + scaled_tile_size / 2
		)

		# Use the center + offset system for tall grass
		var center = JUNGLE_TALL_GRASS_CENTERS[rng.randi() % JUNGLE_TALL_GRASS_CENTERS.size()]
		var grass_rect = _get_jungle_tile(center, "center")

		var sprite = Sprite2D.new()
		sprite.texture = tileset_texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.region_enabled = true
		sprite.region_rect = Rect2(grass_rect)
		sprite.scale = Vector2(jungle_scale, jungle_scale)
		sprite.position = pos
		sprite.z_as_relative = false
		sprite.z_index = 1000  # Overlay on top of characters
		add_child(sprite)
		overlay_sprites.append(sprite)

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

func _generate_water_borders(scaled_tile_size: float) -> void:
	"""Generate water tiles on left, right, and bottom edges of the map."""
	const WATER_BORDER_DEPTH = 10  # 10 tiles of water in each direction

	# Water tile (6,7) = Rect2i(192, 224, 32, 32)
	var water_tile = Rect2i(192, 224, 32, 32)

	# Left water border
	for col in range(WATER_BORDER_DEPTH):
		var tile_x = arena_offset_x - (col + 1) * scaled_tile_size
		for row in range(arena_height_tiles + WATER_BORDER_DEPTH):
			var tile_y = arena_offset_y + row * scaled_tile_size
			_create_tile_sprite(Vector2(tile_x, tile_y), water_tile, "water_border")
			_create_water_collision(Vector2(tile_x, tile_y), scaled_tile_size)

	# Right water border
	for col in range(WATER_BORDER_DEPTH):
		var tile_x = arena_offset_x + (arena_width_tiles + col) * scaled_tile_size
		for row in range(arena_height_tiles + WATER_BORDER_DEPTH):
			var tile_y = arena_offset_y + row * scaled_tile_size
			_create_tile_sprite(Vector2(tile_x, tile_y), water_tile, "water_border")
			_create_water_collision(Vector2(tile_x, tile_y), scaled_tile_size)

	# Bottom water border
	for row in range(WATER_BORDER_DEPTH):
		var tile_y = arena_offset_y + (arena_height_tiles + row) * scaled_tile_size
		for col in range(-WATER_BORDER_DEPTH, arena_width_tiles + WATER_BORDER_DEPTH):
			var tile_x = arena_offset_x + col * scaled_tile_size
			_create_tile_sprite(Vector2(tile_x, tile_y), water_tile, "water_border")
			_create_water_collision(Vector2(tile_x, tile_y), scaled_tile_size)

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
	# For jungle theme, return jungle tiles
	if use_jungle_theme:
		return _get_jungle_tile_rect(tile_type, _x, _y)

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

func _get_jungle_tile_rect(tile_type: String, _x: int, _y: int) -> Rect2i:
	# Jungle tiles are 16px - use center + offset pattern for all tile types
	match tile_type:
		"light_grass":
			# Random grass shade for variety
			var center = JUNGLE_GRASS_CENTERS[rng.randi() % JUNGLE_GRASS_CENTERS.size()]
			return _get_jungle_tile(center, "center")

		# Outer edges - use border center with appropriate edge
		"outer_top": return _get_jungle_tile(JUNGLE_BORDER_CENTER, "top")
		"outer_bottom": return _get_jungle_tile(JUNGLE_BORDER_CENTER, "bottom")
		"outer_left": return _get_jungle_tile(JUNGLE_BORDER_CENTER, "left")
		"outer_right": return _get_jungle_tile(JUNGLE_BORDER_CENTER, "right")
		"outer_top_left": return _get_jungle_tile(JUNGLE_BORDER_CENTER, "top_left")
		"outer_top_right": return _get_jungle_tile(JUNGLE_BORDER_CENTER, "top_right")
		"outer_bottom_left": return _get_jungle_tile(JUNGLE_BORDER_CENTER, "bottom_left")
		"outer_bottom_right": return _get_jungle_tile(JUNGLE_BORDER_CENTER, "bottom_right")

		# Water tiles with proper edges
		"water": return _get_jungle_tile(JUNGLE_WATER_CENTER, "center")
		"water_edge_top": return _get_jungle_tile(JUNGLE_WATER_CENTER, "top")
		"water_edge_bottom": return _get_jungle_tile(JUNGLE_WATER_CENTER, "bottom")
		"water_edge_left": return _get_jungle_tile(JUNGLE_WATER_CENTER, "left")
		"water_edge_right": return _get_jungle_tile(JUNGLE_WATER_CENTER, "right")
		"water_edge_top_left": return _get_jungle_tile(JUNGLE_WATER_CENTER, "top_left")
		"water_edge_top_right": return _get_jungle_tile(JUNGLE_WATER_CENTER, "top_right")
		"water_edge_bottom_left": return _get_jungle_tile(JUNGLE_WATER_CENTER, "bottom_left")
		"water_edge_bottom_right": return _get_jungle_tile(JUNGLE_WATER_CENTER, "bottom_right")

		# Dirt/road tiles with proper edges
		"dirt": return _get_jungle_tile(JUNGLE_DIRT_CENTER, "center")
		"dirt_edge_top": return _get_jungle_tile(JUNGLE_DIRT_CENTER, "top")
		"dirt_edge_bottom": return _get_jungle_tile(JUNGLE_DIRT_CENTER, "bottom")
		"dirt_edge_left": return _get_jungle_tile(JUNGLE_DIRT_CENTER, "left")
		"dirt_edge_right": return _get_jungle_tile(JUNGLE_DIRT_CENTER, "right")
		"dirt_edge_top_left": return _get_jungle_tile(JUNGLE_DIRT_CENTER, "top_left")
		"dirt_edge_top_right": return _get_jungle_tile(JUNGLE_DIRT_CENTER, "top_right")
		"dirt_edge_bottom_left": return _get_jungle_tile(JUNGLE_DIRT_CENTER, "bottom_left")
		"dirt_edge_bottom_right": return _get_jungle_tile(JUNGLE_DIRT_CENTER, "bottom_right")

	# Default: random grass
	var center = JUNGLE_GRASS_CENTERS[rng.randi() % JUNGLE_GRASS_CENTERS.size()]
	return _get_jungle_tile(center, "center")

func _create_tile_sprite(pos: Vector2, region: Rect2i, _tile_type: String = "light_grass") -> void:
	var scaled_tile_size = TILE_SIZE * tile_scale

	var sprite = Sprite2D.new()
	sprite.texture = tileset_texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.region_enabled = true
	sprite.region_rect = Rect2(region)

	# Jungle tiles are 16px, forest tiles are 32px - scale jungle tiles 2x to match
	var actual_scale = tile_scale
	if use_jungle_theme:
		actual_scale = tile_scale * 2.0  # 16px * 2 = 32px equivalent

	sprite.scale = Vector2(actual_scale, actual_scale)
	sprite.position = pos + Vector2(scaled_tile_size / 2, scaled_tile_size / 2)
	sprite.z_index = -10
	add_child(sprite)
	generated_tiles.append(sprite)

# ============================================
# STRUCTURED OBJECT PLACEMENT
# ============================================

func _generate_trees_structured() -> void:
	"""Generate destructible trees with proper spacing (at least 1 tile apart)."""
	var scaled_tile_size = TILE_SIZE * tile_scale

	# Clear tracked positions
	placed_tree_positions.clear()

	# Load destructible tree scene
	var tree_scene = load("res://scenes/environment/destructible_tree.tscn")
	if not tree_scene:
		push_warning("Could not load destructible_tree.tscn")
		return

	# Track placed tree tile positions for spacing check
	var placed_tree_tiles: Array[Vector2i] = []

	# Place trees primarily in border regions (forested edges)
	var trees_placed = 0
	var attempts = 0
	var max_attempts = tree_count * 10

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

		# Check if tree would be too close to water (at least 1 tile away)
		var too_close_to_water = false
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if _is_water_tile(x + dx, y + dy):
					too_close_to_water = true
					break
			if too_close_to_water:
				break
		if too_close_to_water:
			continue

		# Check distance from roads (wider exclusion zone)
		var too_close_to_road = false
		for road_pos in dirt_positions:
			if abs(road_pos.x - x) <= 2 and abs(road_pos.y - y) <= 2:
				too_close_to_road = true
				break
		if too_close_to_road:
			continue

		# Check minimum distance from other trees (at least 1 tile apart)
		var too_close_to_tree = false
		for placed_tile in placed_tree_tiles:
			if abs(placed_tile.x - x) <= 1 and abs(placed_tile.y - y) <= 1:
				too_close_to_tree = true
				break
		if too_close_to_tree:
			continue

		var pos = Vector2(
			arena_offset_x + x * scaled_tile_size,
			arena_offset_y + y * scaled_tile_size
		)

		# Instantiate destructible tree
		var tree_instance = tree_scene.instantiate()
		tree_instance.position = pos
		# Randomize tree size - use region_rect frame size for scale calculation
		var base_scale = tree_scale
		if use_jungle_theme:
			# Jungle tree frames are 64x240, need appropriate scale
			base_scale = tree_scale * 0.4  # Smaller base since frames are tall
		var random_scale = base_scale * rng.randf_range(0.8, 1.3)
		tree_instance.scale = Vector2(random_scale, random_scale)

		# Randomize tree texture based on theme
		var tree_textures_loaded: Array[Texture2D] = []
		var current_tree_textures = get_tree_textures()
		for path in current_tree_textures:
			var tex = load(path)
			if tex:
				tree_textures_loaded.append(tex)

		if not tree_textures_loaded.is_empty():
			var random_tex = tree_textures_loaded[rng.randi() % tree_textures_loaded.size()]
			var sprite_node = tree_instance.get_node_or_null("Sprite")
			if sprite_node:
				sprite_node.texture = random_tex
				# Jungle tree textures are sprite sheets (256x240) - use only first frame
				if use_jungle_theme:
					sprite_node.region_enabled = true
					sprite_node.region_rect = Rect2(0, 0, 64, 240)  # First frame of 4-frame horizontal strip
			var shadow_node = tree_instance.get_node_or_null("Shadow")
			if shadow_node:
				shadow_node.texture = random_tex
				if use_jungle_theme:
					shadow_node.region_enabled = true
					shadow_node.region_rect = Rect2(0, 0, 64, 240)

		add_child(tree_instance)
		tree_sprites.append(tree_instance)
		placed_tree_tiles.append(Vector2i(x, y))
		placed_tree_positions.append(pos)  # Track world position for chest spawn
		trees_placed += 1

	print("TileBackground: Placed %d trees (jungle theme: %s)" % [trees_placed, use_jungle_theme])

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
	"""Create a destructible lamp with light at the given position."""
	# Load destructible lamp scene
	var lamp_scene = load("res://scenes/environment/destructible_lamp.tscn")
	if lamp_scene:
		var lamp_instance = lamp_scene.instantiate()
		lamp_instance.position = pos
		lamp_instance.scale = Vector2(lamp_scale, lamp_scale)

		# Update sprite texture (in case we want different lamp types later)
		var sprite_node = lamp_instance.get_node_or_null("Sprite")
		if sprite_node and lamp_tex:
			sprite_node.texture = lamp_tex

		# Add point light
		var light = PointLight2D.new()
		light.position = Vector2(0, -lamp_tex.get_height() * lamp_scale * 0.35)
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
		lamp_instance.add_child(light)

		add_child(lamp_instance)
		lamp_nodes.append(lamp_instance)
	else:
		# Fallback to old behavior if scene not found
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
	var scaled_tile_size = TILE_SIZE * tile_scale

	# Use jungle decorations or forest decorations based on theme
	if use_jungle_theme:
		if jungle_decoration_tiles.is_empty():
			return
		_generate_jungle_decorations(scaled_tile_size)
	else:
		if decoration_tiles.is_empty():
			return
		_generate_forest_decorations(scaled_tile_size)

func _generate_forest_decorations(scaled_tile_size: float) -> void:
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

func _generate_jungle_decorations(scaled_tile_size: float) -> void:
	# Higher decoration density for jungle theme
	var jungle_decoration_density = decoration_density * 2.0  # Double the density
	var decorations_placed = 0
	# Scale factor for 16px jungle tiles to match 32px forest tiles
	var jungle_scale = tile_scale * 2.0

	for y in range(border_thickness + 2, arena_height_tiles - border_thickness - 2):
		for x in range(border_thickness + 2, arena_width_tiles - border_thickness - 2):
			if rng.randf() > jungle_decoration_density:
				continue

			if _is_water_tile(x, y) or _is_dirt_tile(x, y):
				continue

			# Skip central clearing for decorations
			if _is_in_central_clearing(x, y):
				continue

			var decoration_rect = jungle_decoration_tiles[rng.randi() % jungle_decoration_tiles.size()]
			var sprite = Sprite2D.new()
			sprite.texture = tileset_texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.region_enabled = true
			sprite.region_rect = Rect2(decoration_rect)
			# Use proper jungle scale (16px * 2 = 32px equivalent)
			sprite.scale = Vector2(jungle_scale, jungle_scale)

			var pos = Vector2(
				arena_offset_x + x * scaled_tile_size + scaled_tile_size / 2,
				arena_offset_y + y * scaled_tile_size + scaled_tile_size / 2
			)

			sprite.position = pos
			sprite.z_index = -5  # Above background (-11) but below characters
			add_child(sprite)
			decoration_sprites.append(sprite)
			decorations_placed += 1

	print("TileBackground: Placed %d jungle decorations" % decorations_placed)

func _spawn_treasure_chest(scaled_tile_size: float) -> void:
	"""Spawn a single treasure chest away from player spawn area."""
	var chest_scene = load("res://scenes/environment/treasure_chest.tscn")
	if not chest_scene:
		push_error("TreasureChest: Could not load treasure_chest.tscn")
		return

	var min_tree_distance = scaled_tile_size * 1.5
	# Player spawns in central clearing - chest must be at least 1 screen away
	# Screen is 1280x752, so use ~700 pixels as minimum distance from center
	var min_distance_from_center = 700.0
	var attempts = 0
	var max_attempts = 200

	# Calculate the center of the arena in world coordinates
	var arena_center = Vector2(
		arena_offset_x + (arena_width_tiles / 2.0) * scaled_tile_size,
		arena_offset_y + (arena_height_tiles / 2.0) * scaled_tile_size
	)

	while attempts < max_attempts:
		attempts += 1

		# Pick a random tile position (avoiding borders)
		var x = rng.randi_range(border_thickness + 2, arena_width_tiles - border_thickness - 2)
		var y = rng.randi_range(border_thickness + 2, arena_height_tiles - border_thickness - 2)

		# Skip water tiles
		if _is_water_tile(x, y):
			continue

		var pos = Vector2(
			arena_offset_x + x * scaled_tile_size + scaled_tile_size / 2,
			arena_offset_y + y * scaled_tile_size + scaled_tile_size / 2
		)

		# Skip if too close to arena center (player spawn area)
		if pos.distance_to(arena_center) < min_distance_from_center:
			continue

		# Check distance from all trees
		var too_close_to_tree = false
		for tree_pos in placed_tree_positions:
			if pos.distance_to(tree_pos) < min_tree_distance:
				too_close_to_tree = true
				break
		if too_close_to_tree:
			continue

		# Valid position found - spawn the chest
		chest_node = chest_scene.instantiate()
		chest_node.position = pos
		chest_node.z_index = int(pos.y / 10)
		add_child(chest_node)
		return

	push_error("TreasureChest: Could not find valid position after %d attempts" % max_attempts)

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
	placed_tree_positions.clear()

	# Clear treasure chest
	if chest_node and is_instance_valid(chest_node):
		chest_node.queue_free()
		chest_node = null

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
