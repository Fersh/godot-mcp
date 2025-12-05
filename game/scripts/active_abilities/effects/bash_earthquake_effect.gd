extends Node2D

# Shockwave Shield Bash of Destruction - T3 Signature
# Massive ground-shaking devastation effect with debris and multiple shockwaves

var radius: float = 250.0
var duration: float = 0.8
var pixel_size: int = 4

var _time: float = 0.0
var _fissures: Array[Dictionary] = []
var _debris: Array[Dictionary] = []
var _dust_clouds: Array[Dictionary] = []
var _energy_pillars: Array[Dictionary] = []

# Destruction colors - blue energy with earth tones
const FISSURE_COLOR = Color(0.15, 0.12, 0.1, 1.0)  # Dark crack
const ENERGY_COLOR = Color(0.4, 0.6, 0.9, 1.0)  # Blue energy glow
const ENERGY_BRIGHT = Color(0.7, 0.85, 1.0, 1.0)  # Bright energy
const DEBRIS_COLOR = Color(0.35, 0.3, 0.25, 1.0)  # Rock brown
const DUST_COLOR = Color(0.5, 0.45, 0.4, 0.6)  # Dust cloud
const RING_COLOR = Color(0.3, 0.5, 0.8, 0.8)  # Shockwave ring
const IMPACT_COLOR = Color(0.5, 0.7, 1.0, 1.0)  # Central impact

func _ready() -> void:
	_generate_fissures()
	_generate_debris()
	_generate_dust_clouds()
	_generate_energy_pillars()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 0.8) -> void:
	radius = p_radius
	duration = p_duration

func _generate_fissures() -> void:
	# Major ground cracks radiating outward
	var fissure_count = randi_range(10, 16)
	for i in range(fissure_count):
		var angle = (TAU / fissure_count) * i + randf_range(-0.15, 0.15)
		var length = radius * randf_range(0.7, 1.1)
		var segments: Array[Vector2] = []

		var current_pos = Vector2.ZERO
		var segment_length = 18.0
		var current_angle = angle

		while current_pos.length() < length:
			current_angle += randf_range(-0.25, 0.25)
			current_pos += Vector2.from_angle(current_angle) * segment_length
			segments.append(current_pos)

		_fissures.append({
			"segments": segments,
			"delay": randf_range(0.0, 0.1),
			"has_energy": randf() > 0.5  # Some fissures glow with energy
		})

func _generate_debris() -> void:
	# Large debris chunks flying upward
	var debris_count = randi_range(25, 40)
	for i in range(debris_count):
		var angle = randf() * TAU
		var dist = randf_range(30.0, radius * 0.9)
		_debris.append({
			"start_pos": Vector2.from_angle(angle) * dist * 0.2,
			"end_pos": Vector2.from_angle(angle) * dist,
			"size": randi_range(3, 7),
			"height": randf_range(40.0, 120.0),  # Higher than normal
			"delay": randf_range(0.0, 0.15),
			"rotation": randf() * TAU
		})

func _generate_dust_clouds() -> void:
	var dust_count = randi_range(30, 50)
	for i in range(dust_count):
		var angle = randf() * TAU
		var dist = randf_range(radius * 0.2, radius * 1.2)
		_dust_clouds.append({
			"pos": Vector2.from_angle(angle) * dist,
			"size": randi_range(6, 15),
			"alpha_offset": randf_range(0.0, 0.3),
			"drift": Vector2(randf_range(-1, 1), randf_range(-2, -0.5)) * 20.0
		})

func _generate_energy_pillars() -> void:
	# Vertical energy bursts at impact points
	var pillar_count = randi_range(5, 8)
	for i in range(pillar_count):
		var angle = (TAU / pillar_count) * i + randf_range(-0.3, 0.3)
		var dist = radius * randf_range(0.3, 0.7)
		_energy_pillars.append({
			"pos": Vector2.from_angle(angle) * dist,
			"height": randf_range(60.0, 100.0),
			"width": randi_range(8, 16),
			"delay": randf_range(0.05, 0.2)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Draw expanding shockwave rings
	_draw_shockwave_rings()

	# Draw ground fissures
	_draw_fissures()

	# Draw dust clouds (behind debris)
	_draw_dust_clouds()

	# Draw debris flying up
	_draw_debris()

	# Draw energy pillars
	_draw_energy_pillars()

	# Draw central massive impact
	_draw_central_impact()

func _draw_shockwave_rings() -> void:
	# Multiple powerful rings
	for ring_idx in range(4):
		var ring_delay = ring_idx * 0.08
		var ring_progress = clamp((_time - ring_delay) * 1.8, 0.0, 1.0)
		if ring_progress <= 0:
			continue

		var ring_radius = radius * ring_progress
		var ring_alpha = (1.0 - ring_progress) * (0.9 - ring_idx * 0.15)

		if ring_alpha <= 0:
			continue

		var color = RING_COLOR
		color.a = ring_alpha

		var thickness = pixel_size * (4 - ring_idx)
		var segments = int(ring_radius * 0.4)
		segments = max(segments, 20)

		for i in range(segments):
			var angle = (TAU / segments) * i
			var pos = Vector2.from_angle(angle) * ring_radius
			_draw_pixel_rect(pos, thickness, color)

func _draw_fissures() -> void:
	for fissure in _fissures:
		var fissure_progress = clamp((_time - fissure.delay) * 2.5, 0.0, 1.0)
		if fissure_progress <= 0:
			continue

		var segments: Array = fissure.segments
		var visible_count = int(segments.size() * fissure_progress)

		var prev_pos = Vector2.ZERO
		for j in range(visible_count):
			var seg_pos: Vector2 = segments[j]

			# Draw crack
			var alpha = (1.0 - _time * 0.5) * 0.95
			var crack_color = FISSURE_COLOR
			crack_color.a = alpha
			_draw_pixel_line(prev_pos, seg_pos, pixel_size * 2, crack_color)

			# Energy glow in some fissures
			if fissure.has_energy:
				var energy_alpha = alpha * 0.6 * (1.0 - _time)
				var energy_color = ENERGY_COLOR
				energy_color.a = energy_alpha
				_draw_pixel_line(prev_pos, seg_pos, pixel_size, energy_color)

			prev_pos = seg_pos

func _draw_debris() -> void:
	for debris in _debris:
		var debris_progress = clamp((_time - debris.delay) * 2.0, 0.0, 1.0)
		if debris_progress <= 0:
			continue

		var start_pos: Vector2 = debris.start_pos
		var end_pos: Vector2 = debris.end_pos
		var pos = start_pos.lerp(end_pos, debris_progress)

		# High arc trajectory (launch airborne feel)
		var height = sin(debris_progress * PI) * debris.height
		pos.y -= height

		var alpha = 1.0 - debris_progress * 0.4
		var color = DEBRIS_COLOR
		color.a = alpha

		# Draw rotated debris (pixelated)
		var size = debris.size * pixel_size
		_draw_pixel_rect(pos, size, color)

		# Smaller shadow below
		if height > 20:
			var shadow_color = Color(0, 0, 0, 0.3 * alpha)
			var shadow_pos = start_pos.lerp(end_pos, debris_progress)
			_draw_pixel_rect(shadow_pos, size - pixel_size, shadow_color)

func _draw_dust_clouds() -> void:
	var dust_alpha = (1.0 - _time * 0.7) * 0.7
	if dust_alpha <= 0:
		return

	for dust in _dust_clouds:
		var expand = 1.0 + _time * 0.4
		var pos: Vector2 = dust.pos * expand
		pos += dust.drift * _time

		var color = DUST_COLOR
		color.a = dust_alpha * (1.0 - dust.alpha_offset)

		_draw_pixel_rect(pos, dust.size, color)

func _draw_energy_pillars() -> void:
	for pillar in _energy_pillars:
		var pillar_progress = clamp((_time - pillar.delay) * 3.0, 0.0, 1.0)
		if pillar_progress <= 0:
			continue

		var rise_progress = sin(pillar_progress * PI)  # Rise then fall
		var current_height = pillar.height * rise_progress

		if current_height <= 0:
			continue

		var alpha = rise_progress * 0.8
		var base_pos: Vector2 = pillar.pos

		# Draw vertical pillar
		var steps = int(current_height / pixel_size)
		for i in range(steps):
			var y_offset = -i * pixel_size
			var pos = base_pos + Vector2(0, y_offset)

			# Fade toward top
			var height_factor = float(i) / steps
			var pillar_alpha = alpha * (1.0 - height_factor * 0.5)

			var color = ENERGY_COLOR.lerp(ENERGY_BRIGHT, height_factor)
			color.a = pillar_alpha

			# Width varies (thicker at base)
			var width = pillar.width * (1.0 - height_factor * 0.4)
			_draw_pixel_rect(pos, int(width), color)

func _draw_central_impact() -> void:
	var impact_alpha = (1.0 - _time * 1.2) * 1.0
	if impact_alpha <= 0:
		return

	# Massive central burst
	var color = IMPACT_COLOR
	color.a = impact_alpha

	var impact_size = 60.0 * (1.0 + _time * 0.8)

	# Draw impact crater
	for x in range(-int(impact_size / pixel_size), int(impact_size / pixel_size) + 1):
		for y in range(-int(impact_size / pixel_size), int(impact_size / pixel_size) + 1):
			var pos = Vector2(x, y) * pixel_size
			var dist = pos.length()
			if dist < impact_size * 0.8:
				var dist_factor = dist / (impact_size * 0.8)
				var pixel_color = color
				pixel_color.a *= (1.0 - dist_factor * 0.6)

				# Inner bright core
				if dist < impact_size * 0.3:
					pixel_color = ENERGY_BRIGHT
					pixel_color.a = impact_alpha * (1.0 - dist / (impact_size * 0.3) * 0.3)

				_draw_pixel_rect(pos, pixel_size, pixel_color)

	# Energy star burst
	var star_color = ENERGY_BRIGHT
	star_color.a = impact_alpha
	var star_size = 80.0 * (1.0 + _time * 0.5)

	for i in range(8):
		var angle = (TAU / 8) * i + _time * 1.5
		var end_pos = Vector2.from_angle(angle) * star_size * (1.0 - _time * 0.3)
		_draw_pixel_line(Vector2.ZERO, end_pos, pixel_size * 2, star_color)

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
