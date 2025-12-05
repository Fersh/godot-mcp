extends Node2D

# Omnislash - T3 Dash ultimate with multiple rapid slashes

var pixel_size := 4
var duration := 0.85
var elapsed := 0.0

# Multiple slash positions
var slashes := []
var num_slashes := 12

# Teleport afterimages
var afterimages := []
var num_images := 6

# Final explosion
var final_explosion_alpha := 0.0
var explosion_radius := 0.0
var max_explosion := 80.0

# Speed particles
var speed_particles := []
var num_particles := 30

func _ready() -> void:
	# Initialize slashes (random positions around target)
	for i in range(num_slashes):
		var angle = randf() * TAU
		var dist = randf_range(20, 50)
		slashes.append({
			"pos": Vector2(cos(angle), sin(angle)) * dist,
			"angle": randf() * TAU,
			"length": randf_range(30, 50),
			"alpha": 0.0,
			"trigger_time": i * 0.05
		})

	# Initialize afterimages
	for i in range(num_images):
		var angle = randf() * TAU
		afterimages.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(30, 60),
			"alpha": 0.0,
			"trigger_time": i * 0.1
		})

	# Initialize speed particles
	for i in range(num_particles):
		speed_particles.append({
			"pos": Vector2(randf_range(-60, 60), randf_range(-40, 40)),
			"velocity": Vector2(randf_range(-150, 150), randf_range(-150, 150)),
			"alpha": 0.7
		})

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Update slashes
	for slash in slashes:
		if elapsed > slash.trigger_time:
			var age = elapsed - slash.trigger_time
			if age < 0.05:
				slash.alpha = age / 0.05
			else:
				slash.alpha = max(0, 1.0 - (age - 0.05) / 0.15)

	# Update afterimages
	for img in afterimages:
		if elapsed > img.trigger_time:
			var age = elapsed - img.trigger_time
			if age < 0.1:
				img.alpha = age / 0.1 * 0.6
			else:
				img.alpha = max(0, 0.6 - (age - 0.1) / 0.3)

	# Final explosion
	if progress > 0.7:
		var explosion_progress = (progress - 0.7) / 0.3
		explosion_radius = explosion_progress * max_explosion
		final_explosion_alpha = max(0, 1.0 - explosion_progress)

	# Update speed particles
	for p in speed_particles:
		p.pos += p.velocity * delta
		p.velocity *= 0.95
		p.alpha = max(0, 0.7 - progress)

	queue_redraw()

func _draw() -> void:
	# Draw speed particles
	for p in speed_particles:
		if p.alpha > 0:
			var color = Color(0.8, 0.85, 1.0, p.alpha * 0.5)
			var pos = (p.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Draw afterimages
	for img in afterimages:
		if img.alpha > 0:
			var color = Color(0.5, 0.55, 0.8, img.alpha)
			_draw_simple_silhouette(img.pos, color)

	# Draw slashes
	for slash in slashes:
		if slash.alpha > 0:
			var color = Color(1.0, 0.95, 0.9, slash.alpha)
			var half = slash.length / 2
			var dir = Vector2(cos(slash.angle), sin(slash.angle))
			var start = slash.pos - dir * half
			var end = slash.pos + dir * half
			_draw_slash_effect(start, end, color)

	# Draw final explosion
	if final_explosion_alpha > 0:
		var outer_color = Color(1.0, 0.9, 0.7, final_explosion_alpha * 0.5)
		_draw_pixel_circle(Vector2.ZERO, explosion_radius, outer_color)
		var inner_color = Color(1.0, 1.0, 0.9, final_explosion_alpha)
		_draw_pixel_circle(Vector2.ZERO, explosion_radius * 0.4, inner_color)

func _draw_simple_silhouette(pos: Vector2, color: Color) -> void:
	# Basic figure shape
	_draw_pixel_circle(pos + Vector2(0, -10), 8, color)
	for y in range(4):
		var body_pos = pos + Vector2(0, y * pixel_size)
		body_pos = (body_pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(body_pos, Vector2(pixel_size, pixel_size)), Color(color.r, color.g, color.b, color.a * 0.8))

func _draw_slash_effect(from: Vector2, to: Vector2, color: Color) -> void:
	var dist = from.distance_to(to)
	var dir = (to - from).normalized()
	var perp = dir.rotated(PI/2)
	var steps = int(dist / pixel_size) + 1

	for i in range(steps):
		var t = float(i) / max(steps - 1, 1)
		var pos = from.lerp(to, t)
		var width = 2 * (1.0 - abs(t - 0.5) * 1.5)

		for w in range(int(-width), int(width) + 1):
			var draw_pos = pos + perp * w * pixel_size
			draw_pos = (draw_pos / pixel_size).floor() * pixel_size
			var fade = 1.0 - abs(w) / max(width, 1) * 0.5
			draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), Color(color.r, color.g, color.b, color.a * fade))

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 3)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = center + pos
				draw_pos = (draw_pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)
