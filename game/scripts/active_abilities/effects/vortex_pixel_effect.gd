extends Node2D

# Vortex - T2 Spin with intense spinning tornado effect

var pixel_size := 4
var duration := 0.75
var elapsed := 0.0
var follow_target: Node2D = null

# Rotating blade arcs
var blade_arcs := []
var num_blades := 6
var rotation_speed := 15.0

# Vortex wind particles
var wind_particles := []
var num_wind := 20

# Central spin blur
var blur_rings := []
var num_rings := 4

func _ready() -> void:
	# Initialize blade arcs (more blades for vortex)
	for i in range(num_blades):
		blade_arcs.append({
			"base_angle": (i * TAU / num_blades),
			"radius": randf_range(40, 65),
			"arc_length": randf_range(0.4, 0.7),
			"alpha": 0.9
		})

	# Initialize wind particles (spiral pattern)
	for i in range(num_wind):
		var angle = randf() * TAU
		wind_particles.append({
			"angle": angle,
			"distance": randf_range(25, 80),
			"alpha": 0.6,
			"speed": randf_range(8, 14)
		})

	# Initialize blur rings
	for i in range(num_rings):
		blur_rings.append({
			"radius": 20 + i * 15,
			"alpha": 0.5 - i * 0.1,
			"rotation": randf() * TAU
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func set_follow_target(target: Node2D) -> void:
	follow_target = target

func _process(delta: float) -> void:
	# Follow target if set
	if follow_target and is_instance_valid(follow_target):
		global_position = follow_target.global_position

	elapsed += delta
	var progress = elapsed / duration

	# Update blade arcs
	for arc in blade_arcs:
		arc.base_angle += rotation_speed * delta
		arc.alpha = 0.9 * (1.0 - progress * 0.4)

	# Update wind particles (fast spiral)
	for p in wind_particles:
		p.angle += p.speed * delta
		p.alpha = 0.6 * (1.0 - progress)

	# Update blur rings
	for ring in blur_rings:
		ring.rotation += rotation_speed * 0.8 * delta
		ring.alpha = max(0, (0.5 - blur_rings.find(ring) * 0.1) * (1.0 - progress))

	queue_redraw()

func _draw() -> void:
	# Draw blur rings (motion blur effect)
	for ring in blur_rings:
		if ring.alpha > 0:
			var color = Color(0.7, 0.75, 0.85, ring.alpha * 0.4)
			_draw_pixel_ring(Vector2.ZERO, ring.radius, color, 6)

	# Draw wind particles
	for p in wind_particles:
		if p.alpha > 0:
			var pos = Vector2(cos(p.angle), sin(p.angle)) * p.distance
			var color = Color(0.8, 0.85, 0.95, p.alpha)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)
			# Wind trail
			var trail_angle = p.angle - 0.3
			var trail_pos = Vector2(cos(trail_angle), sin(trail_angle)) * p.distance
			trail_pos = (trail_pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(trail_pos, Vector2(pixel_size, pixel_size)), Color(0.7, 0.75, 0.9, p.alpha * 0.4))

	# Draw blade arcs (silver/white)
	for arc in blade_arcs:
		if arc.alpha > 0:
			# Main blade
			var blade_color = Color(0.9, 0.92, 1.0, arc.alpha)
			_draw_pixel_arc(Vector2.ZERO, arc.radius, arc.base_angle, arc.arc_length, blade_color)
			# Edge gleam
			var gleam_color = Color(1.0, 1.0, 1.0, arc.alpha * 0.8)
			_draw_pixel_arc(Vector2.ZERO, arc.radius + pixel_size, arc.base_angle + 0.1, arc.arc_length * 0.5, gleam_color)

	# Draw center vortex eye
	var center_alpha = 1.0 - elapsed / duration
	if center_alpha > 0:
		var center_color = Color(0.3, 0.35, 0.5, center_alpha * 0.6)
		_draw_pixel_circle(Vector2.ZERO, 15, center_color)
		var eye_color = Color(0.6, 0.65, 0.8, center_alpha * 0.4)
		_draw_pixel_ring(Vector2.ZERO, 15, eye_color, 4)

func _draw_pixel_arc(center: Vector2, radius: float, start_angle: float, arc_length: float, color: Color) -> void:
	var steps = int(arc_length * radius / pixel_size) + 6
	for i in range(steps):
		var t = float(i) / steps
		var angle = start_angle + t * arc_length
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		pos = (pos / pixel_size).floor() * pixel_size
		var fade = 1.0 - t * 0.5
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), Color(color.r, color.g, color.b, color.a * fade))

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 4)
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
