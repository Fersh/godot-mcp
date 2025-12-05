extends Node2D

# Bladestorm - T3 Spin with ultimate blade tornado

var pixel_size := 4
var duration := 0.9
var elapsed := 0.0

# Multiple spinning blade layers
var blade_layers := []
var num_layers := 4
var rotation_speed := 20.0

# Flying blade particles
var blade_particles := []
var num_particles := 20

# Slash trails
var slash_trails := []
var num_trails := 12

# Central storm eye
var storm_eye_alpha := 0.0

func _ready() -> void:
	# Initialize blade layers
	for i in range(num_layers):
		blade_layers.append({
			"radius": 40 + i * 20,
			"num_blades": 4 + i * 2,
			"rotation": randf() * TAU,
			"speed": rotation_speed * (1.0 - i * 0.15),
			"alpha": 0.9 - i * 0.1
		})

	# Initialize blade particles
	for i in range(num_particles):
		var angle = randf() * TAU
		blade_particles.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(30, 80),
			"velocity": Vector2(cos(angle + PI/2), sin(angle + PI/2)) * randf_range(100, 200),
			"rotation": randf() * TAU,
			"alpha": 0.8
		})

	# Initialize slash trails
	for i in range(num_trails):
		slash_trails.append({
			"angle": randf() * TAU,
			"radius": randf_range(50, 90),
			"length": randf_range(0.5, 1.0),
			"alpha": 0.0,
			"trigger_time": randf() * 0.5
		})

	await get_tree().create_timer(duration + 0.15).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Storm eye
	storm_eye_alpha = ease(min(progress * 2, 1.0), 0.3) * (1.0 - progress * 0.3)

	# Update blade layers
	for layer in blade_layers:
		layer.rotation += layer.speed * delta
		layer.alpha = (0.9 - blade_layers.find(layer) * 0.1) * (1.0 - progress * 0.4)

	# Update blade particles
	for p in blade_particles:
		p.pos += p.velocity * delta
		p.velocity = p.velocity.rotated(delta * 3)  # Curve path
		p.rotation += delta * 15
		p.alpha = max(0, 0.8 - progress)

	# Update slash trails
	for trail in slash_trails:
		if elapsed > trail.trigger_time:
			var age = elapsed - trail.trigger_time
			if age < 0.1:
				trail.alpha = age / 0.1
			else:
				trail.alpha = max(0, 1.0 - (age - 0.1) / 0.3)
			trail.angle += delta * 10

	queue_redraw()

func _draw() -> void:
	# Draw storm eye
	if storm_eye_alpha > 0:
		var eye_color = Color(0.3, 0.35, 0.5, storm_eye_alpha * 0.5)
		_draw_pixel_circle(Vector2.ZERO, 25, eye_color)
		var eye_edge = Color(0.6, 0.65, 0.8, storm_eye_alpha * 0.4)
		_draw_pixel_ring(Vector2.ZERO, 25, eye_edge, 4)

	# Draw slash trails
	for trail in slash_trails:
		if trail.alpha > 0:
			var color = Color(0.9, 0.92, 1.0, trail.alpha * 0.6)
			_draw_slash_arc(trail.angle, trail.radius, trail.length, color)

	# Draw blade layers
	for layer in blade_layers:
		if layer.alpha > 0:
			for i in range(layer.num_blades):
				var blade_angle = layer.rotation + (float(i) / layer.num_blades) * TAU
				var blade_pos = Vector2(cos(blade_angle), sin(blade_angle)) * layer.radius
				_draw_spinning_blade(blade_pos, blade_angle, layer.alpha)

	# Draw blade particles
	for p in blade_particles:
		if p.alpha > 0:
			_draw_small_blade(p.pos, p.rotation, p.alpha)

func _draw_spinning_blade(pos: Vector2, angle: float, alpha: float) -> void:
	var blade_color = Color(0.85, 0.88, 0.95, alpha)
	var edge_color = Color(1.0, 1.0, 1.0, alpha * 0.8)
	var blade_length = 18

	# Main blade
	var tip = pos + Vector2(cos(angle), sin(angle)) * blade_length
	_draw_pixel_line(pos, tip, blade_color)

	# Edge gleam
	var gleam_pos = pos + Vector2(cos(angle), sin(angle)) * (blade_length * 0.7)
	gleam_pos = (gleam_pos / pixel_size).floor() * pixel_size
	draw_rect(Rect2(gleam_pos, Vector2(pixel_size, pixel_size)), edge_color)

func _draw_small_blade(pos: Vector2, rotation: float, alpha: float) -> void:
	var color = Color(0.8, 0.82, 0.9, alpha)
	var length = 10

	var tip = pos + Vector2(cos(rotation), sin(rotation)) * length
	_draw_pixel_line(pos, tip, color)

func _draw_slash_arc(start_angle: float, radius: float, arc_length: float, color: Color) -> void:
	var steps = int(arc_length * radius / pixel_size) + 6
	for i in range(steps):
		var t = float(i) / steps
		var angle = start_angle + t * arc_length
		var fade = 1.0 - t
		var pos = Vector2(cos(angle), sin(angle)) * radius
		pos = (pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), Color(color.r, color.g, color.b, color.a * fade))

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
