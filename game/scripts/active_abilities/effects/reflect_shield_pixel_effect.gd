extends Node2D

# Reflect Shield - T2 Block with damage reflection

var pixel_size := 4
var duration := 0.6
var elapsed := 0.0

# Shield barrier
var shield_alpha := 0.0
var shield_size := 0.0
var max_shield_size := 50.0

# Reflection glow
var reflect_pulse := 0.0

# Energy particles orbiting
var orbit_particles := []
var num_orbit := 8

# Impact sparks when reflecting
var reflect_sparks := []
var num_sparks := 12

func _ready() -> void:
	# Initialize orbit particles
	for i in range(num_orbit):
		orbit_particles.append({
			"angle": (i * TAU / num_orbit),
			"radius": 40,
			"alpha": 0.7
		})

	# Initialize reflect sparks
	for i in range(num_sparks):
		var angle = randf() * TAU
		reflect_sparks.append({
			"pos": Vector2(cos(angle), sin(angle)) * 45,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(80, 150),
			"alpha": 0.0,
			"trigger_time": randf() * 0.3
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Shield grows then holds
	shield_size = ease(min(progress * 3, 1.0), 0.3) * max_shield_size
	shield_alpha = (1.0 - progress * 0.5) * 0.8

	# Reflection pulse
	reflect_pulse = sin(elapsed * 10) * 0.3 + 0.7

	# Update orbit particles
	for p in orbit_particles:
		p.angle += delta * 4
		p.alpha = 0.7 * (1.0 - progress * 0.5)

	# Update reflect sparks
	for spark in reflect_sparks:
		if elapsed > spark.trigger_time and spark.alpha == 0:
			spark.alpha = 1.0
		if spark.alpha > 0:
			spark.pos += spark.velocity * delta
			spark.velocity *= 0.9
			spark.alpha = max(0, spark.alpha - delta * 2)

	queue_redraw()

func _draw() -> void:
	# Draw shield base (blue energy barrier)
	if shield_alpha > 0:
		# Outer shield
		var outer_color = Color(0.4, 0.6, 1.0, shield_alpha * 0.6)
		_draw_shield_shape(Vector2.ZERO, shield_size, outer_color)

		# Inner reflection layer (pulsing)
		var reflect_color = Color(0.7, 0.85, 1.0, shield_alpha * reflect_pulse * 0.5)
		_draw_shield_shape(Vector2.ZERO, shield_size * 0.8, reflect_color)

		# Edge highlight
		var edge_color = Color(1.0, 1.0, 1.0, shield_alpha * 0.4)
		_draw_shield_outline(Vector2.ZERO, shield_size, edge_color)

		# Mirror shine effect
		var shine_color = Color(1.0, 1.0, 1.0, shield_alpha * 0.3 * reflect_pulse)
		_draw_mirror_shine(Vector2(-shield_size * 0.2, -shield_size * 0.3), shine_color)

	# Draw orbit particles
	for p in orbit_particles:
		if p.alpha > 0:
			var pos = Vector2(cos(p.angle), sin(p.angle)) * p.radius
			var color = Color(0.6, 0.8, 1.0, p.alpha)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)
			# Trail
			var trail_pos = Vector2(cos(p.angle - 0.3), sin(p.angle - 0.3)) * p.radius
			trail_pos = (trail_pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(trail_pos, Vector2(pixel_size, pixel_size)), Color(0.5, 0.7, 1.0, p.alpha * 0.4))

	# Draw reflect sparks
	for spark in reflect_sparks:
		if spark.alpha > 0:
			var color = Color(0.8, 0.9, 1.0, spark.alpha)
			var pos = (spark.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_shield_shape(center: Vector2, size: float, color: Color) -> void:
	var half_width = size * 0.6
	var height = size

	for y in range(int(-height/2 / pixel_size), int(height/2 / pixel_size) + 1):
		var y_pos = y * pixel_size
		var t = (y_pos + height/2) / height
		var row_width = half_width * (1.0 - t * 0.6)

		for x in range(int(-row_width / pixel_size), int(row_width / pixel_size) + 1):
			var x_pos = x * pixel_size
			var pos = center + Vector2(x_pos, y_pos)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_shield_outline(center: Vector2, size: float, color: Color) -> void:
	var half_width = size * 0.6
	var height = size

	for y in range(int(-height/2 / pixel_size), int(height/2 / pixel_size) + 1):
		var y_pos = y * pixel_size
		var t = (y_pos + height/2) / height
		var row_width = half_width * (1.0 - t * 0.6)

		# Left and right edges only
		var left_pos = center + Vector2(-row_width, y_pos)
		var right_pos = center + Vector2(row_width, y_pos)
		left_pos = (left_pos / pixel_size).floor() * pixel_size
		right_pos = (right_pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(left_pos, Vector2(pixel_size, pixel_size)), color)
		draw_rect(Rect2(right_pos, Vector2(pixel_size, pixel_size)), color)

func _draw_mirror_shine(pos: Vector2, color: Color) -> void:
	# Simple diagonal shine
	for i in range(4):
		var shine_pos = pos + Vector2(i, i) * pixel_size
		shine_pos = (shine_pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(shine_pos, Vector2(pixel_size, pixel_size)), color)
