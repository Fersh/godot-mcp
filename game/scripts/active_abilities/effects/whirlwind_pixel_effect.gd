extends Node2D

# Whirlwind - Procedural pixelated spinning attack effect
# Rotating slash arcs with wind particles and dust vortex

var radius: float = 120.0
var duration: float = 2.0
var pixel_size: int = 4

var _time: float = 0.0
var _slash_arcs: Array[Dictionary] = []
var _wind_particles: Array[Dictionary] = []
var _dust_vortex: Array[Dictionary] = []

# Whirlwind colors
const SLASH_COLOR = Color(0.95, 0.95, 1.0, 0.9)  # Bright slash
const WIND_COLOR = Color(0.8, 0.85, 0.95, 0.5)  # Light blue wind
const DUST_COLOR = Color(0.65, 0.6, 0.5, 0.4)  # Brown dust
const TRAIL_COLOR = Color(0.7, 0.75, 0.85, 0.6)  # Blue-ish trail

func _ready() -> void:
	_generate_slash_arcs()
	_generate_wind_particles()
	_generate_dust_vortex()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 2.0) -> void:
	radius = p_radius
	duration = p_duration

func _generate_slash_arcs() -> void:
	# Multiple rotating slash arcs
	for i in range(4):
		_slash_arcs.append({
			"base_angle": (TAU / 4) * i,
			"arc_length": PI * 0.4,
			"radius_offset": randf_range(-10, 10),
			"rotation_speed": 8.0 + randf_range(-1, 1)
		})

func _generate_wind_particles() -> void:
	var particle_count = randi_range(30, 45)
	for i in range(particle_count):
		_wind_particles.append({
			"base_angle": randf() * TAU,
			"radius": randf_range(radius * 0.3, radius * 1.1),
			"size": randi_range(2, 5),
			"orbit_speed": randf_range(5.0, 9.0),
			"radial_oscillation": randf_range(10, 25),
			"phase": randf() * TAU
		})

func _generate_dust_vortex() -> void:
	var dust_count = randi_range(20, 30)
	for i in range(dust_count):
		_dust_vortex.append({
			"base_angle": randf() * TAU,
			"radius": randf_range(radius * 0.5, radius * 0.9),
			"size": randi_range(4, 10),
			"orbit_speed": randf_range(4.0, 7.0),
			"vertical_offset": randf_range(-15, 15)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Fade in at start, fade out at end
	var fade = 1.0
	if _time < 0.1:
		fade = _time / 0.1
	elif _time > 0.85:
		fade = (1.0 - _time) / 0.15

	_draw_dust_vortex(fade)
	_draw_wind_particles(fade)
	_draw_slash_arcs(fade)
	_draw_center_vortex(fade)

func _draw_slash_arcs(fade: float) -> void:
	var current_rotation = _time * duration * 10.0  # Fast rotation

	for arc in _slash_arcs:
		var arc_angle = arc.base_angle + current_rotation * arc.rotation_speed / 10.0
		var arc_radius = radius + arc.radius_offset

		var alpha = 0.9 * fade
		if alpha <= 0:
			continue

		# Draw the arc
		var segments = 12
		for i in range(segments):
			var t = float(i) / (segments - 1)
			var angle = arc_angle - arc.arc_length * 0.5 + arc.arc_length * t
			var pos = Vector2.from_angle(angle) * arc_radius

			# Fade towards the trailing end
			var segment_alpha = (1.0 - t * 0.7) * alpha
			var color = SLASH_COLOR
			color.a = segment_alpha

			var segment_size = int((1.0 - t * 0.5) * pixel_size * 2)
			_draw_pixel_rect(pos, segment_size, color)

		# Bright leading edge
		var lead_angle = arc_angle + arc.arc_length * 0.5
		var lead_pos = Vector2.from_angle(lead_angle) * arc_radius
		var lead_color = SLASH_COLOR
		lead_color.a = alpha
		_draw_pixel_rect(lead_pos, pixel_size * 3, lead_color)

func _draw_wind_particles(fade: float) -> void:
	var current_time = _time * duration

	for particle in _wind_particles:
		var orbit_angle = particle.base_angle + current_time * particle.orbit_speed
		var current_radius = particle.radius + sin(current_time * 3.0 + particle.phase) * particle.radial_oscillation

		var pos = Vector2.from_angle(orbit_angle) * current_radius

		var alpha = 0.5 * fade
		var color = WIND_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, particle.size * pixel_size, color)

func _draw_dust_vortex(fade: float) -> void:
	var current_time = _time * duration

	for dust in _dust_vortex:
		var orbit_angle = dust.base_angle + current_time * dust.orbit_speed
		var pos = Vector2.from_angle(orbit_angle) * dust.radius
		pos.y += dust.vertical_offset

		var alpha = 0.4 * fade
		var color = DUST_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, dust.size, color)

func _draw_center_vortex(fade: float) -> void:
	# Swirling vortex at center
	var vortex_alpha = 0.4 * fade
	if vortex_alpha <= 0:
		return

	var current_rotation = _time * duration * 12.0

	var color = WIND_COLOR
	color.a = vortex_alpha

	# Draw spiral arms
	for arm in range(3):
		var arm_base_angle = (TAU / 3) * arm + current_rotation
		for i in range(8):
			var t = float(i) / 7
			var spiral_angle = arm_base_angle + t * PI * 0.5
			var spiral_radius = t * radius * 0.4
			var pos = Vector2.from_angle(spiral_angle) * spiral_radius

			var point_alpha = (1.0 - t * 0.5) * vortex_alpha
			var point_color = color
			point_color.a = point_alpha

			_draw_pixel_rect(pos, pixel_size * 2, point_color)

func _draw_pixel_rect(pos: Vector2, size: int, color: Color) -> void:
	var snapped_pos = Vector2(
		snapped(pos.x, pixel_size) - size * 0.5,
		snapped(pos.y, pixel_size) - size * 0.5
	)
	draw_rect(Rect2(snapped_pos, Vector2(size, size)), color)
