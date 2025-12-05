extends Node2D

# Skewer - T2 Impale with deeper penetration and bleed effect

var pixel_size := 4
var duration := 0.55
var elapsed := 0.0

# Thrust spear
var thrust_progress := 0.0
var thrust_length := 70.0

# Penetration sparks
var sparks := []
var num_sparks := 12

# Blood drips
var blood_drips := []
var num_drips := 8

# Impact flash
var impact_alpha := 0.0

func _ready() -> void:
	# Initialize sparks
	for i in range(num_sparks):
		var angle = randf_range(PI/2, 3*PI/2)  # Spread backward
		sparks.append({
			"pos": Vector2(thrust_length * 0.8, 0),
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(80, 150),
			"alpha": 0.0
		})

	# Initialize blood drips
	for i in range(num_drips):
		blood_drips.append({
			"pos": Vector2(thrust_length * randf_range(0.5, 0.9), randf_range(-5, 5)),
			"velocity": Vector2(randf_range(-20, 10), randf_range(30, 80)),
			"alpha": 0.0,
			"size": randi_range(1, 2) * pixel_size
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Thrust moves forward fast
	thrust_progress = ease(min(progress * 3, 1.0), 0.15)

	# Impact flash
	if progress > 0.25 and progress < 0.4:
		impact_alpha = 1.0 - (progress - 0.25) / 0.15
	else:
		impact_alpha = 0

	# Trigger sparks and blood on impact
	if progress > 0.3:
		for spark in sparks:
			if spark.alpha == 0:
				spark.alpha = 1.0
		for drip in blood_drips:
			if drip.alpha == 0:
				drip.alpha = 0.9

	# Update sparks
	for spark in sparks:
		if spark.alpha > 0:
			spark.pos += spark.velocity * delta
			spark.velocity *= 0.9
			spark.alpha = max(0, spark.alpha - delta * 2.5)

	# Update blood drips
	for drip in blood_drips:
		if drip.alpha > 0:
			drip.velocity.y += delta * 150  # Gravity
			drip.pos += drip.velocity * delta
			drip.alpha = max(0, drip.alpha - delta * 1.2)

	queue_redraw()

func _draw() -> void:
	# Draw thrust trail
	if thrust_progress > 0:
		var trail_length = thrust_progress * thrust_length
		# Trail blur
		var trail_color = Color(0.6, 0.55, 0.5, 0.4)
		for y_off in range(-1, 2):
			_draw_pixel_line(Vector2.ZERO, Vector2(trail_length * 0.7, y_off * pixel_size), trail_color)

		# Spear shaft
		var shaft_color = Color(0.55, 0.45, 0.35, 0.9)
		_draw_pixel_line(Vector2.ZERO, Vector2(trail_length * 0.85, 0), shaft_color)

		# Spear head
		var head_pos = Vector2(trail_length, 0)
		var head_color = Color(0.7, 0.65, 0.6, 1.0)
		_draw_spear_head(head_pos, head_color)

	# Draw impact flash
	if impact_alpha > 0:
		var flash_color = Color(1.0, 0.9, 0.7, impact_alpha)
		_draw_pixel_circle(Vector2(thrust_length, 0), 15, flash_color)

	# Draw sparks
	for spark in sparks:
		if spark.alpha > 0:
			var color = Color(1.0, 0.8, 0.4, spark.alpha)
			var pos = (spark.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Draw blood drips
	for drip in blood_drips:
		if drip.alpha > 0:
			var color = Color(0.7, 0.15, 0.1, drip.alpha)
			var pos = (drip.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(drip.size, drip.size)), color)

func _draw_spear_head(tip: Vector2, color: Color) -> void:
	# Triangular spear head
	var head_length = 15
	var head_width = 8
	for i in range(int(head_length / pixel_size)):
		var t = float(i) / (head_length / pixel_size)
		var row_width = head_width * (1.0 - t)
		for y_off in range(int(-row_width / pixel_size), int(row_width / pixel_size) + 1):
			var pos = tip + Vector2(-i * pixel_size, y_off * pixel_size)
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
