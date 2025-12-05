extends Node2D

# Taunt - Procedural pixelated aggro taunt effect
# Threatening aura with target lines and aggro symbols

var radius: float = 200.0
var duration: float = 3.0
var pixel_size: int = 4

var _time: float = 0.0
var _taunt_waves: Array[Dictionary] = []
var _aggro_symbols: Array[Dictionary] = []
var _target_lines: Array[Dictionary] = []

# Taunt colors - aggressive reds
const WAVE_COLOR = Color(0.9, 0.3, 0.2, 0.5)  # Red waves
const SYMBOL_COLOR = Color(1.0, 0.4, 0.3, 0.8)  # Bright red symbols
const LINE_COLOR = Color(0.85, 0.25, 0.2, 0.6)  # Target lines
const CORE_COLOR = Color(1.0, 0.5, 0.3, 0.9)  # Orange core

func _ready() -> void:
	_generate_taunt_waves()
	_generate_aggro_symbols()
	_generate_target_lines()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 3.0) -> void:
	radius = p_radius
	duration = p_duration

func _generate_taunt_waves() -> void:
	for i in range(3):
		_taunt_waves.append({
			"delay": i * 0.15,
			"speed": 1.0 - i * 0.1
		})

func _generate_aggro_symbols() -> void:
	var symbol_count = randi_range(6, 10)
	for i in range(symbol_count):
		var angle = randf() * TAU
		_aggro_symbols.append({
			"angle": angle,
			"radius": randf_range(radius * 0.4, radius * 0.8),
			"size": randi_range(8, 14),
			"pulse_speed": randf_range(3.0, 5.0),
			"phase": randf() * TAU
		})

func _generate_target_lines() -> void:
	var line_count = randi_range(8, 12)
	for i in range(line_count):
		var angle = (TAU / line_count) * i + randf_range(-0.1, 0.1)
		_target_lines.append({
			"angle": angle,
			"pulse_phase": randf() * TAU
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var current_time = _time * duration

	var fade = 1.0
	if _time < 0.1:
		fade = _time / 0.1
	elif _time > 0.85:
		fade = (1.0 - _time) / 0.15

	_draw_taunt_waves(fade)
	_draw_target_lines(fade, current_time)
	_draw_aggro_symbols(fade, current_time)
	_draw_core_pulse(fade, current_time)
	_draw_activation_burst()

func _draw_taunt_waves(fade: float) -> void:
	for wave in _taunt_waves:
		var wave_cycle = fmod(_time * wave.speed + wave.delay, 0.4) / 0.4
		var wave_radius = radius * wave_cycle

		var alpha = (1.0 - wave_cycle) * 0.5 * fade
		if alpha <= 0:
			continue

		var color = WAVE_COLOR
		color.a = alpha

		# Draw expanding ring
		var segments = int(wave_radius * 0.3)
		segments = max(segments, 12)
		for i in range(segments):
			var angle = (TAU / segments) * i
			var pos = Vector2.from_angle(angle) * wave_radius
			_draw_pixel_rect(pos, pixel_size * 2, color)

func _draw_target_lines(fade: float, current_time: float) -> void:
	for line in _target_lines:
		var pulse = sin(current_time * 4.0 + line.pulse_phase) * 0.2 + 0.8

		var alpha = 0.5 * fade * pulse
		if alpha <= 0:
			continue

		var color = LINE_COLOR
		color.a = alpha

		# Dashed line pointing outward
		var segments = 8
		for i in range(segments):
			if i % 2 == 0:
				continue  # Dashed
			var t_start = float(i) / segments
			var t_end = float(i + 1) / segments
			var start_dist = radius * 0.2 + radius * 0.7 * t_start
			var end_dist = radius * 0.2 + radius * 0.7 * t_end

			var start_pos = Vector2.from_angle(line.angle) * start_dist
			var end_pos = Vector2.from_angle(line.angle) * end_dist

			_draw_pixel_line(start_pos, end_pos, pixel_size, color)

func _draw_aggro_symbols(fade: float, current_time: float) -> void:
	for symbol in _aggro_symbols:
		var pulse = sin(current_time * symbol.pulse_speed + symbol.phase) * 0.3 + 0.7

		var pos = Vector2.from_angle(symbol.angle) * symbol.radius

		var alpha = 0.7 * fade * pulse
		var color = SYMBOL_COLOR
		color.a = alpha

		# Draw exclamation mark style aggro symbol
		var size = symbol.size * pulse

		# Vertical line of exclamation
		for i in range(4):
			var y_offset = -size * 0.5 + i * (size * 0.25)
			_draw_pixel_rect(pos + Vector2(0, y_offset), pixel_size * 2, color)

		# Dot at bottom
		_draw_pixel_rect(pos + Vector2(0, size * 0.4), pixel_size * 2, color)

func _draw_core_pulse(fade: float, current_time: float) -> void:
	var pulse = sin(current_time * 6.0) * 0.2 + 0.8
	var alpha = 0.5 * fade * pulse

	if alpha <= 0:
		return

	var color = CORE_COLOR
	color.a = alpha

	var core_size = 30.0 * pulse
	for x in range(-int(core_size / pixel_size), int(core_size / pixel_size) + 1):
		for y in range(-int(core_size / pixel_size), int(core_size / pixel_size) + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() < core_size * 0.5:
				var dist_factor = pos.length() / (core_size * 0.5)
				var pixel_color = color
				pixel_color.a *= (1.0 - dist_factor)
				_draw_pixel_rect(pos, pixel_size, pixel_color)

func _draw_activation_burst() -> void:
	var burst_alpha = (1.0 - _time * 5.0)
	if burst_alpha <= 0:
		return

	var color = SYMBOL_COLOR
	color.a = burst_alpha * 0.9

	# Radial burst
	var burst_radius = radius * 0.8 * _time * 2.0
	var segments = 16
	for i in range(segments):
		var angle = (TAU / segments) * i
		var pos = Vector2.from_angle(angle) * burst_radius
		_draw_pixel_rect(pos, pixel_size * 3, color)

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
