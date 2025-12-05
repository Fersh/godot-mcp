extends Node2D

# Rage Incarnate - T3 Shout transform into pure rage

var pixel_size := 4
var duration := 1.15
var elapsed := 0.0

# Transformation phases
var transform_phase := 0  # 0=normal, 1=transforming, 2=rage form

# Rage energy
var rage_energy_alpha := 0.0
var energy_tendrils := []
var num_tendrils := 12

# Burning aura
var burning_aura := 0.0
var flame_particles := []
var num_flames := 35

# Rage form silhouette
var form_alpha := 0.0
var form_size := 1.0

# Shockwave on transform
var shockwave_radius := 0.0
var shockwave_alpha := 0.0

func _ready() -> void:
	# Initialize energy tendrils
	for i in range(num_tendrils):
		var angle = (i * TAU / num_tendrils)
		energy_tendrils.append({
			"angle": angle,
			"length": 0.0,
			"max_length": randf_range(50, 80),
			"wave_offset": randf() * TAU
		})

	# Initialize flame particles
	for i in range(num_flames):
		var angle = randf() * TAU
		flame_particles.append({
			"base_angle": angle,
			"base_radius": randf_range(20, 45),
			"height": randf_range(20, 50),
			"speed": randf_range(3, 6),
			"alpha": 0.0,
			"phase": randf() * TAU
		})

	# Major screen shake on transformation
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(18, 0.6)

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Phase transitions
	if progress < 0.3:
		transform_phase = 0
	elif progress < 0.5:
		transform_phase = 1
	else:
		transform_phase = 2

	# Rage energy builds
	rage_energy_alpha = ease(min(progress * 2, 1.0), 0.3) * (1.0 - progress * 0.2)

	# Burning aura intensifies
	burning_aura = ease(min(progress * 2.5, 1.0), 0.4)

	# Form grows during transformation
	if transform_phase >= 1:
		form_alpha = min((progress - 0.3) / 0.2, 1.0) * (1.0 - max(0, progress - 0.8) * 5)
		form_size = 1.0 + (progress - 0.3) * 0.8

	# Shockwave at transformation
	if progress > 0.4 and progress < 0.7:
		shockwave_radius = (progress - 0.4) / 0.3 * 100
		shockwave_alpha = max(0, 1.0 - (progress - 0.4) / 0.3)

	# Update energy tendrils
	for tendril in energy_tendrils:
		tendril.length = rage_energy_alpha * tendril.max_length
		var wave = sin(elapsed * 4 + tendril.wave_offset) * 0.3
		tendril.angle += wave * delta

	# Update flame particles
	for flame in flame_particles:
		flame.phase += flame.speed * delta
		flame.alpha = burning_aura * (0.6 + sin(flame.phase) * 0.4)

	queue_redraw()

func _draw() -> void:
	# Draw shockwave
	if shockwave_alpha > 0:
		var wave_color = Color(1.0, 0.4, 0.1, shockwave_alpha * 0.5)
		_draw_pixel_ring(Vector2.ZERO, shockwave_radius, wave_color, 12)

	# Draw energy tendrils
	for tendril in energy_tendrils:
		if tendril.length > 5:
			var color = Color(1.0, 0.5, 0.1, rage_energy_alpha * 0.7)
			var end = Vector2(cos(tendril.angle), sin(tendril.angle)) * tendril.length
			_draw_wavy_line(Vector2.ZERO, end, color, elapsed * 8)

	# Draw burning aura
	if burning_aura > 0:
		var outer_color = Color(1.0, 0.3, 0.0, burning_aura * 0.4)
		_draw_pixel_circle(Vector2.ZERO, 60 * form_size, outer_color)
		var inner_color = Color(1.0, 0.6, 0.2, burning_aura * 0.6)
		_draw_pixel_circle(Vector2.ZERO, 35 * form_size, inner_color)

	# Draw flame particles
	for flame in flame_particles:
		if flame.alpha > 0:
			var rise = (sin(flame.phase) * 0.5 + 0.5) * flame.height
			var pos = Vector2(cos(flame.base_angle), sin(flame.base_angle)) * flame.base_radius
			pos.y -= rise
			var heat = 1.0 - rise / flame.height
			var color = Color(1.0, 0.3 + heat * 0.5, heat * 0.2, flame.alpha)
			_draw_pixel_circle(pos * form_size, 6, color)

	# Draw rage form silhouette
	if form_alpha > 0:
		_draw_rage_form(Vector2.ZERO, form_alpha, form_size)

func _draw_rage_form(center: Vector2, alpha: float, size: float) -> void:
	var color = Color(0.2, 0.05, 0.0, alpha)
	var eye_color = Color(1.0, 0.8, 0.2, alpha)

	# Enlarged demonic figure
	# Head
	_draw_pixel_circle(center + Vector2(0, -25 * size), 12 * size, color)

	# Horns
	var horn_color = Color(0.3, 0.1, 0.05, alpha)
	_draw_pixel_line(center + Vector2(-8, -35) * size, center + Vector2(-15, -50) * size, horn_color)
	_draw_pixel_line(center + Vector2(8, -35) * size, center + Vector2(15, -50) * size, horn_color)

	# Body (larger, muscular)
	for y in range(int(-15 * size), int(25 * size), pixel_size):
		var width = (15 - abs(y) * 0.3) * size
		for x in range(int(-width), int(width) + 1, pixel_size):
			var pos = center + Vector2(x, y)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Burning eyes
	_draw_pixel_circle(center + Vector2(-5, -28) * size, 4 * size, eye_color)
	_draw_pixel_circle(center + Vector2(5, -28) * size, 4 * size, eye_color)

func _draw_wavy_line(from: Vector2, to: Vector2, color: Color, time: float) -> void:
	var dist = from.distance_to(to)
	var dir = (to - from).normalized()
	var perp = dir.rotated(PI/2)
	var steps = int(dist / pixel_size) + 1

	for i in range(steps):
		var t = float(i) / max(steps - 1, 1)
		var base_pos = from.lerp(to, t)
		var wave = sin(t * 8 + time) * 4 * (1.0 - abs(t - 0.5) * 2)
		var pos = base_pos + perp * wave
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
