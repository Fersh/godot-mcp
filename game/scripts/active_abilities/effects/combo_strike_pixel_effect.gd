extends Node2D

# Combo Strike - Procedural pixelated multi-hit combo effect
# Sequential slashes with hit markers and impact flashes

var radius: float = 100.0
var duration: float = 0.5
var pixel_size: int = 4
var hit_count: int = 3

var _time: float = 0.0
var _slash_arcs: Array[Dictionary] = []
var _hit_sparks: Array[Dictionary] = []

# Combo colors
const SLASH_COLOR = Color(1.0, 1.0, 1.0, 0.95)  # White slash
const HIT_COLOR = Color(1.0, 0.9, 0.5, 0.9)  # Golden hit flash
const SPARK_COLOR = Color(1.0, 0.95, 0.7, 0.85)  # Yellow sparks
const TRAIL_COLOR = Color(0.85, 0.85, 0.95, 0.6)  # Light trail

func _ready() -> void:
	_generate_slash_arcs()
	_generate_hit_sparks()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 0.5, p_hits: int = 3) -> void:
	radius = p_radius
	duration = p_duration
	hit_count = p_hits

func _generate_slash_arcs() -> void:
	# Each hit has its own slash arc
	for i in range(hit_count):
		var hit_timing = float(i) / hit_count
		var angle_offset = (i - 1) * 0.4  # Alternate directions
		_slash_arcs.append({
			"timing": hit_timing,
			"angle": angle_offset,
			"arc_length": PI * 0.5,
			"radius": radius * (0.8 + i * 0.1)
		})

func _generate_hit_sparks() -> void:
	for hit in range(hit_count):
		var hit_timing = float(hit) / hit_count
		var spark_count = randi_range(6, 10)
		for i in range(spark_count):
			var angle = randf() * TAU
			_hit_sparks.append({
				"hit_timing": hit_timing,
				"angle": angle,
				"speed": randf_range(50, 100),
				"size": randi_range(2, 4)
			})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	for i in range(hit_count):
		_draw_slash_arc(i)
		_draw_hit_flash(i)
	_draw_hit_sparks()

func _draw_slash_arc(hit_index: int) -> void:
	var arc = _slash_arcs[hit_index]
	var hit_start = arc.timing
	var hit_end = hit_start + 1.0 / hit_count

	if _time < hit_start or _time > hit_end + 0.1:
		return

	var local_time = (_time - hit_start) / (1.0 / hit_count)
	local_time = clamp(local_time, 0.0, 1.0)

	var alpha = 0.9
	if local_time > 0.7:
		alpha = (1.0 - local_time) / 0.3 * 0.9

	if alpha <= 0:
		return

	var color = SLASH_COLOR
	color.a = alpha

	# Draw sweeping arc
	var sweep_progress = local_time
	var start_angle = arc.angle - arc.arc_length * 0.5
	var current_angle = start_angle + arc.arc_length * sweep_progress

	var segments = 10
	var trail_length = arc.arc_length * 0.4 * sweep_progress
	var trail_start = current_angle - trail_length

	for i in range(segments):
		var t = float(i) / (segments - 1)
		var seg_angle = lerp(trail_start, current_angle, t)
		var pos = Vector2.from_angle(seg_angle) * arc.radius

		var seg_alpha = t * alpha
		var seg_color = TRAIL_COLOR
		seg_color.a = seg_alpha

		_draw_pixel_rect(pos, pixel_size * 2, seg_color)

	# Bright leading edge
	var tip_pos = Vector2.from_angle(current_angle) * arc.radius
	_draw_pixel_rect(tip_pos, pixel_size * 3, color)

func _draw_hit_flash(hit_index: int) -> void:
	var hit_timing = float(hit_index) / hit_count
	var hit_window = 1.0 / hit_count

	if _time < hit_timing or _time > hit_timing + hit_window * 0.5:
		return

	var local_time = (_time - hit_timing) / (hit_window * 0.5)
	var flash_alpha = (1.0 - local_time) * 0.8

	if flash_alpha <= 0:
		return

	var color = HIT_COLOR
	color.a = flash_alpha

	var flash_size = 25.0 * (0.5 + local_time * 0.5)
	_draw_pixel_rect(Vector2.ZERO, int(flash_size), color)

func _draw_hit_sparks() -> void:
	for spark in _hit_sparks:
		var hit_start = spark.hit_timing
		var hit_window = 1.0 / hit_count

		if _time < hit_start or _time > hit_start + hit_window:
			continue

		var local_time = (_time - hit_start) / hit_window
		var alpha = (1.0 - local_time) * 0.85

		if alpha <= 0:
			continue

		var pos = Vector2.from_angle(spark.angle) * spark.speed * local_time * (duration / hit_count)

		var color = SPARK_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, spark.size * pixel_size, color)

func _draw_pixel_rect(pos: Vector2, size: int, color: Color) -> void:
	var snapped_pos = Vector2(
		snapped(pos.x, pixel_size) - size * 0.5,
		snapped(pos.y, pixel_size) - size * 0.5
	)
	draw_rect(Rect2(snapped_pos, Vector2(size, size)), color)
