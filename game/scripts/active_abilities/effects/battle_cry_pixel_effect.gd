extends Node2D

# Battle Cry (Shout) - Procedural pixelated war cry effect
# Empowering aura with ascending energy and buff particles

var radius: float = 80.0
var duration: float = 5.0
var pixel_size: int = 4

var _time: float = 0.0
var _aura_rings: Array[Dictionary] = []
var _energy_particles: Array[Dictionary] = []
var _ascending_wisps: Array[Dictionary] = []

# Battle Cry colors - golden/yellow empowerment
const AURA_COLOR = Color(1.0, 0.85, 0.3, 0.5)  # Golden aura
const ENERGY_COLOR = Color(1.0, 0.9, 0.5, 0.7)  # Yellow energy
const WISP_COLOR = Color(1.0, 0.95, 0.6, 0.6)  # Light yellow wisps
const FLASH_COLOR = Color(1.0, 1.0, 0.8, 0.9)  # Bright flash

func _ready() -> void:
	_generate_aura_rings()
	_generate_energy_particles()
	_generate_ascending_wisps()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 5.0) -> void:
	radius = p_radius
	duration = p_duration

func _generate_aura_rings() -> void:
	for i in range(3):
		_aura_rings.append({
			"radius_mult": 0.6 + i * 0.2,
			"rotation_speed": (2.0 + i) * (1 if i % 2 == 0 else -1),
			"segments": 8 + i * 2
		})

func _generate_energy_particles() -> void:
	var particle_count = randi_range(15, 25)
	for i in range(particle_count):
		_energy_particles.append({
			"angle": randf() * TAU,
			"radius": randf_range(radius * 0.4, radius * 0.9),
			"size": randi_range(3, 6),
			"orbit_speed": randf_range(1.0, 2.5),
			"pulse_speed": randf_range(3.0, 6.0),
			"phase": randf() * TAU
		})

func _generate_ascending_wisps() -> void:
	var wisp_count = randi_range(8, 12)
	for i in range(wisp_count):
		_ascending_wisps.append({
			"x_offset": randf_range(-radius * 0.5, radius * 0.5),
			"rise_speed": randf_range(30, 60),
			"size": randi_range(3, 5),
			"spawn_interval": randf_range(0.15, 0.3),
			"lifespan": randf_range(0.4, 0.7)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var current_time = _time * duration

	var fade = 1.0
	if _time < 0.05:
		fade = _time / 0.05
	elif _time > 0.9:
		fade = (1.0 - _time) / 0.1

	_draw_aura_rings(fade, current_time)
	_draw_energy_particles(fade, current_time)
	_draw_ascending_wisps(fade, current_time)
	_draw_activation_burst()

func _draw_aura_rings(fade: float, current_time: float) -> void:
	for ring in _aura_rings:
		var ring_radius = radius * ring.radius_mult
		var rotation = current_time * ring.rotation_speed

		var alpha = 0.4 * fade
		if alpha <= 0:
			continue

		var color = AURA_COLOR
		color.a = alpha

		# Draw dashed ring
		var segments = ring.segments
		for i in range(segments):
			if i % 2 == 0:
				continue  # Skip every other for dashed effect
			var angle = (TAU / segments) * i + rotation
			var pos = Vector2.from_angle(angle) * ring_radius
			_draw_pixel_rect(pos, pixel_size * 2, color)

func _draw_energy_particles(fade: float, current_time: float) -> void:
	for particle in _energy_particles:
		var orbit_angle = particle.angle + current_time * particle.orbit_speed
		var pulse = sin(current_time * particle.pulse_speed + particle.phase) * 0.3 + 0.7

		var current_radius = particle.radius * pulse
		var pos = Vector2.from_angle(orbit_angle) * current_radius

		var alpha = 0.6 * fade * pulse
		var color = ENERGY_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, particle.size, color)

func _draw_ascending_wisps(fade: float, current_time: float) -> void:
	for wisp in _ascending_wisps:
		# Calculate wisp cycle
		var cycle_time = fmod(current_time, wisp.spawn_interval + wisp.lifespan)
		if cycle_time > wisp.lifespan:
			continue

		var wisp_progress = cycle_time / wisp.lifespan

		var pos = Vector2(wisp.x_offset, -wisp_progress * wisp.rise_speed * wisp.lifespan)

		var alpha = sin(wisp_progress * PI) * 0.6 * fade
		var color = WISP_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, wisp.size * pixel_size, color)

func _draw_activation_burst() -> void:
	# Initial burst when ability activates
	var burst_alpha = (1.0 - _time * 6.0)
	if burst_alpha <= 0:
		return

	var color = FLASH_COLOR
	color.a = burst_alpha * 0.8

	var burst_size = radius * 0.8 * (1.0 + _time * 2.0)

	# Radial burst lines
	var line_count = 12
	for i in range(line_count):
		var angle = (TAU / line_count) * i
		var start_pos = Vector2.from_angle(angle) * 10.0
		var end_pos = Vector2.from_angle(angle) * burst_size * _time * 3.0

		_draw_pixel_line(start_pos, end_pos, pixel_size, color)

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
