extends Node2D

# Combo Finisher - T2 Combo with powerful finishing blow

var pixel_size := 4
var duration := 0.6
var elapsed := 0.0

# Build-up hits (fast, small)
var buildup_hits := []
var num_buildup := 3

# Final big hit
var final_hit_alpha := 0.0
var final_hit_size := 0.0
var max_final_size := 50.0

# Explosion particles
var explosion_particles := []
var num_particles := 20

# Shockwave
var shockwave_radius := 0.0
var max_shockwave := 70.0

func _ready() -> void:
	# Initialize buildup hits
	for i in range(num_buildup):
		buildup_hits.append({
			"pos": Vector2(randf_range(-15, 15), randf_range(-10, 10)),
			"alpha": 0.0,
			"trigger_time": i * 0.06,
			"size": 12
		})

	# Initialize explosion particles
	for i in range(num_particles):
		var angle = randf() * TAU
		explosion_particles.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(100, 200),
			"alpha": 0.0,
			"size": randi_range(1, 3) * pixel_size
		})

	# Screen shake on finisher
	await get_tree().create_timer(0.25).timeout
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(12, 0.3)

	await get_tree().create_timer(duration - 0.25 + 0.15).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Update buildup hits
	for hit in buildup_hits:
		if elapsed > hit.trigger_time:
			var age = elapsed - hit.trigger_time
			if age < 0.05:
				hit.alpha = age / 0.05
			else:
				hit.alpha = max(0, 1.0 - (age - 0.05) / 0.1)

	# Final hit triggers after buildup
	if elapsed > 0.25:
		var final_progress = (elapsed - 0.25) / 0.35
		if final_progress < 0.3:
			final_hit_alpha = final_progress / 0.3
			final_hit_size = final_progress / 0.3 * max_final_size
		else:
			final_hit_alpha = max(0, 1.0 - (final_progress - 0.3) / 0.7)
			final_hit_size = max_final_size

		# Shockwave
		shockwave_radius = (elapsed - 0.25) / 0.3 * max_shockwave

		# Trigger particles
		for p in explosion_particles:
			if p.alpha == 0:
				p.alpha = 1.0

	# Update particles
	for p in explosion_particles:
		if p.alpha > 0:
			p.pos += p.velocity * delta
			p.velocity *= 0.95
			p.alpha = max(0, p.alpha - delta * 2)

	queue_redraw()

func _draw() -> void:
	# Draw buildup hits (quick small impacts)
	for hit in buildup_hits:
		if hit.alpha > 0:
			var color = Color(1.0, 0.9, 0.5, hit.alpha)
			_draw_hit_star(hit.pos, hit.size, color)

	# Draw shockwave
	if shockwave_radius > 5:
		var wave_alpha = max(0, 1.0 - shockwave_radius / max_shockwave) * 0.5
		var wave_color = Color(1.0, 0.7, 0.3, wave_alpha)
		_draw_pixel_ring(Vector2.ZERO, shockwave_radius, wave_color, 6)

	# Draw final hit (big explosion burst)
	if final_hit_alpha > 0:
		# Outer glow (orange)
		var outer_color = Color(1.0, 0.5, 0.1, final_hit_alpha * 0.6)
		_draw_pixel_circle(Vector2.ZERO, final_hit_size, outer_color)
		# Core (yellow)
		var core_color = Color(1.0, 0.9, 0.4, final_hit_alpha * 0.8)
		_draw_pixel_circle(Vector2.ZERO, final_hit_size * 0.6, core_color)
		# Center (white)
		var center_color = Color(1.0, 1.0, 1.0, final_hit_alpha)
		_draw_pixel_circle(Vector2.ZERO, final_hit_size * 0.25, center_color)
		# Rays
		_draw_explosion_rays(Vector2.ZERO, final_hit_size * 1.2, Color(1.0, 0.85, 0.4, final_hit_alpha * 0.7))

	# Draw particles
	for p in explosion_particles:
		if p.alpha > 0:
			var color = Color(1.0, 0.7, 0.2, p.alpha)
			var pos = (p.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(p.size, p.size)), color)

func _draw_hit_star(center: Vector2, size: float, color: Color) -> void:
	var dirs = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
	for dir in dirs:
		_draw_pixel_line(center, center + dir * size, color)

func _draw_explosion_rays(center: Vector2, length: float, color: Color) -> void:
	for i in range(8):
		var angle = i * TAU / 8
		var end = center + Vector2(cos(angle), sin(angle)) * length
		_draw_pixel_line(center, end, color)

func _draw_pixel_line(from: Vector2, to: Vector2, color: Color) -> void:
	var dist = from.distance_to(to)
	var steps = int(dist / pixel_size) + 1
	for i in range(steps):
		var t = float(i) / max(steps - 1, 1)
		var pos = from.lerp(to, t)
		pos = (pos / pixel_size).floor() * pixel_size
		var fade = 1.0 - t * 0.3
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), Color(color.r, color.g, color.b, color.a * fade))

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 3)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = center + pos
				draw_pos = (draw_pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)

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
