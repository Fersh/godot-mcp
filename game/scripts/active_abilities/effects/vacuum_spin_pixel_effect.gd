extends Node2D

# Vacuum Spin - T2 Whirlwind with pull-in vortex effect

var pixel_size := 4
var duration := 0.8
var elapsed := 0.0

# Rotating vortex arcs
var vortex_arcs := []
var num_arcs := 5
var rotation_speed := 12.0

# Pull-in particles
var pull_particles := []
var num_pull := 16

# Center vortex
var center_radius := 0.0
var max_center_radius := 25.0

# Debris being pulled in
var debris := []
var num_debris := 10

func _ready() -> void:
	# Initialize vortex arcs
	for i in range(num_arcs):
		vortex_arcs.append({
			"base_angle": (i * TAU / num_arcs),
			"radius": randf_range(50, 80),
			"arc_length": randf_range(0.8, 1.2),
			"alpha": 0.8
		})

	# Initialize pull particles (start far, move inward)
	for i in range(num_pull):
		var angle = randf() * TAU
		var dist = randf_range(80, 120)
		pull_particles.append({
			"angle": angle,
			"distance": dist,
			"start_distance": dist,
			"alpha": 0.7,
			"speed": randf_range(80, 150)
		})

	# Initialize debris
	for i in range(num_debris):
		var angle = randf() * TAU
		debris.append({
			"angle": angle,
			"distance": randf_range(60, 100),
			"size": Vector2(randi_range(1, 3) * pixel_size, randi_range(1, 2) * pixel_size),
			"alpha": 0.8,
			"pull_speed": randf_range(60, 100)
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Center vortex grows
	center_radius = ease(min(progress * 2, 1.0), 0.3) * max_center_radius

	# Update vortex arcs (rotate)
	for arc in vortex_arcs:
		arc.base_angle += rotation_speed * delta
		arc.alpha = 0.8 * (1.0 - progress * 0.5)

	# Update pull particles (spiral inward)
	for p in pull_particles:
		p.distance -= p.speed * delta
		p.angle += delta * 3.0  # Spiral
		if p.distance < 10:
			# Reset to outer edge
			p.distance = p.start_distance
			p.angle = randf() * TAU
		p.alpha = 0.7 * (1.0 - progress)

	# Update debris (pull toward center)
	for d in debris:
		d.distance -= d.pull_speed * delta
		d.angle += delta * 2.0
		d.distance = max(d.distance, 5)
		d.alpha = max(0, 0.8 - progress)

	queue_redraw()

func _draw() -> void:
	# Draw pull particles (showing pull direction)
	for p in pull_particles:
		if p.alpha > 0 and p.distance > 15:
			var pos = Vector2(cos(p.angle), sin(p.angle)) * p.distance
			var color = Color(0.6, 0.7, 0.9, p.alpha * 0.6)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)
			# Trail pointing inward
			var trail_pos = Vector2(cos(p.angle), sin(p.angle)) * (p.distance + 8)
			trail_pos = (trail_pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(trail_pos, Vector2(pixel_size, pixel_size)), Color(0.5, 0.6, 0.8, p.alpha * 0.3))

	# Draw vortex arcs
	for arc in vortex_arcs:
		if arc.alpha > 0:
			var color = Color(0.7, 0.8, 1.0, arc.alpha)
			_draw_pixel_arc(Vector2.ZERO, arc.radius, arc.base_angle, arc.arc_length, color)
			# Inner arc
			var inner_color = Color(0.5, 0.6, 0.9, arc.alpha * 0.6)
			_draw_pixel_arc(Vector2.ZERO, arc.radius * 0.7, arc.base_angle + 0.2, arc.arc_length * 0.8, inner_color)

	# Draw center vortex
	if center_radius > 0:
		# Dark center
		var center_color = Color(0.2, 0.25, 0.4, 0.8)
		_draw_pixel_circle(Vector2.ZERO, center_radius, center_color)
		# Bright edge
		var edge_color = Color(0.6, 0.7, 1.0, 0.6)
		_draw_pixel_ring(Vector2.ZERO, center_radius, edge_color, 4)

	# Draw debris
	for d in debris:
		if d.alpha > 0:
			var pos = Vector2(cos(d.angle), sin(d.angle)) * d.distance
			var color = Color(0.5, 0.45, 0.4, d.alpha)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos - d.size/2, d.size), color)

func _draw_pixel_arc(center: Vector2, radius: float, start_angle: float, arc_length: float, color: Color) -> void:
	var steps = int(arc_length * radius / pixel_size) + 8
	for i in range(steps):
		var t = float(i) / steps
		var angle = start_angle + t * arc_length
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		pos = (pos / pixel_size).floor() * pixel_size
		var fade = 1.0 - abs(t - 0.5) * 0.4
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), Color(color.r, color.g, color.b, color.a * fade))

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 4)
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
