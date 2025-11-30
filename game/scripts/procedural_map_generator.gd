extends Node2D

## Procedural Map Generator
## Creates a 2500x2500 playable area surrounded by water.
## Scatters trees, rocks, lamps, and rare magic stones.

signal map_generated(map_bounds: Rect2)

# Map configuration
const MAP_SIZE: int = 2500  # 2500x2500 playable area
const TILE_SIZE: int = 16
const WATER_BORDER: int = 200  # Water extends 200px beyond playable area
const CAMERA_WATER_MARGIN: int = 100  # How far camera can see into water

# Tile coordinates in Nature.png (16px grid, 19 columns x 8 rows)
# Looking at the tileset: large grass area is at rows 4-5, cols 0-5
# Grass tiles - solid green areas
const TILE_GRASS_1 := Vector2i(0, 4)  # Plain grass (top-left of large grass block)
const TILE_GRASS_2 := Vector2i(1, 4)  # Plain grass variant
const TILE_GRASS_3 := Vector2i(2, 4)  # Plain grass variant
const TILE_GRASS_4 := Vector2i(0, 5)  # Plain grass
const TILE_GRASS_5 := Vector2i(1, 5)  # Plain grass

# Decorative tiles (bottom rows have individual elements)
const TILE_GRASS_FLOWER := Vector2i(7, 7)  # Small flowers
const TILE_GRASS_MUSHROOM := Vector2i(9, 7)  # Mushroom

# Water tiles - the pond area at top-left (0,0 to 2,2)
const TILE_WATER := Vector2i(1, 1)  # Center water
const TILE_WATER_SHORE_TOP := Vector2i(1, 0)  # Shore top edge
const TILE_WATER_SHORE_BOTTOM := Vector2i(1, 2)  # Shore bottom edge
const TILE_WATER_SHORE_LEFT := Vector2i(0, 1)  # Shore left edge
const TILE_WATER_SHORE_RIGHT := Vector2i(2, 1)  # Shore right edge
const TILE_WATER_CORNER_TL := Vector2i(0, 0)  # Corner top-left (inner)
const TILE_WATER_CORNER_TR := Vector2i(2, 0)  # Corner top-right (inner)
const TILE_WATER_CORNER_BL := Vector2i(0, 2)  # Corner bottom-left (inner)
const TILE_WATER_CORNER_BR := Vector2i(2, 2)  # Corner bottom-right (inner)

# Path tiles - dirt area at cols 4-5
const TILE_DIRT := Vector2i(4, 1)  # Dirt/cleared ground center
const TILE_DIRT_2 := Vector2i(5, 1)  # Dirt variant

# Central spawn area config
const SPAWN_AREA_RADIUS: int = 150  # Clear area around spawn point
const PATH_WIDTH: int = 48  # Width of paths

# Decoration density
const TREE_DENSITY: float = 0.0000105  # Trees per pixel squared (~65 trees, reduced 50%)
const ROCK_DENSITY: float = 0.00002  # Rocks per pixel squared (~125 rocks)
const LAMP_SPACING: int = 300  # Approximate spacing between lamps along paths
const MAGIC_STONE_COUNT: int = 1  # Number of magic stones on map

# Water ponds/lakes scattered throughout
const POND_COUNT: int = 8  # Number of water ponds to generate
const MIN_POND_RADIUS: int = 3  # Minimum pond size in tiles
const MAX_POND_RADIUS: int = 8  # Maximum pond size in tiles

# Scenes to instantiate
var tree_scenes: Array[PackedScene] = []
var rock_scenes: Array[PackedScene] = []
var lamp_scene: PackedScene
var magic_stone_scene: PackedScene

# TileMap reference
var ground_tilemap: TileMapLayer
var water_tilemap: TileMapLayer
var decoration_tilemap: TileMapLayer

# RNG for procedural generation
var rng: RandomNumberGenerator

# Generated data
var obstacle_positions: Array[Vector2] = []
var lamp_positions: Array[Vector2] = []
var magic_stone_positions: Array[Vector2] = []
var path_cells: Dictionary = {}  # Cells that are part of paths
var water_cells: Dictionary = {}  # Cells that are water (ponds)
var pond_centers: Array[Vector2] = []  # Center positions of ponds

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	rng.randomize()

	_load_scenes()

func _load_scenes() -> void:
	# Load tree scenes
	var tree1 = load("res://scenes/environment/destructible_tree.tscn")
	if tree1:
		tree_scenes.append(tree1)

	# Load rock scene
	var rock1 = load("res://scenes/environment/destructible_rock.tscn")
	if rock1:
		rock_scenes.append(rock1)

	# Load lamp scene
	lamp_scene = load("res://scenes/environment/lamp.tscn")

	# Load magic stone scene
	magic_stone_scene = load("res://scenes/environment/magic_stone.tscn")

func generate_map() -> void:
	print("ProceduralMapGenerator: Starting map generation...")

	# Clear any existing generated content
	_clear_existing()

	# Create tilemaps
	_setup_tilemaps()

	# Generate terrain
	_generate_ground()
	_generate_water_boundary()

	# Generate paths from center
	_generate_paths()

	# Generate water ponds/lakes scattered throughout
	_generate_ponds()

	# Place decorations
	_place_dirt_pixels()
	_place_trees()
	_place_rocks()
	_place_lamps()
	_place_magic_stones()

	# Calculate and emit map bounds
	var bounds = Rect2(0, 0, MAP_SIZE, MAP_SIZE)
	emit_signal("map_generated", bounds)

	print("ProceduralMapGenerator: Map generation complete!")

func _clear_existing() -> void:
	obstacle_positions.clear()
	lamp_positions.clear()
	magic_stone_positions.clear()
	path_cells.clear()
	water_cells.clear()
	pond_centers.clear()

	# Remove all generated children
	for child in get_children():
		child.queue_free()

func _setup_tilemaps() -> void:
	# Create a solid grass background using ColorRect
	var grass_bg = ColorRect.new()
	grass_bg.name = "GrassBackground"
	grass_bg.color = Color(0.322, 0.537, 0.243)  # Match the grass green from tileset
	grass_bg.position = Vector2(-WATER_BORDER, -WATER_BORDER)
	grass_bg.size = Vector2(MAP_SIZE + WATER_BORDER * 2, MAP_SIZE + WATER_BORDER * 2)
	grass_bg.z_index = -12
	add_child(grass_bg)

	# Create tileset from Nature.png for water and decorations
	var tileset = _create_tileset()

	# Ground layer - for dirt paths only
	ground_tilemap = TileMapLayer.new()
	ground_tilemap.name = "GroundTileMap"
	ground_tilemap.tile_set = tileset
	ground_tilemap.z_index = -10
	add_child(ground_tilemap)

	# Water layer (on top of ground at edges)
	water_tilemap = TileMapLayer.new()
	water_tilemap.name = "WaterTileMap"
	water_tilemap.tile_set = tileset
	water_tilemap.z_index = -9
	add_child(water_tilemap)

	# Decoration layer (flowers, mushrooms)
	decoration_tilemap = TileMapLayer.new()
	decoration_tilemap.name = "DecorationTileMap"
	decoration_tilemap.tile_set = tileset
	decoration_tilemap.z_index = -8
	add_child(decoration_tilemap)

func _create_tileset() -> TileSet:
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Add the Nature.png as a source
	var source = TileSetAtlasSource.new()
	var texture = load("res://assets/enviro/gowl/Tiles/Nature.png")
	if texture:
		source.texture = texture
		source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

		# Create tiles for the entire texture
		var cols = texture.get_width() / TILE_SIZE
		var rows = texture.get_height() / TILE_SIZE

		for y in range(rows):
			for x in range(cols):
				var atlas_coords = Vector2i(x, y)
				source.create_tile(atlas_coords)

		tileset.add_source(source, 0)

	return tileset

func _generate_ground() -> void:
	# Ground is now handled by a solid ColorRect background
	# This function now only adds occasional decorative tiles scattered on the grass
	var tiles_x = MAP_SIZE / TILE_SIZE
	var tiles_y = MAP_SIZE / TILE_SIZE

	# Scatter some decorative elements on the grass (very sparse)
	for y in range(tiles_y):
		for x in range(tiles_x):
			# Very sparse decorations
			if rng.randf() < 0.003:
				var tile_pos = Vector2i(x, y)
				var deco = TILE_GRASS_FLOWER if rng.randf() < 0.7 else TILE_GRASS_MUSHROOM
				decoration_tilemap.set_cell(tile_pos, 0, deco)

func _generate_water_boundary() -> void:
	# Create animated water around the edges using actual water tiles
	print("ProceduralMapGenerator: Generating water boundary with tiles...")

	# Load water animation frames
	var water_frames = [
		load("res://assets/enviro/gowl/Tiles/Water/WaterAnim1.png"),
		load("res://assets/enviro/gowl/Tiles/Water/WaterAnim2.png"),
		load("res://assets/enviro/gowl/Tiles/Water/WaterAnim3.png"),
		load("res://assets/enviro/gowl/Tiles/Water/WaterAnim4.png")
	]

	# Create container for water tiles
	var water_container = Node2D.new()
	water_container.name = "WaterBoundary"
	water_container.z_index = -11
	add_child(water_container)

	# Calculate tile counts
	var tiles_across = int((MAP_SIZE + WATER_BORDER * 2) / TILE_SIZE) + 1
	var border_tiles = int(WATER_BORDER / TILE_SIZE) + 1

	# Create animated water tiles for all four edges
	# Top edge
	for x in range(-border_tiles, tiles_across):
		for y in range(-border_tiles, 0):
			_create_animated_water_tile(water_container, x, y, water_frames)

	# Bottom edge
	for x in range(-border_tiles, tiles_across):
		for y in range(int(MAP_SIZE / TILE_SIZE), int(MAP_SIZE / TILE_SIZE) + border_tiles):
			_create_animated_water_tile(water_container, x, y, water_frames)

	# Left edge (excluding corners already done)
	for x in range(-border_tiles, 0):
		for y in range(0, int(MAP_SIZE / TILE_SIZE)):
			_create_animated_water_tile(water_container, x, y, water_frames)

	# Right edge (excluding corners already done)
	for x in range(int(MAP_SIZE / TILE_SIZE), int(MAP_SIZE / TILE_SIZE) + border_tiles):
		for y in range(0, int(MAP_SIZE / TILE_SIZE)):
			_create_animated_water_tile(water_container, x, y, water_frames)

	# Add shore tiles along the edges using Nature.png tileset
	_add_shore_tiles()

func _create_animated_water_tile(container: Node2D, tile_x: int, tile_y: int, frames: Array) -> void:
	# Create an AnimatedSprite2D for each water tile
	var water_sprite = AnimatedSprite2D.new()
	water_sprite.position = Vector2(tile_x * TILE_SIZE + TILE_SIZE / 2, tile_y * TILE_SIZE + TILE_SIZE / 2)

	# Create sprite frames
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("default")
	sprite_frames.set_animation_loop("default", true)
	sprite_frames.set_animation_speed("default", 4.0)  # 4 FPS for gentle wave

	for frame in frames:
		if frame:
			sprite_frames.add_frame("default", frame)

	water_sprite.sprite_frames = sprite_frames
	water_sprite.play("default")

	# Randomize starting frame for variety
	water_sprite.frame = randi() % frames.size()

	container.add_child(water_sprite)

func _add_shore_tiles() -> void:
	# Add shore/edge tiles along the boundary using Nature.png tileset
	var tiles_x = int(MAP_SIZE / TILE_SIZE)
	var tiles_y = int(MAP_SIZE / TILE_SIZE)

	# Top shore (grass to water transition)
	for x in range(tiles_x):
		water_tilemap.set_cell(Vector2i(x, -1), 0, TILE_WATER_SHORE_BOTTOM)

	# Bottom shore
	for x in range(tiles_x):
		water_tilemap.set_cell(Vector2i(x, tiles_y), 0, TILE_WATER_SHORE_TOP)

	# Left shore
	for y in range(tiles_y):
		water_tilemap.set_cell(Vector2i(-1, y), 0, TILE_WATER_SHORE_RIGHT)

	# Right shore
	for y in range(tiles_y):
		water_tilemap.set_cell(Vector2i(tiles_x, y), 0, TILE_WATER_SHORE_LEFT)

	# Corners
	water_tilemap.set_cell(Vector2i(-1, -1), 0, TILE_WATER_CORNER_BR)
	water_tilemap.set_cell(Vector2i(tiles_x, -1), 0, TILE_WATER_CORNER_BL)
	water_tilemap.set_cell(Vector2i(-1, tiles_y), 0, TILE_WATER_CORNER_TR)
	water_tilemap.set_cell(Vector2i(tiles_x, tiles_y), 0, TILE_WATER_CORNER_TL)

func _generate_paths() -> void:
	# Create 4 paths from center going to each direction using ColorRects
	var center = Vector2(MAP_SIZE / 2, MAP_SIZE / 2)
	var path_color = Color(0.588, 0.463, 0.314)  # Dirt brown color

	# Mark spawn area as path (clear) - for obstacle placement checks
	_mark_circular_path(center, SPAWN_AREA_RADIUS)

	# Create circular spawn area visual
	var spawn_circle = _create_circle_polygon(center, SPAWN_AREA_RADIUS, path_color)
	spawn_circle.name = "SpawnArea"
	spawn_circle.z_index = -11
	add_child(spawn_circle)

	# Create paths in 4 cardinal directions using ColorRects
	# North path
	var path_north = ColorRect.new()
	path_north.name = "PathNorth"
	path_north.color = path_color
	path_north.position = Vector2(center.x - PATH_WIDTH / 2, 0)
	path_north.size = Vector2(PATH_WIDTH, center.y - SPAWN_AREA_RADIUS + 20)
	path_north.z_index = -11
	add_child(path_north)
	_mark_straight_path(center, Vector2(center.x, 0), PATH_WIDTH / 2)

	# South path
	var path_south = ColorRect.new()
	path_south.name = "PathSouth"
	path_south.color = path_color
	path_south.position = Vector2(center.x - PATH_WIDTH / 2, center.y + SPAWN_AREA_RADIUS - 20)
	path_south.size = Vector2(PATH_WIDTH, MAP_SIZE - center.y - SPAWN_AREA_RADIUS + 20)
	path_south.z_index = -11
	add_child(path_south)
	_mark_straight_path(center, Vector2(center.x, MAP_SIZE), PATH_WIDTH / 2)

	# East path
	var path_east = ColorRect.new()
	path_east.name = "PathEast"
	path_east.color = path_color
	path_east.position = Vector2(center.x + SPAWN_AREA_RADIUS - 20, center.y - PATH_WIDTH / 2)
	path_east.size = Vector2(MAP_SIZE - center.x - SPAWN_AREA_RADIUS + 20, PATH_WIDTH)
	path_east.z_index = -11
	add_child(path_east)
	_mark_straight_path(center, Vector2(MAP_SIZE, center.y), PATH_WIDTH / 2)

	# West path
	var path_west = ColorRect.new()
	path_west.name = "PathWest"
	path_west.color = path_color
	path_west.position = Vector2(0, center.y - PATH_WIDTH / 2)
	path_west.size = Vector2(center.x - SPAWN_AREA_RADIUS + 20, PATH_WIDTH)
	path_west.z_index = -11
	add_child(path_west)
	_mark_straight_path(center, Vector2(0, center.y), PATH_WIDTH / 2)

func _create_circle_polygon(center: Vector2, radius: float, color: Color) -> Polygon2D:
	# Create a circular polygon for the spawn area
	var polygon = Polygon2D.new()
	polygon.color = color

	var points: PackedVector2Array = []
	var segments = 32
	for i in range(segments):
		var angle = (i / float(segments)) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	polygon.polygon = points
	polygon.position = center
	return polygon

func _mark_circular_path(center: Vector2, radius: float) -> void:
	# Mark all cells within radius as path
	var min_x = int(center.x - radius) / TILE_SIZE
	var max_x = int(center.x + radius) / TILE_SIZE
	var min_y = int(center.y - radius) / TILE_SIZE
	var max_y = int(center.y + radius) / TILE_SIZE

	for ty in range(min_y, max_y + 1):
		for tx in range(min_x, max_x + 1):
			var cell_center = Vector2(tx * TILE_SIZE + TILE_SIZE / 2, ty * TILE_SIZE + TILE_SIZE / 2)
			if cell_center.distance_to(center) <= radius:
				var key = "%d_%d" % [tx, ty]
				path_cells[key] = Vector2(tx * TILE_SIZE, ty * TILE_SIZE)

func _mark_straight_path(from: Vector2, to: Vector2, half_width: float) -> void:
	# Mark cells along a straight line as path
	var direction = (to - from).normalized()
	var length = from.distance_to(to)
	var perpendicular = Vector2(-direction.y, direction.x)

	var step = TILE_SIZE / 2.0
	var current = 0.0

	while current < length:
		var center = from + direction * current

		# Mark cells across the width
		for w in range(-int(half_width / TILE_SIZE) - 1, int(half_width / TILE_SIZE) + 2):
			var pos = center + perpendicular * (w * TILE_SIZE)
			var tx = int(pos.x) / TILE_SIZE
			var ty = int(pos.y) / TILE_SIZE

			if tx >= 0 and tx < MAP_SIZE / TILE_SIZE and ty >= 0 and ty < MAP_SIZE / TILE_SIZE:
				var key = "%d_%d" % [tx, ty]
				path_cells[key] = Vector2(tx * TILE_SIZE, ty * TILE_SIZE)

		current += step

func _generate_ponds() -> void:
	# Generate water ponds/lakes scattered throughout the map
	print("ProceduralMapGenerator: Generating %d ponds..." % POND_COUNT)

	var center = Vector2(MAP_SIZE / 2, MAP_SIZE / 2)
	var min_dist_from_center = SPAWN_AREA_RADIUS + 100  # Keep ponds away from spawn
	var min_dist_from_path = PATH_WIDTH + 32  # Keep ponds away from paths

	var placed = 0
	var attempts = 0
	var max_attempts = POND_COUNT * 30

	while placed < POND_COUNT and attempts < max_attempts:
		attempts += 1

		# Random position for pond center
		var pond_x = rng.randf_range(150, MAP_SIZE - 150)
		var pond_y = rng.randf_range(150, MAP_SIZE - 150)
		var pond_pos = Vector2(pond_x, pond_y)

		# Check distance from spawn center
		if pond_pos.distance_to(center) < min_dist_from_center:
			continue

		# Check distance from paths
		var too_close_to_path = false
		for key in path_cells:
			var path_pos = path_cells[key]
			if pond_pos.distance_to(path_pos) < min_dist_from_path:
				too_close_to_path = true
				break
		if too_close_to_path:
			continue

		# Check distance from other ponds
		var too_close_to_pond = false
		for other_pond in pond_centers:
			if pond_pos.distance_to(other_pond) < (MAX_POND_RADIUS * TILE_SIZE * 3):
				too_close_to_pond = true
				break
		if too_close_to_pond:
			continue

		# Generate this pond
		var pond_radius = rng.randi_range(MIN_POND_RADIUS, MAX_POND_RADIUS)
		_create_pond(pond_pos, pond_radius)
		pond_centers.append(pond_pos)
		placed += 1

	print("ProceduralMapGenerator: Generated %d ponds" % placed)

func _create_pond(center_pos: Vector2, radius: int) -> void:
	# Create an organic-shaped pond using tilemap tiles for edges and animated sprites for center
	var center_tile_x = int(center_pos.x) / TILE_SIZE
	var center_tile_y = int(center_pos.y) / TILE_SIZE

	# Load water animation frames for center tiles
	var water_frames = [
		load("res://assets/enviro/gowl/Tiles/Water/WaterAnim1.png"),
		load("res://assets/enviro/gowl/Tiles/Water/WaterAnim2.png"),
		load("res://assets/enviro/gowl/Tiles/Water/WaterAnim3.png"),
		load("res://assets/enviro/gowl/Tiles/Water/WaterAnim4.png")
	]

	# Container for this pond's animated water
	var pond_water_container = Node2D.new()
	pond_water_container.name = "PondWater_%d_%d" % [center_tile_x, center_tile_y]
	pond_water_container.z_index = -9
	add_child(pond_water_container)

	# First pass: determine which tiles are water (using noise for organic shape)
	var pond_tiles: Dictionary = {}

	for dy in range(-radius - 1, radius + 2):
		for dx in range(-radius - 1, radius + 2):
			var tx = center_tile_x + dx
			var ty = center_tile_y + dy

			# Skip out of bounds
			if tx < 0 or tx >= MAP_SIZE / TILE_SIZE or ty < 0 or ty >= MAP_SIZE / TILE_SIZE:
				continue

			# Calculate distance from center with some noise for organic shape
			var dist = Vector2(dx, dy).length()
			var noise_offset = sin(dx * 0.8) * cos(dy * 0.8) * 1.5  # Organic variation
			var effective_radius = radius + noise_offset

			if dist <= effective_radius:
				var key = "%d_%d" % [tx, ty]
				pond_tiles[key] = Vector2i(tx, ty)
				water_cells[key] = Vector2(tx * TILE_SIZE, ty * TILE_SIZE)

	# Second pass: place tiles with proper edges
	for key in pond_tiles:
		var tile_pos = pond_tiles[key]
		var tx = tile_pos.x
		var ty = tile_pos.y

		# Check neighbors to determine tile type
		var has_top = "%d_%d" % [tx, ty - 1] in pond_tiles
		var has_bottom = "%d_%d" % [tx, ty + 1] in pond_tiles
		var has_left = "%d_%d" % [tx - 1, ty] in pond_tiles
		var has_right = "%d_%d" % [tx + 1, ty] in pond_tiles

		var is_center = has_top and has_bottom and has_left and has_right

		if is_center:
			# Use animated water sprite for center tiles
			_create_animated_water_tile(pond_water_container, tx, ty, water_frames)
		else:
			# Use tilemap for edge/shore tiles
			var tile_to_use: Vector2i

			if not has_top and has_bottom and has_left and has_right:
				tile_to_use = TILE_WATER_SHORE_TOP
			elif has_top and not has_bottom and has_left and has_right:
				tile_to_use = TILE_WATER_SHORE_BOTTOM
			elif has_top and has_bottom and not has_left and has_right:
				tile_to_use = TILE_WATER_SHORE_LEFT
			elif has_top and has_bottom and has_left and not has_right:
				tile_to_use = TILE_WATER_SHORE_RIGHT
			elif not has_top and has_bottom and not has_left and has_right:
				tile_to_use = TILE_WATER_CORNER_TL
			elif not has_top and has_bottom and has_left and not has_right:
				tile_to_use = TILE_WATER_CORNER_TR
			elif has_top and not has_bottom and not has_left and has_right:
				tile_to_use = TILE_WATER_CORNER_BL
			elif has_top and not has_bottom and has_left and not has_right:
				tile_to_use = TILE_WATER_CORNER_BR
			else:
				# Default - use animated water for isolated or unusual configurations
				_create_animated_water_tile(pond_water_container, tx, ty, water_frames)
				continue

			water_tilemap.set_cell(Vector2i(tx, ty), 0, tile_to_use)

	# Create collision for the pond (StaticBody2D)
	_create_pond_collision(center_pos, radius)

func _create_pond_collision(center_pos: Vector2, radius: int) -> void:
	# Create a static body for water collision
	var water_body = StaticBody2D.new()
	water_body.name = "PondCollision"
	water_body.collision_layer = 8  # Obstacle layer
	water_body.collision_mask = 0
	water_body.position = center_pos

	# Create circular collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius * TILE_SIZE * 0.85  # Slightly smaller than visual
	collision.shape = shape
	water_body.add_child(collision)

	add_child(water_body)

func _place_dirt_pixels() -> void:
	# Add scattered dirt pixels throughout the map, especially on roads
	print("ProceduralMapGenerator: Placing dirt pixels...")

	var dirt_colors = [
		Color(0.45, 0.35, 0.22),  # Light brown
		Color(0.35, 0.25, 0.15),  # Dark brown
		Color(0.50, 0.40, 0.28),  # Lighter tan
		Color(0.30, 0.22, 0.12),  # Darker brown
	]

	# Create a container for dirt pixels
	var dirt_container = Node2D.new()
	dirt_container.name = "DirtPixels"
	dirt_container.z_index = -10  # Below obstacles, above grass
	add_child(dirt_container)

	var dirt_count = 0

	# Place more dirt on paths/roads
	for key in path_cells:
		var cell_pos = path_cells[key]

		# Each path cell gets 2-4 dirt pixels
		var pixels_per_cell = rng.randi_range(2, 4)
		for i in range(pixels_per_cell):
			var pixel_pos = cell_pos + Vector2(
				rng.randf_range(0, TILE_SIZE),
				rng.randf_range(0, TILE_SIZE)
			)

			var dirt = ColorRect.new()
			dirt.color = dirt_colors[rng.randi() % dirt_colors.size()]
			dirt.size = Vector2(rng.randf_range(2, 5), rng.randf_range(2, 5))
			dirt.position = pixel_pos
			dirt_container.add_child(dirt)
			dirt_count += 1

	# Scatter some dirt on the grass areas too (more sparse)
	var grass_dirt_count = 800  # Number of dirt spots on grass
	for i in range(grass_dirt_count):
		var pos = Vector2(
			rng.randf_range(50, MAP_SIZE - 50),
			rng.randf_range(50, MAP_SIZE - 50)
		)

		# Skip if on a path (already has plenty) or in water
		var tx = int(pos.x) / TILE_SIZE
		var ty = int(pos.y) / TILE_SIZE
		var key = "%d_%d" % [tx, ty]
		if key in path_cells:
			continue
		if key in water_cells:
			continue

		var dirt = ColorRect.new()
		dirt.color = dirt_colors[rng.randi() % dirt_colors.size()]
		dirt.size = Vector2(rng.randf_range(2, 4), rng.randf_range(2, 4))
		dirt.position = pos
		dirt_container.add_child(dirt)
		dirt_count += 1

	print("ProceduralMapGenerator: Placed %d dirt pixels" % dirt_count)

func _place_trees() -> void:
	if tree_scenes.is_empty():
		print("ProceduralMapGenerator: No tree scenes loaded!")
		return

	# Calculate number of trees based on density
	var area = MAP_SIZE * MAP_SIZE
	var tree_count = int(area * TREE_DENSITY)

	print("ProceduralMapGenerator: Placing %d trees..." % tree_count)

	var placed = 0
	var attempts = 0
	var max_attempts = tree_count * 10

	while placed < tree_count and attempts < max_attempts:
		attempts += 1

		var pos = Vector2(
			rng.randf_range(100, MAP_SIZE - 100),
			rng.randf_range(100, MAP_SIZE - 100)
		)

		# Check if position is valid (not on path, not too close to other obstacles)
		# Use larger minimum distance (150) to prevent tree overlap with bigger trees
		if _is_valid_obstacle_position(pos, 150):
			var tree = tree_scenes[rng.randi() % tree_scenes.size()].instantiate()
			tree.global_position = pos
			# Vary the tree type visually
			_randomize_tree_appearance(tree)
			add_child(tree)
			obstacle_positions.append(pos)
			placed += 1

	print("ProceduralMapGenerator: Placed %d trees" % placed)

func _randomize_tree_appearance(tree: Node2D) -> void:
	# Load different tree textures randomly
	var tree_textures = [
		"res://assets/enviro/gowl/Trees/Tree1.png",
		"res://assets/enviro/gowl/Trees/Tree2.png",
		"res://assets/enviro/gowl/Trees/Tree3.png"
	]

	var sprite = tree.get_node_or_null("Sprite")
	if sprite and sprite is Sprite2D:
		var tex_path = tree_textures[rng.randi() % tree_textures.size()]
		var tex = load(tex_path)
		if tex:
			sprite.texture = tex

		# Trees with variation (1.0 to 6.0x scale - 50% to 100% of max)
		var scale_var = rng.randf_range(1.0, 6.0)
		sprite.scale = Vector2(scale_var, scale_var)

		# Random flip
		if rng.randf() < 0.5:
			sprite.flip_h = true

	# Update shadow too
	var shadow = tree.get_node_or_null("Shadow")
	if shadow and shadow is Sprite2D and sprite:
		shadow.texture = sprite.texture
		shadow.scale = Vector2(sprite.scale.x * 0.9, sprite.scale.y * 0.4)
		# Move shadow down based on tree scale
		shadow.position.y = 12 + (sprite.scale.y - 1.5) * 8
		if sprite.flip_h:
			shadow.flip_h = true

	# Adjust collision shape based on tree scale
	var collision_shape = tree.get_node_or_null("CollisionShape2D")
	var detection_shape = tree.get_node_or_null("DetectionArea/DetectionShape")
	if collision_shape and sprite:
		# Scale collision and move it to base of tree trunk
		var scale_factor = sprite.scale.x
		var base_collision_y = 20 + (scale_factor - 1.5) * 12  # Move down as tree gets bigger
		collision_shape.position.y = base_collision_y

		# Scale the collision shape size
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(24 * scale_factor * 0.5, 16 * scale_factor * 0.4)
		collision_shape.shape = rect_shape

		# Update detection shape too
		if detection_shape:
			detection_shape.position.y = base_collision_y
			var detect_shape = RectangleShape2D.new()
			detect_shape.size = rect_shape.size
			detection_shape.shape = detect_shape

func _place_rocks() -> void:
	if rock_scenes.is_empty():
		print("ProceduralMapGenerator: No rock scenes loaded!")
		return

	var area = MAP_SIZE * MAP_SIZE
	var rock_count = int(area * ROCK_DENSITY)

	print("ProceduralMapGenerator: Placing %d rocks..." % rock_count)

	var placed = 0
	var attempts = 0
	var max_attempts = rock_count * 10

	while placed < rock_count and attempts < max_attempts:
		attempts += 1

		var pos = Vector2(
			rng.randf_range(30, MAP_SIZE - 30),
			rng.randf_range(30, MAP_SIZE - 30)
		)

		if _is_valid_obstacle_position(pos, 40):
			var rock = rock_scenes[rng.randi() % rock_scenes.size()].instantiate()
			rock.global_position = pos
			_randomize_rock_appearance(rock)
			add_child(rock)
			obstacle_positions.append(pos)
			placed += 1

	print("ProceduralMapGenerator: Placed %d rocks" % placed)

func _randomize_rock_appearance(rock: Node2D) -> void:
	var rock_textures = [
		"res://assets/enviro/gowl/Rocks and Chest/Rocks/Rock1.png",
		"res://assets/enviro/gowl/Rocks and Chest/Rocks/Rock2.png",
		"res://assets/enviro/gowl/Rocks and Chest/Rocks/Rock3.png",
		"res://assets/enviro/gowl/Rocks and Chest/Rocks/Rock4.png",
		"res://assets/enviro/gowl/Rocks and Chest/Rocks/Rock5.png",
		"res://assets/enviro/gowl/Rocks and Chest/Rocks/Rock6.png"
	]

	var sprite = rock.get_node_or_null("Sprite")
	if sprite and sprite is Sprite2D:
		var tex_path = rock_textures[rng.randi() % rock_textures.size()]
		var tex = load(tex_path)
		if tex:
			sprite.texture = tex

		# Smaller rocks (0.4 to 0.7x scale)
		var scale_var = rng.randf_range(0.4, 0.7)
		sprite.scale = Vector2(scale_var, scale_var)

		if rng.randf() < 0.5:
			sprite.flip_h = true

		# Adjust collision shape to match the scaled rock size
		_adjust_rock_collision(rock, tex, scale_var)

func _adjust_rock_collision(rock: Node2D, texture: Texture2D, scale: float) -> void:
	# Adjust the collision shape to match the actual rock size
	var collision_shape = rock.get_node_or_null("CollisionShape2D")
	var detection_shape = rock.get_node_or_null("DetectionArea/DetectionShape")

	if texture and collision_shape:
		# Calculate collision size based on texture and scale
		var tex_width = texture.get_width() * scale
		var tex_height = texture.get_height() * scale

		# Rock collision should be at the base, roughly 60% width and 40% height
		var collision_width = tex_width * 0.6
		var collision_height = tex_height * 0.4

		# Create a new rectangle shape with the adjusted size
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(collision_width, collision_height)
		collision_shape.shape = rect_shape

		# Position collision at base of rock (sprite is offset upward)
		collision_shape.position = Vector2(0, tex_height * 0.1)

		# Update detection area shape too
		if detection_shape:
			var detect_shape = RectangleShape2D.new()
			detect_shape.size = Vector2(collision_width, collision_height)
			detection_shape.shape = detect_shape
			detection_shape.position = collision_shape.position

func _place_lamps() -> void:
	if not lamp_scene:
		print("ProceduralMapGenerator: No lamp scene loaded!")
		return

	print("ProceduralMapGenerator: Placing lamps along paths...")

	# Place lamps along the paths - but beside them, not on them
	var center = Vector2(MAP_SIZE / 2, MAP_SIZE / 2)
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

	for dir in directions:
		var current_dist = SPAWN_AREA_RADIUS + LAMP_SPACING / 2

		while current_dist < MAP_SIZE / 2 - 50:
			var pos = center + dir * current_dist

			# Offset to be BESIDE the path, not on it
			# PATH_WIDTH / 2 gets to the edge, then add 20 to place it off the road
			var side_offset = PATH_WIDTH / 2 + 20
			var perpendicular = Vector2(-dir.y, dir.x)

			# Alternate sides for visual variety
			var side = 1 if int(current_dist / LAMP_SPACING) % 2 == 0 else -1
			var lamp_pos = pos + perpendicular * (side_offset * side)

			if _is_valid_lamp_position(lamp_pos):
				var lamp = lamp_scene.instantiate()
				lamp.global_position = lamp_pos
				add_child(lamp)
				lamp_positions.append(lamp_pos)

			current_dist += LAMP_SPACING

	print("ProceduralMapGenerator: Placed %d lamps" % lamp_positions.size())

func _place_magic_stones() -> void:
	if not magic_stone_scene:
		print("ProceduralMapGenerator: No magic stone scene loaded!")
		return

	print("ProceduralMapGenerator: Placing %d magic stones..." % MAGIC_STONE_COUNT)

	var placed = 0
	var attempts = 0
	var max_attempts = MAGIC_STONE_COUNT * 20

	# Minimum distance from center (spawn area)
	var min_dist_from_center = SPAWN_AREA_RADIUS + 200
	var center = Vector2(MAP_SIZE / 2, MAP_SIZE / 2)

	while placed < MAGIC_STONE_COUNT and attempts < max_attempts:
		attempts += 1

		var pos = Vector2(
			rng.randf_range(100, MAP_SIZE - 100),
			rng.randf_range(100, MAP_SIZE - 100)
		)

		# Must be far from center
		if pos.distance_to(center) < min_dist_from_center:
			continue

		# Must not be on path
		var tx = int(pos.x) / TILE_SIZE
		var ty = int(pos.y) / TILE_SIZE
		var key = "%d_%d" % [tx, ty]
		if key in path_cells:
			continue

		# Must be away from other magic stones
		var too_close = false
		for other_pos in magic_stone_positions:
			if pos.distance_to(other_pos) < 400:
				too_close = true
				break

		if too_close:
			continue

		# Must be away from obstacles
		if not _is_valid_obstacle_position(pos, 50):
			continue

		var stone = magic_stone_scene.instantiate()
		stone.global_position = pos
		add_child(stone)
		magic_stone_positions.append(pos)
		placed += 1

	print("ProceduralMapGenerator: Placed %d magic stones" % placed)

func _is_valid_obstacle_position(pos: Vector2, min_distance: float) -> bool:
	# Check if on a path
	var tx = int(pos.x) / TILE_SIZE
	var ty = int(pos.y) / TILE_SIZE
	var key = "%d_%d" % [tx, ty]

	if key in path_cells:
		return false

	# Check if in water
	if key in water_cells:
		return false

	# Check distance from pond centers (extra margin)
	for pond_pos in pond_centers:
		if pos.distance_to(pond_pos) < (MAX_POND_RADIUS * TILE_SIZE + 20):
			return false

	# Check distance from spawn center
	var center = Vector2(MAP_SIZE / 2, MAP_SIZE / 2)
	if pos.distance_to(center) < SPAWN_AREA_RADIUS + 20:
		return false

	# Check distance from other obstacles
	for other_pos in obstacle_positions:
		if pos.distance_to(other_pos) < min_distance:
			return false

	return true

func _is_valid_lamp_position(pos: Vector2) -> bool:
	# Check distance from other lamps
	for other_pos in lamp_positions:
		if pos.distance_to(other_pos) < LAMP_SPACING * 0.5:
			return false

	# Check not too close to obstacles (trees/rocks) - use larger distance to avoid overlap
	for obs_pos in obstacle_positions:
		if pos.distance_to(obs_pos) < 120:
			return false

	# Check not in water
	var tx = int(pos.x) / TILE_SIZE
	var ty = int(pos.y) / TILE_SIZE
	var key = "%d_%d" % [tx, ty]
	if key in water_cells:
		return false

	# Check distance from pond centers
	for pond_pos in pond_centers:
		if pos.distance_to(pond_pos) < (MAX_POND_RADIUS * TILE_SIZE + 30):
			return false

	return true

# Public API
func get_spawn_position() -> Vector2:
	return Vector2(MAP_SIZE / 2, MAP_SIZE / 2)

func get_map_bounds() -> Rect2:
	return Rect2(0, 0, MAP_SIZE, MAP_SIZE)

func get_camera_bounds() -> Rect2:
	# Camera can see slightly into the water
	return Rect2(
		-CAMERA_WATER_MARGIN,
		-CAMERA_WATER_MARGIN,
		MAP_SIZE + CAMERA_WATER_MARGIN * 2,
		MAP_SIZE + CAMERA_WATER_MARGIN * 2
	)
