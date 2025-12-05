extends Node2D

# Piledriver - T3 Uppercut with devastating slam finish

var pixel_size := 4
var duration := 0.75
var elapsed := 0.0

# Grab phase
var grab_y := 0.0
var grab_max_height := 80.0

# Slam phase
var slam_active := false
var slam_y := 0.0

# Impact crater
var crater_radius := 0.0
var max_crater := 60.0

# Shockwave
var shockwave_radius := 0.0
var max_shockwave := 100.0

# Debris explosion
var debris := []
var num_debris := 28

# Dust cloud
var dust := []
var num_dust := 12

func _ready() -> void:
	# Initialize debris
	for i in range(num_debris):
		var angle = randf() * TAU
		debris.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(150, 300),
			"size": Vector2(randi_range(2, 5) * pixel_size, randi_range(2, 5) * pixel_size),
			"alpha": 0.0,
			"gravity": randf_range(400, 700)
		})

	# Initialize dust
	for i in range(num_dust):
		var angle = randf() * TAU
		dust.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(10, 30),
			"size": randf_range(15, 30),
			"alpha": 0.0
		})

	await get_tree().create_timer(duration + 0.25).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Phase 1: Grab and rise (0-0.35)
	if progress < 0.35:
		grab_y = ease(progress / 0.35, 0.3) * -grab_max_height
		slam_active = false
	# Phase 2: Slam down (0.35-0.5)
	elif progress < 0.5:
		slam_active = true
		var slam_progress = (progress - 0.35) / 0.15
		slam_y = -grab_max_height + ease(slam_progress, 0.1) * grab_max_height
	# Phase 3: Impact (0.5+)
	else:
		slam_y = 0
		var impact_progress = (progress - 0.5) / 0.5

		# Crater
		crater_radius = ease(min(impact_progress * 2, 1.0), 0.3) * max_crater

		# Shockwave
		shockwave_radius = impact_progress * max_shockwave

		# Trigger debris and dust
		for d in debris:
			if d.alpha == 0:
				d.alpha = 1.0
		for ds in dust:
			if ds.alpha == 0:
				ds.alpha = 0.7

		# Screen shake
		if impact_progress < 0.1:
			var camera = get_viewport().get_camera_2d()
			if camera and camera.has_method("shake"):
				camera.shake(20, 0.4)

	# Update debris
	for d in debris:
		if d.alpha > 0:
			d.velocity.y += d.gravity * delta
			d.pos += d.velocity * delta
			d.alpha = max(0, d.alpha - delta * 1.3)

	# Update dust
	for ds in dust:
		if ds.alpha > 0:
			ds.size += delta * 40
			ds.alpha = max(0, ds.alpha - delta * 1.0)

	queue_redraw()

func _draw() -> void:
	# Draw dust clouds
	for ds in dust:
		if ds.alpha > 0:
			var color = Color(0.6, 0.55, 0.45, ds.alpha * 0.5)
			_draw_pixel_circle(ds.pos, ds.size, color)

	# Draw crater
	if crater_radius > 5:
		var crater_color = Color(0.2, 0.15, 0.1, 0.9)
		_draw_pixel_circle(Vector2.ZERO, crater_radius, crater_color)
		var rim_color = Color(0.4, 0.35, 0.25, 0.7)
		_draw_pixel_ring(Vector2.ZERO, crater_radius, rim_color, 8)

	# Draw shockwave
	if shockwave_radius > 10 and shockwave_radius < max_shockwave:
		var wave_alpha = max(0, 1.0 - shockwave_radius / max_shockwave) * 0.6
		var wave_color = Color(0.6, 0.5, 0.4, wave_alpha)
		_draw_pixel_ring(Vector2.ZERO, shockwave_radius, wave_color, 10)

	# Draw impact flash
	if elapsed > duration * 0.5 and elapsed < duration * 0.6:
		var flash_alpha = 1.0 - (elapsed - duration * 0.5) / 0.1
		var flash_color = Color(1.0, 0.9, 0.7, flash_alpha)
		_draw_pixel_circle(Vector2.ZERO, 40, flash_color)

	# Draw grab/slam figure
	var figure_y = grab_y if not slam_active else slam_y
	if elapsed < duration * 0.55:
		_draw_piledriver_figure(Vector2(0, figure_y))

	# Draw debris
	for d in debris:
		if d.alpha > 0:
			var color = Color(0.5, 0.4, 0.3, d.alpha)
			var pos = (d.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos - d.size/2, d.size), color)

func _draw_piledriver_figure(pos: Vector2) -> void:
	# Simplified grabbing figure
	var color = Color(0.8, 0.75, 0.6, 0.9)

	# Arms reaching down
	_draw_pixel_line(pos + Vector2(-15, -10), pos + Vector2(-5, 10), color)
	_draw_pixel_line(pos + Vector2(15, -10), pos + Vector2(5, 10), color)

	# Body
	_draw_pixel_circle(pos + Vector2(0, -15), 10, color)

	# Victim (being driven down)
	var victim_color = Color(0.6, 0.5, 0.5, 0.8)
	_draw_pixel_circle(pos + Vector2(0, 15), 8, victim_color)

func _draw_pixel_line(from: Vector2, to: Vector2, color: Color) -> void:
	var dist = from.distance_to(to)
	var steps = int(dist / pixel_size) + 1
	for i in range(steps):
		var t = float(i) / max(steps - 1, 1)
		var p = from.lerp(to, t)
		p = (p / pixel_size).floor() * pixel_size
		draw_rect(Rect2(p, Vector2(pixel_size, pixel_size)), color)

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
	var steps = max(int(radius / pixel_size), 3)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = center + pos
				draw_pos = (draw_pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)
