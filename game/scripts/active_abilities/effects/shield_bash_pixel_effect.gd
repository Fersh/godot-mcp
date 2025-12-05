extends Node2D

# Shield Bash - Procedural pixelated impact effect
# Metallic shield impact with sparks and shockwave ring

var radius: float = 80.0
var duration: float = 0.35
var pixel_size: int = 4

var _time: float = 0.0
var _sparks: Array[Dictionary] = []
var _impact_lines: Array[Dictionary] = []

# Metallic shield colors
const SHIELD_COLOR = Color(0.7, 0.75, 0.8, 1.0)  # Silver/steel
const SPARK_COLOR = Color(1.0, 0.95, 0.7, 1.0)  # Bright yellow sparks
const IMPACT_COLOR = Color(0.5, 0.55, 0.65, 1.0)  # Darker steel
const RING_COLOR = Color(0.6, 0.65, 0.75, 0.8)  # Steel shockwave

func _ready() -> void:
	_generate_sparks()
	_generate_impact_lines()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 0.35) -> void:
	radius = p_radius
	duration = p_duration

func _generate_sparks() -> void:
	# Generate metallic sparks flying outward
	var spark_count = randi_range(15, 25)
	for i in range(spark_count):
		var angle = randf() * TAU
		var speed = randf_range(80.0, 200.0)
		var size = randi_range(2, 4)
		_sparks.append({
			"angle": angle,
			"speed": speed,
			"size": size,
			"delay": randf_range(0.0, 0.08),
			"lifetime": randf_range(0.5, 1.0)
		})

func _generate_impact_lines() -> void:
	# Generate radial impact lines from shield
	var line_count = randi_range(6, 10)
	for i in range(line_count):
		var angle = (TAU / line_count) * i + randf_range(-0.15, 0.15)
		var length = radius * randf_range(0.5, 0.9)
		_impact_lines.append({
			"angle": angle,
			"length": length,
			"delay": randf_range(0.0, 0.05)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Draw shield impact flash
	_draw_impact_flash()

	# Draw expanding ring
	_draw_shockwave_ring()

	# Draw impact lines
	_draw_impact_lines()

	# Draw sparks
	_draw_sparks()

	# Draw central shield shape
	_draw_shield_center()

func _draw_impact_flash() -> void:
	# Brief bright flash at start
	var flash_alpha = (1.0 - _time * 3.0) * 0.8
	if flash_alpha <= 0:
		return

	var color = SPARK_COLOR
	color.a = flash_alpha

	var flash_size = 40.0 * (1.0 + _time * 2.0)
	for x in range(-int(flash_size / pixel_size), int(flash_size / pixel_size) + 1):
		for y in range(-int(flash_size / pixel_size), int(flash_size / pixel_size) + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() < flash_size * 0.6:
				var dist_factor = pos.length() / (flash_size * 0.6)
				var pixel_color = color
				pixel_color.a *= (1.0 - dist_factor)
				_draw_pixel_rect(pos, pixel_size, pixel_color)

func _draw_shockwave_ring() -> void:
	var ring_progress = clamp(_time * 2.0, 0.0, 1.0)
	var ring_radius = radius * ring_progress
	var ring_alpha = (1.0 - _time) * 0.7

	if ring_alpha <= 0:
		return

	var color = RING_COLOR
	color.a = ring_alpha

	# Draw pixelated ring
	var segments = int(ring_radius * 0.6)
	segments = max(segments, 12)
	for i in range(segments):
		var angle = (TAU / segments) * i
		var pos = Vector2.from_angle(angle) * ring_radius
		_draw_pixel_rect(pos, pixel_size * 2, color)

func _draw_impact_lines() -> void:
	for line in _impact_lines:
		var line_progress = clamp((_time - line.delay) * 4.0, 0.0, 1.0)
		if line_progress <= 0:
			continue

		var alpha = (1.0 - _time) * 0.9
		var color = SHIELD_COLOR
		color.a = alpha

		var start_pos = Vector2.from_angle(line.angle) * 15.0
		var end_pos = Vector2.from_angle(line.angle) * (line.length * line_progress)

		_draw_pixel_line(start_pos, end_pos, pixel_size, color)

func _draw_sparks() -> void:
	for spark in _sparks:
		var spark_progress = clamp((_time - spark.delay) * 2.0, 0.0, spark.lifetime)
		if spark_progress <= 0:
			continue

		var pos = Vector2.from_angle(spark.angle) * spark.speed * spark_progress
		# Add slight gravity
		pos.y += spark_progress * spark_progress * 50.0

		var alpha = (1.0 - spark_progress / spark.lifetime) * 1.0
		var color = SPARK_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, spark.size * pixel_size, color)

		# Trail
		var trail_color = color
		trail_color.a *= 0.4
		var trail_pos = Vector2.from_angle(spark.angle) * spark.speed * spark_progress * 0.7
		trail_pos.y += spark_progress * spark_progress * 50.0 * 0.5
		_draw_pixel_rect(trail_pos, spark.size * pixel_size - pixel_size, trail_color)

func _draw_shield_center() -> void:
	var center_alpha = (1.0 - _time * 1.5) * 0.9
	if center_alpha <= 0:
		return

	var color = IMPACT_COLOR
	color.a = center_alpha

	# Draw pixelated shield shape (rounded rectangle)
	var shield_width = 24.0
	var shield_height = 28.0

	for x in range(-int(shield_width / pixel_size), int(shield_width / pixel_size) + 1):
		for y in range(-int(shield_height / pixel_size), int(shield_height / pixel_size) + 1):
			var pos = Vector2(x, y) * pixel_size
			# Shield shape - wider at top, narrower at bottom
			var width_at_y = shield_width * (1.0 - abs(pos.y) / shield_height * 0.4)
			if abs(pos.x) < width_at_y * 0.5:
				var pixel_color = color
				# Add metallic shine gradient
				if pos.y < 0:
					pixel_color = pixel_color.lightened(0.2)
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
