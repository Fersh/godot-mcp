extends Node2D
# Apex Predator Effect - Chain leap hunting marks with predator eyes
# T3-B: Predator Savage Leap of the Apex

const PIXEL_SIZE = 4
const DURATION = 1.2
const TARGET_COUNT = 3

var elapsed_time: float = 0.0
var eye_flash_time: float = 0.0
var targets_hit: int = 0
var trail_positions: Array[Vector2] = []
var chain_progress: float = 0.0

func _ready() -> void:
	# Initialize chain trail positions
	for i in range(TARGET_COUNT):
		var angle = (i * TAU / TARGET_COUNT) - PI/2
		trail_positions.append(Vector2(cos(angle), sin(angle)) * (40 + i * 30))

	var tween = create_tween()
	tween.tween_property(self, "chain_progress", 1.0, DURATION * 0.8).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_method(_hit_target, 0, TARGET_COUNT, DURATION * 0.6).set_ease(Tween.EASE_IN_OUT)

	await get_tree().create_timer(DURATION).timeout
	queue_free()

func _hit_target(count: int) -> void:
	targets_hit = count

func _process(delta: float) -> void:
	elapsed_time += delta
	eye_flash_time += delta * 8.0
	queue_redraw()

func _draw() -> void:
	# Draw chain leap trails
	for i in range(targets_hit):
		_draw_chain_trail(i)

	# Draw predator eyes at center
	_draw_predator_eyes()

	# Draw hunting marks at each target
	for i in range(targets_hit):
		_draw_hunting_mark(trail_positions[i], i)

func _draw_chain_trail(index: int) -> void:
	var target_pos = trail_positions[index]
	var steps = 6
	var progress = minf(chain_progress * (index + 1) / TARGET_COUNT, 1.0)

	for s in range(int(steps * progress)):
		var t = float(s) / steps
		var pos = target_pos * t
		var alpha = (1.0 - t) * 0.6 * (1.0 - elapsed_time / DURATION)

		# Orange/red trail pixels
		var color = Color(1.0, 0.4 + t * 0.3, 0.1, alpha)
		_draw_pixel(pos, color)

		# Blood trail
		if s > 2:
			var blood_color = Color(0.8, 0.1, 0.1, alpha * 0.7)
			_draw_pixel(pos + Vector2(PIXEL_SIZE, PIXEL_SIZE), blood_color)

func _draw_predator_eyes() -> void:
	var flash = (sin(eye_flash_time) + 1.0) * 0.5
	var eye_color = Color(1.0, 0.2 + flash * 0.3, 0.1, 0.9)
	var glow_color = Color(1.0, 0.3, 0.0, 0.4 * flash)

	# Left eye
	_draw_pixel(Vector2(-PIXEL_SIZE * 2, -PIXEL_SIZE), eye_color)
	_draw_pixel(Vector2(-PIXEL_SIZE * 3, -PIXEL_SIZE), glow_color)

	# Right eye
	_draw_pixel(Vector2(PIXEL_SIZE * 2, -PIXEL_SIZE), eye_color)
	_draw_pixel(Vector2(PIXEL_SIZE * 3, -PIXEL_SIZE), glow_color)

	# Eye shine
	if flash > 0.7:
		var shine_color = Color(1.0, 1.0, 0.8, (flash - 0.7) * 2.0)
		_draw_pixel(Vector2(-PIXEL_SIZE * 2, -PIXEL_SIZE * 2), shine_color)
		_draw_pixel(Vector2(PIXEL_SIZE * 2, -PIXEL_SIZE * 2), shine_color)

func _draw_hunting_mark(pos: Vector2, index: int) -> void:
	if index >= targets_hit:
		return

	var pulse = (sin(elapsed_time * 6.0 + index) + 1.0) * 0.5
	var hit_delay = float(index) / TARGET_COUNT * 0.4
	var local_time = maxf(0.0, elapsed_time - hit_delay)
	var expand = minf(local_time * 4.0, 1.0)
	var fade = 1.0 - maxf(0.0, (elapsed_time - DURATION * 0.6) / (DURATION * 0.4))

	# X mark pattern
	var mark_color = Color(1.0, 0.2, 0.1, fade * (0.7 + pulse * 0.3))
	var size = int(expand * 3)

	for d in range(size):
		var offset = d * PIXEL_SIZE
		_draw_pixel(pos + Vector2(offset, offset), mark_color)
		_draw_pixel(pos + Vector2(-offset, offset), mark_color)
		_draw_pixel(pos + Vector2(offset, -offset), mark_color)
		_draw_pixel(pos + Vector2(-offset, -offset), mark_color)

	# Blood splatter
	if local_time > 0.1:
		var blood_color = Color(0.7, 0.0, 0.0, fade * 0.6)
		_draw_pixel(pos + Vector2(PIXEL_SIZE * 2, 0), blood_color)
		_draw_pixel(pos + Vector2(-PIXEL_SIZE * 2, PIXEL_SIZE), blood_color)
		_draw_pixel(pos + Vector2(0, PIXEL_SIZE * 2), blood_color)

	# Heal indicator (green)
	if local_time > 0.3:
		var heal_pulse = sin(local_time * 8.0) * 0.5 + 0.5
		var heal_color = Color(0.2, 1.0, 0.3, fade * heal_pulse * 0.5)
		_draw_pixel(pos + Vector2(0, -PIXEL_SIZE * 3), heal_color)
		_draw_pixel(pos + Vector2(PIXEL_SIZE, -PIXEL_SIZE * 3), heal_color)

func _draw_pixel(pos: Vector2, color: Color) -> void:
	var snapped_pos = Vector2(
		floorf(pos.x / PIXEL_SIZE) * PIXEL_SIZE,
		floorf(pos.y / PIXEL_SIZE) * PIXEL_SIZE
	)
	draw_rect(Rect2(snapped_pos, Vector2(PIXEL_SIZE, PIXEL_SIZE)), color)
