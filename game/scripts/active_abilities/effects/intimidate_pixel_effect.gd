extends Node2D

# Intimidate - T2 Roar with fear effect

var pixel_size := 4
var duration := 0.7
var elapsed := 0.0

# Fear waves (dark/purple)
var fear_waves := []
var num_waves := 3

# Dark aura
var aura_alpha := 0.0
var aura_radius := 40.0

# Fear symbols (skull-like shapes radiating out)
var fear_symbols := []
var num_symbols := 6

# Shadow particles
var shadow_particles := []
var num_shadows := 12

func _ready() -> void:
	# Initialize fear waves
	for i in range(num_waves):
		fear_waves.append({
			"radius": 0.0,
			"alpha": 0.8,
			"delay": i * 0.12
		})

	# Initialize fear symbols
	for i in range(num_symbols):
		var angle = (i * TAU / num_symbols)
		fear_symbols.append({
			"angle": angle,
			"distance": 0.0,
			"alpha": 0.0,
			"delay": 0.1 + i * 0.05
		})

	# Initialize shadow particles
	for i in range(num_shadows):
		var angle = randf() * TAU
		shadow_particles.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(40, 80),
			"alpha": 0.6,
			"size": randf_range(6, 12)
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Aura pulses
	aura_alpha = (0.6 + 0.2 * sin(elapsed * 8)) * (1.0 - progress * 0.5)

	# Update fear waves
	for wave in fear_waves:
		if elapsed > wave.delay:
			var wave_progress = (elapsed - wave.delay) / 0.4
			wave.radius = wave_progress * 80
			wave.alpha = max(0, 0.8 - wave_progress)

	# Update fear symbols
	for symbol in fear_symbols:
		if elapsed > symbol.delay:
			var sym_progress = (elapsed - symbol.delay) / 0.5
			symbol.distance = sym_progress * 60
			symbol.alpha = max(0, 0.8 - sym_progress * 0.8)

	# Update shadow particles
	for p in shadow_particles:
		p.pos += p.velocity * delta
		p.velocity.y -= delta * 20  # Float up slightly
		p.alpha = max(0, 0.6 - progress * 0.8)
		p.size = max(4, p.size - delta * 5)

	queue_redraw()

func _draw() -> void:
	# Draw shadow particles
	for p in shadow_particles:
		if p.alpha > 0:
			var color = Color(0.2, 0.1, 0.25, p.alpha * 0.5)
			_draw_pixel_circle(p.pos, p.size, color)

	# Draw dark aura
	if aura_alpha > 0:
		var aura_color = Color(0.3, 0.15, 0.35, aura_alpha * 0.5)
		_draw_pixel_circle(Vector2.ZERO, aura_radius, aura_color)

	# Draw fear waves (dark purple rings)
	for wave in fear_waves:
		if wave.alpha > 0 and wave.radius > 5:
			var color = Color(0.4, 0.2, 0.5, wave.alpha * 0.6)
			_draw_pixel_ring(Vector2.ZERO, wave.radius, color, 6)

	# Draw fear symbols
	for symbol in fear_symbols:
		if symbol.alpha > 0:
			var pos = Vector2(cos(symbol.angle), sin(symbol.angle)) * symbol.distance
			var color = Color(0.5, 0.2, 0.4, symbol.alpha)
			_draw_fear_symbol(pos, color)

	# Draw center (menacing eye)
	var eye_alpha = 1.0 - elapsed / duration * 0.5
	var eye_color = Color(0.8, 0.2, 0.3, eye_alpha)
	_draw_menacing_eye(Vector2.ZERO, eye_color)

func _draw_fear_symbol(center: Vector2, color: Color) -> void:
	# Simple skull-like shape
	# Head circle
	_draw_pixel_circle(center, 6, color)
	# Eyes (darker)
	var eye_color = Color(0.1, 0.05, 0.1, color.a)
	draw_rect(Rect2((center + Vector2(-3, -2)) / pixel_size * pixel_size, Vector2(pixel_size, pixel_size)), eye_color)
	draw_rect(Rect2((center + Vector2(2, -2)) / pixel_size * pixel_size, Vector2(pixel_size, pixel_size)), eye_color)

func _draw_menacing_eye(center: Vector2, color: Color) -> void:
	# Central glowing eye
	_draw_pixel_circle(center, 10, Color(color.r * 0.5, color.g * 0.5, color.b * 0.5, color.a * 0.6))
	_draw_pixel_circle(center, 5, color)
	# Pupil
	var pupil_color = Color(0.1, 0.05, 0.1, color.a)
	var snapped = (center / pixel_size).floor() * pixel_size
	draw_rect(Rect2(snapped, Vector2(pixel_size, pixel_size)), pupil_color)

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 2)
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
