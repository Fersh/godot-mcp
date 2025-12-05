extends Node2D

# Orbital Blades - T3 Throw circling blade storm

var pixel_size := 4
var duration := 1.2
var elapsed := 0.0

# Orbiting blades
var blades := []
var num_blades := 8

# Blade trails
var blade_trails := []

# Central vortex
var vortex_alpha := 0.0
var vortex_spin := 0.0

# Energy ring
var energy_ring_radius := 0.0
var energy_ring_alpha := 0.0

func _ready() -> void:
	# Initialize orbiting blades
	for i in range(num_blades):
		var angle = (i * TAU / num_blades)
		blades.append({
			"angle": angle,
			"radius": 50,
			"alpha": 0.0,
			"trail": []
		})

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Vortex builds
	vortex_alpha = ease(min(progress * 2, 1.0), 0.3) * (1.0 - progress * 0.3)
	vortex_spin += delta * 10 * (1.0 + progress * 2)

	# Energy ring expands then contracts
	if progress < 0.5:
		energy_ring_radius = progress * 2 * 70
		energy_ring_alpha = 0.6
	else:
		energy_ring_radius = 70 - (progress - 0.5) * 2 * 30
		energy_ring_alpha = max(0, 0.6 - (progress - 0.5) * 1.2)

	# Update blades
	var spin_speed = 8 + progress * 4
	for blade in blades:
		blade.angle += spin_speed * delta
		blade.alpha = min(progress * 3, 1.0) * (1.0 - max(0, progress - 0.8) * 5)

		# Update trail
		var pos = Vector2(cos(blade.angle), sin(blade.angle)) * blade.radius
		blade.trail.append({"pos": pos, "alpha": blade.alpha})
		if blade.trail.size() > 12:
			blade.trail.pop_front()

		# Fade trail
		for t in blade.trail:
			t.alpha = max(0, t.alpha - delta * 3)

	queue_redraw()

func _draw() -> void:
	# Draw vortex
	if vortex_alpha > 0:
		var vortex_color = Color(0.6, 0.7, 0.9, vortex_alpha * 0.4)
		_draw_pixel_circle(Vector2.ZERO, 30, vortex_color)
		# Spinning lines
		for i in range(4):
			var angle = vortex_spin + i * PI/2
			var end = Vector2(cos(angle), sin(angle)) * 25
			var line_color = Color(0.7, 0.8, 1.0, vortex_alpha * 0.5)
			_draw_pixel_line(Vector2.ZERO, end, line_color)

	# Draw energy ring
	if energy_ring_alpha > 0:
		var ring_color = Color(0.5, 0.6, 0.9, energy_ring_alpha * 0.4)
		_draw_pixel_ring(Vector2.ZERO, energy_ring_radius, ring_color, 6)

	# Draw blade trails
	for blade in blades:
		for t in blade.trail:
			if t.alpha > 0:
				var trail_color = Color(0.7, 0.75, 0.9, t.alpha * 0.4)
				var pos = (t.pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), trail_color)

	# Draw blades
	for blade in blades:
		if blade.alpha > 0:
			var pos = Vector2(cos(blade.angle), sin(blade.angle)) * blade.radius
			_draw_blade(pos, blade.angle + PI/2, blade.alpha)

func _draw_blade(center: Vector2, angle: float, alpha: float) -> void:
	var blade_color = Color(0.8, 0.85, 0.95, alpha)
	var edge_color = Color(1.0, 1.0, 1.0, alpha)

	# Blade body (elongated)
	var length = 16
	var dir = Vector2(cos(angle), sin(angle))
	var tip = center + dir * length
	var back = center - dir * length * 0.5

	# Draw blade shape
	_draw_pixel_line(back, tip, blade_color)

	# Side points
	var perp = dir.rotated(PI/2)
	_draw_pixel_line(center - perp * 4, center + perp * 4, blade_color)

	# Bright edge
	var edge_pos = (tip / pixel_size).floor() * pixel_size
	draw_rect(Rect2(edge_pos, Vector2(pixel_size, pixel_size)), edge_color)

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
