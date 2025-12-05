extends Node2D

# Juggle - T2 Uppercut that launches enemy for follow-up hits

var pixel_size := 4
var duration := 0.6
var elapsed := 0.0

# Upward launch streak
var launch_streak_height := 0.0
var max_launch_height := 80.0

# Multiple hit markers (juggle hits)
var hit_markers := []
var num_hits := 3

# Launch particles
var launch_particles := []
var num_particles := 12

# Impact sparks
var sparks := []
var num_sparks := 8

func _ready() -> void:
	# Initialize hit markers (staggered upward)
	for i in range(num_hits):
		hit_markers.append({
			"y_pos": -20 - i * 25,
			"alpha": 0.0,
			"trigger_time": 0.1 + i * 0.12,
			"size": 20 - i * 3
		})

	# Initialize launch particles
	for i in range(num_particles):
		var angle = randf_range(-PI/4, -3*PI/4)
		launch_particles.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(100, 180),
			"alpha": 1.0,
			"size": pixel_size
		})

	# Initialize sparks
	for i in range(num_sparks):
		var angle = randf_range(-PI/3, -2*PI/3)
		sparks.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(150, 250),
			"alpha": 1.0
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Launch streak rises
	launch_streak_height = ease(min(progress * 2.5, 1.0), 0.3) * max_launch_height

	# Update hit markers
	for marker in hit_markers:
		if elapsed > marker.trigger_time:
			var marker_progress = (elapsed - marker.trigger_time) / 0.2
			if marker_progress < 1.0:
				marker.alpha = 1.0 - marker_progress * 0.5
			else:
				marker.alpha = max(0, marker.alpha - delta * 3)

	# Update launch particles
	for p in launch_particles:
		p.velocity.y += delta * 100  # Slight gravity
		p.pos += p.velocity * delta
		p.alpha = max(0, 1.0 - progress * 1.3)

	# Update sparks
	for spark in sparks:
		spark.velocity *= 0.92
		spark.pos += spark.velocity * delta
		spark.alpha = max(0, 1.0 - progress * 1.5)

	queue_redraw()

func _draw() -> void:
	# Draw launch streak (upward motion blur)
	if launch_streak_height > 0:
		var streak_color = Color(1.0, 0.95, 0.8, 0.6)
		for i in range(3):
			var x_offset = (i - 1) * pixel_size * 2
			_draw_pixel_line(
				Vector2(x_offset, 0),
				Vector2(x_offset, -launch_streak_height),
				streak_color
			)
		# Bright core
		var core_color = Color(1.0, 1.0, 1.0, 0.8)
		_draw_pixel_line(Vector2.ZERO, Vector2(0, -launch_streak_height * 0.7), core_color)

	# Draw hit markers (impact bursts)
	for marker in hit_markers:
		if marker.alpha > 0:
			var pos = Vector2(0, marker.y_pos)
			# Star burst pattern
			var color = Color(1.0, 0.9, 0.5, marker.alpha)
			_draw_hit_burst(pos, marker.size, color)

	# Draw launch particles
	for p in launch_particles:
		if p.alpha > 0:
			var color = Color(1.0, 0.95, 0.7, p.alpha)
			var pos = (p.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Draw sparks
	for spark in sparks:
		if spark.alpha > 0:
			var color = Color(1.0, 0.8, 0.3, spark.alpha)
			var pos = (spark.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_hit_burst(center: Vector2, size: float, color: Color) -> void:
	# 4-point star burst
	var directions = [
		Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),
		Vector2(0.7, 0.7), Vector2(-0.7, 0.7), Vector2(0.7, -0.7), Vector2(-0.7, -0.7)
	]
	for dir in directions:
		var length = size if directions.find(dir) < 4 else size * 0.6
		var end_pos = center + dir * length
		_draw_pixel_line(center, end_pos, color)
	# Center
	_draw_pixel_circle(center, size * 0.3, color)

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
