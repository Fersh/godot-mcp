extends Node2D

# Parry - Procedural pixelated defensive parry effect
# Shield flash, deflection sparks, and timing window indicator

var radius: float = 50.0
var duration: float = 0.5
var pixel_size: int = 4

var _time: float = 0.0
var _shield_particles: Array[Dictionary] = []
var _deflection_sparks: Array[Dictionary] = []

# Parry colors
const SHIELD_COLOR = Color(0.7, 0.8, 1.0, 0.8)  # Blue-white shield
const FLASH_COLOR = Color(1.0, 1.0, 1.0, 1.0)  # Bright white flash
const SPARK_COLOR = Color(0.9, 0.95, 1.0, 0.9)  # White sparks
const RING_COLOR = Color(0.6, 0.7, 0.9, 0.6)  # Blue ring

func _ready() -> void:
	_generate_shield_particles()
	_generate_deflection_sparks()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 0.5) -> void:
	radius = p_radius
	duration = p_duration

func _generate_shield_particles() -> void:
	var particle_count = randi_range(12, 18)
	for i in range(particle_count):
		var angle = randf() * TAU
		_shield_particles.append({
			"angle": angle,
			"radius": randf_range(radius * 0.6, radius * 1.0),
			"size": randi_range(3, 6),
			"pulse_speed": randf_range(4.0, 8.0),
			"phase": randf() * TAU
		})

func _generate_deflection_sparks() -> void:
	var spark_count = randi_range(8, 14)
	for i in range(spark_count):
		var angle = randf_range(-PI * 0.5, PI * 0.5)  # Forward-facing fan
		_deflection_sparks.append({
			"angle": angle,
			"speed": randf_range(60, 120),
			"size": randi_range(2, 4),
			"delay": randf_range(0.0, 0.15)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Fade based on parry window
	var fade = 1.0
	if _time < 0.1:
		fade = _time / 0.1
	elif _time > 0.7:
		fade = (1.0 - _time) / 0.3

	_draw_shield_arc(fade)
	_draw_shield_particles(fade)
	_draw_deflection_sparks(fade)
	_draw_parry_flash()

func _draw_shield_arc(fade: float) -> void:
	# Semi-circular shield in front
	var alpha = 0.6 * fade
	if alpha <= 0:
		return

	var color = SHIELD_COLOR
	color.a = alpha

	# Draw arc facing forward (right side)
	var arc_start = -PI * 0.4
	var arc_end = PI * 0.4
	var segments = 16

	for i in range(segments):
		var t = float(i) / (segments - 1)
		var angle = lerp(arc_start, arc_end, t)
		var pos = Vector2.from_angle(angle) * radius

		_draw_pixel_rect(pos, pixel_size * 2, color)

	# Inner arc
	var inner_color = color
	inner_color.a = alpha * 0.5
	for i in range(segments):
		var t = float(i) / (segments - 1)
		var angle = lerp(arc_start, arc_end, t)
		var pos = Vector2.from_angle(angle) * radius * 0.7

		_draw_pixel_rect(pos, pixel_size * 2, inner_color)

func _draw_shield_particles(fade: float) -> void:
	var current_time = _time * duration

	for particle in _shield_particles:
		var pulse = sin(current_time * particle.pulse_speed + particle.phase) * 0.3 + 0.7
		var current_radius = particle.radius * pulse

		# Only show particles in front arc
		if abs(particle.angle) > PI * 0.5:
			continue

		var pos = Vector2.from_angle(particle.angle) * current_radius

		var alpha = 0.5 * fade * pulse
		var color = SHIELD_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, particle.size, color)

func _draw_deflection_sparks(fade: float) -> void:
	for spark in _deflection_sparks:
		var spark_time = clamp((_time - spark.delay) * 2.0, 0.0, 1.0)
		if spark_time <= 0:
			continue

		var alpha = (1.0 - spark_time) * 0.8 * fade
		if alpha <= 0:
			continue

		var pos = Vector2.from_angle(spark.angle) * (radius + spark.speed * spark_time * duration)

		var color = SPARK_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, spark.size * pixel_size, color)

func _draw_parry_flash() -> void:
	# Initial bright flash
	var flash_alpha = (1.0 - _time * 4.0)
	if flash_alpha <= 0:
		return

	var color = FLASH_COLOR
	color.a = flash_alpha * 0.8

	var flash_size = 30.0 * (1.0 + _time * 0.5)
	for x in range(-int(flash_size / pixel_size), int(flash_size / pixel_size) + 1):
		for y in range(-int(flash_size / pixel_size), int(flash_size / pixel_size) + 1):
			var pos = Vector2(x, y) * pixel_size
			# Only in front hemisphere
			if pos.x < 0:
				continue
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
