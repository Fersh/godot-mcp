extends Node2D

# Apex Predator Strike (T3B) - Lethal predator strike effect
# Deadly slash marks, blood spray, and predator energy

var radius: float = 80.0
var duration: float = 0.35
var pixel_size: int = 4

var _time: float = 0.0
var _slash_marks: Array[Dictionary] = []
var _blood_particles: Array[Dictionary] = []
var _energy_sparks: Array[Dictionary] = []

# Apex predator colors
const SLASH_COLOR = Color(1.0, 0.2, 0.1, 1.0)  # Crimson slash
const ENERGY_COLOR = Color(1.0, 0.9, 0.4, 1.0)  # Golden predator energy
const BLOOD_COLOR = Color(0.6, 0.05, 0.05, 1.0)  # Dark blood
const FERAL_GLOW = Color(1.0, 0.6, 0.2, 1.0)  # Orange feral aura

func _ready() -> void:
	_generate_slashes()
	_generate_blood()
	_generate_energy()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 0.35) -> void:
	radius = p_radius
	duration = p_duration

func _generate_slashes() -> void:
	# Generate X-shaped deadly slash pattern
	var slash_angles = [-0.4, 0.4, -0.1, 0.1]  # Cross pattern
	for i in range(slash_angles.size()):
		var angle = slash_angles[i] + randf_range(-0.1, 0.1)
		var length = radius * randf_range(0.7, 1.0)
		_slash_marks.append({
			"angle": angle,
			"length": length,
			"width": 3 if i < 2 else 2,
			"delay": i * 0.03
		})

func _generate_blood() -> void:
	var blood_count = randi_range(12, 20)
	for i in range(blood_count):
		var angle = randf() * TAU
		var speed = randf_range(60.0, 140.0)
		var size = randi_range(2, 4)
		_blood_particles.append({
			"angle": angle,
			"speed": speed,
			"size": size,
			"gravity": randf_range(200.0, 400.0),
			"delay": randf_range(0.0, 0.1)
		})

func _generate_energy() -> void:
	var spark_count = randi_range(10, 18)
	for i in range(spark_count):
		var angle = randf() * TAU
		var speed = randf_range(100.0, 180.0)
		var size = randi_range(2, 3)
		_energy_sparks.append({
			"angle": angle,
			"speed": speed,
			"size": size,
			"spin": randf_range(-3.0, 3.0)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Draw feral energy burst
	_draw_feral_burst()

	# Draw deadly slashes
	_draw_slashes()

	# Draw blood spray
	_draw_blood()

	# Draw energy sparks
	_draw_energy()

	# Draw kill mark
	_draw_kill_mark()

func _draw_feral_burst() -> void:
	var burst_alpha = (1.0 - _time * 2.0) * 0.6
	if burst_alpha <= 0:
		return

	var color = FERAL_GLOW
	color.a = burst_alpha

	var burst_radius = radius * 0.5 * (1.0 + _time)
	var segments = int(burst_radius * 0.5)
	segments = max(segments, 12)

	for i in range(segments):
		var angle = (TAU / segments) * i
		var wave = sin(angle * 4.0 + _time * 10.0) * 5.0
		var pos = Vector2.from_angle(angle) * (burst_radius + wave)
		_draw_pixel_rect(pos, pixel_size, color)

func _draw_slashes() -> void:
	for slash in _slash_marks:
		var slash_time = clamp((_time - slash.delay) * 5.0, 0.0, 1.0)
		if slash_time <= 0:
			continue

		var alpha = (1.0 - _time * 0.5) * 1.0

		# Main slash - start from edge, sweep through center
		var start_offset = Vector2.from_angle(slash.angle + PI) * slash.length
		var end_offset = Vector2.from_angle(slash.angle) * slash.length

		var current_start = start_offset.lerp(Vector2.ZERO, clamp(slash_time * 2.0, 0.0, 1.0))
		var current_end = Vector2.ZERO.lerp(end_offset, clamp((slash_time - 0.3) * 2.0, 0.0, 1.0))

		if current_start.distance_to(current_end) > 1:
			var color = SLASH_COLOR
			color.a = alpha
			_draw_pixel_line(current_start, current_end, slash.width * pixel_size, color)

			# Slash glow
			var glow_color = ENERGY_COLOR
			glow_color.a = alpha * 0.5
			_draw_pixel_line(current_start, current_end, pixel_size, glow_color)

func _draw_blood() -> void:
	for blood in _blood_particles:
		var blood_time = clamp((_time - blood.delay) * 2.0, 0.0, 1.0)
		if blood_time <= 0:
			continue

		var pos = Vector2.from_angle(blood.angle) * blood.speed * blood_time
		pos.y += blood.gravity * blood_time * blood_time

		var alpha = (1.0 - blood_time) * 0.9
		var color = BLOOD_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, blood.size * pixel_size, color)

		# Blood trail/splatter
		if blood_time > 0.3:
			var splatter_color = color
			splatter_color.a *= 0.5
			for j in range(2):
				var splat_pos = pos + Vector2(randf_range(-8, 8), randf_range(-8, 8))
				_draw_pixel_rect(splat_pos, pixel_size, splatter_color)

func _draw_energy() -> void:
	for spark in _energy_sparks:
		var spark_time = clamp(_time * 2.0, 0.0, 1.0)
		if spark_time <= 0:
			continue

		var spin_angle = spark.angle + spark_time * spark.spin
		var pos = Vector2.from_angle(spin_angle) * spark.speed * spark_time

		var alpha = (1.0 - spark_time) * 0.9
		var color = ENERGY_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, spark.size * pixel_size, color)

func _draw_kill_mark() -> void:
	# Central kill indicator - predator mark
	var mark_alpha = (1.0 - _time * 1.5) * 1.0
	if mark_alpha <= 0:
		return

	var mark_size = 20.0 * (1.0 - _time * 0.3)

	# Draw X mark
	var color = SLASH_COLOR
	color.a = mark_alpha

	var offset = mark_size * 0.7
	_draw_pixel_line(Vector2(-offset, -offset), Vector2(offset, offset), pixel_size * 2, color)
	_draw_pixel_line(Vector2(offset, -offset), Vector2(-offset, offset), pixel_size * 2, color)

	# Central glow
	var glow_color = ENERGY_COLOR
	glow_color.a = mark_alpha * 0.8
	_draw_pixel_rect(Vector2.ZERO, pixel_size * 3, glow_color)

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
