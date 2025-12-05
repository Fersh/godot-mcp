extends Node2D

# Stomp - Procedural pixelated shockwave effect
# Powerful foot stomp creating expanding shockwave with dust and debris

var radius: float = 120.0
var duration: float = 0.5
var pixel_size: int = 4

var _time: float = 0.0
var _shockwave_rings: Array[Dictionary] = []
var _dust_particles: Array[Dictionary] = []
var _debris: Array[Dictionary] = []
var _ground_cracks: Array[Dictionary] = []

# Earth/impact colors
const SHOCKWAVE_COLOR = Color(0.85, 0.75, 0.55, 0.9)  # Sandy shockwave
const DUST_COLOR = Color(0.7, 0.6, 0.45, 0.7)  # Brown dust
const DEBRIS_COLOR = Color(0.5, 0.4, 0.3, 1.0)  # Dark brown rocks
const IMPACT_COLOR = Color(0.9, 0.85, 0.7, 1.0)  # Bright impact flash
const CRACK_COLOR = Color(0.2, 0.15, 0.1, 0.9)  # Dark cracks

func _ready() -> void:
	_generate_shockwave_rings()
	_generate_dust()
	_generate_debris()
	_generate_ground_cracks()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 0.5) -> void:
	radius = p_radius
	duration = p_duration

func _generate_shockwave_rings() -> void:
	# Multiple expanding shockwave rings
	for i in range(4):
		_shockwave_rings.append({
			"delay": i * 0.06,
			"thickness": (4 - i) * 3,
			"alpha_mult": 1.0 - i * 0.2
		})

func _generate_dust() -> void:
	var dust_count = randi_range(25, 40)
	for i in range(dust_count):
		var angle = randf() * TAU
		var dist = randf_range(radius * 0.3, radius * 1.1)
		_dust_particles.append({
			"angle": angle,
			"dist": dist,
			"size": randi_range(4, 12),
			"rise_speed": randf_range(30.0, 60.0),
			"alpha_offset": randf_range(0.0, 0.3)
		})

func _generate_debris() -> void:
	var debris_count = randi_range(12, 20)
	for i in range(debris_count):
		var angle = randf() * TAU
		var dist = randf_range(20.0, radius * 0.8)
		_debris.append({
			"start_pos": Vector2.from_angle(angle) * 10.0,
			"end_pos": Vector2.from_angle(angle) * dist,
			"size": randi_range(2, 4),
			"height": randf_range(25.0, 55.0),
			"delay": randf_range(0.0, 0.1)
		})

func _generate_ground_cracks() -> void:
	var crack_count = randi_range(6, 10)
	for i in range(crack_count):
		var angle = (TAU / crack_count) * i + randf_range(-0.15, 0.15)
		var length = radius * randf_range(0.4, 0.7)
		var segments: Array[Vector2] = []

		var current_pos = Vector2.ZERO
		var segment_length = 10.0
		var current_angle = angle

		while current_pos.length() < length:
			current_angle += randf_range(-0.25, 0.25)
			current_pos += Vector2.from_angle(current_angle) * segment_length
			segments.append(current_pos)

		_ground_cracks.append({
			"segments": segments,
			"delay": randf_range(0.0, 0.08)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Draw in order: cracks, shockwave, debris, dust, impact flash
	_draw_ground_cracks()
	_draw_shockwave_rings()
	_draw_debris()
	_draw_dust()
	_draw_impact_flash()

func _draw_shockwave_rings() -> void:
	for ring in _shockwave_rings:
		var ring_time = clamp((_time - ring.delay) * 1.3, 0.0, 1.0)
		if ring_time <= 0:
			continue

		var ring_radius = radius * ring_time
		var alpha = (1.0 - ring_time) * ring.alpha_mult

		if alpha <= 0:
			continue

		var color = SHOCKWAVE_COLOR
		color.a = alpha

		# Draw pixelated ring
		var segments = int(ring_radius * 0.5)
		segments = max(segments, 16)
		for i in range(segments):
			var angle = (TAU / segments) * i
			var pos = Vector2.from_angle(angle) * ring_radius
			_draw_pixel_rect(pos, ring.thickness, color)

func _draw_ground_cracks() -> void:
	for crack in _ground_cracks:
		var crack_progress = clamp((_time - crack.delay) * 2.5, 0.0, 1.0)
		if crack_progress <= 0:
			continue

		var segments: Array = crack.segments
		var visible_count = int(segments.size() * crack_progress)

		# Fade out cracks over time
		var fade = 1.0 - (_time * 0.5)
		if fade <= 0:
			continue

		var color = CRACK_COLOR
		color.a *= fade

		var prev_pos = Vector2.ZERO
		for j in range(visible_count):
			var seg_pos: Vector2 = segments[j]
			_draw_pixel_line(prev_pos, seg_pos, pixel_size, color)
			prev_pos = seg_pos

func _draw_debris() -> void:
	for debris in _debris:
		var progress = clamp((_time - debris.delay) * 1.5, 0.0, 1.0)
		if progress <= 0:
			continue

		var start_pos: Vector2 = debris.start_pos
		var end_pos: Vector2 = debris.end_pos
		var pos = start_pos.lerp(end_pos, progress)

		# Arc trajectory
		var height = sin(progress * PI) * debris.height
		pos.y -= height

		var alpha = 1.0 - progress * 0.4
		var color = DEBRIS_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, debris.size * pixel_size, color)

func _draw_dust() -> void:
	var dust_alpha = (1.0 - _time * 0.8) * 0.8
	if dust_alpha <= 0:
		return

	for dust in _dust_particles:
		var expand = 0.3 + _time * 0.7
		var pos = Vector2.from_angle(dust.angle) * dust.dist * expand
		pos.y -= _time * dust.rise_speed  # Rise upward

		var color = DUST_COLOR
		color.a = dust_alpha * (1.0 - dust.alpha_offset)

		_draw_pixel_rect(pos, dust.size, color)

func _draw_impact_flash() -> void:
	# Bright flash at center that fades quickly
	var flash_alpha = (1.0 - _time * 5.0)
	if flash_alpha <= 0:
		return

	var color = IMPACT_COLOR
	color.a = flash_alpha

	var flash_size = 30.0 * (1.0 + _time * 1.5)
	for x in range(-int(flash_size / pixel_size), int(flash_size / pixel_size) + 1):
		for y in range(-int(flash_size / pixel_size), int(flash_size / pixel_size) + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() < flash_size * 0.5:
				var dist_factor = pos.length() / (flash_size * 0.5)
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
