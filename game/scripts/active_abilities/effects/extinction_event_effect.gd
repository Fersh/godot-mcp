extends Node2D

# Extinction Event (T3A) - Massive meteor impact effect
# Apocalyptic crater, fire rings, and devastation particles

var radius: float = 250.0
var duration: float = 0.7
var pixel_size: int = 4

var _time: float = 0.0
var _fire_particles: Array[Dictionary] = []
var _debris_chunks: Array[Dictionary] = []
var _crater_cracks: Array[Dictionary] = []
var _ember_particles: Array[Dictionary] = []

# Apocalyptic/meteor colors
const FIRE_CORE = Color(1.0, 0.95, 0.7, 1.0)  # White-hot center
const FIRE_MID = Color(1.0, 0.6, 0.1, 1.0)  # Orange fire
const FIRE_OUTER = Color(0.9, 0.3, 0.05, 1.0)  # Red fire
const CRATER_COLOR = Color(0.2, 0.15, 0.1, 1.0)  # Scorched earth
const SMOKE_COLOR = Color(0.3, 0.25, 0.2, 0.7)  # Dark smoke
const EMBER_COLOR = Color(1.0, 0.7, 0.2, 1.0)  # Glowing embers

func _ready() -> void:
	_generate_fire_particles()
	_generate_debris()
	_generate_crater_cracks()
	_generate_embers()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 0.7) -> void:
	radius = p_radius
	duration = p_duration

func _generate_fire_particles() -> void:
	var fire_count = randi_range(40, 60)
	for i in range(fire_count):
		var angle = randf() * TAU
		var speed = randf_range(100.0, 300.0)
		var size = randi_range(3, 7)
		_fire_particles.append({
			"angle": angle,
			"speed": speed,
			"size": size,
			"rise": randf_range(-100.0, -200.0),
			"delay": randf_range(0.0, 0.15),
			"color_type": randi() % 3  # 0=core, 1=mid, 2=outer
		})

func _generate_debris() -> void:
	var debris_count = randi_range(15, 25)
	for i in range(debris_count):
		var angle = randf() * TAU
		var speed = randf_range(150.0, 350.0)
		var size = randi_range(4, 10)
		_debris_chunks.append({
			"angle": angle,
			"speed": speed,
			"size": size,
			"gravity": randf_range(400.0, 700.0),
			"rotation_speed": randf_range(-5.0, 5.0)
		})

func _generate_crater_cracks() -> void:
	var crack_count = randi_range(12, 18)
	for i in range(crack_count):
		var angle = (TAU / crack_count) * i + randf_range(-0.2, 0.2)
		var length = radius * randf_range(0.7, 1.0)
		_crater_cracks.append({
			"angle": angle,
			"length": length,
			"glow": randf() > 0.5
		})

func _generate_embers() -> void:
	var ember_count = randi_range(30, 50)
	for i in range(ember_count):
		var angle = randf() * TAU
		var dist = randf_range(0.0, radius)
		var rise_speed = randf_range(30.0, 80.0)
		var drift = randf_range(-20.0, 20.0)
		_ember_particles.append({
			"angle": angle,
			"dist": dist,
			"rise_speed": rise_speed,
			"drift": drift,
			"delay": randf_range(0.0, 0.4),
			"flicker": randf() * TAU
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Draw massive crater
	_draw_crater()

	# Draw crater cracks with lava glow
	_draw_crater_cracks()

	# Draw expanding fire ring
	_draw_fire_ring()

	# Draw fire particles
	_draw_fire_particles()

	# Draw debris chunks
	_draw_debris()

	# Draw rising embers
	_draw_embers()

	# Draw central impact
	_draw_impact_core()

func _draw_crater() -> void:
	var crater_progress = clamp(_time * 3.0, 0.0, 1.0)
	var crater_alpha = (1.0 - _time * 0.3) * 0.8

	var color = CRATER_COLOR
	color.a = crater_alpha

	var crater_radius = radius * 0.5 * crater_progress

	# Fill crater with pixels
	for x in range(-int(crater_radius / pixel_size), int(crater_radius / pixel_size) + 1):
		for y in range(-int(crater_radius / pixel_size), int(crater_radius / pixel_size) + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() < crater_radius:
				var dist_factor = pos.length() / crater_radius
				var pixel_color = color
				pixel_color.a *= (0.5 + dist_factor * 0.5)
				_draw_pixel_rect(pos, pixel_size, pixel_color)

func _draw_crater_cracks() -> void:
	for crack in _crater_cracks:
		var crack_progress = clamp(_time * 4.0, 0.0, 1.0)
		if crack_progress <= 0:
			continue

		var alpha = (1.0 - _time * 0.5) * 0.9

		# Main crack color
		var color = CRATER_COLOR
		color.a = alpha

		var end_pos = Vector2.from_angle(crack.angle) * (crack.length * crack_progress)
		_draw_pixel_line(Vector2.ZERO, end_pos, pixel_size * 2, color)

		# Glowing lava in some cracks
		if crack.glow:
			var glow_color = FIRE_MID
			glow_color.a = alpha * (0.5 + sin(_time * 10.0) * 0.3)
			_draw_pixel_line(Vector2.ZERO, end_pos * 0.8, pixel_size, glow_color)

func _draw_fire_ring() -> void:
	# Multiple expanding fire rings
	for ring_idx in range(3):
		var ring_delay = ring_idx * 0.1
		var ring_time = clamp((_time - ring_delay) * 2.5, 0.0, 1.0)
		if ring_time <= 0:
			continue

		var ring_radius = radius * ring_time
		var ring_alpha = (1.0 - ring_time) * (0.9 - ring_idx * 0.2)

		var color = FIRE_MID.lerp(FIRE_OUTER, ring_time)
		color.a = ring_alpha

		var segments = int(ring_radius * 0.5)
		segments = max(segments, 20)

		for i in range(segments):
			var angle = (TAU / segments) * i
			var wave = sin(angle * 6.0 + _time * 8.0) * 8.0
			var pos = Vector2.from_angle(angle) * (ring_radius + wave)
			_draw_pixel_rect(pos, pixel_size * (3 - ring_idx), color)

func _draw_fire_particles() -> void:
	for fire in _fire_particles:
		var fire_time = clamp((_time - fire.delay) * 1.5, 0.0, 1.0)
		if fire_time <= 0:
			continue

		var pos = Vector2.from_angle(fire.angle) * fire.speed * fire_time
		pos.y += fire.rise * fire_time

		var alpha = (1.0 - fire_time) * 0.9

		var color: Color
		match fire.color_type:
			0: color = FIRE_CORE
			1: color = FIRE_MID
			_: color = FIRE_OUTER
		color.a = alpha

		_draw_pixel_rect(pos, fire.size * pixel_size, color)

		# Fire trail
		var trail_color = color
		trail_color.a *= 0.4
		var trail_pos = Vector2.from_angle(fire.angle) * fire.speed * fire_time * 0.6
		trail_pos.y += fire.rise * fire_time * 0.5
		_draw_pixel_rect(trail_pos, fire.size * pixel_size - pixel_size, trail_color)

func _draw_debris() -> void:
	for debris in _debris_chunks:
		var pos = Vector2.from_angle(debris.angle) * debris.speed * _time
		pos.y += debris.gravity * _time * _time

		var alpha = (1.0 - _time) * 0.9
		var color = CRATER_COLOR.lightened(0.3)
		color.a = alpha

		_draw_pixel_rect(pos, debris.size * pixel_size, color)

		# Debris on fire
		if _time < 0.5:
			var fire_color = FIRE_OUTER
			fire_color.a = alpha * 0.6
			_draw_pixel_rect(pos + Vector2(0, -debris.size * pixel_size * 0.5), pixel_size * 2, fire_color)

func _draw_embers() -> void:
	for ember in _ember_particles:
		var ember_time = clamp((_time - ember.delay) * 1.2, 0.0, 1.0)
		if ember_time <= 0:
			continue

		var start_pos = Vector2.from_angle(ember.angle) * ember.dist
		var pos = start_pos + Vector2(ember.drift * ember_time, -ember.rise_speed * ember_time)

		# Flickering alpha
		var flicker = sin(ember_time * 20.0 + ember.flicker) * 0.3 + 0.7
		var alpha = (1.0 - ember_time) * flicker * 0.8

		var color = EMBER_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, pixel_size * 2, color)

func _draw_impact_core() -> void:
	var core_alpha = (1.0 - _time * 2.0) * 1.0
	if core_alpha <= 0:
		return

	# White-hot center
	var core_size = 60.0 * (1.0 - _time * 0.3)

	for x in range(-int(core_size / pixel_size), int(core_size / pixel_size) + 1):
		for y in range(-int(core_size / pixel_size), int(core_size / pixel_size) + 1):
			var pos = Vector2(x, y) * pixel_size
			var dist = pos.length()
			if dist < core_size:
				var dist_factor = dist / core_size
				var color = FIRE_CORE.lerp(FIRE_MID, dist_factor)
				color.a = core_alpha * (1.0 - dist_factor * 0.5)
				_draw_pixel_rect(pos, pixel_size, color)

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
