extends Resource
class_name MapConfig
## Simple resource to configure procedural map tiles
## Create a .tres file, assign tile coordinates, and load in tile_background.gd

# Tileset
@export var tileset_path: String = "res://assets/enviro/forest_tileset.png"

# Floor tiles (column, row) - will be converted to Rect2i
@export var floor_tiles: Array[Vector2i] = []

# Outer edge tiles
@export var edge_top: Vector2i
@export var edge_bottom: Vector2i
@export var edge_left: Vector2i
@export var edge_right: Vector2i
@export var edge_top_left: Vector2i
@export var edge_top_right: Vector2i
@export var edge_bottom_left: Vector2i
@export var edge_bottom_right: Vector2i

# Water/hazard tiles
@export var water_center: Vector2i
@export var water_top: Vector2i
@export var water_bottom: Vector2i
@export var water_left: Vector2i
@export var water_right: Vector2i
@export var water_top_left: Vector2i
@export var water_top_right: Vector2i
@export var water_bottom_left: Vector2i
@export var water_bottom_right: Vector2i

# Path/road tiles
@export var path_center: Vector2i
@export var path_top: Vector2i
@export var path_bottom: Vector2i
@export var path_left: Vector2i
@export var path_right: Vector2i
@export var path_top_left: Vector2i
@export var path_top_right: Vector2i
@export var path_bottom_left: Vector2i
@export var path_bottom_right: Vector2i

# Top border extension
@export var border_edge: Vector2i
@export var border_fill: Vector2i

# Decorations (column, row)
@export var decorations: Array[Vector2i] = []

# Obstacle textures (trees, pillars, etc)
@export var obstacle_textures: Array[String] = []

# Lamp texture
@export var lamp_texture: String = ""

# Chest textures (closed, opening, open)
@export var chest_textures: Array[String] = []

# Light color
@export var light_color: Color = Color(1.0, 0.85, 0.6)

# Helper to convert (col, row) to Rect2i
func tile_rect(pos: Vector2i) -> Rect2i:
	return Rect2i(pos.x * 32, pos.y * 32, 32, 32)
