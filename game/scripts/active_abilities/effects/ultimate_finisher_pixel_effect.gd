extends Node2D

# Ultimate Finisher - T3 Combo devastating final blow

var pixel_size := 4
var duration := 1.0
var elapsed := 0.0

# Windup phase
var windup_alpha := 0.0
var windup_charge := 0.0

# Massive impact
var impact_alpha := 0.0
var impact_radius := 0.0
var max_impact := 100.0

# Shatter effect
var shatter_pieces := []
var num_pieces := 40

# Energy convergence
var energy_beams := []
var num_beams := 8

# Final flash
var flash_alpha := 0.0

func _ready() -> void:
	# Initialize shatter pieces
	for i in range(num_pieces):
		var angle = randf() * TAU
		shatter_pieces.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(200, 400),
			"alpha": 0.0,
			"size": randf_range(6, 14),
			"rotation": randf() * TAU
		})

	# Initialize energy beams (converge to center)
	for i in range(num_beams):
		var angle = (i * TAU / num_beams)
		energy_beams.append({
			"angle": angle,
			"length": 120.0,
			"alpha": 0.0
		})

	# Screen shake on impact
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(20, 0.5)

	await get_tree().create_timer(duration + 0.25).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Windup phase (0-0.4)
	if progress < 0.4:
		windup_charge = progress / 0.4
		windup_alpha = windup_charge
		# Energy beams converge
		for beam in energy_beams:
			beam.length = 120 * (1.0 - windup_charge)
			beam.alpha = windup_charge * 0.8
	else:
		windup_alpha = max(0, windup_alpha - delta * 5)
		for beam in energy_beams:
			beam.alpha = max(0, beam.alpha - delta * 5)

	# Impact phase (0.4+)
	if progress > 0.4:
		var impact_progress = (progress - 0.4) / 0.3
		impact_radius = ease(min(impact_progress, 1.0), 0.2) * max_impact
		impact_alpha = max(0, 1.0 - impact_progress * 0.8)

		# Flash at moment of impact
		if progress < 0.5:
			flash_alpha = 1.0 - (progress - 0.4) / 0.1
		else:
			flash_alpha = 0

		# Trigger shatter
		for piece in shatter_pieces:
			if piece.alpha == 0:
				piece.alpha = 1.0

	# Update shatter pieces
	for piece in shatter_pieces:
		if piece.alpha > 0:
			piece.velocity *= 0.95
			piece.pos += piece.velocity * delta
			piece.rotation += delta * 5
			piece.alpha = max(0, piece.alpha - delta * 1.2)

	queue_redraw()

func _draw() -> void:
	# Draw energy beams converging
	for beam in energy_beams:
		if beam.alpha > 0:
			var color = Color(1.0, 0.8, 0.4, beam.alpha)
			var start = Vector2(cos(beam.angle), sin(beam.angle)) * beam.length
			_draw_pixel_line(start, Vector2.ZERO, color)

	# Draw windup charge
	if windup_alpha > 0:
		var charge_color = Color(1.0, 0.9, 0.5, windup_alpha * 0.6)
		_draw_pixel_circle(Vector2.ZERO, 25 * windup_charge, charge_color)

	# Draw flash
	if flash_alpha > 0:
		var flash_color = Color(1.0, 1.0, 0.95, flash_alpha)
		_draw_pixel_circle(Vector2.ZERO, 60, flash_color)

	# Draw impact wave
	if impact_alpha > 0:
		# Outer ring
		var outer_color = Color(1.0, 0.6, 0.2, impact_alpha * 0.5)
		_draw_pixel_ring(Vector2.ZERO, impact_radius, outer_color, 12)
		# Inner core
		var inner_color = Color(1.0, 0.85, 0.5, impact_alpha * 0.8)
		_draw_pixel_circle(Vector2.ZERO, impact_radius * 0.3, inner_color)

	# Draw shatter pieces
	for piece in shatter_pieces:
		if piece.alpha > 0:
			var color = Color(1.0, 0.7, 0.3, piece.alpha)
			_draw_rotated_rect(piece.pos, piece.size, piece.rotation, color)

func _draw_rotated_rect(center: Vector2, size: float, angle: float, color: Color) -> void:
	# Draw a pixelated rotated rectangle
	var half = size / 2
	for i in range(-int(half/pixel_size), int(half/pixel_size) + 1):
		for j in range(-int(half/pixel_size), int(half/pixel_size) + 1):
			var local = Vector2(i, j) * pixel_size
			var rotated = local.rotated(angle)
			var pos = center + rotated
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
	var steps = max(int(radius / pixel_size), 2)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = center + pos
				draw_pos = (draw_pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)
