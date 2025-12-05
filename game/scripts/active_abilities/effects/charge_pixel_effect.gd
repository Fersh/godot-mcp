extends Node2D

# Charge - Procedural pixelated rushing charge effect
# Speed lines, dust trail, and impact burst

var charge_distance: float = 200.0
var duration: float = 0.4
var pixel_size: int = 4
var direction: Vector2 = Vector2.RIGHT

var _time: float = 0.0
var _speed_lines: Array[Dictionary] = []
var _dust_trail: Array[Dictionary] = []
var _impact_burst: Array[Dictionary] = []

# Charge effect colors
const SPEED_LINE_COLOR = Color(0.9, 0.9, 1.0, 0.8)  # White speed lines
const DUST_COLOR = Color(0.6, 0.55, 0.45, 0.6)  # Brown dust
const IMPACT_COLOR = Color(1.0, 0.95, 0.8, 1.0)  # Bright impact
const ENERGY_COLOR = Color(0.8, 0.85, 1.0, 0.7)  # Blue energy aura

func _ready() -> void:
	rotation = direction.angle()
	_generate_speed_lines()
	_generate_dust_trail()
	_generate_impact_burst()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_distance: float, p_duration: float = 0.4) -> void:
	charge_distance = p_distance
	duration = p_duration

func _generate_speed_lines() -> void:
	var line_count = randi_range(12, 18)
	for i in range(line_count):
		var y_offset = randf_range(-40, 40)
		_speed_lines.append({
			"y_offset": y_offset,
			"length": randf_range(30, 80),
			"start_x": randf_range(-20, charge_distance * 0.3),
			"speed": randf_range(1.5, 2.5),
			"width": randi_range(2, 4)
		})

func _generate_dust_trail() -> void:
	var dust_count = randi_range(20, 35)
	for i in range(dust_count):
		var spawn_progress = randf()  # When along the charge path to spawn
		_dust_trail.append({
			"spawn_progress": spawn_progress,
			"y_offset": randf_range(-25, 25),
			"size": randi_range(4, 10),
			"drift": Vector2(randf_range(-30, -60), randf_range(-20, 20)),
			"alpha_offset": randf_range(0.0, 0.3)
		})

func _generate_impact_burst() -> void:
	var burst_count = randi_range(10, 16)
	for i in range(burst_count):
		var angle = randf_range(-PI * 0.4, PI * 0.4)
		_impact_burst.append({
			"angle": angle,
			"dist": randf_range(20, 50),
			"size": randi_range(3, 6)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	_draw_speed_lines()
	_draw_dust_trail()
	_draw_energy_aura()
	_draw_impact_burst()

func _draw_speed_lines() -> void:
	for line in _speed_lines:
		# Speed lines move backward relative to charge direction
		var line_x = line.start_x - _time * charge_distance * line.speed

		# Only draw lines in visible range
		if line_x > charge_distance or line_x + line.length < -charge_distance * 0.5:
			continue

		var alpha = 0.8 * (1.0 - abs(line.y_offset) / 50.0)
		alpha *= (1.0 - _time * 0.3)

		if alpha <= 0:
			continue

		var color = SPEED_LINE_COLOR
		color.a = alpha

		var start_pos = Vector2(line_x, line.y_offset)
		var end_pos = Vector2(line_x + line.length, line.y_offset)

		_draw_pixel_line(start_pos, end_pos, line.width, color)

func _draw_dust_trail() -> void:
	for dust in _dust_trail:
		# Dust spawns as the charge progresses
		if _time < dust.spawn_progress:
			continue

		var dust_age = _time - dust.spawn_progress
		var dust_alpha = (1.0 - dust_age * 1.5) * (1.0 - dust.alpha_offset)

		if dust_alpha <= 0:
			continue

		var color = DUST_COLOR
		color.a = dust_alpha

		# Position along the charge path where dust spawned, then drift
		var spawn_x = dust.spawn_progress * charge_distance * 0.8
		var pos = Vector2(spawn_x, dust.y_offset)
		pos += dust.drift * dust_age

		_draw_pixel_rect(pos, dust.size, color)

func _draw_energy_aura() -> void:
	# Energy aura around the charging player (at leading edge)
	var lead_x = _time * charge_distance

	var aura_alpha = 0.6 * (1.0 - _time * 0.4)
	if aura_alpha <= 0:
		return

	var color = ENERGY_COLOR
	color.a = aura_alpha

	# Draw aura circle at leading edge
	var aura_radius = 25.0 + sin(_time * PI * 4) * 5.0
	var segments = 16
	for i in range(segments):
		var angle = (TAU / segments) * i
		var pos = Vector2(lead_x, 0) + Vector2.from_angle(angle) * aura_radius
		_draw_pixel_rect(pos, pixel_size * 2, color)

func _draw_impact_burst() -> void:
	# Impact burst at the end of charge
	var impact_time = clamp((_time - 0.7) * 4.0, 0.0, 1.0)
	if impact_time <= 0:
		return

	var alpha = (1.0 - impact_time) * 1.0
	if alpha <= 0:
		return

	var impact_x = charge_distance

	for burst in _impact_burst:
		var color = IMPACT_COLOR
		color.a = alpha

		var pos = Vector2(impact_x, 0) + Vector2.from_angle(burst.angle) * burst.dist * impact_time
		_draw_pixel_rect(pos, burst.size * pixel_size, color)

	# Central impact flash
	var flash_color = IMPACT_COLOR
	flash_color.a = alpha * 1.2
	var flash_size = 20.0 * (1.0 + impact_time * 0.5)
	_draw_pixel_rect(Vector2(impact_x, 0), int(flash_size), flash_color)

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
