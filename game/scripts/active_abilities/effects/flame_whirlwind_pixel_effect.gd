extends Node2D

# Flame Whirlwind - T2 Whirlwind with fire damage

var pixel_size := 4
var duration := 0.85
var elapsed := 0.0
var follow_target: Node2D = null

# Rotating flame arcs
var flame_arcs := []
var num_arcs := 4
var rotation_speed := 10.0

# Fire particles
var fire_particles := []
var num_fire := 24

# Embers
var embers := []
var num_embers := 16

# Heat shimmer ring
var heat_ring_radius := 0.0
var max_heat_radius := 75.0

func _ready() -> void:
	# Initialize flame arcs
	for i in range(num_arcs):
		flame_arcs.append({
			"base_angle": (i * TAU / num_arcs),
			"radius": randf_range(45, 70),
			"arc_length": randf_range(0.9, 1.4),
			"alpha": 0.9
		})

	# Initialize fire particles
	for i in range(num_fire):
		var angle = randf() * TAU
		var dist = randf_range(20, 60)
		fire_particles.append({
			"pos": Vector2(cos(angle), sin(angle)) * dist,
			"velocity": Vector2(0, randf_range(-60, -100)),
			"size": randf_range(6, 12),
			"alpha": 0.8,
			"orbit_angle": angle,
			"orbit_speed": randf_range(4, 8)
		})

	# Initialize embers
	for i in range(num_embers):
		var angle = randf() * TAU
		embers.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(30, 70),
			"velocity": Vector2(randf_range(-20, 20), randf_range(-80, -40)),
			"alpha": 1.0,
			"orbit_angle": angle
		})

	await get_tree().create_timer(duration + 0.15).timeout
	queue_free()

func set_follow_target(target: Node2D) -> void:
	follow_target = target

func _process(delta: float) -> void:
	# Follow target if set
	if follow_target and is_instance_valid(follow_target):
		global_position = follow_target.global_position

	elapsed += delta
	var progress = elapsed / duration

	# Heat ring expands
	heat_ring_radius = progress * max_heat_radius

	# Update flame arcs (rotate)
	for arc in flame_arcs:
		arc.base_angle += rotation_speed * delta
		arc.alpha = 0.9 * (1.0 - progress * 0.3)

	# Update fire particles (rise and orbit)
	for p in fire_particles:
		p.orbit_angle += p.orbit_speed * delta
		var orbit_dist = 40 + sin(elapsed * 3 + p.orbit_angle) * 20
		p.pos = Vector2(cos(p.orbit_angle), sin(p.orbit_angle)) * orbit_dist
		p.pos.y += p.velocity.y * delta
		p.velocity.y += delta * 50  # Slow rise
		p.size = max(4, p.size - delta * 8)
		p.alpha = max(0, 0.8 - progress)

	# Update embers
	for e in embers:
		e.orbit_angle += delta * 5
		e.pos += e.velocity * delta
		e.velocity.y -= delta * 30  # Rise
		e.alpha = max(0, 1.0 - progress * 1.2)

	queue_redraw()

func _draw() -> void:
	# Draw heat shimmer ring
	if heat_ring_radius > 10:
		var shimmer_color = Color(1.0, 0.5, 0.2, 0.2 * (1.0 - elapsed/duration))
		_draw_pixel_ring(Vector2.ZERO, heat_ring_radius, shimmer_color, 8)

	# Draw flame arcs
	for arc in flame_arcs:
		if arc.alpha > 0:
			# Outer flame (orange)
			var outer_color = Color(1.0, 0.5, 0.1, arc.alpha * 0.8)
			_draw_pixel_arc(Vector2.ZERO, arc.radius, arc.base_angle, arc.arc_length, outer_color)
			# Core flame (yellow)
			var core_color = Color(1.0, 0.9, 0.3, arc.alpha)
			_draw_pixel_arc(Vector2.ZERO, arc.radius * 0.75, arc.base_angle + 0.1, arc.arc_length * 0.8, core_color)
			# Inner white
			var inner_color = Color(1.0, 1.0, 0.8, arc.alpha * 0.7)
			_draw_pixel_arc(Vector2.ZERO, arc.radius * 0.5, arc.base_angle + 0.15, arc.arc_length * 0.6, inner_color)

	# Draw fire particles
	for p in fire_particles:
		if p.alpha > 0:
			# Gradient from yellow core to orange edge
			var core_color = Color(1.0, 0.9, 0.4, p.alpha)
			var outer_color = Color(1.0, 0.4, 0.1, p.alpha * 0.6)
			_draw_pixel_circle(p.pos, p.size * 0.5, core_color)
			_draw_pixel_circle(p.pos, p.size, outer_color)

	# Draw embers (small bright particles)
	for e in embers:
		if e.alpha > 0:
			var color = Color(1.0, 0.7, 0.2, e.alpha)
			var pos = (e.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)
			# Glow
			var glow_color = Color(1.0, 0.5, 0.1, e.alpha * 0.4)
			draw_rect(Rect2(pos + Vector2(pixel_size, 0), Vector2(pixel_size, pixel_size)), glow_color)
			draw_rect(Rect2(pos + Vector2(-pixel_size, 0), Vector2(pixel_size, pixel_size)), glow_color)

func _draw_pixel_arc(center: Vector2, radius: float, start_angle: float, arc_length: float, color: Color) -> void:
	var steps = int(arc_length * radius / pixel_size) + 8
	for i in range(steps):
		var t = float(i) / steps
		var angle = start_angle + t * arc_length
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		pos = (pos / pixel_size).floor() * pixel_size
		var fade = 1.0 - abs(t - 0.5) * 0.5
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), Color(color.r, color.g, color.b, color.a * fade))

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
