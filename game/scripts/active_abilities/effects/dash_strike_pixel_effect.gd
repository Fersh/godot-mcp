extends Node2D

# Dash Strike - Procedural pixelated quick dash effect
# Speed blur, afterimage, and slash at destination

var dash_distance: float = 200.0
var duration: float = 0.3
var pixel_size: int = 4
var direction: Vector2 = Vector2.RIGHT

var _time: float = 0.0
var _speed_blur: Array[Dictionary] = []
var _afterimages: Array[Dictionary] = []
var _slash_particles: Array[Dictionary] = []

# Dash colors
const BLUR_COLOR = Color(0.8, 0.85, 1.0, 0.6)  # Light blue blur
const AFTERIMAGE_COLOR = Color(0.6, 0.65, 0.8, 0.4)  # Faded afterimage
const SLASH_COLOR = Color(1.0, 1.0, 1.0, 0.95)  # White slash
const TRAIL_COLOR = Color(0.7, 0.75, 0.9, 0.5)  # Blue-ish trail

func _ready() -> void:
	rotation = direction.angle()
	_generate_speed_blur()
	_generate_afterimages()
	_generate_slash_particles()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_distance: float, p_duration: float = 0.3) -> void:
	dash_distance = p_distance
	duration = p_duration

func _generate_speed_blur() -> void:
	var blur_count = randi_range(15, 22)
	for i in range(blur_count):
		_speed_blur.append({
			"y_offset": randf_range(-30, 30),
			"length": randf_range(40, 100),
			"speed": randf_range(2.0, 3.5),
			"width": randi_range(2, 4),
			"start_x": randf_range(-30, dash_distance * 0.4)
		})

func _generate_afterimages() -> void:
	# Ghost afterimages at intervals along path
	for i in range(4):
		_afterimages.append({
			"x_position": dash_distance * (0.2 + i * 0.2),
			"fade_delay": i * 0.08,
			"size": 20 - i * 3
		})

func _generate_slash_particles() -> void:
	var particle_count = randi_range(10, 16)
	for i in range(particle_count):
		var angle = randf_range(-PI * 0.4, PI * 0.4)
		_slash_particles.append({
			"angle": angle,
			"speed": randf_range(60, 120),
			"size": randi_range(2, 4),
			"delay": randf_range(0.5, 0.7)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	_draw_speed_blur()
	_draw_afterimages()
	_draw_dash_trail()
	_draw_slash_particles()
	_draw_destination_slash()

func _draw_speed_blur() -> void:
	for blur in _speed_blur:
		var blur_x = blur.start_x - _time * dash_distance * blur.speed

		if blur_x > dash_distance or blur_x + blur.length < -dash_distance * 0.3:
			continue

		var alpha = 0.6 * (1.0 - abs(blur.y_offset) / 40.0) * (1.0 - _time * 0.5)
		if alpha <= 0:
			continue

		var color = BLUR_COLOR
		color.a = alpha

		var start_pos = Vector2(blur_x, blur.y_offset)
		var end_pos = Vector2(blur_x + blur.length, blur.y_offset)

		_draw_pixel_line(start_pos, end_pos, blur.width, color)

func _draw_afterimages() -> void:
	for image in _afterimages:
		# Afterimage appears as dash passes, then fades
		var appear_time = image.x_position / dash_distance
		if _time < appear_time:
			continue

		var image_age = _time - appear_time
		var alpha = (1.0 - image_age * 2.0) * 0.5
		if alpha <= 0:
			continue

		var color = AFTERIMAGE_COLOR
		color.a = alpha

		# Simple silhouette shape
		var pos = Vector2(image.x_position, 0)
		for y in range(-2, 3):
			for x in range(-1, 2):
				var offset = Vector2(x * pixel_size * 2, y * pixel_size * 3)
				_draw_pixel_rect(pos + offset, image.size, color)

func _draw_dash_trail() -> void:
	# Continuous trail from start to current position
	var current_x = _time * dash_distance

	var alpha = 0.5 * (1.0 - _time * 0.3)
	if alpha <= 0:
		return

	var color = TRAIL_COLOR
	color.a = alpha

	# Draw trail line
	var trail_start = max(0, current_x - dash_distance * 0.3)
	_draw_pixel_line(Vector2(trail_start, 0), Vector2(current_x, 0), pixel_size * 2, color)

func _draw_slash_particles() -> void:
	for particle in _slash_particles:
		var particle_time = clamp((_time - particle.delay) * 3.0, 0.0, 1.0)
		if particle_time <= 0:
			continue

		var alpha = (1.0 - particle_time) * 0.9
		if alpha <= 0:
			continue

		var base_pos = Vector2(dash_distance, 0)
		var offset = Vector2.from_angle(particle.angle) * particle.speed * particle_time * duration
		var pos = base_pos + offset

		var color = SLASH_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, particle.size * pixel_size, color)

func _draw_destination_slash() -> void:
	# Slash effect at destination
	var slash_time = clamp((_time - 0.5) * 3.0, 0.0, 1.0)
	if slash_time <= 0:
		return

	var alpha = (1.0 - slash_time) * 0.95
	if alpha <= 0:
		return

	var color = SLASH_COLOR
	color.a = alpha

	# Diagonal slash lines
	var slash_length = 40.0 * slash_time
	var base_pos = Vector2(dash_distance, 0)

	_draw_pixel_line(
		base_pos + Vector2(-slash_length * 0.5, -slash_length * 0.5),
		base_pos + Vector2(slash_length * 0.5, slash_length * 0.5),
		pixel_size * 2, color
	)

	# Impact flash
	var flash_color = SLASH_COLOR
	flash_color.a = alpha * 0.8
	_draw_pixel_rect(base_pos, int(20.0 * (1.0 - slash_time * 0.5)), flash_color)

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
