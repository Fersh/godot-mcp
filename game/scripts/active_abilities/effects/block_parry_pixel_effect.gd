extends Node2D

# Block Parry - T2 Block with counter window (block tree's parry ability)

var pixel_size := 4
var duration := 0.5
var elapsed := 0.0

# Shield block
var block_alpha := 0.0
var block_size := 45.0

# Parry timing window flash
var parry_window_alpha := 0.0

# Deflection sparks
var sparks := []
var num_sparks := 10

# Success indicator
var success_ring_radius := 0.0
var max_ring := 55.0

func _ready() -> void:
	# Initialize sparks
	for i in range(num_sparks):
		var angle = randf_range(-PI/2, PI/2)
		sparks.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(120, 200),
			"alpha": 0.8
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Block appears instantly
	if progress < 0.1:
		block_alpha = progress / 0.1
	else:
		block_alpha = max(0, 1.0 - (progress - 0.1) / 0.9 * 0.5)

	# Parry window flash (quick golden flash)
	if progress < 0.15:
		parry_window_alpha = 1.0
	elif progress < 0.25:
		parry_window_alpha = 1.0 - (progress - 0.15) / 0.1
	else:
		parry_window_alpha = 0

	# Success ring expands
	success_ring_radius = progress * max_ring

	# Update sparks
	for spark in sparks:
		spark.pos += spark.velocity * delta
		spark.velocity *= 0.88
		spark.alpha = max(0, spark.alpha - delta * 2)

	queue_redraw()

func _draw() -> void:
	# Draw success ring (timing indicator)
	if success_ring_radius > 5:
		var ring_alpha = max(0, 1.0 - success_ring_radius / max_ring) * 0.4
		var ring_color = Color(1.0, 0.85, 0.3, ring_alpha)
		_draw_pixel_ring(Vector2.ZERO, success_ring_radius, ring_color, 4)

	# Draw shield block
	if block_alpha > 0:
		# Main shield
		var shield_color = Color(0.5, 0.6, 0.8, block_alpha * 0.8)
		_draw_shield_shape(Vector2.ZERO, block_size, shield_color)

		# Edge
		var edge_color = Color(0.7, 0.75, 0.9, block_alpha * 0.6)
		_draw_shield_outline(Vector2.ZERO, block_size, edge_color)

	# Draw parry window flash (golden overlay)
	if parry_window_alpha > 0:
		var flash_color = Color(1.0, 0.9, 0.4, parry_window_alpha * 0.5)
		_draw_shield_shape(Vector2.ZERO, block_size * 1.1, flash_color)
		# "Perfect" timing indicator
		var indicator_color = Color(1.0, 1.0, 0.6, parry_window_alpha)
		_draw_timing_indicator(Vector2(0, -block_size * 0.7), indicator_color)

	# Draw sparks
	for spark in sparks:
		if spark.alpha > 0:
			var color = Color(1.0, 0.9, 0.5, spark.alpha)
			var pos = (spark.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_timing_indicator(center: Vector2, color: Color) -> void:
	# Small star/sparkle
	var dirs = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
	for dir in dirs:
		var end = center + dir * 8
		_draw_pixel_line(center, end, color)

func _draw_shield_shape(center: Vector2, size: float, color: Color) -> void:
	var half_width = size * 0.55
	var height = size

	for y in range(int(-height/2 / pixel_size), int(height/2 / pixel_size) + 1):
		var y_pos = y * pixel_size
		var t = (y_pos + height/2) / height
		var row_width = half_width * (1.0 - t * 0.55)

		for x in range(int(-row_width / pixel_size), int(row_width / pixel_size) + 1):
			var x_pos = x * pixel_size
			var pos = center + Vector2(x_pos, y_pos)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_shield_outline(center: Vector2, size: float, color: Color) -> void:
	var half_width = size * 0.55
	var height = size

	# Top edge
	for x in range(int(-half_width / pixel_size), int(half_width / pixel_size) + 1):
		var pos = center + Vector2(x * pixel_size, -height/2)
		pos = (pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Sides
	for y in range(int(-height/2 / pixel_size), int(height/2 / pixel_size) + 1):
		var y_pos = y * pixel_size
		var t = (y_pos + height/2) / height
		var row_width = half_width * (1.0 - t * 0.55)

		var left_pos = center + Vector2(-row_width, y_pos)
		var right_pos = center + Vector2(row_width, y_pos)
		left_pos = (left_pos / pixel_size).floor() * pixel_size
		right_pos = (right_pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(left_pos, Vector2(pixel_size, pixel_size)), color)
		draw_rect(Rect2(right_pos, Vector2(pixel_size, pixel_size)), color)

func _draw_pixel_line(from: Vector2, to: Vector2, color: Color) -> void:
	var dist = from.distance_to(to)
	var steps = int(dist / pixel_size) + 1
	for i in range(steps):
		var t = float(i) / max(steps - 1, 1)
		var pos = from.lerp(to, t)
		pos = (pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_pixel_ring(center: Vector2, radius: float, color: Color, thickness: float) -> void:
	var circumference = TAU * radius
	var steps = max(int(circumference / pixel_size), 12)
	for i in range(steps):
		var angle = (float(i) / steps) * TAU
		for t in range(int(thickness / pixel_size)):
			var r = radius - t * pixel_size
			if r > 0:
				var pos = center + Vector2(cos(angle), sin(angle)) * r
				pos = (pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)
