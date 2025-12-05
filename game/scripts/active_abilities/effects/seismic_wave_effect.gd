extends Node2D

# Seismic Wave Effect - T2 Seismic Ground Slam
# Multiple expanding shockwave rings with pixelated rock particles

var radius: float = 150.0
var duration: float = 1.5
var wave_count: int = 3
var pixel_size: int = 4

var _time: float = 0.0
var _waves: Array[Dictionary] = []
var _rock_particles: Array[Dictionary] = []
var _ground_cracks: Array[Dictionary] = []

# Seismic colors - brown/tan earth tones
const WAVE_COLOR_INNER = Color(0.5, 0.4, 0.3, 0.9)
const WAVE_COLOR_OUTER = Color(0.35, 0.28, 0.2, 0.6)
const ROCK_COLOR = Color(0.4, 0.32, 0.22, 1.0)
const CRACK_COLOR = Color(0.15, 0.12, 0.08, 0.9)
const DUST_COLOR = Color(0.7, 0.6, 0.5, 0.5)

func _ready() -> void:
	_generate_waves()
	_generate_rocks()
	_generate_cracks()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 1.5) -> void:
	radius = p_radius
	duration = p_duration

func _generate_waves() -> void:
	for i in range(wave_count):
		_waves.append({
			"delay": i * 0.25,
			"thickness": 8 + i * 2
		})

func _generate_rocks() -> void:
	var rock_count = randi_range(25, 40)
	for i in range(rock_count):
		var angle = randf() * TAU
		var dist = randf_range(30.0, radius)
		var wave_index = randi_range(0, wave_count - 1)
		_rock_particles.append({
			"angle": angle,
			"base_dist": dist,
			"size": randi_range(2, 5),
			"height": randf_range(15.0, 45.0),
			"wave_index": wave_index,
			"offset": randf_range(-0.1, 0.1)
		})

func _generate_cracks() -> void:
	# Radial cracks that persist
	var crack_count = randi_range(10, 16)
	for i in range(crack_count):
		var angle = (TAU / crack_count) * i + randf_range(-0.15, 0.15)
		var segments: Array[Dictionary] = []
		var current_pos = Vector2.ZERO
		var length = radius * randf_range(0.7, 1.0)

		while current_pos.length() < length:
			angle += randf_range(-0.25, 0.25)
			var seg_length = randf_range(8.0, 16.0)
			var new_pos = current_pos + Vector2.from_angle(angle) * seg_length
			segments.append({"from": current_pos, "to": new_pos})
			current_pos = new_pos

		_ground_cracks.append({
			"segments": segments,
			"delay": randf_range(0.0, 0.1)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Draw cracks first (under everything)
	_draw_cracks()

	# Draw expanding wave rings
	_draw_waves()

	# Draw flying rock particles
	_draw_rocks()

	# Draw dust haze
	_draw_dust_haze()

func _draw_waves() -> void:
	for i in range(_waves.size()):
		var wave = _waves[i]
		var wave_progress = clamp((_time - wave.delay) / (1.0 - wave.delay * 0.5), 0.0, 1.0)
		if wave_progress <= 0:
			continue

		var wave_radius = radius * wave_progress
		var wave_alpha = (1.0 - wave_progress) * 0.7
		var thickness: int = wave.thickness

		# Draw pixelated ring
		var segments = int(wave_radius * 0.4)
		segments = max(segments, 20)

		for j in range(segments):
			var angle = (TAU / segments) * j
			var inner_pos = Vector2.from_angle(angle) * (wave_radius - thickness)
			var outer_pos = Vector2.from_angle(angle) * wave_radius

			var inner_color = WAVE_COLOR_INNER
			inner_color.a = wave_alpha
			var outer_color = WAVE_COLOR_OUTER
			outer_color.a = wave_alpha * 0.6

			# Draw inner and outer edge pixels
			_draw_pixel_rect(inner_pos, pixel_size * 2, inner_color)
			_draw_pixel_rect(outer_pos, pixel_size * 2, outer_color)

			# Fill between for thicker waves
			if thickness > 10:
				var mid_pos = (inner_pos + outer_pos) * 0.5
				var mid_color = inner_color.lerp(outer_color, 0.5)
				_draw_pixel_rect(mid_pos, pixel_size * 2, mid_color)

func _draw_rocks() -> void:
	for rock in _rock_particles:
		var wave = _waves[rock.wave_index]
		var wave_progress = clamp((_time - wave.delay + rock.offset) / (1.0 - wave.delay * 0.5), 0.0, 1.0)
		if wave_progress <= 0 or wave_progress >= 1:
			continue

		var current_dist = rock.base_dist * wave_progress
		var pos = Vector2.from_angle(rock.angle) * current_dist

		# Parabolic arc for height
		var height = sin(wave_progress * PI) * rock.height
		pos.y -= height

		var alpha = 1.0 - wave_progress * 0.7
		var color = ROCK_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, rock.size * pixel_size, color)

func _draw_cracks() -> void:
	var crack_alpha = 1.0 - _time * 0.3  # Cracks fade slowly

	for crack in _ground_cracks:
		var crack_progress = clamp((_time - crack.delay) * 4.0, 0.0, 1.0)
		if crack_progress <= 0:
			continue

		var segments: Array = crack.segments
		var visible_count = int(segments.size() * crack_progress)

		for j in range(visible_count):
			var seg: Dictionary = segments[j]
			var color = CRACK_COLOR
			color.a = crack_alpha
			_draw_pixel_line(seg.from, seg.to, pixel_size, color)

func _draw_dust_haze() -> void:
	var dust_alpha = _time * (1.0 - _time) * 2.0  # Peak at middle
	if dust_alpha <= 0.1:
		return

	var dust_radius = radius * (0.5 + _time * 0.5)
	var dust_count = 30

	for i in range(dust_count):
		var angle = (TAU / dust_count) * i + _time * 0.5
		var dist = dust_radius * randf_range(0.6, 1.0)
		var pos = Vector2.from_angle(angle) * dist
		pos.y -= _time * 15.0  # Float up

		var color = DUST_COLOR
		color.a = dust_alpha * randf_range(0.3, 0.7)

		_draw_pixel_rect(pos, randi_range(4, 10), color)

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
