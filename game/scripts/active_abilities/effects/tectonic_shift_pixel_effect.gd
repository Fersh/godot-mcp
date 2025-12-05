extends Node2D

# Tectonic Shift - T3 Stomp ultimate with massive earth manipulation

var pixel_size := 4
var duration := 0.9
var elapsed := 0.0

# Multiple massive shockwaves
var shockwaves := []
var num_waves := 4

# Rising earth pillars
var pillars := []
var num_pillars := 8

# Deep cracks spreading
var cracks := []
var num_cracks := 12

# Massive debris
var debris := []
var num_debris := 24

# Ground upheaval effect
var upheaval_radius := 0.0
var max_upheaval := 120.0

func _ready() -> void:
	# Initialize shockwaves
	for i in range(num_waves):
		shockwaves.append({
			"radius": 0.0,
			"alpha": 1.0,
			"delay": i * 0.1,
			"max_radius": 100 + i * 20
		})

	# Initialize pillars (rising from ground)
	for i in range(num_pillars):
		var angle = (i * TAU / num_pillars) + randf() * 0.2
		var dist = randf_range(40, 80)
		pillars.append({
			"pos": Vector2(cos(angle), sin(angle)) * dist,
			"height": 0.0,
			"max_height": randf_range(30, 60),
			"width": randf_range(12, 20),
			"delay": randf() * 0.2,
			"alpha": 1.0
		})

	# Initialize cracks
	for i in range(num_cracks):
		var angle = (i * TAU / num_cracks) + randf() * 0.3
		cracks.append({
			"angle": angle,
			"length": 0.0,
			"max_length": randf_range(60, 110),
			"width": randf_range(4, 8)
		})

	# Initialize debris
	for i in range(num_debris):
		var angle = randf() * TAU
		debris.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(150, 280),
			"size": Vector2(randi_range(2, 5) * pixel_size, randi_range(2, 5) * pixel_size),
			"alpha": 1.0,
			"gravity": randf_range(350, 550),
			"rotation": randf() * TAU
		})

	# Major screen shake
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(20, 0.6)

	await get_tree().create_timer(duration + 0.3).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Upheaval grows
	upheaval_radius = ease(min(progress * 1.5, 1.0), 0.3) * max_upheaval

	# Update shockwaves
	for wave in shockwaves:
		if elapsed > wave.delay:
			var wave_progress = (elapsed - wave.delay) / 0.5
			wave.radius = wave_progress * wave.max_radius
			wave.alpha = max(0, 1.0 - wave_progress)

	# Update pillars
	for pillar in pillars:
		if elapsed > pillar.delay:
			var pillar_progress = (elapsed - pillar.delay) / 0.3
			pillar.height = ease(min(pillar_progress, 1.0), 0.2) * pillar.max_height
			pillar.alpha = max(0, 1.0 - max(0, pillar_progress - 0.5) * 2)

	# Update cracks
	for crack in cracks:
		crack.length = min(progress * 2.5, 1.0) * crack.max_length

	# Update debris
	for d in debris:
		d.velocity.y += d.gravity * delta
		d.pos += d.velocity * delta
		d.alpha = max(0, 1.0 - progress * 1.1)
		d.rotation += delta * 4

	queue_redraw()

func _draw() -> void:
	# Draw cracks (deep brown/black)
	for crack in cracks:
		if crack.length > 0:
			var color = Color(0.15, 0.1, 0.08, 0.9)
			var end = Vector2(cos(crack.angle), sin(crack.angle)) * crack.length
			_draw_jagged_crack(Vector2.ZERO, end, color, crack.width)

	# Draw shockwaves
	for wave in shockwaves:
		if wave.alpha > 0 and wave.radius > 5:
			var color = Color(0.6, 0.5, 0.35, wave.alpha * 0.7)
			_draw_pixel_ring(Vector2.ZERO, wave.radius, color, 10)

	# Draw earth pillars
	for pillar in pillars:
		if pillar.height > 0 and pillar.alpha > 0:
			_draw_earth_pillar(pillar.pos, pillar.width, pillar.height, pillar.alpha)

	# Draw debris
	for d in debris:
		if d.alpha > 0:
			var color = Color(0.5, 0.4, 0.3, d.alpha)
			var pos = (d.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos - d.size/2, d.size), color)

	# Draw center impact
	var impact_alpha = max(0, 1.0 - elapsed / 0.3)
	if impact_alpha > 0:
		var flash_color = Color(0.9, 0.8, 0.5, impact_alpha)
		_draw_pixel_circle(Vector2.ZERO, 30, flash_color)

func _draw_earth_pillar(base: Vector2, width: float, height: float, alpha: float) -> void:
	var stone_color = Color(0.45, 0.38, 0.3, alpha)
	var highlight_color = Color(0.6, 0.55, 0.45, alpha * 0.7)

	# Main pillar body
	for y in range(int(height / pixel_size)):
		var y_pos = -y * pixel_size
		var row_width = width * (1.0 - float(y) / (height / pixel_size) * 0.3)
		for x in range(int(-row_width / 2 / pixel_size), int(row_width / 2 / pixel_size) + 1):
			var pos = base + Vector2(x * pixel_size, y_pos)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), stone_color)

	# Top highlight
	var top_pos = base + Vector2(0, -height)
	for x in range(int(-width / 3 / pixel_size), int(width / 3 / pixel_size) + 1):
		var pos = top_pos + Vector2(x * pixel_size, 0)
		pos = (pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), highlight_color)

func _draw_jagged_crack(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var dist = from.distance_to(to)
	var dir = (to - from).normalized()
	var perp = dir.rotated(PI/2)
	var segments = int(dist / 15) + 1
	var current = from

	for i in range(segments):
		var t = float(i + 1) / segments
		var target = from.lerp(to, t)
		var offset = perp * randf_range(-8, 8)
		var next = target + offset

		for w in range(int(width / pixel_size)):
			var w_offset = perp * (w - width / pixel_size / 2) * pixel_size
			_draw_pixel_line(current + w_offset, next + w_offset, color)

		current = next

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
	var steps = max(int(circumference / pixel_size), 20)
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
