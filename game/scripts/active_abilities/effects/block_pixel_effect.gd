extends Node2D

# Block - Procedural pixelated shield block effect
# Solid shield with energy barrier and damage reduction glow

var radius: float = 60.0
var duration: float = 1.5
var pixel_size: int = 4

var _time: float = 0.0
var _barrier_particles: Array[Dictionary] = []
var _shield_edges: Array[Dictionary] = []

# Block colors
const SHIELD_COLOR = Color(0.5, 0.55, 0.65, 0.85)  # Steel gray shield
const BARRIER_COLOR = Color(0.6, 0.7, 0.9, 0.5)  # Blue energy barrier
const EDGE_COLOR = Color(0.8, 0.85, 0.95, 0.9)  # Bright edge
const GLOW_COLOR = Color(0.5, 0.6, 0.8, 0.4)  # Soft blue glow

func _ready() -> void:
	_generate_barrier_particles()
	_generate_shield_edges()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 1.5) -> void:
	radius = p_radius
	duration = p_duration

func _generate_barrier_particles() -> void:
	var particle_count = randi_range(15, 25)
	for i in range(particle_count):
		var angle = randf_range(-PI * 0.5, PI * 0.5)  # Front half
		_barrier_particles.append({
			"angle": angle,
			"radius": randf_range(radius * 0.7, radius * 1.1),
			"size": randi_range(3, 6),
			"drift_speed": randf_range(10, 25),
			"phase": randf() * TAU
		})

func _generate_shield_edges() -> void:
	# Hexagonal shield edge points
	for i in range(6):
		var angle = -PI * 0.4 + (PI * 0.8 / 5) * i
		_shield_edges.append({
			"angle": angle,
			"pulse_phase": randf() * TAU
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var fade = 1.0
	if _time < 0.1:
		fade = _time / 0.1
	elif _time > 0.85:
		fade = (1.0 - _time) / 0.15

	_draw_shield_glow(fade)
	_draw_shield_body(fade)
	_draw_barrier_particles(fade)
	_draw_shield_edges(fade)
	_draw_activation_flash()

func _draw_shield_glow(fade: float) -> void:
	var glow_alpha = 0.3 * fade
	if glow_alpha <= 0:
		return

	var color = GLOW_COLOR
	color.a = glow_alpha

	# Soft glow behind shield
	var glow_radius = radius * 1.3
	var segments = 20
	for i in range(segments):
		var t = float(i) / (segments - 1)
		var angle = lerp(-PI * 0.5, PI * 0.5, t)
		for r in range(3):
			var ring_radius = glow_radius * (0.7 + r * 0.15)
			var pos = Vector2.from_angle(angle) * ring_radius

			var ring_alpha = glow_alpha * (1.0 - r * 0.3)
			var ring_color = color
			ring_color.a = ring_alpha

			_draw_pixel_rect(pos, pixel_size * 2, ring_color)

func _draw_shield_body(fade: float) -> void:
	var alpha = 0.7 * fade
	if alpha <= 0:
		return

	var color = SHIELD_COLOR
	color.a = alpha

	# Draw shield as filled arc
	var segments = 12
	for i in range(segments):
		var t = float(i) / (segments - 1)
		var angle = lerp(-PI * 0.4, PI * 0.4, t)

		# Multiple layers for thickness
		for layer in range(4):
			var layer_radius = radius * (0.6 + layer * 0.1)
			var pos = Vector2.from_angle(angle) * layer_radius

			var layer_alpha = alpha * (1.0 - layer * 0.15)
			var layer_color = color
			layer_color.a = layer_alpha

			_draw_pixel_rect(pos, pixel_size * 3, layer_color)

func _draw_barrier_particles(fade: float) -> void:
	var current_time = _time * duration

	for particle in _barrier_particles:
		var drift = sin(current_time * 2.0 + particle.phase) * particle.drift_speed
		var current_radius = particle.radius + drift

		var pos = Vector2.from_angle(particle.angle) * current_radius

		var pulse = sin(current_time * 3.0 + particle.phase) * 0.3 + 0.7
		var alpha = 0.5 * fade * pulse
		var color = BARRIER_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, particle.size, color)

func _draw_shield_edges(fade: float) -> void:
	var current_time = _time * duration

	var alpha = 0.9 * fade
	if alpha <= 0:
		return

	var color = EDGE_COLOR
	color.a = alpha

	# Draw edges connecting hexagon points
	var prev_pos: Vector2
	for i in range(_shield_edges.size()):
		var edge = _shield_edges[i]
		var pulse = sin(current_time * 4.0 + edge.pulse_phase) * 0.1 + 0.9
		var edge_radius = radius * pulse

		var pos = Vector2.from_angle(edge.angle) * edge_radius

		if i > 0:
			_draw_pixel_line(prev_pos, pos, pixel_size, color)

		# Corner points brighter
		var point_color = color
		point_color.a = alpha * 1.2
		_draw_pixel_rect(pos, pixel_size * 2, point_color)

		prev_pos = pos

func _draw_activation_flash() -> void:
	var flash_alpha = (1.0 - _time * 5.0)
	if flash_alpha <= 0:
		return

	var color = EDGE_COLOR
	color.a = flash_alpha * 0.7

	var flash_size = radius * 0.6 * (1.0 + _time * 0.3)
	for x in range(0, int(flash_size / pixel_size) + 1):
		for y in range(-int(flash_size / pixel_size), int(flash_size / pixel_size) + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() < flash_size * 0.8:
				var dist_factor = pos.length() / (flash_size * 0.8)
				var pixel_color = color
				pixel_color.a *= (1.0 - dist_factor)
				_draw_pixel_rect(pos, pixel_size, pixel_color)

func _draw_pixel_rect(pos: Vector2, size: int, color: Color) -> void:
	var snapped_pos = Vector2(
		snapped(pos.x, pixel_size) - size * 0.5,
		snapped(pos.y, pixel_size) - size * 0.5
	)
	draw_rect(Rect2(snapped_pos, Vector2(size, size)), color)

func _draw_pixel_line(from: Vector2, to: Vector2, width: int, color: Color) -> void:
	var dist = from.distance_to(to)
	var steps = int(dist / pixel_size) + 1
	for i in range(steps + 1):
		var t = float(i) / max(steps, 1)
		var pos = from.lerp(to, t)
		_draw_pixel_rect(pos, width, color)
