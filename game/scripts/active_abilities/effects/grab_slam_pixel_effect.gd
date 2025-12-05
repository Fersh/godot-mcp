extends Node2D

# Grab Slam - T2 Uppercut variant that grabs and slams down

var pixel_size := 4
var duration := 0.65
var elapsed := 0.0

# Grab effect (upward then downward arc)
var grab_phase := 0  # 0 = grab up, 1 = slam down
var arc_progress := 0.0

# Impact crater
var crater_radius := 0.0
var max_crater_radius := 45.0

# Ground debris
var debris := []
var num_debris := 14

# Dust cloud
var dust_clouds := []
var num_dust := 8

# Grab hands visual
var hand_alpha := 0.0

func _ready() -> void:
	# Initialize debris (triggered on slam)
	for i in range(num_debris):
		var angle = randf() * TAU
		debris.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(100, 180),
			"size": Vector2(randi_range(1, 3) * pixel_size, randi_range(1, 3) * pixel_size),
			"alpha": 0.0,
			"gravity": randf_range(300, 500)
		})

	# Initialize dust
	for i in range(num_dust):
		var angle = randf() * TAU
		dust_clouds.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(15, 35),
			"size": randf_range(12, 22),
			"alpha": 0.0
		})

	# Screen shake on slam
	await get_tree().create_timer(0.3).timeout
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(12, 0.3)

	await get_tree().create_timer(duration - 0.3 + 0.15).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Phase transitions
	if elapsed < 0.25:
		# Grab phase (upward)
		grab_phase = 0
		arc_progress = elapsed / 0.25
		hand_alpha = arc_progress
	elif elapsed < 0.35:
		# Hold at top
		grab_phase = 0
		arc_progress = 1.0
		hand_alpha = 1.0
	else:
		# Slam phase (downward)
		grab_phase = 1
		var slam_progress = (elapsed - 0.35) / 0.15
		arc_progress = min(slam_progress, 1.0)
		hand_alpha = max(0, 1.0 - (elapsed - 0.35) / 0.2)

		# Trigger crater and debris on slam
		if elapsed > 0.5:
			crater_radius = min((elapsed - 0.5) / 0.15, 1.0) * max_crater_radius
			for d in debris:
				if d.alpha == 0:
					d.alpha = 1.0
			for dust in dust_clouds:
				if dust.alpha == 0:
					dust.alpha = 0.7

	# Update debris
	for d in debris:
		if d.alpha > 0:
			d.velocity.y += d.gravity * delta
			d.pos += d.velocity * delta
			d.alpha = max(0, d.alpha - delta * 1.5)

	# Update dust
	for dust in dust_clouds:
		if dust.alpha > 0:
			dust.size += delta * 30
			dust.alpha = max(0, dust.alpha - delta * 1.2)

	queue_redraw()

func _draw() -> void:
	# Draw grab hands/claws
	if hand_alpha > 0:
		var y_offset = 0.0
		if grab_phase == 0:
			y_offset = -40 * arc_progress
		else:
			y_offset = -40 + 50 * arc_progress

		var hand_color = Color(0.9, 0.85, 0.7, hand_alpha * 0.8)
		# Left claw
		_draw_claw(Vector2(-20, y_offset), hand_color, false)
		# Right claw
		_draw_claw(Vector2(20, y_offset), hand_color, true)

	# Draw crater
	if crater_radius > 0:
		# Dark crater center
		var crater_color = Color(0.25, 0.2, 0.15, 0.8)
		_draw_pixel_circle(Vector2.ZERO, crater_radius, crater_color)
		# Rim
		var rim_color = Color(0.5, 0.4, 0.3, 0.6)
		_draw_pixel_ring(Vector2.ZERO, crater_radius, rim_color, 6)
		# Impact flash
		if elapsed < 0.55:
			var flash_alpha = 1.0 - (elapsed - 0.5) / 0.05
			var flash_color = Color(1.0, 0.9, 0.6, flash_alpha)
			_draw_pixel_circle(Vector2.ZERO, crater_radius * 0.6, flash_color)

	# Draw dust clouds
	for dust in dust_clouds:
		if dust.alpha > 0:
			var color = Color(0.6, 0.55, 0.45, dust.alpha * 0.5)
			_draw_pixel_circle(dust.pos, dust.size, color)

	# Draw debris
	for d in debris:
		if d.alpha > 0:
			var color = Color(0.5, 0.4, 0.3, d.alpha)
			var pos = (d.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos - d.size/2, d.size), color)

func _draw_claw(center: Vector2, color: Color, flip: bool) -> void:
	var dir = -1 if flip else 1
	# Three fingers
	for i in range(3):
		var finger_angle = (i - 1) * 0.3 * dir
		var finger_start = center
		var finger_end = center + Vector2(cos(finger_angle - PI/2), sin(finger_angle - PI/2)) * 15
		_draw_pixel_line(finger_start, finger_end, color)
	# Palm
	_draw_pixel_circle(center, 8, color)

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
