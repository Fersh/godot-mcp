extends Node2D

# Riposte - T3 Block counter-attack after perfect block

var pixel_size := 4
var duration := 0.75
var elapsed := 0.0

# Block phase
var block_alpha := 0.0
var block_impact := 0.0

# Counter strike
var counter_alpha := 0.0
var counter_progress := 0.0
var counter_length := 70.0

# Impact sparks
var sparks := []
var num_sparks := 30

# Energy transfer
var energy_trail := []
var num_trail := 15

func _ready() -> void:
	# Initialize sparks
	for i in range(num_sparks):
		var angle = randf_range(-PI/4, PI/4)
		sparks.append({
			"pos": Vector2(-20, 0),
			"velocity": Vector2(cos(angle + PI), sin(angle)) * randf_range(100, 200),
			"alpha": 0.0,
			"trigger_time": 0.1
		})

	# Initialize energy trail
	for i in range(num_trail):
		energy_trail.append({
			"pos": Vector2(-15 + i * 5, randf_range(-5, 5)),
			"alpha": 0.0,
			"delay": 0.3 + i * 0.02
		})

	await get_tree().create_timer(duration + 0.15).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Block phase (0-0.3)
	if progress < 0.3:
		block_alpha = 1.0
		if progress > 0.1 and progress < 0.2:
			block_impact = 1.0 - (progress - 0.1) / 0.1
			# Trigger sparks
			for spark in sparks:
				if spark.alpha == 0 and elapsed > spark.trigger_time:
					spark.alpha = 1.0
		else:
			block_impact = 0
	else:
		block_alpha = max(0, block_alpha - delta * 5)

	# Counter phase (0.3+)
	if progress > 0.3:
		counter_alpha = min((progress - 0.3) / 0.1, 1.0) * (1.0 - max(0, progress - 0.7) / 0.3)
		counter_progress = ease(min((progress - 0.3) / 0.25, 1.0), 0.2)

	# Update sparks
	for spark in sparks:
		if spark.alpha > 0:
			spark.velocity *= 0.92
			spark.pos += spark.velocity * delta
			spark.alpha = max(0, spark.alpha - delta * 3)

	# Update energy trail
	for trail in energy_trail:
		if elapsed > trail.delay:
			trail.alpha = min((elapsed - trail.delay) / 0.05, 1.0) * (1.0 - progress * 0.5)

	queue_redraw()

func _draw() -> void:
	# Draw block shield
	if block_alpha > 0:
		var shield_color = Color(0.6, 0.65, 0.8, block_alpha * 0.7)
		_draw_shield(Vector2(-15, 0), shield_color)

		# Impact flash
		if block_impact > 0:
			var flash_color = Color(1.0, 0.95, 0.8, block_impact)
			_draw_pixel_circle(Vector2(-15, 0), 25, flash_color)

	# Draw sparks
	for spark in sparks:
		if spark.alpha > 0:
			var color = Color(1.0, 0.9, 0.6, spark.alpha)
			var pos = (spark.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Draw energy trail
	for trail in energy_trail:
		if trail.alpha > 0:
			var color = Color(0.9, 0.8, 0.5, trail.alpha * 0.6)
			var pos = (trail.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Draw counter strike
	if counter_alpha > 0:
		var strike_end = counter_progress * counter_length
		# Trail
		var trail_color = Color(0.9, 0.7, 0.4, counter_alpha * 0.7)
		for y_off in range(-2, 3):
			_draw_pixel_line(
				Vector2(0, y_off * pixel_size),
				Vector2(strike_end, y_off * pixel_size),
				trail_color
			)
		# Blade
		var blade_color = Color(1.0, 0.95, 0.85, counter_alpha)
		for y_off in range(-1, 2):
			var pos = Vector2(strike_end, y_off * pixel_size)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size * 2, pixel_size)), blade_color)

func _draw_shield(center: Vector2, color: Color) -> void:
	# Simple shield shape
	for y in range(-4, 5):
		var width = 3 - abs(y) * 0.5
		if width > 0:
			for x in range(-int(width), int(width) + 1):
				var pos = center + Vector2(x, y) * pixel_size
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
