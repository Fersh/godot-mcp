extends CanvasLayer

# Off-screen enemy indicators
# Shows red arrows at screen edges pointing to enemies outside view
# Different sizes: normal enemies (small), elites (medium + skull), bosses (large + skull)

class IndicatorDrawer extends Control:
	var parent_ref: Node = null

	func _draw() -> void:
		if parent_ref and parent_ref.has_method("draw_indicators"):
			parent_ref.draw_indicators(self)

const INDICATOR_MARGIN: float = 40.0  # Distance from screen edge
const NORMAL_SIZE: float = 8.0
const ELITE_SIZE: float = 14.0
const BOSS_SIZE: float = 20.0

const NORMAL_COLOR: Color = Color(0.9, 0.2, 0.2, 0.7)
const ELITE_COLOR: Color = Color(1.0, 0.5, 0.1, 0.85)
const BOSS_COLOR: Color = Color(0.9, 0.1, 0.1, 0.95)

var player: Node2D = null
var camera: Camera2D = null
var drawer: Control = null

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_PAUSABLE

	# Create custom drawer control
	drawer = IndicatorDrawer.new()
	drawer.parent_ref = self
	drawer.name = "IndicatorDrawer"
	drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(drawer)

	# Set initial size
	_update_drawer_size()

func _update_drawer_size() -> void:
	if drawer:
		var viewport_size = get_viewport().get_visible_rect().size
		drawer.position = Vector2.ZERO
		drawer.size = viewport_size

func _process(_delta: float) -> void:
	# Find player and camera if not found
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if camera == null:
		if player:
			camera = player.get_node_or_null("Camera2D")
		# Fallback: find any Camera2D in the scene
		if camera == null:
			camera = get_tree().get_first_node_in_group("camera")
			if camera == null:
				var cameras = get_tree().get_nodes_in_group("")
				for node in get_tree().root.get_children():
					var found_cam = _find_camera_recursive(node)
					if found_cam:
						camera = found_cam
						break

	# Update drawer size in case viewport changed
	_update_drawer_size()

	# Request redraw
	if drawer:
		drawer.queue_redraw()

func _find_camera_recursive(node: Node) -> Camera2D:
	if node is Camera2D and node.is_current():
		return node
	for child in node.get_children():
		var result = _find_camera_recursive(child)
		if result:
			return result
	return null

func draw_indicators(canvas: Control) -> void:
	if player == null or camera == null:
		return

	var viewport_size = get_viewport().get_visible_rect().size
	var camera_pos = camera.global_position
	var half_size = viewport_size / 2

	# Screen bounds in world coordinates
	var screen_left = camera_pos.x - half_size.x
	var screen_right = camera_pos.x + half_size.x
	var screen_top = camera_pos.y - half_size.y
	var screen_bottom = camera_pos.y + half_size.y

	# Get all enemies
	var enemies = get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var enemy_pos = enemy.global_position

		# Check if off-screen (with small buffer)
		var buffer = 20.0
		if enemy_pos.x >= screen_left + buffer and enemy_pos.x <= screen_right - buffer and \
		   enemy_pos.y >= screen_top + buffer and enemy_pos.y <= screen_bottom - buffer:
			continue  # On screen, skip

		# Get enemy rarity
		var rarity = "normal"
		if "enemy_rarity" in enemy:
			rarity = enemy.enemy_rarity

		# Calculate direction from screen center to enemy
		var direction = (enemy_pos - camera_pos).normalized()

		# Calculate screen edge position
		var screen_pos = _get_screen_edge_pos(direction, viewport_size)

		# Draw indicator based on rarity
		_draw_indicator(canvas, screen_pos, direction, rarity)

func _get_screen_edge_pos(direction: Vector2, viewport_size: Vector2) -> Vector2:
	var center = viewport_size / 2
	var margin = INDICATOR_MARGIN

	# Find where the ray from center in direction hits the screen edge
	var bounds = Vector2(center.x - margin, center.y - margin)

	var t_x = INF
	var t_y = INF

	if abs(direction.x) > 0.001:
		t_x = bounds.x / abs(direction.x)
	if abs(direction.y) > 0.001:
		t_y = bounds.y / abs(direction.y)

	var t = min(t_x, t_y)

	return center + direction * t

func _draw_indicator(canvas: Control, pos: Vector2, direction: Vector2, rarity: String) -> void:
	var size: float
	var color: Color
	var draw_skull: bool = false

	match rarity:
		"boss":
			size = BOSS_SIZE
			color = BOSS_COLOR
			draw_skull = true
		"elite":
			size = ELITE_SIZE
			color = ELITE_COLOR
			draw_skull = true
		_:
			size = NORMAL_SIZE
			color = NORMAL_COLOR

	# Draw arrow triangle pointing in direction (toward center of screen)
	var inward_dir = -direction  # Point inward to indicate "enemy is that way"
	var points = PackedVector2Array()

	# Triangle pointing outward (toward enemy)
	var tip = pos + direction * size * 0.8
	var base_offset = direction.rotated(PI / 2) * size * 0.5
	var back = pos - direction * size * 0.4

	points.append(tip)
	points.append(back + base_offset)
	points.append(back - base_offset)

	# Draw outline first (slightly larger)
	var outline_color = Color(0, 0, 0, color.a)
	canvas.draw_polygon(points, [outline_color])

	# Draw main triangle slightly smaller
	var inner_points = PackedVector2Array()
	var inner_tip = pos + direction * size * 0.6
	var inner_back = pos - direction * size * 0.2
	var inner_offset = direction.rotated(PI / 2) * size * 0.35
	inner_points.append(inner_tip)
	inner_points.append(inner_back + inner_offset)
	inner_points.append(inner_back - inner_offset)
	canvas.draw_polygon(inner_points, [color])

	# Draw skull for elites/bosses (behind the arrow, toward screen center)
	if draw_skull:
		var skull_pos = pos - direction * size * 1.2
		_draw_skull(canvas, skull_pos, size * 0.6, color)

func _draw_skull(canvas: Control, pos: Vector2, size: float, color: Color) -> void:
	# Simple pixel skull - 5x5 grid
	var s = size / 4.0  # Pixel size
	var skull_color = Color(1, 1, 1, color.a)
	var eye_color = Color(0, 0, 0, color.a)

	# Draw skull background (rounded head shape)
	# Row 1 (top) - 3 pixels centered
	canvas.draw_rect(Rect2(pos.x - s * 1.5, pos.y - s * 2, s * 3, s), skull_color)
	# Row 2 - 5 pixels wide
	canvas.draw_rect(Rect2(pos.x - s * 2.5, pos.y - s, s * 5, s), skull_color)
	# Row 3 (eyes) - 5 pixels with 2 eye holes
	canvas.draw_rect(Rect2(pos.x - s * 2.5, pos.y, s * 5, s), skull_color)
	canvas.draw_rect(Rect2(pos.x - s * 1.5, pos.y, s, s), eye_color)  # Left eye
	canvas.draw_rect(Rect2(pos.x + s * 0.5, pos.y, s, s), eye_color)  # Right eye
	# Row 4 (nose area) - 3 pixels centered
	canvas.draw_rect(Rect2(pos.x - s * 1.5, pos.y + s, s * 3, s), skull_color)
	# Row 5 (jaw) - teeth pattern
	canvas.draw_rect(Rect2(pos.x - s, pos.y + s * 2, s * 2, s), skull_color)
