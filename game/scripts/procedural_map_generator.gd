extends Node2D

## Procedural Map Generator
## Creates an organic map with irregular edges, scattered dirt, and fog of war.

signal map_generated(map_bounds: Rect2)

# Map configuration
const MAP_SIZE: int = 2500
const TILE_SIZE: int = 16

# Tile coordinates in Nature.png
const TILE_GRASS_LIGHT_1 := Vector2i(6, 3)
const TILE_GRASS_LIGHT_2 := Vector2i(7, 3)
const TILE_GRASS_LIGHT_3 := Vector2i(8, 3)
const TILE_GRASS_LIGHT_4 := Vector2i(6, 4)
const TILE_GRASS_LIGHT_5 := Vector2i(7, 4)

const TILE_GRASS_DARK_1 := Vector2i(9, 3)
const TILE_GRASS_DARK_2 := Vector2i(10, 3)
const TILE_GRASS_DARK_3 := Vector2i(9, 4)
const TILE_GRASS_DARK_4 := Vector2i(10, 4)
const TILE_GRASS_DARK_5 := Vector2i(8, 4)

const TILE_GRASS_FLOWER := Vector2i(7, 7)
const TILE_GRASS_MUSHROOM := Vector2i(9, 7)

const TILE_DIRT := Vector2i(4, 1)
const TILE_DIRT_2 := Vector2i(5, 1)

# Spawn area
const SPAWN_AREA_RADIUS: int = 120

# Decoration density
const TREE_DENSITY: float = 0.000015
const ROCK_DENSITY: float = 0.000025
const LAMP_COUNT: int = 30
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

# Player reference
var player: Node2D = null

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	rng.randomize()
	_load_scenes()

func _process(_delta: float) -> void:
	_update_fog_of_war()

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

	for child in get_children():
		child.queue_free()

func _setup_tilemaps() -> void:
	var tileset = _create_tileset()

	grass_tilemap = TileMapLayer.new()
	grass_tilemap.name = "GrassTileMap"
	grass_tilemap.tile_set = tileset
	grass_tilemap.z_index = -12
	add_child(grass_tilemap)

	dirt_tilemap = TileMapLayer.new()
	dirt_tilemap.name = "DirtTileMap"
	dirt_tilemap.tile_set = tileset
	dirt_tilemap.z_index = -11
	add_child(dirt_tilemap)

	decoration_tilemap = TileMapLayer.new()
	decoration_tilemap.name = "DecorationTileMap"
	decoration_tilemap.tile_set = tileset
	decoration_tilemap.z_index = -10
	add_child(decoration_tilemap)

func _create_tileset() -> TileSet:
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var source = TileSetAtlasSource.new()
	var texture = load("res://assets/enviro/gowl/Tiles/Nature.png")
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
	water_container.z_index = -13
	add_child(water_container)

	# Add water inlets cutting into land
	for i in range(WATER_INLET_COUNT):
		_create_water_inlet(tiles_x, tiles_y)

	# Place water where there's no land (only near edges)
	for y in range(-3, tiles_y + 3):
		for x in range(-3, tiles_x + 3):
			var key = "%d_%d" % [x, y]
			if key not in land_cells:
				if _is_near_land(x, y, 3):
					water_cells[key] = Vector2i(x, y)
					_create_water_tile(water_container, x, y, water_frames)

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

func _generate_grass() -> void:
	print("ProceduralMapGenerator: Generating grass...")

	var light_tiles = [TILE_GRASS_LIGHT_1, TILE_GRASS_LIGHT_2, TILE_GRASS_LIGHT_3, TILE_GRASS_LIGHT_4, TILE_GRASS_LIGHT_5]
	var dark_tiles = [TILE_GRASS_DARK_1, TILE_GRASS_DARK_2, TILE_GRASS_DARK_3, TILE_GRASS_DARK_4, TILE_GRASS_DARK_5]

	for key in land_cells:
		var pos = land_cells[key]
		var tile = light_tiles[rng.randi() % light_tiles.size()]
		grass_tilemap.set_cell(pos, 0, tile)

		# Random dark grass variation
		if rng.randf() < 0.12:
			var dark = dark_tiles[rng.randi() % dark_tiles.size()]
			decoration_tilemap.set_cell(pos, 0, dark)

		# Very sparse flowers/mushrooms
		if rng.randf() < 0.004:
			var deco = TILE_GRASS_FLOWER if rng.randf() < 0.7 else TILE_GRASS_MUSHROOM
			decoration_tilemap.set_cell(pos, 0, deco)

func _place_dirt_patches() -> void:
	print("ProceduralMapGenerator: Placing dirt patches...")

	var dirt_tiles = [TILE_DIRT, TILE_DIRT_2]

	for i in range(DIRT_PATCH_COUNT):
		# Random position on land
		var attempts = 0
		while attempts < 20:
			var x = rng.randi_range(50, MAP_SIZE - 50)
			var y = rng.randi_range(50, MAP_SIZE - 50)
			var tx = x / TILE_SIZE
			var ty = y / TILE_SIZE

			if land_cells.has("%d_%d" % [tx, ty]):
				# Create organic dirt patch
				var patch_size = rng.randi_range(2, 7)
				_create_dirt_patch(tx, ty, patch_size, dirt_tiles)
				break
			attempts += 1

func _create_dirt_patch(center_x: int, center_y: int, size: int, dirt_tiles: Array) -> void:
	for dy in range(-size, size + 1):
		for dx in range(-size, size + 1):
			var dist = Vector2(dx, dy).length()
			if dist <= size and rng.randf() < (1.0 - dist / size * 0.5):
				var tx = center_x + dx
				var ty = center_y + dy
				var key = "%d_%d" % [tx, ty]

				if land_cells.has(key) and not water_cells.has(key):
					var tile = dirt_tiles[rng.randi() % dirt_tiles.size()]
					dirt_tilemap.set_cell(Vector2i(tx, ty), 0, tile)
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
			add_child(tree)
			obstacle_positions.append(pos)
			placed += 1

func _randomize_tree(tree: Node2D) -> void:
	var textures = [
		"res://assets/enviro/gowl/Trees/Tree1.png",
		"res://assets/enviro/gowl/Trees/Tree2.png",
		"res://assets/enviro/gowl/Trees/Tree3.png"
	]

	var sprite = tree.get_node_or_null("Sprite")
	if sprite and sprite is Sprite2D:
		var tex = load(textures[rng.randi() % textures.size()])
		if tex:
			sprite.texture = tex

		var scale_val = rng.randf_range(1.5, 5.0)
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
			add_child(rock)
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
			add_child(lamp)
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
				add_child(stone)
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

	# Reveal area around player
	for dy in range(-reveal_radius, reveal_radius + 1):
		for dx in range(-reveal_radius, reveal_radius + 1):
			var px = fog_x + dx
			var py = fog_y + dy

			if px >= 0 and px < fog_image.get_width() and py >= 0 and py < fog_image.get_height():
				var dist = Vector2(dx, dy).length()
				if dist <= reveal_radius:
					# Gradual fade at edges
					var alpha = 0.0
					if dist > reveal_radius * 0.7:
						alpha = (dist - reveal_radius * 0.7) / (reveal_radius * 0.3) * 0.85
					fog_image.set_pixel(px, py, Color(0, 0, 0, alpha))

	fog_texture.update(fog_image)

# Public API
func get_spawn_position() -> Vector2:
	if _spawn_center != Vector2.ZERO:
		return _spawn_center
	return Vector2(MAP_SIZE / 2, MAP_SIZE / 2)

func get_map_bounds() -> Rect2:
	return Rect2(0, 0, MAP_SIZE, MAP_SIZE)

func get_camera_bounds() -> Rect2:
	return Rect2(-50, -50, MAP_SIZE + 100, MAP_SIZE + 100)
