extends Node2D

# Counter Strike - T2 Parry with retaliating attack

var pixel_size := 4
var duration := 0.5
var elapsed := 0.0

# Parry flash
var parry_alpha := 0.0

# Counter slash
var counter_progress := 0.0
var counter_angle := PI/4

# Deflection sparks
var deflect_sparks := []
var num_deflect := 8

# Counter attack sparks
var counter_sparks := []
var num_counter := 10

func _ready() -> void:
	# Initialize deflection sparks
	for i in range(num_deflect):
		var angle = randf_range(-PI/2, PI/2)
		deflect_sparks.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(100, 180),
			"alpha": 1.0
		})

	# Initialize counter sparks
	for i in range(num_counter):
		var angle = counter_angle + randf_range(-0.3, 0.3)
		counter_sparks.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(120, 200),
			"alpha": 0.0
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Parry flash (quick)
	if progress < 0.2:
		parry_alpha = 1.0 - progress / 0.2
	else:
		parry_alpha = 0

	# Counter slash (after parry)
	if progress > 0.15:
		counter_progress = ease((progress - 0.15) / 0.25, 0.2)
		if counter_progress > 0.1:
			for spark in counter_sparks:
				if spark.alpha == 0:
					spark.alpha = 1.0

	# Update deflect sparks
	for spark in deflect_sparks:
		spark.pos += spark.velocity * delta
		spark.velocity *= 0.88
		spark.alpha = max(0, spark.alpha - delta * 3)

	# Update counter sparks
	for spark in counter_sparks:
		if spark.alpha > 0:
			spark.pos += spark.velocity * delta
			spark.velocity *= 0.9
			spark.alpha = max(0, spark.alpha - delta * 2.5)

	queue_redraw()

func _draw() -> void:
	# Draw parry flash (defensive)
	if parry_alpha > 0:
		var flash_color = Color(0.6, 0.8, 1.0, parry_alpha * 0.7)
		_draw_pixel_circle(Vector2.ZERO, 30, flash_color)
		# Shield icon
		var shield_color = Color(0.8, 0.9, 1.0, parry_alpha)
		_draw_shield_icon(Vector2(-5, 0), shield_color)

	# Draw deflection sparks (blue tint)
	for spark in deflect_sparks:
		if spark.alpha > 0:
			var color = Color(0.7, 0.85, 1.0, spark.alpha)
			var pos = (spark.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Draw counter slash
	if counter_progress > 0:
		var slash_length = 60 * counter_progress
		var slash_color = Color(1.0, 0.9, 0.7, 1.0 - (elapsed - 0.15) / 0.35 * 0.5)
		var start = Vector2.ZERO
		var end = Vector2(cos(counter_angle), sin(counter_angle)) * slash_length
		# Slash trail
		_draw_slash_trail(start, end, slash_color)

	# Draw counter sparks (golden)
	for spark in counter_sparks:
		if spark.alpha > 0:
			var color = Color(1.0, 0.85, 0.4, spark.alpha)
			var pos = (spark.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_shield_icon(center: Vector2, color: Color) -> void:
	# Simple shield shape
	var size = 18
	for y in range(int(size / pixel_size)):
		var t = float(y) / (size / pixel_size)
		var row_width = (size * 0.6) * (1.0 - t * 0.5)
		for x in range(int(-row_width / pixel_size), int(row_width / pixel_size) + 1):
			var pos = center + Vector2(x * pixel_size, y * pixel_size - size/2)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_slash_trail(from: Vector2, to: Vector2, color: Color) -> void:
	var dist = from.distance_to(to)
	var steps = int(dist / pixel_size) + 1
	var perpendicular = (to - from).normalized().rotated(PI/2)

	for i in range(steps):
		var t = float(i) / max(steps - 1, 1)
		var pos = from.lerp(to, t)
		var width = 3 * (1.0 - t * 0.5)  # Tapers
		var alpha = 1.0 - t * 0.4

		for w in range(int(-width), int(width) + 1):
			var draw_pos = pos + perpendicular * w * pixel_size
			draw_pos = (draw_pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), Color(color.r, color.g, color.b, color.a * alpha))

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 3)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = center + pos
				draw_pos = (draw_pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)
