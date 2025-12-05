extends Node2D

# Execute - Procedural pixelated execution strike effect
# Heavy downward strike with blood splatter and dark energy

var radius: float = 150.0
var duration: float = 0.45
var pixel_size: int = 4

var _time: float = 0.0
var _strike_trail: Array[Dictionary] = []
var _blood_splatter: Array[Dictionary] = []
var _dark_energy: Array[Dictionary] = []

# Execute colors - dark and brutal
const BLADE_COLOR = Color(0.9, 0.9, 0.95, 1.0)  # Steel blade
const BLOOD_COLOR = Color(0.7, 0.1, 0.1, 0.85)  # Dark red blood
const DARK_ENERGY_COLOR = Color(0.3, 0.1, 0.4, 0.7)  # Purple dark energy
const IMPACT_COLOR = Color(0.8, 0.2, 0.2, 1.0)  # Red impact

func _ready() -> void:
	_generate_strike_trail()
	_generate_blood_splatter()
	_generate_dark_energy()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 0.45) -> void:
	radius = p_radius
	duration = p_duration

func _generate_strike_trail() -> void:
	for i in range(6):
		_strike_trail.append({
			"x_offset": randf_range(-8, 8),
			"width": (6 - i) * 2 + 2,
			"delay": i * 0.015
		})

func _generate_blood_splatter() -> void:
	var splatter_count = randi_range(15, 25)
	for i in range(splatter_count):
		var angle = randf_range(-PI * 0.7, PI * 0.7)
		_blood_splatter.append({
			"angle": angle,
			"speed": randf_range(60, 140),
			"size": randi_range(2, 5),
			"delay": randf_range(0.15, 0.35),
			"gravity": randf_range(150, 250)
		})

func _generate_dark_energy() -> void:
	var energy_count = randi_range(8, 14)
	for i in range(energy_count):
		_dark_energy.append({
			"angle": randf() * TAU,
			"radius": randf_range(20, 50),
			"size": randi_range(4, 8),
			"pulse_speed": randf_range(3.0, 6.0),
			"phase": randf() * TAU
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	_draw_dark_energy()
	_draw_strike_trail()
	_draw_blood_splatter()
	_draw_impact_flash()

func _draw_strike_trail() -> void:
	var strike_progress = clamp(_time * 2.0, 0.0, 1.0)

	for trail in _strike_trail:
		var trail_time = clamp((_time - trail.delay) * 1.8, 0.0, 1.0)
		if trail_time <= 0:
			continue

		var alpha = (1.0 - trail_time * 0.5) * 0.95
		if alpha <= 0:
			continue

		var color = BLADE_COLOR
		color.a = alpha

		# Downward diagonal strike
		var segments = 12
		for i in range(int(segments * trail_time)):
			var t = float(i) / (segments - 1)
			# Diagonal downward path
			var x = trail.x_offset + t * radius * 0.3
			var y = -radius * 0.4 + t * radius * 0.8

			var point_alpha = (1.0 - t * 0.4) * alpha
			var point_color = color
			point_color.a = point_alpha

			_draw_pixel_rect(Vector2(x, y), trail.width, point_color)

	# Blade tip
	if strike_progress > 0.2:
		var tip_progress = clamp((strike_progress - 0.2) / 0.8, 0.0, 1.0)
		var tip_x = tip_progress * radius * 0.3
		var tip_y = -radius * 0.4 + tip_progress * radius * 0.8
		var tip_color = BLADE_COLOR
		tip_color.a = 1.0 - _time * 0.4
		_draw_pixel_rect(Vector2(tip_x, tip_y), pixel_size * 3, tip_color)

func _draw_blood_splatter() -> void:
	for blood in _blood_splatter:
		var blood_time = clamp((_time - blood.delay) * 1.5, 0.0, 1.0)
		if blood_time <= 0:
			continue

		var alpha = (1.0 - blood_time * 0.7) * 0.85
		if alpha <= 0:
			continue

		# Parabolic trajectory with gravity
		var velocity = Vector2.from_angle(blood.angle) * blood.speed
		var pos = velocity * blood_time * duration
		pos.y += 0.5 * blood.gravity * pow(blood_time * duration, 2)

		var color = BLOOD_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, blood.size * pixel_size, color)

func _draw_dark_energy() -> void:
	# Only show dark energy briefly around impact
	var energy_alpha = 0.0
	if _time > 0.1 and _time < 0.6:
		energy_alpha = sin((_time - 0.1) / 0.5 * PI) * 0.7

	if energy_alpha <= 0:
		return

	for energy in _dark_energy:
		var pulse = sin(_time * energy.pulse_speed * TAU + energy.phase) * 0.3 + 0.7
		var current_radius = energy.radius * pulse

		var pos = Vector2.from_angle(energy.angle) * current_radius

		var color = DARK_ENERGY_COLOR
		color.a = energy_alpha * pulse

		_draw_pixel_rect(pos, energy.size, color)

func _draw_impact_flash() -> void:
	# Red impact flash at hit moment
	var impact_start = 0.25
	var flash_time = clamp((_time - impact_start) * 4.0, 0.0, 1.0)

	if flash_time <= 0 or flash_time >= 1.0:
		return

	var flash_alpha = (1.0 - flash_time) * 0.9

	var color = IMPACT_COLOR
	color.a = flash_alpha

	var flash_size = 35.0 * (0.5 + flash_time * 0.5)
	for x in range(-int(flash_size / pixel_size), int(flash_size / pixel_size) + 1):
		for y in range(-int(flash_size / pixel_size), int(flash_size / pixel_size) + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() < flash_size * 0.6:
				var dist_factor = pos.length() / (flash_size * 0.6)
				var pixel_color = color
				pixel_color.a *= (1.0 - dist_factor * 0.7)
				_draw_pixel_rect(pos, pixel_size, pixel_color)

func _draw_pixel_rect(pos: Vector2, size: int, color: Color) -> void:
	var snapped_pos = Vector2(
		snapped(pos.x, pixel_size) - size * 0.5,
		snapped(pos.y, pixel_size) - size * 0.5
	)
	draw_rect(Rect2(snapped_pos, Vector2(size, size)), color)
