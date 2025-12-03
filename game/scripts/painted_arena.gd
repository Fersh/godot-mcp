@tool
extends Node2D
## Painted Arena - A hand-painted tile map for challenge mode
##
## HOW TO USE:
## 1. Open this scene in Godot (scenes/painted_arena.tscn)
## 2. Select the TileMapLayer you want to paint on:
##    - GroundLayer: Base terrain (grass, dirt, field tiles)
##    - WaterLayer: Water tiles (will auto-generate collision)
##    - DecorationLayer: Small decorations (rocks, logs, flowers)
##    - OverlayLayer: Tall grass, trees (y-sorted, players walk through)
## 3. Open the TileSet panel at the bottom
## 4. Click on forest_tileset.tres to configure tiles if needed
## 5. Paint tiles directly on the map!
##
## TILE COORDINATES (from forest_tileset.png, 32x32 grid):
## - (6,4) = Light field center
## - (3,4) = Dark grass center
## - (9,4) = Dark grass variant
## - (6,1) = Dirt center (for roads)
## - (6,7) = Water center
## - (4,18) = Yellow tall grass
## - (1,24) = Green tall grass
## - Small objects: (6,19) to (13,21)
## - Logs: (7,22) to (12,22)

# Tile scale (to match procedural map)
@export var tile_scale: float = 2.0

# Editor button to regenerate the starter arena
@export var regenerate_arena: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			_generate_starter_arena()
			print("Regenerated arena tiles!")

# Water tile IDs - set these after configuring your TileSet
# You'll need to note which atlas coords are water tiles
@export var water_atlas_coords: Array[Vector2i] = [
	Vector2i(6, 7),   # Water center
	Vector2i(6, 6),   # Water edge top
	Vector2i(6, 8),   # Water edge bottom
	Vector2i(5, 7),   # Water edge left
	Vector2i(7, 7),   # Water edge right
	Vector2i(5, 6),   # Water corner top-left
	Vector2i(7, 6),   # Water corner top-right
	Vector2i(5, 8),   # Water corner bottom-left
	Vector2i(7, 8),   # Water corner bottom-right
]

# Collision bodies for water
var water_collision_bodies: Array[StaticBody2D] = []

# Cached bounds
var arena_bounds: Rect2 = Rect2()

func _ready() -> void:
	# Check if we need to auto-generate a starter map
	var ground_layer = get_node_or_null("GroundLayer") as TileMapLayer
	if ground_layer and ground_layer.get_used_cells().is_empty():
		_generate_starter_arena()

	# Only generate collisions and bounds at runtime, not in editor
	if not Engine.is_editor_hint():
		# Generate water collisions
		_generate_water_collisions()

		# Calculate arena bounds from painted tiles
		_calculate_arena_bounds()

func _generate_starter_arena() -> void:
	"""Generate a basic starter arena if no tiles are painted."""
	var ground = get_node_or_null("GroundLayer") as TileMapLayer
	var water = get_node_or_null("WaterLayer") as TileMapLayer

	if not ground:
		print("ERROR: No GroundLayer found!")
		return

	# Get the tileset and find valid source
	var tileset = ground.tile_set
	if not tileset:
		print("ERROR: No tileset assigned!")
		return

	# Find first valid source ID
	var source_id = -1
	for i in range(tileset.get_source_count()):
		source_id = tileset.get_source_id(i)
		print("Found tileset source ID: ", source_id)
		break

	if source_id < 0:
		print("ERROR: No tileset sources found!")
		return

	# Simple arena - 16x12 tiles starting at (0,0)
	var width = 16
	var height = 12

	# Tile coordinates that exist in the tileset (verified from .tres file)
	var light_field = Vector2i(6, 4)
	var dark_grass = Vector2i(3, 4)
	var dirt_center = Vector2i(6, 1)
	var water_tile = Vector2i(6, 7)

	print("Generating ", width, "x", height, " arena with source_id=", source_id)

	# Paint the ground
	for y in range(height):
		for x in range(width):
			var tile_to_use: Vector2i

			# Border
			if x == 0 or x == width - 1 or y == 0 or y == height - 1:
				tile_to_use = dark_grass
			# Roads through middle
			elif y == height / 2 or x == width / 2:
				tile_to_use = dirt_center
			# Field
			else:
				tile_to_use = light_field

			ground.set_cell(Vector2i(x, y), source_id, tile_to_use)

	# Add water pool
	if water:
		for dy in range(2):
			for dx in range(2):
				water.set_cell(Vector2i(3 + dx, 3 + dy), source_id, water_tile)

	print("Generated simple starter arena!")

	# Force editor refresh
	if Engine.is_editor_hint():
		ground.notify_property_list_changed()

func _generate_water_collisions() -> void:
	"""Create collision bodies for all water tiles."""
	var water_layer = get_node_or_null("WaterLayer") as TileMapLayer
	if not water_layer:
		return

	# Clear existing collisions
	for body in water_collision_bodies:
		if is_instance_valid(body):
			body.queue_free()
	water_collision_bodies.clear()

	# Get all used cells in water layer
	var used_cells = water_layer.get_used_cells()
	var layer_scale = water_layer.scale
	var tile_size = 32.0 * layer_scale.x

	for cell in used_cells:
		# Check if this cell has a water tile
		var atlas_coords = water_layer.get_cell_atlas_coords(cell)
		if atlas_coords in water_atlas_coords:
			var world_pos = Vector2(cell.x * tile_size, cell.y * tile_size)
			_create_water_collision(world_pos, tile_size)

func _create_water_collision(pos: Vector2, size: float) -> void:
	"""Create a collision body for a water tile."""
	var body = StaticBody2D.new()
	body.position = pos + Vector2(size / 2, size / 2)
	body.collision_layer = 2  # Same as walls
	body.collision_mask = 0

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(size * 0.85, size * 0.85)
	collision.shape = shape

	body.add_child(collision)
	add_child(body)
	water_collision_bodies.append(body)

func _calculate_arena_bounds() -> Rect2:
	"""Calculate the bounding box of all painted tiles."""
	var ground_layer = get_node_or_null("GroundLayer") as TileMapLayer
	if not ground_layer:
		return Rect2()

	var used_cells = ground_layer.get_used_cells()
	if used_cells.is_empty():
		return Rect2()

	var layer_scale = ground_layer.scale
	var tile_size = 32.0 * layer_scale.x

	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF

	for cell in used_cells:
		min_x = min(min_x, cell.x)
		min_y = min(min_y, cell.y)
		max_x = max(max_x, cell.x)
		max_y = max(max_y, cell.y)

	arena_bounds = Rect2(
		min_x * tile_size,
		min_y * tile_size,
		(max_x - min_x + 1) * tile_size,
		(max_y - min_y + 1) * tile_size
	)

	return arena_bounds

func get_arena_bounds() -> Rect2:
	"""Get the calculated arena bounds for player clamping."""
	if arena_bounds.size == Vector2.ZERO:
		_calculate_arena_bounds()
	return arena_bounds

func get_player_spawn_position() -> Vector2:
	"""Get the center of the arena for player spawn."""
	var bounds = get_arena_bounds()
	return bounds.position + bounds.size / 2

func regenerate_collisions() -> void:
	"""Call this after modifying water tiles at runtime."""
	_generate_water_collisions()
