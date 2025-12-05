extends Node2D

# Throw Weapon - Procedural pixelated thrown weapon effect
# Spinning weapon projectile with motion trail and impact

var throw_distance: float = 350.0
var duration: float = 0.5
var pixel_size: int = 4
var direction: Vector2 = Vector2.RIGHT

var _time: float = 0.0
var _spin_trail: Array[Dictionary] = []
var _motion_blur: Array[Dictionary] = []

# Throw colors
const BLADE_COLOR = Color(0.85, 0.85, 0.9, 1.0)  # Steel blade
const TRAIL_COLOR = Color(0.7, 0.75, 0.85, 0.5)  # Motion trail
const GLINT_COLOR = Color(1.0, 1.0, 1.0, 0.95)  # Blade glint
const IMPACT_COLOR = Color(1.0, 0.95, 0.8, 0.9)  # Impact flash

func _ready() -> void:
	rotation = direction.angle()
	_generate_spin_trail()
	_generate_motion_blur()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_distance: float, p_duration: float = 0.5) -> void:
	throw_distance = p_distance
	duration = p_duration

func _generate_spin_trail() -> void:
	# Trail points for spinning weapon
	for i in range(8):
		_spin_trail.append({
			"angle_offset": (TAU / 8) * i,
			"length": 15 - i,
			"alpha": 1.0 - i * 0.1
		})

func _generate_motion_blur() -> void:
	var blur_count = randi_range(8, 12)
	for i in range(blur_count):
		_motion_blur.append({
			"y_offset": randf_range(-15, 15),
			"length": randf_range(30, 60),
			"width": randi_range(2, 3)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	_draw_motion_blur()
	_draw_spinning_weapon()
	_draw_impact_effect()

func _draw_motion_blur() -> void:
	var throw_progress = _time
	var current_x = throw_progress * throw_distance

	var alpha = 0.5 * (1.0 - _time * 0.3)
	if alpha <= 0:
		return

	for blur in _motion_blur:
		var blur_start = max(0, current_x - blur.length)
		var blur_end = current_x

		var color = TRAIL_COLOR
		color.a = alpha * (1.0 - abs(blur.y_offset) / 20.0)

		var start_pos = Vector2(blur_start, blur.y_offset)
		var end_pos = Vector2(blur_end, blur.y_offset)

		_draw_pixel_line(start_pos, end_pos, blur.width, color)

func _draw_spinning_weapon() -> void:
	var throw_progress = _time
	var current_x = throw_progress * throw_distance
	var spin_angle = _time * duration * 20.0  # Fast spin

	var alpha = 1.0 - _time * 0.2
	if alpha <= 0:
		return

	var weapon_pos = Vector2(current_x, 0)

	# Draw spinning blade
	var blade_length = 20.0
	var blade_width = 6.0

	# Main blade
	var blade_color = BLADE_COLOR
	blade_color.a = alpha

	var blade_start = weapon_pos + Vector2.from_angle(spin_angle) * blade_length * 0.5
	var blade_end = weapon_pos - Vector2.from_angle(spin_angle) * blade_length * 0.5
	_draw_pixel_line(blade_start, blade_end, int(blade_width), blade_color)

	# Cross guard
	var guard_start = weapon_pos + Vector2.from_angle(spin_angle + PI * 0.5) * blade_width
	var guard_end = weapon_pos - Vector2.from_angle(spin_angle + PI * 0.5) * blade_width
	_draw_pixel_line(guard_start, guard_end, pixel_size, blade_color)

	# Spin trail effect
	for trail in _spin_trail:
		var trail_angle = spin_angle + trail.angle_offset
		var trail_start = weapon_pos
		var trail_end = weapon_pos + Vector2.from_angle(trail_angle) * trail.length

		var trail_color = TRAIL_COLOR
		trail_color.a = trail.alpha * alpha * 0.6

		_draw_pixel_line(trail_start, trail_end, pixel_size, trail_color)

	# Glint on blade tip
	var glint_pos = blade_start
	var glint_color = GLINT_COLOR
	glint_color.a = alpha * (0.5 + sin(_time * duration * 30.0) * 0.5)
	_draw_pixel_rect(glint_pos, pixel_size * 2, glint_color)

func _draw_impact_effect() -> void:
	# Impact at end of throw
	var impact_time = clamp((_time - 0.85) * 7.0, 0.0, 1.0)
	if impact_time <= 0:
		return

	var alpha = (1.0 - impact_time) * 0.9
	if alpha <= 0:
		return

	var impact_pos = Vector2(throw_distance, 0)

	# Impact sparks
	var spark_count = 8
	for i in range(spark_count):
		var angle = (TAU / spark_count) * i
		var dist = 20.0 * impact_time

		var spark_pos = impact_pos + Vector2.from_angle(angle) * dist

		var color = IMPACT_COLOR
		color.a = alpha

		_draw_pixel_rect(spark_pos, pixel_size * 2, color)

	# Central flash
	var flash_color = IMPACT_COLOR
	flash_color.a = alpha * 1.2
	_draw_pixel_rect(impact_pos, int(15.0 * (1.0 - impact_time * 0.5)), flash_color)

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
