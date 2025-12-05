extends Node2D

# Fortify Taunt - T2 Taunt with defensive buff

var pixel_size := 4
var duration := 0.7
var elapsed := 0.0

# Taunt aggro lines
var aggro_lines := []
var num_lines := 8

# Fortify shield aura
var shield_alpha := 0.0
var shield_radius := 45.0

# Defense particles (rising)
var defense_particles := []
var num_particles := 12

# Fortify ring
var fortify_ring_radius := 0.0
var max_ring := 60.0

func _ready() -> void:
	# Initialize aggro lines (pointing inward)
	for i in range(num_lines):
		var angle = (i * TAU / num_lines)
		aggro_lines.append({
			"angle": angle,
			"outer_radius": randf_range(70, 90),
			"inner_radius": randf_range(25, 35),
			"alpha": 0.0,
			"delay": i * 0.03
		})

	# Initialize defense particles
	for i in range(num_particles):
		var angle = randf() * TAU
		defense_particles.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(20, 40),
			"velocity": Vector2(0, randf_range(-40, -70)),
			"alpha": 0.7,
			"size": randf_range(4, 8)
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Shield builds up
	shield_alpha = ease(min(progress * 3, 1.0), 0.3) * (1.0 - progress * 0.3)

	# Fortify ring expands
	fortify_ring_radius = ease(min(progress * 2, 1.0), 0.3) * max_ring

	# Update aggro lines
	for line in aggro_lines:
		if elapsed > line.delay:
			var age = elapsed - line.delay
			if age < 0.2:
				line.alpha = age / 0.2
			else:
				line.alpha = max(0, 1.0 - (age - 0.2) / 0.4)

	# Update defense particles
	for p in defense_particles:
		p.pos += p.velocity * delta
		p.alpha = max(0, 0.7 - progress * 0.8)

	queue_redraw()

func _draw() -> void:
	# Draw fortify ring (blue tint for defense)
	if fortify_ring_radius > 10:
		var ring_alpha = max(0, 1.0 - fortify_ring_radius / max_ring) * 0.4
		var ring_color = Color(0.4, 0.6, 0.9, ring_alpha)
		_draw_pixel_ring(Vector2.ZERO, fortify_ring_radius, ring_color, 6)

	# Draw aggro lines (red, pointing at center)
	for line in aggro_lines:
		if line.alpha > 0:
			var color = Color(1.0, 0.3, 0.2, line.alpha * 0.7)
			var outer = Vector2(cos(line.angle), sin(line.angle)) * line.outer_radius
			var inner = Vector2(cos(line.angle), sin(line.angle)) * line.inner_radius
			_draw_pixel_line(outer, inner, color)
			# Arrow head at inner end
			_draw_arrow_head(inner, line.angle + PI, color)

	# Draw shield aura (blue/cyan)
	if shield_alpha > 0:
		# Outer shield glow
		var outer_color = Color(0.4, 0.6, 1.0, shield_alpha * 0.4)
		_draw_pixel_circle(Vector2.ZERO, shield_radius, outer_color)
		# Inner shield
		var inner_color = Color(0.6, 0.8, 1.0, shield_alpha * 0.6)
		_draw_pixel_circle(Vector2.ZERO, shield_radius * 0.6, inner_color)
		# Shield edge
		var edge_color = Color(0.8, 0.9, 1.0, shield_alpha * 0.4)
		_draw_pixel_ring(Vector2.ZERO, shield_radius, edge_color, 4)

	# Draw defense particles (blue rising)
	for p in defense_particles:
		if p.alpha > 0:
			var color = Color(0.5, 0.7, 1.0, p.alpha)
			_draw_pixel_circle(p.pos, p.size, color)

	# Draw taunt symbol at center
	var symbol_alpha = 1.0 - elapsed / duration * 0.4
	_draw_taunt_symbol(Vector2.ZERO, Color(1.0, 0.4, 0.3, symbol_alpha))

func _draw_arrow_head(tip: Vector2, angle: float, color: Color) -> void:
	var size = 8
	var left = tip + Vector2(cos(angle + 2.5), sin(angle + 2.5)) * size
	var right = tip + Vector2(cos(angle - 2.5), sin(angle - 2.5)) * size
	_draw_pixel_line(tip, left, color)
	_draw_pixel_line(tip, right, color)

func _draw_taunt_symbol(center: Vector2, color: Color) -> void:
	# Exclamation mark style
	# Vertical line
	for y in range(-3, 2):
		var pos = center + Vector2(0, y * pixel_size)
		pos = (pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)
	# Dot
	var dot_pos = center + Vector2(0, 4 * pixel_size)
	dot_pos = (dot_pos / pixel_size).floor() * pixel_size
	draw_rect(Rect2(dot_pos, Vector2(pixel_size, pixel_size)), color)

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
