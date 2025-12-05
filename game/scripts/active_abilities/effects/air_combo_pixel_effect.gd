extends Node2D

# Air Combo - T3 Uppercut with aerial juggle combo

var pixel_size := 4
var duration := 0.8
var elapsed := 0.0

# Launch effect
var launch_height := 0.0
var max_launch := 100.0

# Air hits
var air_hits := []
var num_hits := 6

# Combo sparks
var sparks := []
var num_sparks := 24

# Wind trails
var wind_trails := []

func _ready() -> void:
	# Initialize air hits (spread vertically)
	for i in range(num_hits):
		var y_pos = -25 - i * 15
		var x_offset = sin(i * 1.2) * 15
		air_hits.append({
			"pos": Vector2(x_offset, y_pos),
			"alpha": 0.0,
			"trigger_time": 0.1 + i * 0.08,
			"size": 22 - i * 2
		})

	# Initialize sparks
	for i in range(num_sparks):
		var angle = randf_range(-PI, 0)
		sparks.append({
			"pos": Vector2(0, randf_range(-30, -80)),
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(80, 160),
			"alpha": 0.0,
			"trigger_time": randf() * 0.4
		})

	# Initialize wind trails
	for i in range(4):
		wind_trails.append({
			"x_offset": randf_range(-15, 15),
			"alpha": 0.6
		})

	await get_tree().create_timer(duration + 0.15).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Launch rises
	launch_height = ease(min(progress * 2, 1.0), 0.4) * max_launch

	# Update air hits
	for hit in air_hits:
		if elapsed > hit.trigger_time:
			var age = elapsed - hit.trigger_time
			if age < 0.08:
				hit.alpha = age / 0.08
			else:
				hit.alpha = max(0, 1.0 - (age - 0.08) / 0.2)

	# Update sparks
	for spark in sparks:
		if elapsed > spark.trigger_time:
			if spark.alpha == 0:
				spark.alpha = 1.0
			spark.pos += spark.velocity * delta
			spark.velocity *= 0.92
			spark.alpha = max(0, spark.alpha - delta * 2)

	# Update wind trails
	for trail in wind_trails:
		trail.alpha = max(0, 0.6 - progress * 0.8)

	queue_redraw()

func _draw() -> void:
	# Draw wind trails (motion blur going up)
	for trail in wind_trails:
		if trail.alpha > 0:
			var color = Color(0.9, 0.92, 1.0, trail.alpha * 0.4)
			_draw_pixel_line(
				Vector2(trail.x_offset, 10),
				Vector2(trail.x_offset, -launch_height),
				color
			)

	# Draw launch streak
	if launch_height > 10:
		var streak_color = Color(1.0, 0.95, 0.8, 0.7 * (1.0 - elapsed/duration))
		for i in range(3):
			var x = (i - 1) * pixel_size * 2
			_draw_pixel_line(Vector2(x, 0), Vector2(x, -launch_height * 0.8), streak_color)

	# Draw air hits
	for hit in air_hits:
		if hit.alpha > 0:
			var color = Color(1.0, 0.9, 0.5, hit.alpha)
			_draw_combo_hit(hit.pos, hit.size, color)

	# Draw sparks
	for spark in sparks:
		if spark.alpha > 0:
			var color = Color(1.0, 0.85, 0.4, spark.alpha)
			var pos = (spark.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Draw combo counter effect at top
	if elapsed > 0.3:
		var counter_alpha = min((elapsed - 0.3) / 0.2, 1.0) * max(0, 1.0 - (elapsed - 0.5) / 0.3)
		if counter_alpha > 0:
			var counter_color = Color(1.0, 0.9, 0.3, counter_alpha)
			_draw_combo_counter(Vector2(0, -launch_height - 15), counter_color)

func _draw_combo_hit(center: Vector2, size: float, color: Color) -> void:
	# Star burst
	for i in range(8):
		var angle = i * TAU / 8
		var length = size if i % 2 == 0 else size * 0.6
		var end = center + Vector2(cos(angle), sin(angle)) * length
		_draw_pixel_line(center, end, color)
	# Center
	_draw_pixel_circle(center, size * 0.2, color)

func _draw_combo_counter(center: Vector2, color: Color) -> void:
	# Simple "MAX" or hit indicator
	var size = 8
	# Draw an X pattern
	_draw_pixel_line(center + Vector2(-size, -size), center + Vector2(size, size), color)
	_draw_pixel_line(center + Vector2(size, -size), center + Vector2(-size, size), color)
	# Circle around
	_draw_pixel_ring(center, size + 4, color, pixel_size)

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
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
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
