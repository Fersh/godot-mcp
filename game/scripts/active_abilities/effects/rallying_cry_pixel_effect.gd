extends Node2D

# Rallying Cry - T2 Battle Cry with ally buff visual

var pixel_size := 4
var duration := 0.8
var elapsed := 0.0

# Golden inspiration waves
var inspire_waves := []
var num_waves := 3

# Rising morale particles (golden wisps)
var morale_particles := []
var num_particles := 20

# Banner/flag visual
var banner_alpha := 0.0
var banner_wave := 0.0

# Buff ring
var buff_ring_radius := 0.0
var max_ring := 80.0

func _ready() -> void:
	# Initialize inspiration waves
	for i in range(num_waves):
		inspire_waves.append({
			"radius": 0.0,
			"alpha": 0.8,
			"delay": i * 0.1
		})

	# Initialize morale particles
	for i in range(num_particles):
		var angle = randf() * TAU
		var dist = randf_range(20, 50)
		morale_particles.append({
			"pos": Vector2(cos(angle), sin(angle)) * dist,
			"velocity": Vector2(0, randf_range(-50, -90)),
			"alpha": 0.0,
			"size": randf_range(4, 8),
			"delay": randf() * 0.3
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Banner waves
	banner_wave = sin(elapsed * 6) * 0.2
	banner_alpha = (1.0 - progress * 0.6)

	# Buff ring expands
	buff_ring_radius = ease(min(progress * 1.5, 1.0), 0.3) * max_ring

	# Update inspiration waves
	for wave in inspire_waves:
		if elapsed > wave.delay:
			var wave_progress = (elapsed - wave.delay) / 0.5
			wave.radius = wave_progress * 90
			wave.alpha = max(0, 0.8 - wave_progress)

	# Update morale particles
	for p in morale_particles:
		if elapsed > p.delay:
			if p.alpha == 0:
				p.alpha = 0.8
			p.pos += p.velocity * delta
			p.alpha = max(0, p.alpha - delta * 1.2)

	queue_redraw()

func _draw() -> void:
	# Draw buff ring
	if buff_ring_radius > 10:
		var ring_alpha = max(0, 1.0 - buff_ring_radius / max_ring) * 0.4
		var ring_color = Color(1.0, 0.9, 0.4, ring_alpha)
		_draw_pixel_ring(Vector2.ZERO, buff_ring_radius, ring_color, 6)

	# Draw inspiration waves (golden)
	for wave in inspire_waves:
		if wave.alpha > 0 and wave.radius > 5:
			var color = Color(1.0, 0.85, 0.3, wave.alpha * 0.5)
			_draw_pixel_ring(Vector2.ZERO, wave.radius, color, 8)

	# Draw morale particles (golden wisps rising)
	for p in morale_particles:
		if p.alpha > 0:
			var color = Color(1.0, 0.9, 0.5, p.alpha)
			_draw_pixel_circle(p.pos, p.size, color)
			# Sparkle effect
			if p.size > 5:
				var sparkle_color = Color(1.0, 1.0, 0.8, p.alpha * 0.6)
				_draw_sparkle(p.pos, sparkle_color)

	# Draw banner
	if banner_alpha > 0:
		_draw_banner(Vector2.ZERO, banner_alpha, banner_wave)

	# Draw center glow
	var center_alpha = 1.0 - elapsed / duration * 0.5
	var center_color = Color(1.0, 0.95, 0.6, center_alpha * 0.6)
	_draw_pixel_circle(Vector2.ZERO, 20, center_color)

func _draw_banner(center: Vector2, alpha: float, wave_offset: float) -> void:
	var pole_color = Color(0.5, 0.4, 0.3, alpha)
	var flag_color = Color(1.0, 0.8, 0.2, alpha * 0.8)

	# Pole
	_draw_pixel_line(center + Vector2(0, 10), center + Vector2(0, -30), pole_color)

	# Flag (wavy)
	for y in range(5):
		var y_offset = -25 + y * pixel_size
		var wave = sin(wave_offset + y * 0.5) * 4
		var width = 20 - y * 2
		for x in range(int(width / pixel_size)):
			var pos = center + Vector2(x * pixel_size + 4 + wave, y_offset)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), flag_color)

func _draw_sparkle(center: Vector2, color: Color) -> void:
	var dirs = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
	for dir in dirs:
		var pos = center + dir * pixel_size * 2
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
