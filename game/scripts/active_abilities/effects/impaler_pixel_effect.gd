extends Node2D

# Impaler - T3 Throw massive spear that pins enemies

var pixel_size := 4
var duration := 0.9
var elapsed := 0.0

# Giant spear
var spear_progress := 0.0
var spear_length := 120.0

# Impaling impact
var impact_alpha := 0.0
var impact_waves := []
var num_waves := 3

# Blood splatter
var blood := []
var num_blood := 20

# Pinned indicator
var pinned_alpha := 0.0

# Ground crack
var cracks := []
var num_cracks := 6

func _ready() -> void:
	# Initialize impact waves
	for i in range(num_waves):
		impact_waves.append({
			"radius": 0.0,
			"alpha": 0.0,
			"delay": 0.3 + i * 0.08
		})

	# Initialize blood
	for i in range(num_blood):
		var angle = randf_range(-PI * 0.8, -PI * 0.2)
		blood.append({
			"pos": Vector2(60, 0),
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(80, 180),
			"alpha": 0.0
		})

	# Initialize cracks
	for i in range(num_cracks):
		var angle = randf_range(-PI/3, PI/3)
		cracks.append({
			"angle": angle,
			"length": 0.0,
			"max_length": randf_range(30, 60)
		})

	# Screen shake on impact
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(12, 0.3)

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Spear flies forward
	spear_progress = ease(min(progress * 3, 1.0), 0.15)

	# Impact at hit point
	if progress > 0.33:
		impact_alpha = max(0, 1.0 - (progress - 0.33) / 0.3)

		# Trigger blood
		for b in blood:
			if b.alpha == 0:
				b.alpha = 1.0

		# Update waves
		for wave in impact_waves:
			if elapsed > wave.delay:
				var wave_age = elapsed - wave.delay
				wave.radius = wave_age * 150
				wave.alpha = max(0, 0.8 - wave_age * 2)

		# Grow cracks
		for crack in cracks:
			crack.length = min(progress * 2, 1.0) * crack.max_length

		# Pinned indicator
		if progress > 0.5:
			pinned_alpha = min((progress - 0.5) / 0.2, 1.0) * (1.0 - max(0, progress - 0.8) * 5)

	# Update blood
	for b in blood:
		if b.alpha > 0:
			b.velocity.y += 300 * delta
			b.pos += b.velocity * delta
			b.alpha = max(0, b.alpha - delta * 1.5)

	queue_redraw()

func _draw() -> void:
	# Draw ground cracks
	for crack in cracks:
		if crack.length > 5:
			var color = Color(0.3, 0.25, 0.2, 0.7)
			var start = Vector2(60, 10)
			var end = start + Vector2(cos(crack.angle), sin(crack.angle)) * crack.length
			_draw_pixel_line(start, end, color)

	# Draw impact waves
	for wave in impact_waves:
		if wave.alpha > 0:
			var color = Color(0.8, 0.6, 0.4, wave.alpha * 0.5)
			_draw_pixel_ring(Vector2(60, 0), wave.radius, color, 6)

	# Draw spear
	if spear_progress > 0:
		var spear_end = -40 + spear_progress * spear_length
		_draw_giant_spear(Vector2(-40, 0), Vector2(spear_end, 0))

	# Draw impact flash
	if impact_alpha > 0:
		var flash_color = Color(1.0, 0.9, 0.7, impact_alpha * 0.7)
		_draw_pixel_circle(Vector2(60, 0), 30, flash_color)

	# Draw blood
	for b in blood:
		if b.alpha > 0:
			var color = Color(0.7, 0.1, 0.1, b.alpha)
			var pos = (b.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Draw pinned indicator
	if pinned_alpha > 0:
		_draw_pinned_symbol(Vector2(60, -35), pinned_alpha)

func _draw_giant_spear(from: Vector2, to: Vector2) -> void:
	var dir = (to - from).normalized()
	var perp = dir.rotated(PI/2)

	# Shaft
	var shaft_color = Color(0.5, 0.4, 0.35, 0.9)
	for w in range(-1, 2):
		_draw_pixel_line(from + perp * w * pixel_size, to + perp * w * pixel_size, shaft_color)

	# Spear head (at end)
	var head_start = to - dir * 20
	var head_color = Color(0.7, 0.65, 0.6, 1.0)
	var edge_color = Color(0.9, 0.85, 0.8, 1.0)

	# Triangular head
	for i in range(20):
		var t = float(i) / 20
		var width = (1.0 - t) * 8
		var pos = head_start + dir * i * 1.0
		for w in range(-int(width/pixel_size), int(width/pixel_size) + 1):
			var draw_pos = pos + perp * w * pixel_size
			draw_pos = (draw_pos / pixel_size).floor() * pixel_size
			var color = edge_color if t > 0.8 else head_color
			draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)

func _draw_pinned_symbol(center: Vector2, alpha: float) -> void:
	# Skull icon
	var color = Color(0.8, 0.2, 0.2, alpha)
	_draw_pixel_circle(center, 12, color)
	# Eyes
	var eye_color = Color(0.1, 0.05, 0.05, alpha)
	draw_rect(Rect2((center + Vector2(-5, -3)) / pixel_size * pixel_size, Vector2(pixel_size, pixel_size)), eye_color)
	draw_rect(Rect2((center + Vector2(4, -3)) / pixel_size * pixel_size, Vector2(pixel_size, pixel_size)), eye_color)

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
