extends Node2D

# Impale - Procedural pixelated thrust attack effect
# Piercing spear thrust with trail and penetration sparks

var thrust_distance: float = 180.0
var duration: float = 0.35
var pixel_size: int = 4
var direction: Vector2 = Vector2.RIGHT

var _time: float = 0.0
var _thrust_trail: Array[Dictionary] = []
var _penetration_sparks: Array[Dictionary] = []
var _blood_drops: Array[Dictionary] = []

# Impale colors
const SPEAR_COLOR = Color(0.85, 0.85, 0.9, 1.0)  # Steel spear
const TRAIL_COLOR = Color(0.7, 0.7, 0.8, 0.6)  # Motion trail
const SPARK_COLOR = Color(1.0, 0.95, 0.8, 0.9)  # Impact sparks
const BLOOD_COLOR = Color(0.7, 0.15, 0.1, 0.8)  # Blood

func _ready() -> void:
	rotation = direction.angle()
	_generate_thrust_trail()
	_generate_penetration_sparks()
	_generate_blood_drops()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_distance: float, p_duration: float = 0.35) -> void:
	thrust_distance = p_distance
	duration = p_duration

func _generate_thrust_trail() -> void:
	for i in range(6):
		_thrust_trail.append({
			"y_offset": (i - 2.5) * 3,
			"width": 6 - abs(i - 2.5),
			"delay": i * 0.01
		})

func _generate_penetration_sparks() -> void:
	var spark_count = randi_range(10, 16)
	for i in range(spark_count):
		var angle = randf_range(-PI * 0.3, PI * 0.3)
		_penetration_sparks.append({
			"angle": angle,
			"speed": randf_range(40, 90),
			"size": randi_range(2, 3),
			"delay": randf_range(0.3, 0.5)
		})

func _generate_blood_drops() -> void:
	var drop_count = randi_range(6, 10)
	for i in range(drop_count):
		var angle = randf_range(-PI * 0.5, PI * 0.5)
		_blood_drops.append({
			"angle": angle,
			"speed": randf_range(30, 70),
			"size": randi_range(2, 4),
			"delay": randf_range(0.35, 0.55),
			"gravity": randf_range(100, 180)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	_draw_thrust_trail()
	_draw_spear_tip()
	_draw_penetration_sparks()
	_draw_blood_drops()
	_draw_impact_flash()

func _draw_thrust_trail() -> void:
	var thrust_progress = clamp(_time * 2.0, 0.0, 1.0)
	var current_x = thrust_progress * thrust_distance

	for trail in _thrust_trail:
		var trail_time = clamp((_time - trail.delay) * 1.5, 0.0, 1.0)
		if trail_time <= 0:
			continue

		var alpha = (1.0 - trail_time * 0.5) * 0.7
		if alpha <= 0:
			continue

		var color = TRAIL_COLOR
		color.a = alpha

		var trail_start = max(0, current_x - thrust_distance * 0.4)
		var start_pos = Vector2(trail_start, trail.y_offset)
		var end_pos = Vector2(current_x, trail.y_offset)

		_draw_pixel_line(start_pos, end_pos, int(trail.width), color)

func _draw_spear_tip() -> void:
	var thrust_progress = clamp(_time * 2.0, 0.0, 1.0)
	var current_x = thrust_progress * thrust_distance

	var alpha = 1.0 - _time * 0.3
	if alpha <= 0:
		return

	var color = SPEAR_COLOR
	color.a = alpha

	# Spear head shape - triangular tip
	var tip_length = 20
	var tip_width = 8

	# Draw spear head
	for i in range(tip_length):
		var t = float(i) / tip_length
		var width = int(tip_width * (1.0 - t))
		var x = current_x + i - tip_length * 0.5

		for w in range(-width, width + 1):
			_draw_pixel_rect(Vector2(x, w), pixel_size, color)

func _draw_penetration_sparks() -> void:
	for spark in _penetration_sparks:
		var spark_time = clamp((_time - spark.delay) * 3.0, 0.0, 1.0)
		if spark_time <= 0:
			continue

		var alpha = (1.0 - spark_time) * 0.9
		if alpha <= 0:
			continue

		var base_pos = Vector2(thrust_distance, 0)
		var offset = Vector2.from_angle(spark.angle) * spark.speed * spark_time * duration
		var pos = base_pos + offset

		var color = SPARK_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, spark.size * pixel_size, color)

func _draw_blood_drops() -> void:
	for drop in _blood_drops:
		var drop_time = clamp((_time - drop.delay) * 2.0, 0.0, 1.0)
		if drop_time <= 0:
			continue

		var alpha = (1.0 - drop_time * 0.6) * 0.8
		if alpha <= 0:
			continue

		var base_pos = Vector2(thrust_distance, 0)
		var velocity = Vector2.from_angle(drop.angle) * drop.speed
		var pos = base_pos + velocity * drop_time * duration
		pos.y += 0.5 * drop.gravity * pow(drop_time * duration, 2)

		var color = BLOOD_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, drop.size * pixel_size, color)

func _draw_impact_flash() -> void:
	var impact_time = clamp((_time - 0.4) * 4.0, 0.0, 1.0)
	if impact_time <= 0 or impact_time >= 1.0:
		return

	var flash_alpha = (1.0 - impact_time) * 0.7

	var color = SPARK_COLOR
	color.a = flash_alpha

	var flash_size = 20.0 * (0.5 + impact_time * 0.5)
	_draw_pixel_rect(Vector2(thrust_distance, 0), int(flash_size), color)

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
