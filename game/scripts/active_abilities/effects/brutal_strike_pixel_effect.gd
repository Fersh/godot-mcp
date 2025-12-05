extends Node2D

# Brutal Strike - T2 Execute with massive impact and blood

var pixel_size := 4
var duration := 0.5
var elapsed := 0.0

# Heavy downward strike
var strike_progress := 0.0

# Blood splatter
var blood := []
var num_blood := 18

# Impact shockwave
var shockwave_radius := 0.0
var max_shockwave := 50.0

# Ground crack
var crack_length := 0.0
var max_crack := 40.0

# Impact flash
var flash_alpha := 0.0

func _ready() -> void:
	# Initialize blood
	for i in range(num_blood):
		var angle = randf_range(-PI, 0)  # Upward spray
		blood.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(100, 200),
			"size": randi_range(1, 3) * pixel_size,
			"alpha": 0.0,
			"gravity": randf_range(300, 500)
		})

	# Screen shake
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(15, 0.25)

	await get_tree().create_timer(duration + 0.15).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Strike comes down fast
	strike_progress = ease(min(progress * 4, 1.0), 0.1)

	# Impact effects trigger after strike lands
	if progress > 0.25:
		var impact_progress = (progress - 0.25) / 0.75
		shockwave_radius = impact_progress * max_shockwave
		crack_length = min(impact_progress * 2, 1.0) * max_crack

		# Trigger blood
		for b in blood:
			if b.alpha == 0:
				b.alpha = 1.0

		# Flash
		if progress < 0.35:
			flash_alpha = 1.0 - (progress - 0.25) / 0.1
		else:
			flash_alpha = 0

	# Update blood
	for b in blood:
		if b.alpha > 0:
			b.velocity.y += b.gravity * delta
			b.pos += b.velocity * delta
			b.alpha = max(0, b.alpha - delta * 1.5)

	queue_redraw()

func _draw() -> void:
	# Draw ground crack
	if crack_length > 0:
		var crack_color = Color(0.2, 0.15, 0.1, 0.9)
		_draw_pixel_line(Vector2.ZERO, Vector2(0, crack_length), crack_color)
		_draw_pixel_line(Vector2.ZERO, Vector2(-crack_length * 0.6, crack_length * 0.8), crack_color)
		_draw_pixel_line(Vector2.ZERO, Vector2(crack_length * 0.6, crack_length * 0.8), crack_color)

	# Draw shockwave
	if shockwave_radius > 5:
		var wave_alpha = max(0, 1.0 - shockwave_radius / max_shockwave)
		var wave_color = Color(0.5, 0.3, 0.2, wave_alpha * 0.6)
		_draw_pixel_ring(Vector2.ZERO, shockwave_radius, wave_color, 6)

	# Draw strike (heavy blade coming down)
	if strike_progress > 0:
		var strike_y = -80 + strike_progress * 80
		# Blade trail
		var trail_color = Color(0.4, 0.35, 0.4, 0.6)
		if strike_y < 0:
			_draw_pixel_line(Vector2(0, -80), Vector2(0, strike_y), trail_color)
		# Blade head (wide)
		var blade_color = Color(0.7, 0.65, 0.75, 1.0)
		_draw_blade(Vector2(0, strike_y), blade_color)

	# Draw impact flash
	if flash_alpha > 0:
		var flash_color = Color(1.0, 0.9, 0.7, flash_alpha)
		_draw_pixel_circle(Vector2.ZERO, 25, flash_color)

	# Draw blood
	for b in blood:
		if b.alpha > 0:
			var color = Color(0.7, 0.1, 0.1, b.alpha)
			var pos = (b.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(b.size, b.size)), color)

func _draw_blade(pos: Vector2, color: Color) -> void:
	# Heavy blade shape
	var blade_width = 20
	var blade_height = 30
	for y in range(int(blade_height / pixel_size)):
		var row_width = blade_width * (1.0 - float(y) / (blade_height / pixel_size) * 0.5)
		for x in range(int(-row_width / 2 / pixel_size), int(row_width / 2 / pixel_size) + 1):
			var draw_pos = pos + Vector2(x * pixel_size, y * pixel_size - blade_height)
			draw_pos = (draw_pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)

func _draw_pixel_line(from: Vector2, to: Vector2, color: Color) -> void:
	var dist = from.distance_to(to)
	var steps = int(dist / pixel_size) + 1
	for i in range(steps):
		var t = float(i) / max(steps - 1, 1)
		var pos = from.lerp(to, t)
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
