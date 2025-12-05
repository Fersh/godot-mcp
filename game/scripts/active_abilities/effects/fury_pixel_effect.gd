extends Node2D

# Fury - T2 Rampage with damage boost aura

var pixel_size := 4
var duration := 0.85
var elapsed := 0.0

# Intense red aura
var aura_intensity := 0.0
var aura_radius := 50.0

# Rage flames
var flames := []
var num_flames := 16

# Power particles rising
var power_particles := []
var num_particles := 12

# Damage boost indicator
var boost_ring_radius := 0.0
var max_boost_radius := 60.0

func _ready() -> void:
	# Initialize flames (around character)
	for i in range(num_flames):
		var angle = (i * TAU / num_flames)
		flames.append({
			"base_angle": angle,
			"radius": randf_range(25, 40),
			"height": randf_range(15, 30),
			"alpha": 0.8,
			"flicker": randf() * TAU
		})

	# Initialize power particles
	for i in range(num_particles):
		var angle = randf() * TAU
		power_particles.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(15, 35),
			"velocity": Vector2(0, randf_range(-60, -100)),
			"alpha": 0.9,
			"size": randf_range(4, 8)
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Aura builds up then sustains
	if progress < 0.3:
		aura_intensity = progress / 0.3
	else:
		aura_intensity = 1.0 - (progress - 0.3) / 0.7 * 0.3

	# Boost ring expands
	boost_ring_radius = ease(min(progress * 2, 1.0), 0.3) * max_boost_radius

	# Update flames
	for flame in flames:
		flame.flicker += delta * 10
		flame.alpha = (0.6 + 0.3 * sin(flame.flicker)) * (1.0 - progress * 0.4)

	# Update power particles
	for p in power_particles:
		p.pos += p.velocity * delta
		p.alpha = max(0, 0.9 - progress)
		# Reset when too high
		if p.pos.y < -50:
			p.pos.y = randf_range(10, 30)
			p.pos.x = randf_range(-30, 30)

	queue_redraw()

func _draw() -> void:
	# Draw outer boost ring
	if boost_ring_radius > 10:
		var ring_alpha = (1.0 - boost_ring_radius / max_boost_radius) * 0.5
		var ring_color = Color(1.0, 0.3, 0.1, ring_alpha)
		_draw_pixel_ring(Vector2.ZERO, boost_ring_radius, ring_color, 6)

	# Draw aura glow (intense red)
	if aura_intensity > 0:
		var aura_color = Color(1.0, 0.2, 0.1, aura_intensity * 0.4)
		_draw_pixel_circle(Vector2.ZERO, aura_radius * aura_intensity, aura_color)

	# Draw flames
	for flame in flames:
		if flame.alpha > 0:
			var base_pos = Vector2(cos(flame.base_angle), sin(flame.base_angle)) * flame.radius
			var flicker_height = flame.height * (0.7 + 0.3 * sin(flame.flicker))

			# Flame gradient (yellow core, orange middle, red outer)
			var core_color = Color(1.0, 0.9, 0.4, flame.alpha)
			var mid_color = Color(1.0, 0.5, 0.1, flame.alpha * 0.8)
			var outer_color = Color(0.9, 0.2, 0.1, flame.alpha * 0.5)

			# Draw flame layers
			_draw_flame(base_pos, flicker_height, outer_color, 1.2)
			_draw_flame(base_pos, flicker_height * 0.7, mid_color, 0.9)
			_draw_flame(base_pos, flicker_height * 0.4, core_color, 0.6)

	# Draw power particles
	for p in power_particles:
		if p.alpha > 0:
			var color = Color(1.0, 0.6, 0.2, p.alpha)
			_draw_pixel_circle(p.pos, p.size, color)

func _draw_flame(base: Vector2, height: float, color: Color, width_scale: float) -> void:
	var base_width = 8 * width_scale
	for y in range(int(height / pixel_size)):
		var t = float(y) / (height / pixel_size)
		var row_width = base_width * (1.0 - t)
		for x in range(int(-row_width / pixel_size), int(row_width / pixel_size) + 1):
			var pos = base + Vector2(x * pixel_size, -y * pixel_size)
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
