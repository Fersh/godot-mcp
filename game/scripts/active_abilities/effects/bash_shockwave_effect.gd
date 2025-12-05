extends Node2D

# Shockwave Shield Bash - Procedural pixelated AoE shockwave effect
# Multiple expanding energy rings with metallic/blue energy aesthetic

var radius: float = 150.0
var duration: float = 0.5
var pixel_size: int = 4

var _time: float = 0.0
var _energy_particles: Array[Dictionary] = []
var _arc_segments: Array[Dictionary] = []

# Energy shockwave colors - blue/steel theme
const RING_COLOR_INNER = Color(0.6, 0.8, 1.0, 1.0)  # Light blue
const RING_COLOR_OUTER = Color(0.3, 0.5, 0.8, 0.8)  # Darker blue
const ENERGY_COLOR = Color(0.7, 0.9, 1.0, 1.0)  # Bright energy
const SHIELD_COLOR = Color(0.5, 0.6, 0.75, 1.0)  # Steel blue
const SPARK_COLOR = Color(1.0, 1.0, 0.9, 1.0)  # White sparks

func _ready() -> void:
	_generate_energy_particles()
	_generate_arc_segments()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 0.5) -> void:
	radius = p_radius
	duration = p_duration

func _generate_energy_particles() -> void:
	var particle_count = randi_range(25, 40)
	for i in range(particle_count):
		var angle = randf() * TAU
		var dist = randf_range(0.3, 1.0) * radius
		_energy_particles.append({
			"angle": angle,
			"target_dist": dist,
			"size": randi_range(2, 5),
			"delay": randf_range(0.0, 0.15),
			"speed_mult": randf_range(0.8, 1.2)
		})

func _generate_arc_segments() -> void:
	# Generate energy arc segments around the shockwave
	var arc_count = randi_range(8, 12)
	for i in range(arc_count):
		var angle = (TAU / arc_count) * i + randf_range(-0.2, 0.2)
		var arc_length = randf_range(0.3, 0.6)
		_arc_segments.append({
			"start_angle": angle,
			"arc_length": arc_length,
			"delay": randf_range(0.0, 0.1),
			"thickness": randi_range(1, 2)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Draw multiple expanding rings
	_draw_shockwave_rings()

	# Draw energy arcs
	_draw_energy_arcs()

	# Draw energy particles
	_draw_energy_particles()

	# Draw central impact
	_draw_central_burst()

func _draw_shockwave_rings() -> void:
	# Draw 3 rings at different stages
	for ring_idx in range(3):
		var ring_delay = ring_idx * 0.1
		var ring_progress = clamp((_time - ring_delay) * 2.0, 0.0, 1.0)
		if ring_progress <= 0:
			continue

		var ring_radius = radius * ring_progress
		var ring_alpha = (1.0 - ring_progress) * (0.8 - ring_idx * 0.2)

		if ring_alpha <= 0:
			continue

		# Interpolate between inner and outer colors
		var color = RING_COLOR_INNER.lerp(RING_COLOR_OUTER, ring_idx / 2.0)
		color.a = ring_alpha

		# Draw pixelated ring with varying thickness
		var thickness = pixel_size * (3 - ring_idx)
		var segments = int(ring_radius * 0.5)
		segments = max(segments, 16)

		for i in range(segments):
			var angle = (TAU / segments) * i
			var pos = Vector2.from_angle(angle) * ring_radius
			_draw_pixel_rect(pos, thickness, color)

func _draw_energy_arcs() -> void:
	for arc in _arc_segments:
		var arc_progress = clamp((_time - arc.delay) * 2.5, 0.0, 1.0)
		if arc_progress <= 0:
			continue

		var alpha = (1.0 - _time) * 0.9
		var color = ENERGY_COLOR
		color.a = alpha

		var arc_radius = radius * arc_progress
		var arc_start = arc.start_angle
		var arc_end = arc.start_angle + arc.arc_length

		# Draw arc as series of pixels
		var arc_segments = int(arc.arc_length * arc_radius * 0.3)
		arc_segments = max(arc_segments, 8)

		for i in range(arc_segments):
			var t = float(i) / max(arc_segments - 1, 1)
			var angle = lerp(arc_start, arc_end, t)
			var pos = Vector2.from_angle(angle) * arc_radius
			_draw_pixel_rect(pos, pixel_size * arc.thickness, color)

func _draw_energy_particles() -> void:
	for particle in _energy_particles:
		var particle_progress = clamp((_time - particle.delay) * particle.speed_mult * 2.5, 0.0, 1.0)
		if particle_progress <= 0:
			continue

		var dist = particle.target_dist * particle_progress
		var pos = Vector2.from_angle(particle.angle) * dist

		# Slight wave motion
		var wave_offset = sin(particle_progress * PI * 2 + particle.angle * 3) * 5.0
		pos += Vector2.from_angle(particle.angle + PI/2) * wave_offset

		var alpha = (1.0 - particle_progress) * 0.9
		var color = SPARK_COLOR if randf() > 0.7 else ENERGY_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, particle.size * pixel_size, color)

func _draw_central_burst() -> void:
	var burst_alpha = (1.0 - _time * 2.0) * 1.0
	if burst_alpha <= 0:
		return

	# Central shield flash
	var color = SHIELD_COLOR
	color.a = burst_alpha

	var burst_size = 35.0 * (1.0 + _time * 0.5)

	# Draw pixelated burst
	for x in range(-int(burst_size / pixel_size), int(burst_size / pixel_size) + 1):
		for y in range(-int(burst_size / pixel_size), int(burst_size / pixel_size) + 1):
			var pos = Vector2(x, y) * pixel_size
			var dist = pos.length()
			if dist < burst_size * 0.7:
				var dist_factor = dist / (burst_size * 0.7)
				var pixel_color = color
				pixel_color.a *= (1.0 - dist_factor * 0.7)
				# Add energy highlight
				if dist < burst_size * 0.3:
					pixel_color = pixel_color.lightened(0.3)
				_draw_pixel_rect(pos, pixel_size, pixel_color)

	# Draw energy cross/star at center
	var cross_color = ENERGY_COLOR
	cross_color.a = burst_alpha
	var cross_size = 20.0 * (1.0 - _time * 0.5)

	for i in range(4):
		var angle = (TAU / 4) * i + _time * 2.0  # Rotate slightly
		var end_pos = Vector2.from_angle(angle) * cross_size
		_draw_pixel_line(Vector2.ZERO, end_pos, pixel_size, cross_color)

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
