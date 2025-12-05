extends Node2D

# Shield Charge - T2 Charge with shield impact and defensive aura

var pixel_size := 4
var duration := 0.55
var elapsed := 0.0

# Shield impact
var shield_flash_alpha := 1.0
var shield_size := 0.0
var max_shield_size := 50.0

# Impact shockwave
var wave_radius := 0.0
var max_wave_radius := 70.0
var wave_alpha := 1.0

# Metal sparks
var sparks := []
var num_sparks := 14

# Speed lines
var speed_lines := []
var num_lines := 8

# Dust
var dust := []
var num_dust := 10

func _ready() -> void:
	# Initialize sparks (metallic colors)
	for i in range(num_sparks):
		var angle = randf_range(-PI/3, PI/3)
		sparks.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(120, 220),
			"alpha": 1.0,
			"color_shift": randf()  # For varying metal colors
		})

	# Initialize speed lines (behind)
	for i in range(num_lines):
		speed_lines.append({
			"y_offset": randf_range(-30, 30),
			"length": randf_range(30, 60),
			"alpha": 0.8,
			"x_pos": randf_range(-80, -40)
		})

	# Initialize dust
	for i in range(num_dust):
		var angle = randf_range(PI/2, PI*3/2)  # Behind the charge
		dust.append({
			"pos": Vector2(randf_range(-40, -20), randf_range(-15, 15)),
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(20, 50),
			"size": randf_range(8, 14),
			"alpha": 0.5
		})

	# Screen shake
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(10, 0.3)

	await get_tree().create_timer(duration + 0.15).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Shield expands then holds
	shield_size = ease(min(progress * 3, 1.0), 0.3) * max_shield_size
	shield_flash_alpha = max(0, 1.0 - progress * 1.5)

	# Shockwave expands
	wave_radius = progress * max_wave_radius
	wave_alpha = max(0, 1.0 - progress)

	# Update sparks
	for spark in sparks:
		spark.velocity *= 0.93
		spark.pos += spark.velocity * delta
		spark.alpha = max(0, 1.0 - progress * 1.3)

	# Update speed lines (move left)
	for line in speed_lines:
		line.x_pos -= delta * 150
		line.alpha = max(0, 0.8 - progress)

	# Update dust
	for d in dust:
		d.pos += d.velocity * delta
		d.velocity *= 0.95
		d.alpha = max(0, 0.5 - progress * 0.7)
		d.size += delta * 8

	queue_redraw()

func _draw() -> void:
	# Draw speed lines (behind shield)
	for line in speed_lines:
		if line.alpha > 0:
			var color = Color(0.7, 0.75, 0.8, line.alpha * 0.5)
			var start = Vector2(line.x_pos, line.y_offset)
			var end = Vector2(line.x_pos + line.length, line.y_offset)
			_draw_pixel_line(start, end, color)

	# Draw dust
	for d in dust:
		if d.alpha > 0:
			var color = Color(0.6, 0.55, 0.5, d.alpha * 0.4)
			_draw_pixel_circle(d.pos, d.size, color)

	# Draw shockwave ring
	if wave_alpha > 0:
		var color = Color(0.6, 0.7, 0.9, wave_alpha * 0.5)
		_draw_pixel_ring(Vector2.ZERO, wave_radius, color, 6)

	# Draw shield shape (rounded rectangle / shield icon)
	if shield_flash_alpha > 0:
		# Shield body (metallic blue)
		var body_color = Color(0.4, 0.5, 0.8, shield_flash_alpha * 0.8)
		_draw_shield_shape(Vector2.ZERO, shield_size, body_color)

		# Shield highlight
		var highlight_color = Color(0.8, 0.85, 1.0, shield_flash_alpha * 0.6)
		_draw_shield_shape(Vector2(-4, -4), shield_size * 0.6, highlight_color)

		# Shield edge glow
		var edge_color = Color(1.0, 1.0, 1.0, shield_flash_alpha * 0.4)
		_draw_shield_outline(Vector2.ZERO, shield_size, edge_color)

	# Draw sparks
	for spark in sparks:
		if spark.alpha > 0:
			# Metallic color variation
			var r = 0.8 + spark.color_shift * 0.2
			var g = 0.7 + spark.color_shift * 0.2
			var b = 0.5 + spark.color_shift * 0.3
			var color = Color(r, g, b, spark.alpha)
			var pos = (spark.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_shield_shape(center: Vector2, size: float, color: Color) -> void:
	# Simple shield shape - wider at top, pointed at bottom
	var half_width = size * 0.6
	var height = size

	for y in range(int(-height/2 / pixel_size), int(height/2 / pixel_size) + 1):
		var y_pos = y * pixel_size
		# Width decreases toward bottom
		var t = (y_pos + height/2) / height
		var row_width = half_width * (1.0 - t * 0.6)

		for x in range(int(-row_width / pixel_size), int(row_width / pixel_size) + 1):
			var x_pos = x * pixel_size
			var pos = center + Vector2(x_pos, y_pos)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_shield_outline(center: Vector2, size: float, color: Color) -> void:
	var half_width = size * 0.6
	var height = size

	# Top edge
	for x in range(int(-half_width / pixel_size), int(half_width / pixel_size) + 1):
		var pos = center + Vector2(x * pixel_size, -height/2)
		pos = (pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Sides and bottom point
	for y in range(int(-height/2 / pixel_size), int(height/2 / pixel_size) + 1):
		var y_pos = y * pixel_size
		var t = (y_pos + height/2) / height
		var row_width = half_width * (1.0 - t * 0.6)

		# Left edge
		var left_pos = center + Vector2(-row_width, y_pos)
		left_pos = (left_pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(left_pos, Vector2(pixel_size, pixel_size)), color)

		# Right edge
		var right_pos = center + Vector2(row_width, y_pos)
		right_pos = (right_pos / pixel_size).floor() * pixel_size
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

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 4)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = center + pos
				draw_pos = (draw_pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)
