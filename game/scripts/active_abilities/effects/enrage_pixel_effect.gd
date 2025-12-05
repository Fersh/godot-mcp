extends Node2D

# Enrage - T2 Roar with self-buff rage effect

var pixel_size := 4
var duration := 0.75
var elapsed := 0.0

# Rage aura (red/orange pulsing)
var rage_aura_alpha := 0.0
var rage_aura_radius := 45.0

# Rising rage particles
var rage_particles := []
var num_particles := 16

# Veins/energy lines
var energy_lines := []
var num_lines := 8

# Power burst ring
var burst_radius := 0.0
var max_burst := 65.0

func _ready() -> void:
	# Initialize rage particles
	for i in range(num_particles):
		var angle = randf() * TAU
		rage_particles.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(10, 30),
			"velocity": Vector2(0, randf_range(-80, -120)),
			"alpha": 0.8,
			"size": randf_range(4, 8)
		})

	# Initialize energy lines (radial)
	for i in range(num_lines):
		energy_lines.append({
			"angle": (i * TAU / num_lines) + randf() * 0.2,
			"length": 0.0,
			"max_length": randf_range(35, 55),
			"pulse_offset": randf() * TAU
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Rage aura intensifies
	rage_aura_alpha = (0.7 + 0.2 * sin(elapsed * 12)) * (1.0 - progress * 0.3)

	# Burst ring expands
	burst_radius = ease(min(progress * 2, 1.0), 0.3) * max_burst

	# Update rage particles
	for p in rage_particles:
		p.pos += p.velocity * delta
		p.alpha = max(0, 0.8 - progress)
		# Reset if too high
		if p.pos.y < -60:
			p.pos.y = randf_range(10, 30)
			p.pos.x = randf_range(-25, 25)

	# Update energy lines (pulse outward)
	for line in energy_lines:
		var pulse = sin(elapsed * 8 + line.pulse_offset) * 0.3 + 0.7
		line.length = pulse * line.max_length * min(progress * 3, 1.0)

	queue_redraw()

func _draw() -> void:
	# Draw burst ring
	if burst_radius > 5:
		var ring_alpha = max(0, 1.0 - burst_radius / max_burst) * 0.5
		var ring_color = Color(1.0, 0.4, 0.1, ring_alpha)
		_draw_pixel_ring(Vector2.ZERO, burst_radius, ring_color, 6)

	# Draw rage aura
	if rage_aura_alpha > 0:
		var aura_color = Color(1.0, 0.3, 0.1, rage_aura_alpha * 0.4)
		_draw_pixel_circle(Vector2.ZERO, rage_aura_radius, aura_color)
		# Inner hot core
		var core_color = Color(1.0, 0.6, 0.2, rage_aura_alpha * 0.6)
		_draw_pixel_circle(Vector2.ZERO, rage_aura_radius * 0.5, core_color)

	# Draw energy lines
	for line in energy_lines:
		if line.length > 0:
			var color = Color(1.0, 0.5, 0.2, 0.7 * (1.0 - elapsed/duration))
			var end = Vector2(cos(line.angle), sin(line.angle)) * line.length
			_draw_pixel_line(Vector2.ZERO, end, color)

	# Draw rage particles (rising flames)
	for p in rage_particles:
		if p.alpha > 0:
			# Gradient from yellow to red
			var heat = (p.pos.y + 60) / 90  # 0 at bottom, 1 at top
			var r = 1.0
			var g = 0.8 - heat * 0.5
			var b = 0.2 - heat * 0.15
			var color = Color(r, g, b, p.alpha)
			_draw_pixel_circle(p.pos, p.size, color)

	# Draw rage symbol at center (angry face/marks)
	var symbol_alpha = 1.0 - elapsed / duration * 0.5
	_draw_rage_symbol(Vector2.ZERO, Color(1.0, 0.9, 0.5, symbol_alpha))

func _draw_rage_symbol(center: Vector2, color: Color) -> void:
	# Angry eyebrows / rage marks
	# Left mark
	_draw_pixel_line(center + Vector2(-12, -8), center + Vector2(-4, -4), color)
	# Right mark
	_draw_pixel_line(center + Vector2(12, -8), center + Vector2(4, -4), color)
	# Center vertical line
	_draw_pixel_line(center + Vector2(0, -6), center + Vector2(0, 6), Color(color.r, color.g, color.b, color.a * 0.5))

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
