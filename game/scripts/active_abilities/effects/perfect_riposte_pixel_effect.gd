extends Node2D

# Perfect Riposte - T3 Parry flawless counter with massive damage

var pixel_size := 4
var duration := 0.8
var elapsed := 0.0

# Perfect parry flash
var parry_flash := 0.0

# Counter strike
var counter_progress := 0.0
var counter_length := 80.0

# Sparks explosion
var sparks := []
var num_sparks := 40

# Perfection aura
var perfection_ring := 0.0
var ring_radius := 0.0

# Time slow effect (visual distortion)
var time_distort := []
var num_distort := 15

func _ready() -> void:
	# Initialize sparks
	for i in range(num_sparks):
		var angle = randf() * TAU
		sparks.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(150, 350),
			"alpha": 0.0,
			"size": randf_range(2, 6)
		})

	# Initialize time distortion lines
	for i in range(num_distort):
		time_distort.append({
			"y": randf_range(-60, 60),
			"speed": randf_range(100, 200),
			"alpha": 0.0,
			"width": randf_range(20, 60)
		})

	# Screen flash
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(8, 0.2)

	await get_tree().create_timer(duration + 0.15).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Perfect parry flash (instant)
	if progress < 0.15:
		parry_flash = 1.0 - progress / 0.15
	else:
		parry_flash = 0

	# Perfection ring expands
	if progress < 0.3:
		ring_radius = progress / 0.3 * 60
		perfection_ring = 1.0
	else:
		perfection_ring = max(0, 1.0 - (progress - 0.3) / 0.3)

	# Counter strike
	if progress > 0.15:
		counter_progress = min((progress - 0.15) / 0.2, 1.0)
		# Trigger sparks at impact
		if progress > 0.35 and progress < 0.4:
			for spark in sparks:
				if spark.alpha == 0:
					spark.alpha = 1.0

	# Update sparks
	for spark in sparks:
		if spark.alpha > 0:
			spark.velocity *= 0.94
			spark.pos += spark.velocity * delta
			spark.alpha = max(0, spark.alpha - delta * 2)

	# Time distortion effect
	for distort in time_distort:
		if progress < 0.5:
			distort.alpha = min(progress * 4, 1.0) * 0.4
		else:
			distort.alpha = max(0, 0.4 - (progress - 0.5) * 0.8)

	queue_redraw()

func _draw() -> void:
	# Draw time distortion
	for distort in time_distort:
		if distort.alpha > 0:
			var color = Color(0.8, 0.85, 1.0, distort.alpha)
			var start = Vector2(-100, distort.y)
			var end = Vector2(-100 + distort.width, distort.y)
			_draw_pixel_line(start, end, color)

	# Draw perfection ring
	if perfection_ring > 0:
		var ring_color = Color(1.0, 0.95, 0.7, perfection_ring * 0.7)
		_draw_pixel_ring(Vector2.ZERO, ring_radius, ring_color, 6)

	# Draw parry flash
	if parry_flash > 0:
		var flash_color = Color(1.0, 1.0, 0.95, parry_flash)
		_draw_pixel_circle(Vector2.ZERO, 40, flash_color)

	# Draw counter strike
	if counter_progress > 0:
		var strike_end = counter_progress * counter_length
		# Blade trail
		var trail_color = Color(1.0, 0.9, 0.6, 0.8 * (1.0 - elapsed/duration))
		for y_off in range(-2, 3):
			_draw_pixel_line(
				Vector2(0, y_off * pixel_size),
				Vector2(strike_end, y_off * pixel_size),
				trail_color
			)
		# Perfect blade edge
		var edge_color = Color(1.0, 1.0, 0.9, 1.0)
		for y_off in range(-1, 2):
			var pos = Vector2(strike_end, y_off * pixel_size)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size * 2, pixel_size)), edge_color)

	# Draw sparks
	for spark in sparks:
		if spark.alpha > 0:
			var color = Color(1.0, 0.95, 0.7, spark.alpha)
			var pos = (spark.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(spark.size, spark.size)), color)

	# Draw "PERFECT" indicator
	if elapsed > 0.1 and elapsed < 0.6:
		var text_alpha = min((elapsed - 0.1) / 0.1, 1.0) * max(0, 1.0 - (elapsed - 0.3) / 0.3)
		_draw_perfect_text(Vector2(0, -45), text_alpha)

func _draw_perfect_text(center: Vector2, alpha: float) -> void:
	# Simple star burst to indicate perfection
	var color = Color(1.0, 0.9, 0.4, alpha)
	for i in range(8):
		var angle = i * TAU / 8
		var end = center + Vector2(cos(angle), sin(angle)) * 15
		_draw_pixel_line(center, end, color)

func _draw_pixel_ring(center: Vector2, radius: float, color: Color, thickness: float) -> void:
	var circumference = TAU * radius
	var steps = max(int(circumference / pixel_size), 16)
	for i in range(steps):
		var angle = (float(i) / steps) * TAU
		for t in range(int(thickness / pixel_size)):
			var r = radius - t * pixel_size
			if r > 0:
				var pos = center + Vector2(cos(angle), sin(angle)) * r
				pos = (pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_pixel_line(from: Vector2, to: Vector2, color: Color) -> void:
	var dist = from.distance_to(to)
	var steps = int(dist / pixel_size) + 1
	for i in range(steps):
		var t = float(i) / max(steps - 1, 1)
		var pos = from.lerp(to, t)
		pos = (pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 2)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = center + pos
				draw_pos = (draw_pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)
