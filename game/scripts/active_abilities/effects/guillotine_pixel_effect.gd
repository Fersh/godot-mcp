extends Node2D

# Guillotine - T3 Cleave execution with massive overhead strike

var pixel_size := 4
var duration := 0.6
var elapsed := 0.0

# Giant blade falling
var blade_y := -120.0
var blade_target := 0.0
var blade_alpha := 1.0

# Impact shockwave
var shockwave_radius := 0.0
var max_shockwave := 90.0

# Blood explosion
var blood := []
var num_blood := 24

# Ground crack
var crack_length := 0.0
var max_crack := 70.0

# Execution flash
var flash_alpha := 0.0

func _ready() -> void:
	# Initialize blood
	for i in range(num_blood):
		var angle = randf_range(-PI, 0)
		blood.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(120, 250),
			"size": randi_range(1, 4) * pixel_size,
			"alpha": 0.0,
			"gravity": randf_range(300, 500)
		})

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Blade falls fast
	if progress < 0.25:
		blade_y = -120 + ease(progress / 0.25, 0.1) * 120
	else:
		blade_y = 0

	# Impact effects
	if progress > 0.25:
		var impact_progress = (progress - 0.25) / 0.75

		# Shockwave
		shockwave_radius = impact_progress * max_shockwave

		# Crack
		crack_length = min(impact_progress * 2, 1.0) * max_crack

		# Flash
		if impact_progress < 0.15:
			flash_alpha = 1.0 - impact_progress / 0.15
		else:
			flash_alpha = 0

		# Trigger blood
		for b in blood:
			if b.alpha == 0:
				b.alpha = 1.0

		# Screen shake
		if impact_progress < 0.1:
			var camera = get_viewport().get_camera_2d()
			if camera and camera.has_method("shake"):
				camera.shake(15, 0.3)

	# Blade fades
	blade_alpha = max(0, 1.0 - max(0, progress - 0.4) / 0.6)

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
		var crack_color = Color(0.15, 0.1, 0.08, 0.9)
		_draw_pixel_line(Vector2.ZERO, Vector2(0, crack_length), crack_color)
		_draw_pixel_line(Vector2.ZERO, Vector2(-crack_length * 0.5, crack_length * 0.7), crack_color)
		_draw_pixel_line(Vector2.ZERO, Vector2(crack_length * 0.5, crack_length * 0.7), crack_color)

	# Draw shockwave
	if shockwave_radius > 5:
		var wave_alpha = max(0, 1.0 - shockwave_radius / max_shockwave) * 0.6
		var wave_color = Color(0.6, 0.2, 0.2, wave_alpha)
		_draw_pixel_ring(Vector2.ZERO, shockwave_radius, wave_color, 8)

	# Draw execution flash
	if flash_alpha > 0:
		var flash_color = Color(1.0, 0.9, 0.8, flash_alpha)
		_draw_pixel_circle(Vector2.ZERO, 50, flash_color)

	# Draw giant blade
	if blade_alpha > 0:
		_draw_guillotine_blade(Vector2(0, blade_y), blade_alpha)

	# Draw blood
	for b in blood:
		if b.alpha > 0:
			var color = Color(0.7, 0.1, 0.1, b.alpha)
			var pos = (b.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(b.size, b.size)), color)

func _draw_guillotine_blade(pos: Vector2, alpha: float) -> void:
	var blade_width := 60
	var blade_height := 50

	# Blade body (dark steel)
	var blade_color = Color(0.5, 0.5, 0.55, alpha)
	for y in range(int(blade_height / pixel_size)):
		var y_pos = y * pixel_size
		var width_factor = 1.0 if y < blade_height / pixel_size * 0.7 else (1.0 - (float(y) / (blade_height / pixel_size) - 0.7) / 0.3 * 0.4)
		var row_width = blade_width * width_factor

		for x in range(int(-row_width / 2 / pixel_size), int(row_width / 2 / pixel_size) + 1):
			var draw_pos = pos + Vector2(x * pixel_size, y_pos)
			draw_pos = (draw_pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), blade_color)

	# Sharp edge (bright)
	var edge_color = Color(0.9, 0.9, 0.95, alpha)
	for x in range(int(-blade_width / 2 / pixel_size), int(blade_width / 2 / pixel_size) + 1):
		var draw_pos = pos + Vector2(x * pixel_size, blade_height)
		draw_pos = (draw_pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), edge_color)

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
		for t in range(int(thickness / pixel_size)):
			var r = radius - t * pixel_size
			if r > 0:
				var pos = center + Vector2(cos(angle), sin(angle)) * r
				pos = (pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 4)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = center + pos
				draw_pos = (draw_pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)
