extends Node2D

# Meteor Slam Effect - T3 Crater Ground Slam of Meteors
# Massive fiery impact crater with dramatic pixelated flames

var radius: float = 180.0
var duration: float = 0.8
var pixel_size: int = 4

var _time: float = 0.0
var _crater_pixels: Array[Dictionary] = []
var _fire_pillars: Array[Dictionary] = []
var _debris: Array[Dictionary] = []
var _sparks: Array[Dictionary] = []
var _ring_cracks: Array[Dictionary] = []

# Meteor/Fire colors - intense oranges and reds
const CRATER_HOT = Color(1.0, 0.5, 0.15, 0.95)  # Bright molten
const CRATER_WARM = Color(0.9, 0.3, 0.1, 0.85)  # Hot red
const CRATER_COOL = Color(0.4, 0.15, 0.08, 0.7)  # Cooling lava
const FLAME_BASE = Color(1.0, 0.45, 0.1, 0.95)  # Orange fire
const FLAME_TIP = Color(1.0, 0.9, 0.4, 0.8)  # Yellow tip
const DEBRIS_COLOR = Color(0.3, 0.2, 0.15, 1.0)  # Dark rock
const SPARK_COLOR = Color(1.0, 0.8, 0.3, 1.0)  # Bright sparks
const CRACK_COLOR = Color(0.1, 0.05, 0.02, 0.9)  # Dark cracks
const CRACK_GLOW = Color(1.0, 0.4, 0.1, 0.7)  # Glowing cracks

func _ready() -> void:
	z_index = -1
	_generate_crater()
	_generate_fire_pillars()
	_generate_debris()
	_generate_sparks()
	_generate_ring_cracks()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float = 180.0, p_duration: float = 0.8) -> void:
	radius = p_radius
	duration = p_duration

func _generate_crater() -> void:
	var pixel_radius = int(radius / pixel_size)
	for x in range(-pixel_radius, pixel_radius + 1):
		for y in range(-pixel_radius, pixel_radius + 1):
			var pos = Vector2(x, y) * pixel_size
			var dist = pos.length()
			if dist < radius:
				var heat = 1.0 - (dist / radius)
				heat = pow(heat, 0.5)  # More heat spread
				heat += randf_range(-0.1, 0.1)
				heat = clamp(heat, 0.0, 1.0)

				_crater_pixels.append({
					"pos": pos,
					"heat": heat,
					"pulse_offset": randf() * TAU
				})

func _generate_fire_pillars() -> void:
	var pillar_count = randi_range(12, 20)
	for i in range(pillar_count):
		var angle = randf() * TAU
		var dist = randf_range(15.0, radius * 0.7)
		_fire_pillars.append({
			"pos": Vector2.from_angle(angle) * dist,
			"height": randf_range(40.0, 90.0),
			"width": randf_range(12.0, 24.0),
			"phase": randf() * TAU,
			"speed": randf_range(4.0, 8.0),
			"delay": randf_range(0.0, 0.15)
		})

func _generate_debris() -> void:
	var debris_count = randi_range(30, 50)
	for i in range(debris_count):
		var angle = randf() * TAU
		var speed = randf_range(200.0, 500.0)
		_debris.append({
			"angle": angle,
			"speed": speed,
			"size": randi_range(3, 7),
			"max_height": randf_range(50.0, 120.0),
			"rotation": randf() * TAU
		})

func _generate_sparks() -> void:
	var spark_count = randi_range(50, 80)
	for i in range(spark_count):
		var angle = randf() * TAU
		_sparks.append({
			"angle": angle,
			"speed": randf_range(150.0, 400.0),
			"size": randi_range(2, 4),
			"max_height": randf_range(30.0, 80.0),
			"spawn_delay": randf_range(0.0, 0.2)
		})

func _generate_ring_cracks() -> void:
	var crack_count = randi_range(12, 18)
	for i in range(crack_count):
		var angle = (TAU / crack_count) * i + randf_range(-0.15, 0.15)
		var segments: Array[Vector2] = []
		var current_pos = Vector2.ZERO
		var length = radius * randf_range(0.9, 1.3)

		while current_pos.length() < length:
			angle += randf_range(-0.25, 0.25)
			current_pos += Vector2.from_angle(angle) * randf_range(12.0, 22.0)
			segments.append(current_pos)

		_ring_cracks.append({
			"segments": segments,
			"width": randf_range(4.0, 8.0)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var impact_progress = clamp(_time * 4.0, 0.0, 1.0)  # Quick initial impact
	var fade = 1.0 - pow(_time, 1.5)

	# Draw expanding shockwave first
	_draw_shockwave(impact_progress)

	# Draw crater base
	_draw_crater(fade, impact_progress)

	# Draw ring cracks
	_draw_cracks(fade, impact_progress)

	# Draw fire pillars
	_draw_fire_pillars(fade)

	# Draw flying debris
	_draw_debris()

	# Draw sparks
	_draw_sparks()

	# Draw central flash on impact
	if _time < 0.15:
		_draw_impact_flash()

func _draw_shockwave(progress: float) -> void:
	var wave_radius = radius * 1.5 * progress
	var wave_alpha = (1.0 - progress) * 0.6

	var color = Color(1.0, 0.6, 0.3, wave_alpha)

	var segments = int(wave_radius * 0.4)
	segments = max(segments, 24)
	for i in range(segments):
		var angle = (TAU / segments) * i
		var pos = Vector2.from_angle(angle) * wave_radius
		_draw_pixel_rect(pos, pixel_size * 3, color)

func _draw_crater(fade: float, progress: float) -> void:
	var anim_time = _time * duration * 3.0
	var crater_scale = 0.3 + progress * 0.7  # Expand crater

	for pixel in _crater_pixels:
		var pos: Vector2 = pixel.pos * crater_scale
		var heat: float = pixel.heat

		# Pulse heat
		var pulse = sin(anim_time * 2.0 + pixel.pulse_offset) * 0.15 + 0.85
		heat *= pulse * fade

		# Color based on heat
		var color: Color
		if heat > 0.7:
			color = CRATER_WARM.lerp(CRATER_HOT, (heat - 0.7) / 0.3)
		elif heat > 0.3:
			color = CRATER_COOL.lerp(CRATER_WARM, (heat - 0.3) / 0.4)
		else:
			color = CRACK_COLOR.lerp(CRATER_COOL, heat / 0.3)

		color.a *= fade * progress

		_draw_pixel_rect(pos, pixel_size, color)

func _draw_cracks(fade: float, progress: float) -> void:
	var crack_progress = clamp(progress * 1.5, 0.0, 1.0)
	var glow_pulse = sin(_time * duration * 6.0) * 0.3 + 0.7

	for crack in _ring_cracks:
		var segments: Array = crack.segments
		var visible_count = int(segments.size() * crack_progress)

		var prev_pos = Vector2.ZERO
		for j in range(visible_count):
			var seg_pos: Vector2 = segments[j]

			# Dark crack
			var color = CRACK_COLOR
			color.a = fade
			_draw_pixel_line(prev_pos, seg_pos, int(crack.width), color)

			# Glowing center
			var glow_color = CRACK_GLOW
			glow_color.a = fade * glow_pulse * 0.7
			_draw_pixel_line(prev_pos, seg_pos, int(crack.width * 0.5), glow_color)

			prev_pos = seg_pos

func _draw_fire_pillars(fade: float) -> void:
	var anim_time = _time * duration * 2.0

	for pillar in _fire_pillars:
		var pillar_progress = clamp((_time - pillar.delay) * 3.0, 0.0, 1.0)
		if pillar_progress <= 0:
			continue

		var pos: Vector2 = pillar.pos
		var height: float = pillar.height * pillar_progress * fade
		var width: float = pillar.width

		# Flickering
		var flicker = sin(anim_time * pillar.speed + pillar.phase) * 0.25 + 0.75
		height *= flicker

		var segments = int(height / pixel_size)
		for i in range(segments):
			var t = float(i) / max(segments - 1, 1)
			var seg_width = width * (1.0 - t * 0.8)
			var seg_y = -i * pixel_size

			var color = FLAME_BASE.lerp(FLAME_TIP, t)
			color.a *= fade * flicker * pillar_progress

			var x_offset = sin(anim_time * 6.0 + pillar.phase + i * 0.3) * 4.0
			var seg_pos = pos + Vector2(x_offset, seg_y)

			for px in range(-int(seg_width / pixel_size / 2), int(seg_width / pixel_size / 2) + 1):
				_draw_pixel_rect(seg_pos + Vector2(px * pixel_size, 0), pixel_size, color)

func _draw_debris() -> void:
	for debris in _debris:
		var debris_progress = clamp(_time * 2.0, 0.0, 1.0)
		if debris_progress >= 1.0:
			continue

		var dist = debris.speed * debris_progress * duration * 0.5
		var pos = Vector2.from_angle(debris.angle) * dist

		# Arc trajectory
		var height = sin(debris_progress * PI) * debris.max_height
		pos.y -= height

		var alpha = 1.0 - debris_progress
		var color = DEBRIS_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, debris.size * pixel_size, color)

func _draw_sparks() -> void:
	for spark in _sparks:
		var spark_progress = clamp((_time - spark.spawn_delay) * 3.0, 0.0, 1.0)
		if spark_progress <= 0 or spark_progress >= 1:
			continue

		var dist = spark.speed * spark_progress * duration * 0.3
		var pos = Vector2.from_angle(spark.angle) * dist

		var height = sin(spark_progress * PI) * spark.max_height
		pos.y -= height

		var alpha = sin(spark_progress * PI)
		var color = SPARK_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, spark.size * pixel_size, color)

func _draw_impact_flash() -> void:
	var flash_progress = _time / 0.15
	var flash_alpha = (1.0 - flash_progress) * 0.8
	var flash_radius = 60.0 * (1.0 + flash_progress * 0.5)

	var color = Color(1.0, 0.95, 0.8, flash_alpha)

	# Draw central bright flash
	for x in range(-int(flash_radius / pixel_size), int(flash_radius / pixel_size) + 1):
		for y in range(-int(flash_radius / pixel_size), int(flash_radius / pixel_size) + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() < flash_radius:
				var dist_factor = pos.length() / flash_radius
				var pixel_color = color
				pixel_color.a = flash_alpha * (1.0 - dist_factor)
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
