extends Node2D

# Roar - Procedural pixelated terrifying roar effect
# Expanding sound waves with fear particles and intimidation aura

var radius: float = 200.0
var duration: float = 0.8
var pixel_size: int = 4

var _time: float = 0.0
var _sound_waves: Array[Dictionary] = []
var _fear_particles: Array[Dictionary] = []
var _roar_lines: Array[Dictionary] = []

# Roar colors - intimidating reds and oranges
const WAVE_COLOR = Color(0.9, 0.4, 0.2, 0.6)  # Orange sound wave
const FEAR_COLOR = Color(0.8, 0.2, 0.3, 0.7)  # Red fear
const CORE_COLOR = Color(1.0, 0.6, 0.3, 0.9)  # Bright orange core
const LINE_COLOR = Color(0.95, 0.5, 0.2, 0.8)  # Roar lines

func _ready() -> void:
	_generate_sound_waves()
	_generate_fear_particles()
	_generate_roar_lines()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 0.8) -> void:
	radius = p_radius
	duration = p_duration

func _generate_sound_waves() -> void:
	for i in range(4):
		_sound_waves.append({
			"delay": i * 0.1,
			"thickness": (4 - i) * 3 + 2,
			"alpha_mult": 1.0 - i * 0.2
		})

func _generate_fear_particles() -> void:
	var particle_count = randi_range(20, 30)
	for i in range(particle_count):
		var angle = randf() * TAU
		_fear_particles.append({
			"angle": angle,
			"speed": randf_range(100, 200),
			"size": randi_range(3, 6),
			"delay": randf_range(0.0, 0.2),
			"wobble_speed": randf_range(8.0, 15.0),
			"wobble_amount": randf_range(10, 25)
		})

func _generate_roar_lines() -> void:
	var line_count = randi_range(12, 18)
	for i in range(line_count):
		var angle = (TAU / line_count) * i + randf_range(-0.1, 0.1)
		_roar_lines.append({
			"angle": angle,
			"length": randf_range(radius * 0.5, radius * 0.9),
			"width": randi_range(2, 4),
			"delay": randf_range(0.0, 0.1)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	_draw_sound_waves()
	_draw_roar_lines()
	_draw_fear_particles()
	_draw_core_burst()

func _draw_sound_waves() -> void:
	for wave in _sound_waves:
		var wave_time = clamp((_time - wave.delay) * 1.5, 0.0, 1.0)
		if wave_time <= 0:
			continue

		var wave_radius = radius * wave_time
		var alpha = (1.0 - wave_time) * wave.alpha_mult

		if alpha <= 0:
			continue

		var color = WAVE_COLOR
		color.a = alpha

		# Draw expanding ring
		var segments = int(wave_radius * 0.4)
		segments = max(segments, 16)
		for i in range(segments):
			var angle = (TAU / segments) * i
			var pos = Vector2.from_angle(angle) * wave_radius
			_draw_pixel_rect(pos, wave.thickness, color)

func _draw_roar_lines() -> void:
	for line in _roar_lines:
		var line_time = clamp((_time - line.delay) * 2.0, 0.0, 1.0)
		if line_time <= 0:
			continue

		var alpha = (1.0 - line_time * 0.7) * 0.8
		if alpha <= 0:
			continue

		var color = LINE_COLOR
		color.a = alpha

		var current_length = line.length * line_time
		var start_pos = Vector2.from_angle(line.angle) * 20.0
		var end_pos = Vector2.from_angle(line.angle) * current_length

		_draw_pixel_line(start_pos, end_pos, line.width, color)

func _draw_fear_particles() -> void:
	for particle in _fear_particles:
		var particle_time = clamp((_time - particle.delay) * 1.2, 0.0, 1.0)
		if particle_time <= 0:
			continue

		var alpha = (1.0 - particle_time) * 0.7
		if alpha <= 0:
			continue

		# Wobbling outward motion
		var wobble = sin(particle_time * particle.wobble_speed * TAU) * particle.wobble_amount
		var base_pos = Vector2.from_angle(particle.angle) * particle.speed * particle_time * duration
		var perp = Vector2.from_angle(particle.angle + PI * 0.5)
		var pos = base_pos + perp * wobble

		var color = FEAR_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, particle.size, color)

func _draw_core_burst() -> void:
	# Central burst at roar origin
	var burst_alpha = (1.0 - _time * 2.0)
	if burst_alpha <= 0:
		return

	var color = CORE_COLOR
	color.a = burst_alpha

	var burst_size = 40.0 * (1.0 + _time * 0.5)
	for x in range(-int(burst_size / pixel_size), int(burst_size / pixel_size) + 1):
		for y in range(-int(burst_size / pixel_size), int(burst_size / pixel_size) + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() < burst_size * 0.5:
				var dist_factor = pos.length() / (burst_size * 0.5)
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
