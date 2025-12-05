extends Node2D

# Rampage - Procedural pixelated rage aura effect
# Pulsing red/orange aura with energy particles and rage flames

var radius: float = 60.0
var duration: float = 5.0
var pixel_size: int = 4

var _time: float = 0.0
var _aura_particles: Array[Dictionary] = []
var _rage_flames: Array[Dictionary] = []
var _energy_wisps: Array[Dictionary] = []

# Rampage colors - fiery rage
const AURA_COLOR = Color(0.9, 0.3, 0.1, 0.5)  # Red-orange aura
const FLAME_COLOR = Color(1.0, 0.5, 0.1, 0.8)  # Orange flames
const CORE_COLOR = Color(1.0, 0.8, 0.3, 0.9)  # Yellow core
const WISP_COLOR = Color(0.95, 0.4, 0.2, 0.6)  # Red wisps

func _ready() -> void:
	_generate_aura_particles()
	_generate_rage_flames()
	_generate_energy_wisps()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 5.0) -> void:
	radius = p_radius
	duration = p_duration

func _generate_aura_particles() -> void:
	var particle_count = randi_range(20, 30)
	for i in range(particle_count):
		_aura_particles.append({
			"angle": randf() * TAU,
			"radius": randf_range(radius * 0.4, radius * 1.0),
			"size": randi_range(3, 7),
			"orbit_speed": randf_range(1.5, 3.0),
			"pulse_speed": randf_range(2.0, 4.0),
			"phase": randf() * TAU
		})

func _generate_rage_flames() -> void:
	var flame_count = randi_range(8, 12)
	for i in range(flame_count):
		var angle = (TAU / flame_count) * i + randf_range(-0.2, 0.2)
		_rage_flames.append({
			"base_angle": angle,
			"height": randf_range(25, 45),
			"width": randi_range(8, 14),
			"flicker_speed": randf_range(8.0, 15.0),
			"phase": randf() * TAU
		})

func _generate_energy_wisps() -> void:
	var wisp_count = randi_range(6, 10)
	for i in range(wisp_count):
		_energy_wisps.append({
			"start_angle": randf() * TAU,
			"radius": randf_range(radius * 0.6, radius * 0.9),
			"rise_speed": randf_range(40, 80),
			"size": randi_range(2, 4),
			"lifespan": randf_range(0.3, 0.6),
			"spawn_interval": randf_range(0.1, 0.3),
			"last_spawn": 0.0
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var current_time = _time * duration

	# Fade in at start, fade out at end
	var fade = 1.0
	if _time < 0.05:
		fade = _time / 0.05
	elif _time > 0.9:
		fade = (1.0 - _time) / 0.1

	_draw_aura_glow(fade)
	_draw_aura_particles(fade, current_time)
	_draw_rage_flames(fade, current_time)
	_draw_energy_wisps(fade, current_time)

func _draw_aura_glow(fade: float) -> void:
	# Pulsing central aura glow
	var pulse = sin(_time * duration * 4.0) * 0.2 + 0.8
	var aura_alpha = 0.4 * fade * pulse

	if aura_alpha <= 0:
		return

	var color = AURA_COLOR
	color.a = aura_alpha

	# Draw circular aura
	var segments = 24
	for i in range(segments):
		var angle = (TAU / segments) * i
		for r in range(3):
			var ring_radius = radius * (0.5 + r * 0.2)
			var pos = Vector2.from_angle(angle) * ring_radius

			var ring_alpha = aura_alpha * (1.0 - r * 0.25)
			var ring_color = color
			ring_color.a = ring_alpha

			_draw_pixel_rect(pos, pixel_size * 2, ring_color)

func _draw_aura_particles(fade: float, current_time: float) -> void:
	for particle in _aura_particles:
		var orbit_angle = particle.angle + current_time * particle.orbit_speed
		var pulse = sin(current_time * particle.pulse_speed + particle.phase) * 0.3 + 0.7

		var current_radius = particle.radius * pulse
		var pos = Vector2.from_angle(orbit_angle) * current_radius

		var alpha = 0.6 * fade * pulse
		var color = AURA_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, particle.size, color)

func _draw_rage_flames(fade: float, current_time: float) -> void:
	for flame in _rage_flames:
		var flicker = sin(current_time * flame.flicker_speed + flame.phase) * 0.3 + 0.7
		var current_height = flame.height * flicker

		var base_pos = Vector2.from_angle(flame.base_angle) * radius * 0.7

		# Draw flame as series of rects going upward
		var segments = 6
		for i in range(segments):
			var t = float(i) / (segments - 1)
			var flame_width = flame.width * (1.0 - t * 0.7) * flicker
			var flame_y = -t * current_height

			var pos = base_pos + Vector2(0, flame_y).rotated(flame.base_angle - PI * 0.5)

			# Color gradient from core to flame
			var color_t = t
			var color = CORE_COLOR.lerp(FLAME_COLOR, color_t)
			color.a = (1.0 - t * 0.4) * fade * flicker

			_draw_pixel_rect(pos, int(flame_width), color)

func _draw_energy_wisps(fade: float, current_time: float) -> void:
	# Rising energy wisps that spawn periodically
	for wisp in _energy_wisps:
		# Calculate current wisp phase
		var cycle_time = fmod(current_time, wisp.spawn_interval + wisp.lifespan)
		if cycle_time > wisp.lifespan:
			continue

		var wisp_progress = cycle_time / wisp.lifespan

		var base_pos = Vector2.from_angle(wisp.start_angle) * wisp.radius
		var rise_offset = Vector2(0, -wisp_progress * wisp.rise_speed * wisp.lifespan)
		var pos = base_pos + rise_offset.rotated(wisp.start_angle - PI * 0.5)

		var alpha = sin(wisp_progress * PI) * 0.7 * fade
		var color = WISP_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, wisp.size * pixel_size, color)

func _draw_pixel_rect(pos: Vector2, size: int, color: Color) -> void:
	var snapped_pos = Vector2(
		snapped(pos.x, pixel_size) - size * 0.5,
		snapped(pos.y, pixel_size) - size * 0.5
	)
	draw_rect(Rect2(snapped_pos, Vector2(size, size)), color)
