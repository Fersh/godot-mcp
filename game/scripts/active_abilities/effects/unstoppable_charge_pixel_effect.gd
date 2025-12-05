extends Node2D

# Unstoppable - T3 Charge that cannot be interrupted

var pixel_size := 4
var duration := 0.75
var elapsed := 0.0

# Unstoppable aura (golden/white)
var aura_alpha := 0.0
var aura_radius := 55.0

# Charge trail
var trail_length := 120.0
var trail_alpha := 0.0

# Power particles
var power_particles := []
var num_particles := 24

# Barrier effect
var barrier_segments := []
var num_segments := 8

# Impact shockwave
var shockwave_radius := 0.0
var max_shockwave := 80.0

func _ready() -> void:
	# Initialize power particles
	for i in range(num_particles):
		var angle = randf() * TAU
		power_particles.append({
			"pos": Vector2(randf_range(-50, 30), randf_range(-25, 25)),
			"velocity": Vector2(randf_range(-100, -50), randf_range(-30, 30)),
			"alpha": 0.8,
			"size": randf_range(4, 10)
		})

	# Initialize barrier segments
	for i in range(num_segments):
		var angle = (i * TAU / num_segments)
		barrier_segments.append({
			"angle": angle,
			"pulse": randf() * TAU,
			"alpha": 0.7
		})

	# Screen shake
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(12, 0.4)

	await get_tree().create_timer(duration + 0.15).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Aura builds and sustains
	aura_alpha = ease(min(progress * 3, 1.0), 0.3) * (1.0 - progress * 0.3)

	# Trail shows motion
	trail_alpha = 0.6 * (1.0 - progress)

	# Shockwave at end
	if progress > 0.6:
		shockwave_radius = (progress - 0.6) / 0.4 * max_shockwave

	# Update power particles
	for p in power_particles:
		p.pos += p.velocity * delta
		p.alpha = max(0, 0.8 - progress)
		# Reset if too far behind
		if p.pos.x < -70:
			p.pos.x = randf_range(-30, 30)
			p.pos.y = randf_range(-25, 25)

	# Update barrier segments
	for seg in barrier_segments:
		seg.pulse += delta * 8
		seg.alpha = (0.5 + 0.3 * sin(seg.pulse)) * (1.0 - progress * 0.4)

	queue_redraw()

func _draw() -> void:
	# Draw trail
	if trail_alpha > 0:
		var trail_color = Color(1.0, 0.9, 0.5, trail_alpha * 0.4)
		for y_off in range(-4, 5):
			_draw_pixel_line(
				Vector2(-trail_length, y_off * pixel_size * 2),
				Vector2(0, y_off * pixel_size * 2),
				Color(trail_color.r, trail_color.g, trail_color.b, trail_color.a * (1.0 - abs(y_off) / 5.0))
			)

	# Draw shockwave
	if shockwave_radius > 5:
		var wave_alpha = max(0, 1.0 - shockwave_radius / max_shockwave) * 0.5
		var wave_color = Color(1.0, 0.85, 0.4, wave_alpha)
		_draw_pixel_ring(Vector2.ZERO, shockwave_radius, wave_color, 8)

	# Draw aura
	if aura_alpha > 0:
		# Outer glow
		var outer_color = Color(1.0, 0.9, 0.5, aura_alpha * 0.4)
		_draw_pixel_circle(Vector2.ZERO, aura_radius, outer_color)
		# Inner bright
		var inner_color = Color(1.0, 0.95, 0.7, aura_alpha * 0.6)
		_draw_pixel_circle(Vector2.ZERO, aura_radius * 0.6, inner_color)

	# Draw barrier segments
	for seg in barrier_segments:
		if seg.alpha > 0:
			var color = Color(1.0, 0.95, 0.6, seg.alpha)
			var inner = Vector2(cos(seg.angle), sin(seg.angle)) * 35
			var outer = Vector2(cos(seg.angle), sin(seg.angle)) * 50
			_draw_pixel_line(inner, outer, color)

	# Draw power particles
	for p in power_particles:
		if p.alpha > 0:
			var color = Color(1.0, 0.9, 0.4, p.alpha)
			_draw_pixel_circle(p.pos, p.size, color)

	# Draw unstoppable symbol at center
	var symbol_alpha = aura_alpha * 0.8
	if symbol_alpha > 0:
		_draw_unstoppable_symbol(Vector2.ZERO, Color(1.0, 1.0, 0.9, symbol_alpha))

func _draw_unstoppable_symbol(center: Vector2, color: Color) -> void:
	# Arrow pointing forward
	var arrow_length = 20
	# Shaft
	_draw_pixel_line(center + Vector2(-arrow_length/2, 0), center + Vector2(arrow_length/2, 0), color)
	# Head
	_draw_pixel_line(center + Vector2(arrow_length/2, 0), center + Vector2(arrow_length/4, -8), color)
	_draw_pixel_line(center + Vector2(arrow_length/2, 0), center + Vector2(arrow_length/4, 8), color)

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
	var steps = max(int(circumference / pixel_size), 12)
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
