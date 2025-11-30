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
const TREE_DENSITY: float = 0.00003  # Trees per pixel squared (~190 trees total)
const ROCK_DENSITY: float = 0.00002  # Rocks per pixel squared (~125 rocks)
const LAMP_SPACING: int = 300  # Approximate spacing between lamps along paths
const MAGIC_STONE_COUNT: int = 1  # Number of magic stones on map

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
	# Create water around the edges using ColorRects for clean appearance
	var water_color = Color(0.247, 0.463, 0.580)  # Blue water color
	var shore_color = Color(0.761, 0.698, 0.502)  # Sandy shore color

	# Create water rectangles for each edge
	# Top water
	var water_top = ColorRect.new()
	water_top.name = "WaterTop"
	water_top.color = water_color
	water_top.position = Vector2(-WATER_BORDER, -WATER_BORDER)
	water_top.size = Vector2(MAP_SIZE + WATER_BORDER * 2, WATER_BORDER)
	water_top.z_index = -11
	add_child(water_top)

	# Bottom water
	var water_bottom = ColorRect.new()
	water_bottom.name = "WaterBottom"
	water_bottom.color = water_color
	water_bottom.position = Vector2(-WATER_BORDER, MAP_SIZE)
	water_bottom.size = Vector2(MAP_SIZE + WATER_BORDER * 2, WATER_BORDER)
	water_bottom.z_index = -11
	add_child(water_bottom)

	# Left water
	var water_left = ColorRect.new()
	water_left.name = "WaterLeft"
	water_left.color = water_color
	water_left.position = Vector2(-WATER_BORDER, 0)
	water_left.size = Vector2(WATER_BORDER, MAP_SIZE)
	water_left.z_index = -11
	add_child(water_left)

	# Right water
	var water_right = ColorRect.new()
	water_right.name = "WaterRight"
	water_right.color = water_color
	water_right.position = Vector2(MAP_SIZE, 0)
	water_right.size = Vector2(WATER_BORDER, MAP_SIZE)
	water_right.z_index = -11
	add_child(water_right)

	# Add thin shore/beach lines at the water edge
	_add_shoreline(shore_color)

func _add_shoreline(shore_color: Color) -> void:
	# Add thin shore/beach lines at the edge of water using ColorRects
	var shore_width = 8.0  # Thin beach strip

	# Top shore (at y=0, below water)
	var shore_top = ColorRect.new()
	shore_top.name = "ShoreTop"
	shore_top.color = shore_color
	shore_top.position = Vector2(0, -shore_width)
	shore_top.size = Vector2(MAP_SIZE, shore_width)
	shore_top.z_index = -10
	add_child(shore_top)

	# Bottom shore (at y=MAP_SIZE, above water)
	var shore_bottom = ColorRect.new()
	shore_bottom.name = "ShoreBottom"
	shore_bottom.color = shore_color
	shore_bottom.position = Vector2(0, MAP_SIZE)
	shore_bottom.size = Vector2(MAP_SIZE, shore_width)
	shore_bottom.z_index = -10
	add_child(shore_bottom)

	# Left shore
	var shore_left = ColorRect.new()
	shore_left.name = "ShoreLeft"
	shore_left.color = shore_color
	shore_left.position = Vector2(-shore_width, 0)
	shore_left.size = Vector2(shore_width, MAP_SIZE)
	shore_left.z_index = -10
	add_child(shore_left)

	# Right shore
	var shore_right = ColorRect.new()
	shore_right.name = "ShoreRight"
	shore_right.color = shore_color
	shore_right.position = Vector2(MAP_SIZE, 0)
	shore_right.size = Vector2(shore_width, MAP_SIZE)
	shore_right.z_index = -10
	add_child(shore_right)

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

		# Skip if on a path (already has plenty)
		var tx = int(pos.x) / TILE_SIZE
		var ty = int(pos.y) / TILE_SIZE
		var key = "%d_%d" % [tx, ty]
		if key in path_cells:
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

		# Bigger trees with variation (2.0 to 3.0x scale)
		var scale_var = rng.randf_range(2.0, 3.0)
		sprite.scale = Vector2(scale_var, scale_var)

		# Random flip
		if rng.randf() < 0.5:
			sprite.flip_h = true

	# Update shadow too
	var shadow = tree.get_node_or_null("Shadow")
	if shadow and shadow is Sprite2D and sprite:
		shadow.texture = sprite.texture
		shadow.scale = Vector2(sprite.scale.x * 0.9, sprite.scale.y * 0.4)
		if sprite.flip_h:
			shadow.flip_h = true

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

	# Check not too close to obstacles
	for obs_pos in obstacle_positions:
		if pos.distance_to(obs_pos) < 30:
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
