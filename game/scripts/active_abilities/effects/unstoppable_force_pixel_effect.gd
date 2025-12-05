extends Node2D

# Unstoppable Force - T3 Rampage with maximum power

var pixel_size := 4
var duration := 1.0
var elapsed := 0.0

# Overwhelming power aura
var power_aura_alpha := 0.0
var aura_radius := 65.0

# Energy eruption
var eruption_particles := []
var num_eruption := 30

# Force waves
var force_waves := []
var num_waves := 4

# Lightning-like energy
var energy_arcs := []
var num_arcs := 8

# Ground tremor cracks
var tremor_cracks := []
var num_cracks := 8

func _ready() -> void:
	# Initialize eruption particles
	for i in range(num_eruption):
		var angle = randf() * TAU
		eruption_particles.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(100, 250),
			"alpha": 0.9,
			"size": randf_range(6, 14)
		})

	# Initialize force waves
	for i in range(num_waves):
		force_waves.append({
			"radius": 0.0,
			"alpha": 0.8,
			"delay": i * 0.15
		})

	# Initialize energy arcs
	for i in range(num_arcs):
		energy_arcs.append({
			"angle": (i * TAU / num_arcs),
			"length": randf_range(40, 70),
			"flicker": randf() * TAU
		})

	# Initialize tremor cracks
	for i in range(num_cracks):
		tremor_cracks.append({
			"angle": (i * TAU / num_cracks) + randf() * 0.3,
			"length": 0.0,
			"max_length": randf_range(50, 80)
		})

	# Major screen shake
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(18, 0.6)

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Power aura
	power_aura_alpha = ease(min(progress * 2, 1.0), 0.3) * (1.0 - progress * 0.2)

	# Update eruption particles
	for p in eruption_particles:
		p.velocity *= 0.96
		p.pos += p.velocity * delta
		p.alpha = max(0, 0.9 - progress)

	# Update force waves
	for wave in force_waves:
		if elapsed > wave.delay:
			var wave_progress = (elapsed - wave.delay) / 0.4
			wave.radius = wave_progress * 100
			wave.alpha = max(0, 0.8 - wave_progress)

	# Update energy arcs
	for arc in energy_arcs:
		arc.flicker += delta * 20

	# Update tremor cracks
	for crack in tremor_cracks:
		crack.length = min(progress * 2, 1.0) * crack.max_length

	queue_redraw()

func _draw() -> void:
	# Draw tremor cracks
	for crack in tremor_cracks:
		if crack.length > 5:
			var color = Color(0.2, 0.15, 0.1, 0.8)
			var end = Vector2(cos(crack.angle), sin(crack.angle)) * crack.length
			_draw_pixel_line(Vector2.ZERO, end, color)

	# Draw force waves
	for wave in force_waves:
		if wave.alpha > 0 and wave.radius > 10:
			var color = Color(1.0, 0.6, 0.2, wave.alpha * 0.5)
			_draw_pixel_ring(Vector2.ZERO, wave.radius, color, 8)

	# Draw power aura
	if power_aura_alpha > 0:
		# Outer glow (orange/red)
		var outer_color = Color(1.0, 0.4, 0.1, power_aura_alpha * 0.4)
		_draw_pixel_circle(Vector2.ZERO, aura_radius, outer_color)
		# Inner fire
		var inner_color = Color(1.0, 0.7, 0.3, power_aura_alpha * 0.6)
		_draw_pixel_circle(Vector2.ZERO, aura_radius * 0.6, inner_color)
		# Core
		var core_color = Color(1.0, 0.9, 0.6, power_aura_alpha)
		_draw_pixel_circle(Vector2.ZERO, aura_radius * 0.3, core_color)

	# Draw energy arcs
	for arc in energy_arcs:
		var arc_alpha = (0.5 + 0.4 * sin(arc.flicker)) * (1.0 - elapsed / duration)
		if arc_alpha > 0:
			var color = Color(1.0, 0.8, 0.3, arc_alpha)
			var end = Vector2(cos(arc.angle), sin(arc.angle)) * arc.length
			_draw_electric_arc(Vector2.ZERO, end, color)

	# Draw eruption particles
	for p in eruption_particles:
		if p.alpha > 0:
			var heat = p.pos.length() / 100
			var r = 1.0
			var g = 0.7 - heat * 0.3
			var b = 0.2 - heat * 0.15
			var color = Color(r, g, b, p.alpha)
			_draw_pixel_circle(p.pos, p.size, color)

func _draw_electric_arc(from: Vector2, to: Vector2, color: Color) -> void:
	var dist = from.distance_to(to)
	var segments = int(dist / 10) + 1
	var dir = (to - from).normalized()
	var perp = dir.rotated(PI/2)
	var current = from

	for i in range(segments):
		var t = float(i + 1) / segments
		var target = from.lerp(to, t)
		var offset = perp * randf_range(-5, 5)
		var next = target + offset
		_draw_pixel_line(current, next, color)
		current = next

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
	var steps = max(int(radius / pixel_size), 3)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = center + pos
				draw_pos = (draw_pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)
