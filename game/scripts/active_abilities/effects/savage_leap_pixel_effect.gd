extends Node2D

# Savage Leap - Procedural pixelated landing impact effect
# Dust cloud, ground crack lines, and impact shockwave

var radius: float = 100.0
var duration: float = 0.4
var pixel_size: int = 4

var _time: float = 0.0
var _dust_particles: Array[Dictionary] = []
var _crack_lines: Array[Dictionary] = []
var _debris: Array[Dictionary] = []

# Earth/ground colors
const DUST_COLOR = Color(0.65, 0.55, 0.4, 1.0)  # Brown dust
const CRACK_COLOR = Color(0.3, 0.25, 0.2, 1.0)  # Dark brown cracks
const IMPACT_COLOR = Color(0.8, 0.7, 0.5, 1.0)  # Light tan impact
const DEBRIS_COLOR = Color(0.5, 0.4, 0.3, 1.0)  # Rock debris

func _ready() -> void:
	_generate_dust()
	_generate_cracks()
	_generate_debris()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 0.4) -> void:
	radius = p_radius
	duration = p_duration

func _generate_dust() -> void:
	# Generate dust cloud particles
	var dust_count = randi_range(20, 35)
	for i in range(dust_count):
		var angle = randf() * TAU
		var speed = randf_range(60.0, 150.0)
		var size = randi_range(2, 5)
		_dust_particles.append({
			"angle": angle,
			"speed": speed,
			"size": size,
			"delay": randf_range(0.0, 0.1),
			"lifetime": randf_range(0.6, 1.0),
			"rise": randf_range(-40.0, -80.0)  # Dust rises up
		})

func _generate_cracks() -> void:
	# Generate ground crack lines from impact point
	var crack_count = randi_range(5, 8)
	for i in range(crack_count):
		var angle = (TAU / crack_count) * i + randf_range(-0.3, 0.3)
		var length = radius * randf_range(0.4, 0.8)
		var branches: Array[Dictionary] = []
		# Add small branch cracks
		if randf() > 0.4:
			var branch_angle = angle + randf_range(-0.5, 0.5)
			branches.append({
				"angle": branch_angle,
				"length": length * randf_range(0.3, 0.5),
				"start_t": randf_range(0.3, 0.6)
			})
		_crack_lines.append({
			"angle": angle,
			"length": length,
			"branches": branches
		})

func _generate_debris() -> void:
	# Generate flying rock debris
	var debris_count = randi_range(8, 15)
	for i in range(debris_count):
		var angle = randf() * TAU
		var speed = randf_range(100.0, 200.0)
		var size = randi_range(3, 6)
		_debris.append({
			"angle": angle,
			"speed": speed,
			"size": size,
			"gravity": randf_range(300.0, 500.0),
			"rotation": randf() * TAU
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Draw ground impact circle
	_draw_impact_crater()

	# Draw crack lines
	_draw_cracks()

	# Draw dust cloud
	_draw_dust()

	# Draw debris
	_draw_debris()

	# Draw central impact flash
	_draw_impact_flash()

func _draw_impact_crater() -> void:
	var crater_progress = clamp(_time * 3.0, 0.0, 1.0)
	var crater_alpha = (1.0 - _time) * 0.6

	if crater_alpha <= 0:
		return

	var color = CRACK_COLOR
	color.a = crater_alpha

	# Draw pixelated crater ring
	var crater_radius = radius * 0.3 * crater_progress
	var segments = int(crater_radius * 0.8)
	segments = max(segments, 8)

	for i in range(segments):
		var angle = (TAU / segments) * i
		var pos = Vector2.from_angle(angle) * crater_radius
		_draw_pixel_rect(pos, pixel_size * 2, color)

func _draw_cracks() -> void:
	for crack in _crack_lines:
		var crack_progress = clamp(_time * 5.0, 0.0, 1.0)
		if crack_progress <= 0:
			continue

		var alpha = (1.0 - _time * 0.7) * 0.9
		var color = CRACK_COLOR
		color.a = alpha

		# Main crack
		var end_pos = Vector2.from_angle(crack.angle) * (crack.length * crack_progress)
		_draw_pixel_line(Vector2.ZERO, end_pos, pixel_size, color)

		# Branch cracks
		for branch in crack.branches:
			if crack_progress > branch.start_t:
				var branch_progress = (crack_progress - branch.start_t) / (1.0 - branch.start_t)
				var branch_start = Vector2.from_angle(crack.angle) * (crack.length * branch.start_t)
				var branch_end = branch_start + Vector2.from_angle(branch.angle) * (branch.length * branch_progress)
				_draw_pixel_line(branch_start, branch_end, pixel_size, color)

func _draw_dust() -> void:
	for dust in _dust_particles:
		var dust_progress = clamp((_time - dust.delay) * 1.5, 0.0, dust.lifetime)
		if dust_progress <= 0:
			continue

		var pos = Vector2.from_angle(dust.angle) * dust.speed * dust_progress
		pos.y += dust.rise * dust_progress  # Rise up

		var alpha = (1.0 - dust_progress / dust.lifetime) * 0.7
		var color = DUST_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, dust.size * pixel_size, color)

		# Dust trail
		var trail_alpha = alpha * 0.3
		var trail_color = color
		trail_color.a = trail_alpha
		var trail_pos = Vector2.from_angle(dust.angle) * dust.speed * dust_progress * 0.6
		trail_pos.y += dust.rise * dust_progress * 0.5
		_draw_pixel_rect(trail_pos, dust.size * pixel_size - pixel_size, trail_color)

func _draw_debris() -> void:
	for debris in _debris:
		var pos = Vector2.from_angle(debris.angle) * debris.speed * _time
		pos.y += debris.gravity * _time * _time  # Gravity arc

		var alpha = (1.0 - _time) * 0.9
		var color = DEBRIS_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, debris.size * pixel_size, color)

func _draw_impact_flash() -> void:
	var flash_alpha = (1.0 - _time * 4.0) * 0.9
	if flash_alpha <= 0:
		return

	var color = IMPACT_COLOR
	color.a = flash_alpha

	var flash_size = 30.0 * (1.0 + _time)
	for x in range(-int(flash_size / pixel_size), int(flash_size / pixel_size) + 1):
		for y in range(-int(flash_size / pixel_size), int(flash_size / pixel_size) + 1):
			var pos = Vector2(x, y) * pixel_size
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

func _draw_pixel_line(from: Vector2, to: Vector2, width: int, color: Color) -> void:
	var dist = from.distance_to(to)
	var steps = int(dist / pixel_size) + 1
	for i in range(steps + 1):
		var t = float(i) / max(steps, 1)
		var pos = from.lerp(to, t)
		_draw_pixel_rect(pos, width, color)
