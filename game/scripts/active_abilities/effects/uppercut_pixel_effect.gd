extends Node2D

# Uppercut - Procedural pixelated rising strike effect
# Upward slash arc with launch particles and impact flash

var radius: float = 100.0
var duration: float = 0.4
var pixel_size: int = 4

var _time: float = 0.0
var _slash_trail: Array[Dictionary] = []
var _launch_particles: Array[Dictionary] = []
var _impact_sparks: Array[Dictionary] = []

# Uppercut colors
const SLASH_COLOR = Color(1.0, 0.98, 0.9, 1.0)  # Bright white/cream
const TRAIL_COLOR = Color(0.85, 0.8, 0.7, 0.7)  # Warm trail
const LAUNCH_COLOR = Color(0.9, 0.85, 0.6, 0.8)  # Golden launch effect
const IMPACT_COLOR = Color(1.0, 1.0, 0.85, 1.0)  # Bright impact flash

func _ready() -> void:
	_generate_slash_trail()
	_generate_launch_particles()
	_generate_impact_sparks()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 0.4) -> void:
	radius = p_radius
	duration = p_duration

func _generate_slash_trail() -> void:
	# Upward curving slash trail
	for i in range(8):
		_slash_trail.append({
			"offset": i * 5,
			"width": (8 - i) * 2,
			"delay": i * 0.02
		})

func _generate_launch_particles() -> void:
	var particle_count = randi_range(12, 20)
	for i in range(particle_count):
		_launch_particles.append({
			"start_x": randf_range(-30, 30),
			"velocity": Vector2(randf_range(-40, 40), randf_range(-150, -250)),
			"size": randi_range(2, 4),
			"delay": randf_range(0.0, 0.15)
		})

func _generate_impact_sparks() -> void:
	var spark_count = randi_range(10, 16)
	for i in range(spark_count):
		var angle = randf_range(-PI * 0.6, -PI * 0.1)  # Upward fan
		_impact_sparks.append({
			"angle": angle,
			"speed": randf_range(80, 160),
			"size": randi_range(2, 4),
			"delay": randf_range(0.05, 0.2)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	_draw_slash_trail()
	_draw_launch_particles()
	_draw_impact_sparks()
	_draw_impact_flash()

func _draw_slash_trail() -> void:
	# Curved upward slash path
	var slash_progress = clamp(_time * 1.5, 0.0, 1.0)

	for trail in _slash_trail:
		var trail_time = clamp((_time - trail.delay) * 1.4, 0.0, 1.0)
		if trail_time <= 0:
			continue

		var alpha = (1.0 - trail_time * 0.6) * 0.9
		if alpha <= 0:
			continue

		var color = TRAIL_COLOR
		color.a = alpha

		# Draw curved upward path
		var segments = 10
		for i in range(int(segments * trail_time)):
			var t = float(i) / (segments - 1)
			# Curved upward arc
			var x = sin(t * PI * 0.5) * radius * 0.4
			var y = -t * radius - trail.offset

			var point_alpha = (1.0 - t * 0.5) * alpha
			var point_color = color
			point_color.a = point_alpha

			_draw_pixel_rect(Vector2(x, y), trail.width, point_color)

	# Leading edge - bright tip
	if slash_progress > 0:
		var tip_y = -slash_progress * radius
		var tip_x = sin(slash_progress * PI * 0.5) * radius * 0.4
		var tip_color = SLASH_COLOR
		tip_color.a = 1.0 - _time * 0.5
		_draw_pixel_rect(Vector2(tip_x, tip_y), pixel_size * 3, tip_color)

func _draw_launch_particles() -> void:
	for particle in _launch_particles:
		var particle_time = clamp((_time - particle.delay) * 1.5, 0.0, 1.0)
		if particle_time <= 0:
			continue

		var alpha = (1.0 - particle_time) * 0.8
		if alpha <= 0:
			continue

		var pos = Vector2(particle.start_x, 0) + particle.velocity * particle_time * duration

		var color = LAUNCH_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, particle.size * pixel_size, color)

func _draw_impact_sparks() -> void:
	for spark in _impact_sparks:
		var spark_time = clamp((_time - spark.delay) * 2.0, 0.0, 1.0)
		if spark_time <= 0:
			continue

		var alpha = (1.0 - spark_time) * 0.9
		if alpha <= 0:
			continue

		var pos = Vector2.from_angle(spark.angle) * spark.speed * spark_time * duration

		var color = SLASH_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, spark.size * pixel_size, color)

func _draw_impact_flash() -> void:
	# Central impact flash
	var flash_alpha = (1.0 - _time * 3.0)
	if flash_alpha <= 0:
		return

	var color = IMPACT_COLOR
	color.a = flash_alpha

	var flash_size = 25.0 * (1.0 + _time * 0.5)
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
