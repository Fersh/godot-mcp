extends Node2D

# Cleave - Procedural pixelated wide arc slash effect
# Sweeping weapon arc with slash trails and impact sparks

var radius: float = 180.0
var arc_angle: float = PI * 0.8  # ~145 degree arc
var duration: float = 0.35
var pixel_size: int = 4
var direction: Vector2 = Vector2.RIGHT

var _time: float = 0.0
var _slash_trails: Array[Dictionary] = []
var _sparks: Array[Dictionary] = []
var _impact_lines: Array[Dictionary] = []

# Metallic slash colors
const SLASH_COLOR = Color(0.95, 0.95, 1.0, 0.95)  # Bright white/silver
const TRAIL_COLOR = Color(0.7, 0.75, 0.85, 0.7)  # Blue-tinted trail
const SPARK_COLOR = Color(1.0, 0.95, 0.7, 1.0)  # Golden sparks
const EDGE_COLOR = Color(0.5, 0.55, 0.7, 0.8)  # Dark edge highlight

func _ready() -> void:
	rotation = direction.angle()
	_generate_slash_trails()
	_generate_sparks()
	_generate_impact_lines()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 0.35) -> void:
	radius = p_radius
	duration = p_duration

func _generate_slash_trails() -> void:
	# Multiple arc trails at different radii
	for i in range(5):
		var trail_radius = radius * (0.4 + i * 0.15)
		_slash_trails.append({
			"radius": trail_radius,
			"width": (5 - i) * 2 + 2,
			"delay": i * 0.02,
			"alpha_mult": 1.0 - i * 0.15
		})

func _generate_sparks() -> void:
	var spark_count = randi_range(15, 25)
	for i in range(spark_count):
		var angle = randf_range(-arc_angle * 0.5, arc_angle * 0.5)
		var dist = radius * randf_range(0.7, 1.1)
		_sparks.append({
			"angle": angle,
			"dist": dist,
			"size": randi_range(2, 4),
			"velocity": Vector2.from_angle(angle + randf_range(-0.3, 0.3)) * randf_range(80, 150),
			"delay": randf_range(0.1, 0.3)
		})

func _generate_impact_lines() -> void:
	# Short radial lines at the arc edge
	var line_count = randi_range(8, 14)
	for i in range(line_count):
		var angle = randf_range(-arc_angle * 0.5, arc_angle * 0.5)
		_impact_lines.append({
			"angle": angle,
			"length": randf_range(15, 35),
			"delay": randf_range(0.0, 0.15)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	_draw_slash_arcs()
	_draw_impact_lines()
	_draw_sparks()
	_draw_leading_edge()

func _draw_slash_arcs() -> void:
	for trail in _slash_trails:
		var trail_time = clamp((_time - trail.delay) * 1.5, 0.0, 1.0)
		if trail_time <= 0:
			continue

		# Arc sweeps from one side to the other
		var sweep_start = -arc_angle * 0.5
		var sweep_end = arc_angle * 0.5
		var current_sweep = lerp(sweep_start, sweep_end, trail_time)

		# Draw trail behind the sweep
		var trail_length = arc_angle * 0.4 * trail_time
		var trail_start = current_sweep - trail_length

		var alpha = trail.alpha_mult * (1.0 - _time * 0.5)
		if alpha <= 0:
			continue

		var color = TRAIL_COLOR
		color.a = alpha

		# Draw arc as series of points
		var segments = int(trail_length * trail.radius / pixel_size)
		segments = max(segments, 8)
		for i in range(segments):
			var t = float(i) / max(segments - 1, 1)
			var angle = lerp(trail_start, current_sweep, t)
			var pos = Vector2.from_angle(angle) * trail.radius

			# Fade trail towards start
			var point_alpha = t * alpha
			var point_color = color
			point_color.a = point_alpha

			_draw_pixel_rect(pos, trail.width, point_color)

func _draw_leading_edge() -> void:
	# Bright leading edge of the slash
	var sweep_progress = clamp(_time * 1.3, 0.0, 1.0)
	var sweep_start = -arc_angle * 0.5
	var sweep_end = arc_angle * 0.5
	var current_angle = lerp(sweep_start, sweep_end, sweep_progress)

	var alpha = 1.0 - _time * 0.7
	if alpha <= 0:
		return

	var color = SLASH_COLOR
	color.a = alpha

	# Draw bright line from center to edge at current angle
	var edge_start = Vector2.from_angle(current_angle) * radius * 0.2
	var edge_end = Vector2.from_angle(current_angle) * radius

	_draw_pixel_line(edge_start, edge_end, pixel_size * 2, color)

	# Bright tip
	var tip_color = SLASH_COLOR
	tip_color.a = alpha * 1.2
	_draw_pixel_rect(edge_end, pixel_size * 3, tip_color)

func _draw_impact_lines() -> void:
	for line in _impact_lines:
		var line_time = clamp((_time - line.delay) * 2.0, 0.0, 1.0)
		if line_time <= 0:
			continue

		var alpha = (1.0 - line_time) * 0.8
		if alpha <= 0:
			continue

		var color = SLASH_COLOR
		color.a = alpha

		var start_pos = Vector2.from_angle(line.angle) * radius
		var end_pos = Vector2.from_angle(line.angle) * (radius + line.length * line_time)

		_draw_pixel_line(start_pos, end_pos, pixel_size, color)

func _draw_sparks() -> void:
	for spark in _sparks:
		var spark_time = clamp((_time - spark.delay) * 2.0, 0.0, 1.0)
		if spark_time <= 0:
			continue

		var alpha = (1.0 - spark_time) * 0.9
		if alpha <= 0:
			continue

		var base_pos = Vector2.from_angle(spark.angle) * spark.dist
		var pos = base_pos + spark.velocity * spark_time * duration

		var color = SPARK_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, spark.size * pixel_size, color)

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
