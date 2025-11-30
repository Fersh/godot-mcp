extends Node2D

## Procedural Map Generator
## Creates an organic map with irregular edges, scattered dirt, and fog of war.

signal map_generated(map_bounds: Rect2)

# Map configuration
const MAP_SIZE: int = 2500
const TILE_SIZE: int = 16

# Tile coordinates in forest_tileset.png (16x16 grid)
# Solid grass tiles from the large green block (bottom-left area, rows 10-12)
const TILE_GRASS_LIGHT_1 := Vector2i(0, 10)  # Solid grass center
const TILE_GRASS_LIGHT_2 := Vector2i(1, 10)  # Solid grass center
const TILE_GRASS_LIGHT_3 := Vector2i(2, 10)  # Solid grass center
const TILE_GRASS_LIGHT_4 := Vector2i(0, 11)  # Solid grass center
const TILE_GRASS_LIGHT_5 := Vector2i(1, 11)  # Solid grass center

# Darker grass for variation (slightly different shade tiles)
const TILE_GRASS_DARK_1 := Vector2i(2, 11)
const TILE_GRASS_DARK_2 := Vector2i(3, 10)
const TILE_GRASS_DARK_3 := Vector2i(3, 11)
const TILE_GRASS_DARK_4 := Vector2i(0, 12)
const TILE_GRASS_DARK_5 := Vector2i(1, 12)

# Decorations (flowers, mushrooms from middle rows around row 7-8)
const TILE_GRASS_FLOWER := Vector2i(5, 8)
const TILE_GRASS_MUSHROOM := Vector2i(7, 8)

# Dirt/path tiles (top section, tan colored area)
const TILE_DIRT := Vector2i(2, 0)
const TILE_DIRT_2 := Vector2i(3, 0)

# Spawn area
const SPAWN_AREA_RADIUS: int = 120

# Decoration density
const TREE_DENSITY: float = 0.00000375
const ROCK_DENSITY: float = 0.00000625  # Reduced by 50%
const LAMP_COUNT: int = 15
const MAGIC_STONE_COUNT: int = 1

# Dirt patches
const DIRT_PATCH_COUNT: int = 100
const WATER_INLET_COUNT: int = 3

# Fog of war
const FOG_REVEAL_RADIUS: float = 300.0
const FOG_SCALE: int = 4  # Downscale for performance

# Scenes
var tree_scenes: Array[PackedScene] = []
var rock_scenes: Array[PackedScene] = []
var lamp_scene: PackedScene
var magic_stone_scene: PackedScene

# Tilemaps
var grass_tilemap: TileMapLayer
var dirt_tilemap: TileMapLayer
var decoration_tilemap: TileMapLayer

# Fog of war
var fog_sprite: Sprite2D
var fog_image: Image
var fog_texture: ImageTexture

# RNG
var rng: RandomNumberGenerator

# Data
var obstacle_positions: Array[Vector2] = []
var lamp_positions: Array[Vector2] = []
var magic_stone_positions: Array[Vector2] = []
var land_cells: Dictionary = {}
var water_cells: Dictionary = {}
var dirt_cells: Dictionary = {}
var _spawn_center: Vector2 = Vector2.ZERO

# References to spawned objects for fog visibility
var spawned_trees: Array[Node2D] = []
var spawned_rocks: Array[Node2D] = []
var spawned_lamps: Array[Node2D] = []
var spawned_stones: Array[Node2D] = []

# Player reference
var player: Node2D = null

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	rng.randomize()
	_load_scenes()

func _process(_delta: float) -> void:
	_update_fog_of_war()
	_update_object_visibility()

func _load_scenes() -> void:
	var tree1 = load("res://scenes/environment/destructible_tree.tscn")
	if tree1:
		tree_scenes.append(tree1)

	var rock1 = load("res://scenes/environment/destructible_rock.tscn")
	if rock1:
		rock_scenes.append(rock1)

	lamp_scene = load("res://scenes/environment/lamp.tscn")
	magic_stone_scene = load("res://scenes/environment/magic_stone.tscn")

func generate_map() -> void:
	print("ProceduralMapGenerator: Starting map generation...")

	_clear_existing()
	_setup_tilemaps()
	_generate_land_shape()
	_generate_water()
	_generate_grass()
	_place_dirt_patches()
	_place_trees()
	_place_rocks()
	_place_lamps()
	_place_magic_stones()
	_setup_fog_of_war()

	emit_signal("map_generated", Rect2(0, 0, MAP_SIZE, MAP_SIZE))
	print("ProceduralMapGenerator: Map generation complete!")

func _clear_existing() -> void:
	obstacle_positions.clear()
	lamp_positions.clear()
	magic_stone_positions.clear()
	land_cells.clear()
	water_cells.clear()
	dirt_cells.clear()
	spawned_trees.clear()
	spawned_rocks.clear()
	spawned_lamps.clear()
	spawned_stones.clear()

	for child in get_children():
		child.queue_free()

func _setup_tilemaps() -> void:
	# Create solid grass background using ColorRect (more reliable than tiles)
	var grass_bg = ColorRect.new()
	grass_bg.name = "GrassBackground"
	grass_bg.color = Color(0.286, 0.478, 0.208)  # Green grass color
	grass_bg.position = Vector2(-100, -100)
	grass_bg.size = Vector2(MAP_SIZE + 200, MAP_SIZE + 200)
	grass_bg.z_index = -20  # Bottom layer
	add_child(grass_bg)

	var tileset = _create_tileset()

	# Dark grass overlay for variation (above grass bg)
	grass_tilemap = TileMapLayer.new()
	grass_tilemap.name = "GrassVariationTileMap"
	grass_tilemap.tile_set = tileset
	grass_tilemap.z_index = -18
	add_child(grass_tilemap)

	# Dirt layer for dirt patches (above grass)
	dirt_tilemap = TileMapLayer.new()
	dirt_tilemap.name = "DirtTileMap"
	dirt_tilemap.tile_set = tileset
	dirt_tilemap.z_index = -16
	add_child(dirt_tilemap)

	decoration_tilemap = TileMapLayer.new()
	decoration_tilemap.name = "DecorationTileMap"
	decoration_tilemap.tile_set = tileset
	decoration_tilemap.z_index = -12
	add_child(decoration_tilemap)

func _create_tileset() -> TileSet:
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var source = TileSetAtlasSource.new()
	var texture = load("res://assets/enviro/forest_tileset.png")
	if texture:
		source.texture = texture
		source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

		var cols = texture.get_width() / TILE_SIZE
		var rows = texture.get_height() / TILE_SIZE

		for y in range(rows):
			for x in range(cols):
				source.create_tile(Vector2i(x, y))

		tileset.add_source(source, 0)

	return tileset

func _generate_land_shape() -> void:
	print("ProceduralMapGenerator: Generating organic land shape...")

	var tiles_x = MAP_SIZE / TILE_SIZE
	var tiles_y = MAP_SIZE / TILE_SIZE

	# Use noise for organic edges
	var noise = FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.006

	# Set spawn center
	_spawn_center = Vector2(
		rng.randf_range(MAP_SIZE * 0.35, MAP_SIZE * 0.65),
		rng.randf_range(MAP_SIZE * 0.35, MAP_SIZE * 0.65)
	)

	# Determine land cells using noise
	for y in range(tiles_y):
		for x in range(tiles_x):
			var world_pos = Vector2(x * TILE_SIZE + TILE_SIZE/2, y * TILE_SIZE + TILE_SIZE/2)
			var dist_from_center = world_pos.distance_to(Vector2(MAP_SIZE/2, MAP_SIZE/2))

			var noise_val = noise.get_noise_2d(x * 2, y * 2)
			var land_radius = 950 + noise_val * 250
			var edge_noise = noise.get_noise_2d(x * 4, y * 4) * 60

			if dist_from_center < land_radius + edge_noise:
				land_cells["%d_%d" % [x, y]] = Vector2i(x, y)

func _generate_water() -> void:
	print("ProceduralMapGenerator: Generating water...")

	var tiles_x = MAP_SIZE / TILE_SIZE
	var tiles_y = MAP_SIZE / TILE_SIZE

	var water_frames = [
		load("res://assets/enviro/gowl/Tiles/Water/WaterAnim1.png"),
		load("res://assets/enviro/gowl/Tiles/Water/WaterAnim2.png"),
		load("res://assets/enviro/gowl/Tiles/Water/WaterAnim3.png"),
		load("res://assets/enviro/gowl/Tiles/Water/WaterAnim4.png")
	]

	var water_container = Node2D.new()
	water_container.name = "WaterContainer"
	water_container.z_index = -14  # Above dirt (-16) and grass (-18/-20), below decorations (-12)
	add_child(water_container)

	# Water collision container
	var water_collision = StaticBody2D.new()
	water_collision.name = "WaterCollision"
	water_collision.collision_layer = 8  # Obstacles layer
	water_collision.collision_mask = 0
	add_child(water_collision)

	# Add water inlets cutting into land
	for i in range(WATER_INLET_COUNT):
		_create_water_inlet(tiles_x, tiles_y)

	# Place water in all non-land areas within reasonable range
	# Extended margin to ensure full coverage at map edges
	var water_margin = 8
	for y in range(-water_margin, tiles_y + water_margin):
		for x in range(-water_margin, tiles_x + water_margin):
			var key = "%d_%d" % [x, y]
			if key not in land_cells:
				# Only create water tiles that are within viewable range (near land or near map bounds)
				if _is_near_land(x, y, 6) or x < 5 or x > tiles_x - 5 or y < 5 or y > tiles_y - 5:
					water_cells[key] = Vector2i(x, y)
					_create_water_tile(water_container, x, y, water_frames)
					_create_water_collision(water_collision, x, y)

func _is_near_land(x: int, y: int, radius: int) -> bool:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if land_cells.has("%d_%d" % [x + dx, y + dy]):
				return true
	return false

func _create_water_inlet(tiles_x: int, tiles_y: int) -> void:
	var edge = rng.randi() % 4
	var start_pos: Vector2i
	var direction: Vector2i

	match edge:
		0:  # Top
			start_pos = Vector2i(rng.randi_range(tiles_x/4, 3*tiles_x/4), 0)
			direction = Vector2i(0, 1)
		1:  # Right
			start_pos = Vector2i(tiles_x - 1, rng.randi_range(tiles_y/4, 3*tiles_y/4))
			direction = Vector2i(-1, 0)
		2:  # Bottom
			start_pos = Vector2i(rng.randi_range(tiles_x/4, 3*tiles_x/4), tiles_y - 1)
			direction = Vector2i(0, -1)
		3:  # Left
			start_pos = Vector2i(0, rng.randi_range(tiles_y/4, 3*tiles_y/4))
			direction = Vector2i(1, 0)

	var inlet_length = rng.randi_range(10, 25)
	var inlet_width = rng.randi_range(4, 10)

	for d in range(inlet_length):
		var pos = start_pos + direction * d
		var width = max(2, inlet_width - int(d * 0.4))

		for w in range(-width, width + 1):
			var tx = pos.x + (w if direction.y != 0 else 0)
			var ty = pos.y + (w if direction.x != 0 else 0)

			if tx >= 0 and tx < tiles_x and ty >= 0 and ty < tiles_y:
				land_cells.erase("%d_%d" % [tx, ty])

func _create_water_tile(container: Node2D, tile_x: int, tile_y: int, frames: Array) -> void:
	var sprite = AnimatedSprite2D.new()
	sprite.position = Vector2(tile_x * TILE_SIZE + TILE_SIZE/2, tile_y * TILE_SIZE + TILE_SIZE/2)

	# Water frames are 32x16, scale to fit 16x16 tile
	sprite.scale = Vector2(0.5, 1.0)

	var sf = SpriteFrames.new()
	sf.add_animation("default")
	sf.set_animation_loop("default", true)
	sf.set_animation_speed("default", 4.0)

	for frame in frames:
		if frame:
			sf.add_frame("default", frame)

	sprite.sprite_frames = sf
	sprite.play("default")
	sprite.frame = rng.randi() % max(1, frames.size())

	container.add_child(sprite)

func _create_water_collision(collision_body: StaticBody2D, tile_x: int, tile_y: int) -> void:
	var collision = CollisionShape2D.new()
	collision.position = Vector2(tile_x * TILE_SIZE + TILE_SIZE/2, tile_y * TILE_SIZE + TILE_SIZE/2)

	var shape = RectangleShape2D.new()
	shape.size = Vector2(TILE_SIZE, TILE_SIZE)
	collision.shape = shape

	collision_body.add_child(collision)

func _generate_grass() -> void:
	print("ProceduralMapGenerator: Generating grass variation...")

	# Add darker grass patches randomly for visual variation
	# The base grass is already a solid ColorRect
	var dark_grass_color = Color(0.22, 0.40, 0.16)  # Darker green

	for key in land_cells:
		var pos = land_cells[key]

		# Random darker grass patches (about 10% of tiles)
		if rng.randf() < 0.10:
			# Create small dark grass patches using ColorRects
			var dark_patch = ColorRect.new()
			dark_patch.color = dark_grass_color
			dark_patch.size = Vector2(TILE_SIZE, TILE_SIZE)
			dark_patch.position = Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE)
			dark_patch.z_index = -19  # Above grass bg (-20), below grass tilemap (-18)
			add_child(dark_patch)

func _place_dirt_patches() -> void:
	print("ProceduralMapGenerator: Placing dirt patches...")

	var dirt_colors = [
		Color(0.45, 0.35, 0.22),  # Light brown
		Color(0.40, 0.30, 0.18),  # Medium brown
		Color(0.50, 0.38, 0.25),  # Tan
	]

	for i in range(DIRT_PATCH_COUNT):
		var attempts = 0
		while attempts < 20:
			var x = rng.randi_range(100, MAP_SIZE - 100)
			var y = rng.randi_range(100, MAP_SIZE - 100)
			var tx = x / TILE_SIZE
			var ty = y / TILE_SIZE

			if land_cells.has("%d_%d" % [tx, ty]):
				var patch_size = rng.randi_range(2, 6)
				_create_dirt_patch(tx, ty, patch_size, dirt_colors)
				break
			attempts += 1

func _create_dirt_patch(center_x: int, center_y: int, size: int, dirt_colors: Array) -> void:
	var base_color = dirt_colors[rng.randi() % dirt_colors.size()]

	for dy in range(-size, size + 1):
		for dx in range(-size, size + 1):
			var dist = Vector2(dx, dy).length()
			if dist <= size and rng.randf() < (1.0 - dist / size * 0.6):
				var tx = center_x + dx
				var ty = center_y + dy
				var key = "%d_%d" % [tx, ty]

				if land_cells.has(key) and not water_cells.has(key):
					# Create dirt tile with slight color variation
					var dirt_rect = ColorRect.new()
					var color_var = rng.randf_range(-0.03, 0.03)
					dirt_rect.color = Color(
						base_color.r + color_var,
						base_color.g + color_var,
						base_color.b + color_var
					)
					dirt_rect.size = Vector2(TILE_SIZE, TILE_SIZE)
					dirt_rect.position = Vector2(tx * TILE_SIZE, ty * TILE_SIZE)
					dirt_rect.z_index = -17  # Above grass (-18/-19/-20), below water (-14)
					add_child(dirt_rect)
					dirt_cells[key] = Vector2i(tx, ty)

func _place_trees() -> void:
	if tree_scenes.is_empty():
		return

	var area = MAP_SIZE * MAP_SIZE
	var tree_count = int(area * TREE_DENSITY)
	print("ProceduralMapGenerator: Placing %d trees..." % tree_count)

	var placed = 0
	var attempts = 0

	while placed < tree_count and attempts < tree_count * 10:
		attempts += 1
		var pos = Vector2(rng.randf_range(100, MAP_SIZE - 100), rng.randf_range(100, MAP_SIZE - 100))

		if _is_valid_position(pos, 100):
			var tree = tree_scenes[0].instantiate()
			tree.global_position = pos
			_randomize_tree(tree)
			tree.visible = false  # Start hidden until fog reveals
			add_child(tree)
			spawned_trees.append(tree)
			obstacle_positions.append(pos)
			placed += 1

func _randomize_tree(tree: Node2D) -> void:
	var textures = [
		"res://assets/enviro/gowl/Trees/Tree1.png",
		"res://assets/enviro/gowl/Trees/Tree2.png",
		"res://assets/enviro/gowl/Trees/Tree3.png"
	]

	var scale_val = 1.5
	var sprite = tree.get_node_or_null("Sprite")
	if sprite and sprite is Sprite2D:
		var tex = load(textures[rng.randi() % textures.size()])
		if tex:
			sprite.texture = tex

		scale_val = rng.randf_range(1.5, 5.0)
		sprite.scale = Vector2(scale_val, scale_val)

		if rng.randf() < 0.5:
			sprite.flip_h = true

	var shadow = tree.get_node_or_null("Shadow")
	if shadow and shadow is Sprite2D and sprite:
		shadow.texture = sprite.texture
		shadow.scale = Vector2(sprite.scale.x * 0.9, sprite.scale.y * 0.4)
		shadow.position.y = 12 + (sprite.scale.y - 1.5) * 8
		if sprite.flip_h:
			shadow.flip_h = true

	var collision = tree.get_node_or_null("CollisionShape2D")
	if collision and sprite:
		var scale_factor = sprite.scale.x
		collision.position.y = 20 + (scale_factor - 1.5) * 12
		var shape = RectangleShape2D.new()
		shape.size = Vector2(24 * scale_factor * 0.5, 16 * scale_factor * 0.4)
		collision.shape = shape

	# Small/medium trees (scale < 3.0) render below player
	if scale_val < 3.0:
		tree.z_index = -5  # Below player, player walks over them

func _place_rocks() -> void:
	if rock_scenes.is_empty():
		return

	var area = MAP_SIZE * MAP_SIZE
	var rock_count = int(area * ROCK_DENSITY)
	print("ProceduralMapGenerator: Placing %d rocks..." % rock_count)

	var placed = 0
	var attempts = 0

	while placed < rock_count and attempts < rock_count * 10:
		attempts += 1
		var pos = Vector2(rng.randf_range(50, MAP_SIZE - 50), rng.randf_range(50, MAP_SIZE - 50))

		if _is_valid_position(pos, 50):
			var rock = rock_scenes[0].instantiate()
			rock.global_position = pos
			_randomize_rock(rock)
			rock.visible = false  # Start hidden until fog reveals
			add_child(rock)
			spawned_rocks.append(rock)
			obstacle_positions.append(pos)
			placed += 1

func _randomize_rock(rock: Node2D) -> void:
	var textures = [
		"res://assets/enviro/gowl/Rocks and Chest/Rocks/Rock1.png",
		"res://assets/enviro/gowl/Rocks and Chest/Rocks/Rock2.png",
		"res://assets/enviro/gowl/Rocks and Chest/Rocks/Rock3.png",
		"res://assets/enviro/gowl/Rocks and Chest/Rocks/Rock4.png",
		"res://assets/enviro/gowl/Rocks and Chest/Rocks/Rock5.png",
		"res://assets/enviro/gowl/Rocks and Chest/Rocks/Rock6.png"
	]

	var sprite = rock.get_node_or_null("Sprite")
	if sprite and sprite is Sprite2D:
		var tex = load(textures[rng.randi() % textures.size()])
		if tex:
			sprite.texture = tex

		var scale_val = rng.randf_range(0.4, 0.8)
		sprite.scale = Vector2(scale_val, scale_val)

		if rng.randf() < 0.5:
			sprite.flip_h = true

	# ALL rocks are decorative - disable collision so players/enemies can walk over them
	var collision = rock.get_node_or_null("CollisionShape2D")
	if collision:
		collision.set_deferred("disabled", true)
	rock.collision_layer = 0
	rock.collision_mask = 0

	# Remove health functionality - rocks are just visual decoration
	if rock.has_method("set"):
		rock.set("max_health", 0)
		rock.set("show_health_bar", false)

func _place_lamps() -> void:
	if not lamp_scene:
		return

	print("ProceduralMapGenerator: Placing %d lamps..." % LAMP_COUNT)

	var placed = 0
	var attempts = 0

	while placed < LAMP_COUNT and attempts < LAMP_COUNT * 20:
		attempts += 1
		var pos = Vector2(rng.randf_range(150, MAP_SIZE - 150), rng.randf_range(150, MAP_SIZE - 150))

		if _is_valid_lamp_position(pos):
			var lamp = lamp_scene.instantiate()
			lamp.global_position = pos
			lamp.visible = false  # Start hidden until fog reveals
			add_child(lamp)
			spawned_lamps.append(lamp)
			lamp_positions.append(pos)
			placed += 1

func _place_magic_stones() -> void:
	if not magic_stone_scene:
		return

	print("ProceduralMapGenerator: Placing magic stones...")

	var placed = 0
	var attempts = 0

	while placed < MAGIC_STONE_COUNT and attempts < 100:
		attempts += 1
		var pos = Vector2(rng.randf_range(200, MAP_SIZE - 200), rng.randf_range(200, MAP_SIZE - 200))

		if pos.distance_to(_spawn_center) > SPAWN_AREA_RADIUS + 300:
			if _is_valid_position(pos, 150):
				var stone = magic_stone_scene.instantiate()
				stone.global_position = pos
				stone.visible = false  # Start hidden until fog reveals
				add_child(stone)
				spawned_stones.append(stone)
				magic_stone_positions.append(pos)
				placed += 1

func _is_valid_position(pos: Vector2, min_dist: float) -> bool:
	var tx = int(pos.x) / TILE_SIZE
	var ty = int(pos.y) / TILE_SIZE
	var key = "%d_%d" % [tx, ty]

	# Must be on land
	if not land_cells.has(key):
		return false

	# Not in water
	if water_cells.has(key):
		return false

	# Away from spawn
	if pos.distance_to(_spawn_center) < SPAWN_AREA_RADIUS + 30:
		return false

	# Away from other obstacles
	for other in obstacle_positions:
		if pos.distance_to(other) < min_dist:
			return false

	return true

func _is_valid_lamp_position(pos: Vector2) -> bool:
	var tx = int(pos.x) / TILE_SIZE
	var ty = int(pos.y) / TILE_SIZE

	if not land_cells.has("%d_%d" % [tx, ty]):
		return false

	if water_cells.has("%d_%d" % [tx, ty]):
		return false

	for other in lamp_positions:
		if pos.distance_to(other) < 200:
			return false

	for obs in obstacle_positions:
		if pos.distance_to(obs) < 80:
			return false

	return true

# Fog of War
func _setup_fog_of_war() -> void:
	print("ProceduralMapGenerator: Setting up fog of war...")

	var fog_width = MAP_SIZE / FOG_SCALE
	var fog_height = MAP_SIZE / FOG_SCALE

	fog_image = Image.create(fog_width, fog_height, false, Image.FORMAT_RGBA8)
	fog_image.fill(Color(0, 0, 0, 0.85))  # Dark fog

	fog_texture = ImageTexture.create_from_image(fog_image)

	fog_sprite = Sprite2D.new()
	fog_sprite.name = "FogOfWar"
	fog_sprite.texture = fog_texture
	fog_sprite.centered = false
	fog_sprite.scale = Vector2(FOG_SCALE, FOG_SCALE)
	fog_sprite.z_index = 100  # On top of everything
	add_child(fog_sprite)

	# Find player
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _update_fog_of_war() -> void:
	if not player or not fog_image or not fog_texture:
		return

	var player_pos = player.global_position
	var fog_x = int(player_pos.x / FOG_SCALE)
	var fog_y = int(player_pos.y / FOG_SCALE)
	var reveal_radius = int(FOG_REVEAL_RADIUS / FOG_SCALE)

	# Use noise for organic fog edges
	var time_offset = Time.get_ticks_msec() * 0.0005  # Slow animation

	# Reveal area around player
	for dy in range(-reveal_radius - 10, reveal_radius + 11):
		for dx in range(-reveal_radius - 10, reveal_radius + 11):
			var px = fog_x + dx
			var py = fog_y + dy

			if px >= 0 and px < fog_image.get_width() and py >= 0 and py < fog_image.get_height():
				var dist = Vector2(dx, dy).length()

				# Add noise variation to the edge (use world position for consistent noise)
				var world_px = px * FOG_SCALE
				var world_py = py * FOG_SCALE
				var angle = atan2(dy, dx)
				var noise_val = sin(angle * 3.0 + time_offset) * 0.15 + sin(angle * 7.0 - time_offset * 0.7) * 0.1
				var varied_radius = reveal_radius * (1.0 + noise_val)

				if dist <= varied_radius:
					# More gradual fade starting earlier
					var alpha = 0.0
					var fade_start = varied_radius * 0.5
					if dist > fade_start:
						alpha = (dist - fade_start) / (varied_radius - fade_start) * 0.85
					fog_image.set_pixel(px, py, Color(0, 0, 0, alpha))

	fog_texture.update(fog_image)

func _update_object_visibility() -> void:
	if not player:
		return

	var player_pos = player.global_position
	var visibility_radius = FOG_REVEAL_RADIUS + 50  # Slightly larger than fog reveal

	# Update trees visibility
	for tree in spawned_trees:
		if is_instance_valid(tree):
			tree.visible = tree.global_position.distance_to(player_pos) < visibility_radius

	# Update rocks visibility
	for rock in spawned_rocks:
		if is_instance_valid(rock):
			rock.visible = rock.global_position.distance_to(player_pos) < visibility_radius

	# Update lamps visibility
	for lamp in spawned_lamps:
		if is_instance_valid(lamp):
			lamp.visible = lamp.global_position.distance_to(player_pos) < visibility_radius

	# Update magic stones visibility
	for stone in spawned_stones:
		if is_instance_valid(stone):
			stone.visible = stone.global_position.distance_to(player_pos) < visibility_radius

# Public API
func get_spawn_position() -> Vector2:
	if _spawn_center != Vector2.ZERO:
		return _spawn_center
	return Vector2(MAP_SIZE / 2, MAP_SIZE / 2)

func get_map_bounds() -> Rect2:
	return Rect2(0, 0, MAP_SIZE, MAP_SIZE)

func get_camera_bounds() -> Rect2:
	return Rect2(-50, -50, MAP_SIZE + 100, MAP_SIZE + 100)

func get_random_land_position(min_dist_from_player: float = 300.0) -> Vector2:
	"""Get a random position on land, away from player and water."""
	var attempts = 0
	var max_attempts = 50

	while attempts < max_attempts:
		attempts += 1

		# Pick a random land cell
		if land_cells.is_empty():
			break

		var keys = land_cells.keys()
		var random_key = keys[rng.randi() % keys.size()]
		var cell = land_cells[random_key]

		var pos = Vector2(cell.x * TILE_SIZE + TILE_SIZE/2, cell.y * TILE_SIZE + TILE_SIZE/2)

		# Check not in water
		if water_cells.has(random_key):
			continue

		# Check distance from player
		if player and pos.distance_to(player.global_position) < min_dist_from_player:
			continue

		# Check not too close to spawn
		if pos.distance_to(_spawn_center) < SPAWN_AREA_RADIUS:
			continue

		return pos

	# Fallback to center area if no valid position found
	return Vector2(MAP_SIZE / 2 + rng.randf_range(-200, 200), MAP_SIZE / 2 + rng.randf_range(-200, 200))

func is_position_on_land(pos: Vector2) -> bool:
	"""Check if a position is on valid land (not water)."""
	var tx = int(pos.x) / TILE_SIZE
	var ty = int(pos.y) / TILE_SIZE
	var key = "%d_%d" % [tx, ty]
	return land_cells.has(key) and not water_cells.has(key)
