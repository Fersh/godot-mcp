extends Node2D

# Shockwave Cleave - T3 Cleave with massive force wave

var pixel_size := 4
var duration := 0.7
var elapsed := 0.0

# Main arc slash (huge)
var arc_progress := 0.0
var arc_width := 130.0
var arc_angle_span := PI * 0.9

# Shockwave expanding from slash
var shockwave_progress := 0.0
var shockwave_range := 100.0

# Force particles pushed outward
var force_particles := []
var num_particles := 28

# Wind/air displacement
var wind_lines := []
var num_wind := 12

# Debris blown away
var debris := []
var num_debris := 16

func _ready() -> void:
	# Initialize force particles
	for i in range(num_particles):
		var angle = randf_range(-arc_angle_span/2, arc_angle_span/2) - PI/2
		force_particles.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(30, 60),
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(200, 350),
			"alpha": 1.0,
			"size": randf_range(4, 10)
		})

	# Initialize wind lines
	for i in range(num_wind):
		var angle = randf_range(-arc_angle_span/2, arc_angle_span/2) - PI/2
		wind_lines.append({
			"angle": angle,
			"start_dist": randf_range(40, 70),
			"length": randf_range(30, 60),
			"alpha": 0.0
		})

	# Initialize debris
	for i in range(num_debris):
		var angle = randf_range(-arc_angle_span/2, arc_angle_span/2) - PI/2
		debris.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(20, 50),
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(150, 280),
			"size": Vector2(randi_range(1, 3) * pixel_size, randi_range(1, 3) * pixel_size),
			"alpha": 1.0,
			"gravity": randf_range(100, 300)
		})

	# Screen shake
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(12, 0.35)

	await get_tree().create_timer(duration + 0.15).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Arc sweeps
	arc_progress = ease(min(progress * 2, 1.0), 0.15)

	# Shockwave follows arc
	if progress > 0.15:
		shockwave_progress = (progress - 0.15) / 0.85

	# Update wind lines
	for line in wind_lines:
		if progress > 0.1:
			line.alpha = max(0, 0.8 - (progress - 0.1) / 0.6)

	# Update force particles
	for p in force_particles:
		p.pos += p.velocity * delta
		p.velocity *= 0.95
		p.alpha = max(0, 1.0 - progress * 1.2)

	# Update debris
	for d in debris:
		d.velocity.y += d.gravity * delta
		d.pos += d.velocity * delta
		d.alpha = max(0, 1.0 - progress)

	queue_redraw()

func _draw() -> void:
	# Draw shockwave arc
	if shockwave_progress > 0:
		var wave_dist = shockwave_progress * shockwave_range
		var wave_alpha = max(0, 1.0 - shockwave_progress) * 0.5
		var wave_color = Color(0.8, 0.85, 0.95, wave_alpha)

		# Draw expanding arc wave
		var steps = 30
		for i in range(steps):
			var t = float(i) / steps
			var angle = -arc_angle_span/2 - PI/2 + t * arc_angle_span
			for r_off in range(3):
				var radius = 50 + wave_dist + r_off * pixel_size
				var pos = Vector2(cos(angle), sin(angle)) * radius
				pos = (pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), wave_color)

	# Draw wind lines
	for line in wind_lines:
		if line.alpha > 0:
			var color = Color(0.9, 0.92, 0.98, line.alpha)
			var start = Vector2(cos(line.angle), sin(line.angle)) * (line.start_dist + shockwave_progress * 50)
			var end = start + Vector2(cos(line.angle), sin(line.angle)) * line.length
			_draw_pixel_line(start, end, color)

	# Draw main arc (massive)
	if arc_progress > 0:
		var steps = int(arc_angle_span * arc_progress * 25)
		for i in range(steps):
			var t = float(i) / max(steps, 1)
			var angle = -arc_angle_span/2 - PI/2 + t * arc_angle_span * arc_progress
			var fade = 1.0 - t * 0.3

			# Outer edge
			var outer_color = Color(0.7, 0.75, 0.9, fade * 0.7)
			for r in range(4):
				var radius = arc_width - r * pixel_size
				var pos = Vector2(cos(angle), sin(angle)) * radius
				pos = (pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), outer_color)

			# Core
			var core_color = Color(1.0, 1.0, 1.0, fade)
			for r in range(2):
				var radius = 50 + r * pixel_size
				var pos = Vector2(cos(angle), sin(angle)) * radius
				pos = (pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), core_color)

	# Draw force particles
	for p in force_particles:
		if p.alpha > 0:
			var color = Color(0.9, 0.92, 1.0, p.alpha)
			_draw_pixel_circle(p.pos, p.size, color)

	# Draw debris
	for d in debris:
		if d.alpha > 0:
			var color = Color(0.5, 0.45, 0.4, d.alpha)
			var pos = (d.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos - d.size/2, d.size), color)

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
