extends Node2D

# Ricochet Blade - T2 Throw that bounces between targets

var pixel_size := 4
var duration := 0.7
var elapsed := 0.0

# Blade bouncing path
var bounce_points := []
var current_segment := 0
var segment_progress := 0.0

# Trail particles
var trail_particles := []

# Impact sparks at each bounce
var bounce_sparks := []

# Blade rotation
var blade_rotation := 0.0

func _ready() -> void:
	# Define bounce path (3 targets)
	bounce_points = [
		Vector2(-30, 0),
		Vector2(40, -20),
		Vector2(-20, 30),
		Vector2(50, 10)
	]

	# Initialize bounce sparks for each point
	for i in range(bounce_points.size() - 1):
		var sparks_at_point = []
		for j in range(6):
			var angle = randf() * TAU
			sparks_at_point.append({
				"pos": bounce_points[i + 1],
				"velocity": Vector2(cos(angle), sin(angle)) * randf_range(80, 140),
				"alpha": 0.0
			})
		bounce_sparks.append(sparks_at_point)

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Calculate which segment we're on
	var total_segments = bounce_points.size() - 1
	var segment_duration = 1.0 / total_segments
	current_segment = int(progress / segment_duration)
	current_segment = min(current_segment, total_segments - 1)
	segment_progress = fmod(progress, segment_duration) / segment_duration

	# Trigger sparks at bounce points
	if current_segment > 0:
		for spark in bounce_sparks[current_segment - 1]:
			if spark.alpha == 0:
				spark.alpha = 1.0

	# Update all sparks
	for sparks_group in bounce_sparks:
		for spark in sparks_group:
			if spark.alpha > 0:
				spark.pos += spark.velocity * delta
				spark.velocity *= 0.9
				spark.alpha = max(0, spark.alpha - delta * 3)

	# Blade spins
	blade_rotation += delta * 20

	# Add trail particles
	if progress < 0.9:
		var blade_pos = _get_blade_position()
		trail_particles.append({
			"pos": blade_pos,
			"alpha": 0.6,
			"size": pixel_size * 2
		})

	# Update trail
	for i in range(trail_particles.size() - 1, -1, -1):
		trail_particles[i].alpha -= delta * 3
		if trail_particles[i].alpha <= 0:
			trail_particles.remove_at(i)

	queue_redraw()

func _get_blade_position() -> Vector2:
	if current_segment >= bounce_points.size() - 1:
		return bounce_points[-1]
	var start = bounce_points[current_segment]
	var end = bounce_points[current_segment + 1]
	return start.lerp(end, ease(segment_progress, 0.5))

func _draw() -> void:
	# Draw trail
	for particle in trail_particles:
		if particle.alpha > 0:
			var color = Color(0.7, 0.75, 0.85, particle.alpha * 0.5)
			var pos = (particle.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(particle.size, particle.size)), color)

	# Draw bounce point indicators
	for i in range(1, bounce_points.size()):
		var point = bounce_points[i]
		var indicator_alpha = 0.3 if current_segment < i else 0.1
		var color = Color(1.0, 0.8, 0.3, indicator_alpha)
		_draw_pixel_circle(point, 8, color)

	# Draw path lines (faded)
	for i in range(bounce_points.size() - 1):
		var alpha = 0.2 if current_segment > i else 0.1
		var color = Color(0.6, 0.65, 0.7, alpha)
		_draw_pixel_line(bounce_points[i], bounce_points[i + 1], color)

	# Draw bounce sparks
	for sparks_group in bounce_sparks:
		for spark in sparks_group:
			if spark.alpha > 0:
				var color = Color(1.0, 0.85, 0.4, spark.alpha)
				var pos = (spark.pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Draw blade
	var blade_pos = _get_blade_position()
	_draw_spinning_blade(blade_pos, blade_rotation)

func _draw_spinning_blade(center: Vector2, rotation: float) -> void:
	var blade_length = 16
	var blade_color = Color(0.8, 0.82, 0.9, 1.0)
	var edge_color = Color(1.0, 1.0, 1.0, 0.8)

	# 4 blade points (spinning star)
	for i in range(4):
		var angle = rotation + i * PI / 2
		var end = center + Vector2(cos(angle), sin(angle)) * blade_length
		_draw_pixel_line(center, end, blade_color)
		# Tip highlight
		var tip_pos = (end / pixel_size).floor() * pixel_size
		draw_rect(Rect2(tip_pos, Vector2(pixel_size, pixel_size)), edge_color)

	# Center
	var center_pos = (center / pixel_size).floor() * pixel_size
	draw_rect(Rect2(center_pos, Vector2(pixel_size, pixel_size)), blade_color)

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
