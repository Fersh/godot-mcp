extends Node2D

# Singularity - T3 Whirlwind black hole pull effect

var pixel_size := 4
var duration := 1.0
var elapsed := 0.0

# Black hole center
var singularity_radius := 0.0
var max_singularity := 30.0

# Event horizon ring
var horizon_radius := 0.0
var max_horizon := 70.0

# Pulled debris spiraling in
var pulled_debris := []
var num_debris := 30

# Distortion rings
var distortion_rings := []
var num_rings := 4

# Energy being consumed
var energy_wisps := []
var num_wisps := 16

func _ready() -> void:
	# Initialize debris (start far, spiral in)
	for i in range(num_debris):
		var angle = randf() * TAU
		var dist = randf_range(80, 140)
		pulled_debris.append({
			"angle": angle,
			"distance": dist,
			"start_distance": dist,
			"size": Vector2(randi_range(1, 3) * pixel_size, randi_range(1, 3) * pixel_size),
			"alpha": 0.8,
			"pull_speed": randf_range(60, 120),
			"orbit_speed": randf_range(3, 7)
		})

	# Initialize distortion rings
	for i in range(num_rings):
		distortion_rings.append({
			"radius": 90 - i * 15,
			"rotation": randf() * TAU,
			"speed": 2 + i * 0.5
		})

	# Initialize energy wisps
	for i in range(num_wisps):
		var angle = randf() * TAU
		energy_wisps.append({
			"angle": angle,
			"distance": randf_range(50, 90),
			"alpha": 0.7,
			"speed": randf_range(80, 150)
		})

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Singularity grows
	singularity_radius = ease(min(progress * 2, 1.0), 0.3) * max_singularity

	# Horizon expands then contracts
	if progress < 0.5:
		horizon_radius = progress * 2 * max_horizon
	else:
		horizon_radius = max_horizon * (1.0 - (progress - 0.5) * 0.5)

	# Update debris (spiral in and disappear)
	for debris in pulled_debris:
		debris.angle += debris.orbit_speed * delta
		debris.distance -= debris.pull_speed * delta
		if debris.distance < 15:
			debris.alpha = max(0, debris.alpha - delta * 5)
		else:
			debris.alpha = 0.8 * (1.0 - progress * 0.3)

	# Update distortion rings
	for ring in distortion_rings:
		ring.rotation += ring.speed * delta

	# Update energy wisps (pulled in)
	for wisp in energy_wisps:
		wisp.angle += delta * 4
		wisp.distance -= wisp.speed * delta
		if wisp.distance < 20:
			wisp.distance = randf_range(70, 100)
			wisp.angle = randf() * TAU
		wisp.alpha = 0.7 * (1.0 - progress * 0.5)

	queue_redraw()

func _draw() -> void:
	# Draw distortion rings
	for ring in distortion_rings:
		var distort_alpha = 0.3 * (1.0 - elapsed / duration)
		var color = Color(0.3, 0.2, 0.5, distort_alpha)
		_draw_distorted_ring(Vector2.ZERO, ring.radius, ring.rotation, color)

	# Draw energy wisps being pulled
	for wisp in energy_wisps:
		if wisp.alpha > 0:
			var pos = Vector2(cos(wisp.angle), sin(wisp.angle)) * wisp.distance
			var color = Color(0.6, 0.4, 0.9, wisp.alpha)
			_draw_pixel_circle(pos, 4, color)
			# Trail toward center
			var trail_pos = pos * 0.8
			_draw_pixel_line(trail_pos, pos, Color(0.5, 0.3, 0.8, wisp.alpha * 0.5))

	# Draw debris spiraling in
	for debris in pulled_debris:
		if debris.alpha > 0 and debris.distance > 10:
			var pos = Vector2(cos(debris.angle), sin(debris.angle)) * debris.distance
			var color = Color(0.5, 0.4, 0.45, debris.alpha)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos - debris.size/2, debris.size), color)

	# Draw event horizon
	if horizon_radius > 20:
		var horizon_color = Color(0.2, 0.1, 0.3, 0.6)
		_draw_pixel_ring(Vector2.ZERO, horizon_radius, horizon_color, 8)
		# Inner glow
		var glow_color = Color(0.5, 0.3, 0.7, 0.4)
		_draw_pixel_ring(Vector2.ZERO, horizon_radius * 0.7, glow_color, 6)

	# Draw singularity (black center with purple edge)
	if singularity_radius > 5:
		var black_color = Color(0.05, 0.02, 0.08, 0.95)
		_draw_pixel_circle(Vector2.ZERO, singularity_radius, black_color)
		var edge_color = Color(0.4, 0.2, 0.6, 0.8)
		_draw_pixel_ring(Vector2.ZERO, singularity_radius, edge_color, 4)

func _draw_distorted_ring(center: Vector2, radius: float, rotation: float, color: Color) -> void:
	var steps = 24
	for i in range(steps):
		var angle = rotation + (float(i) / steps) * TAU
		var wobble = sin(angle * 3 + elapsed * 5) * 8
		var pos = center + Vector2(cos(angle), sin(angle)) * (radius + wobble)
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

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 3)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = center + pos
				draw_pos = (draw_pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)
