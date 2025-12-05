extends Node2D

# Blood Rage - T3 Roar berserker fury with blood effects

var pixel_size := 4
var duration := 1.0
var elapsed := 0.0

# Rage aura
var rage_aura_alpha := 0.0
var aura_pulse := 0.0

# Blood veins spreading
var veins := []
var num_veins := 16

# Rage particles
var rage_particles := []
var num_particles := 30

# Berserker eyes
var eye_glow := 0.0

# Roar wave
var roar_wave_radius := 0.0
var roar_wave_alpha := 0.0

func _ready() -> void:
	# Initialize veins
	for i in range(num_veins):
		var angle = (i * TAU / num_veins) + randf() * 0.2
		veins.append({
			"angle": angle,
			"length": 0.0,
			"max_length": randf_range(35, 65),
			"branch_angle": randf_range(-0.5, 0.5)
		})

	# Initialize rage particles
	for i in range(num_particles):
		var angle = randf() * TAU
		rage_particles.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(60, 140),
			"alpha": 0.0,
			"size": randf_range(4, 10)
		})

	# Screen shake
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(12, 0.4)

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Rage aura intensifies
	rage_aura_alpha = ease(min(progress * 2, 1.0), 0.3) * (1.0 - progress * 0.2)
	aura_pulse = sin(elapsed * 12) * 0.3 + 0.7

	# Eye glow
	eye_glow = ease(min(progress * 3, 1.0), 0.3) * (1.0 - progress * 0.3)

	# Roar wave expands
	roar_wave_radius = progress * 120
	roar_wave_alpha = max(0, 0.8 - progress)

	# Update veins
	for vein in veins:
		vein.length = ease(min(progress * 2.5, 1.0), 0.3) * vein.max_length

	# Update rage particles
	for p in rage_particles:
		if p.alpha == 0 and progress > 0.1:
			p.alpha = 0.9
		if p.alpha > 0:
			p.velocity *= 0.96
			p.pos += p.velocity * delta
			p.alpha = max(0, p.alpha - delta * 1.2)

	queue_redraw()

func _draw() -> void:
	# Draw roar wave
	if roar_wave_alpha > 0:
		var wave_color = Color(0.8, 0.2, 0.1, roar_wave_alpha * 0.3)
		_draw_pixel_ring(Vector2.ZERO, roar_wave_radius, wave_color, 10)

	# Draw rage aura
	if rage_aura_alpha > 0:
		var outer_color = Color(0.6, 0.1, 0.1, rage_aura_alpha * 0.4 * aura_pulse)
		_draw_pixel_circle(Vector2.ZERO, 55, outer_color)
		var inner_color = Color(0.9, 0.2, 0.1, rage_aura_alpha * 0.6 * aura_pulse)
		_draw_pixel_circle(Vector2.ZERO, 30, inner_color)

	# Draw veins
	for vein in veins:
		if vein.length > 5:
			var color = Color(0.7, 0.15, 0.1, 0.8 * (1.0 - elapsed/duration))
			var end = Vector2(cos(vein.angle), sin(vein.angle)) * vein.length
			_draw_pixel_line(Vector2.ZERO, end, color)
			# Branch
			if vein.length > 20:
				var branch_start = Vector2(cos(vein.angle), sin(vein.angle)) * (vein.length * 0.6)
				var branch_angle = vein.angle + vein.branch_angle
				var branch_end = branch_start + Vector2(cos(branch_angle), sin(branch_angle)) * (vein.length * 0.4)
				_draw_pixel_line(branch_start, branch_end, color)

	# Draw rage particles
	for p in rage_particles:
		if p.alpha > 0:
			var heat = 1.0 - p.pos.length() / 100
			var color = Color(0.9, 0.2 * heat, 0.1 * heat, p.alpha)
			_draw_pixel_circle(p.pos, p.size, color)

	# Draw berserker eyes
	if eye_glow > 0:
		var eye_color = Color(1.0, 0.3, 0.1, eye_glow)
		# Left eye
		_draw_pixel_circle(Vector2(-8, -20), 5, eye_color)
		# Right eye
		_draw_pixel_circle(Vector2(8, -20), 5, eye_color)
		# Glow around eyes
		var glow_color = Color(1.0, 0.2, 0.1, eye_glow * 0.4)
		_draw_pixel_circle(Vector2(-8, -20), 10, glow_color)
		_draw_pixel_circle(Vector2(8, -20), 10, glow_color)

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
