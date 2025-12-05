extends Node2D

# Reaper Touch - T2 Execute with death essence and soul drain visual

var pixel_size := 4
var duration := 0.55
var elapsed := 0.0

# Dark slash
var slash_progress := 0.0
var slash_angle := -PI/4

# Soul wisps being drained
var soul_wisps := []
var num_wisps := 10

# Death essence particles
var death_particles := []
var num_death := 16

# Reaper mark (skull/death symbol)
var mark_alpha := 0.0

func _ready() -> void:
	# Initialize soul wisps (float toward center)
	for i in range(num_wisps):
		var angle = randf() * TAU
		var dist = randf_range(50, 80)
		soul_wisps.append({
			"pos": Vector2(cos(angle), sin(angle)) * dist,
			"target": Vector2.ZERO,
			"alpha": 0.8,
			"speed": randf_range(80, 140),
			"wobble": randf() * TAU
		})

	# Initialize death particles
	for i in range(num_death):
		var angle = randf() * TAU
		death_particles.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(10, 40),
			"velocity": Vector2(0, randf_range(-40, -80)),
			"alpha": 0.7,
			"size": randf_range(4, 8)
		})

	await get_tree().create_timer(duration + 0.15).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Slash sweeps
	slash_progress = ease(min(progress * 3, 1.0), 0.2)

	# Mark appears then fades
	if elapsed < 0.2:
		mark_alpha = elapsed / 0.2
	else:
		mark_alpha = max(0, 1.0 - (elapsed - 0.2) / 0.35)

	# Update soul wisps (float toward center)
	for wisp in soul_wisps:
		var dir = (wisp.target - wisp.pos).normalized()
		wisp.wobble += delta * 5
		var wobble_offset = Vector2(sin(wisp.wobble), cos(wisp.wobble)) * 10
		wisp.pos += (dir * wisp.speed + wobble_offset * 0.3) * delta
		if wisp.pos.length() < 15:
			wisp.alpha = max(0, wisp.alpha - delta * 4)
		wisp.alpha = max(0, wisp.alpha - delta * 0.8)

	# Update death particles (rise and fade)
	for p in death_particles:
		p.pos += p.velocity * delta
		p.alpha = max(0, 0.7 - progress)
		p.size = max(2, p.size - delta * 3)

	queue_redraw()

func _draw() -> void:
	# Draw death particles (dark purple/black)
	for p in death_particles:
		if p.alpha > 0:
			var color = Color(0.3, 0.1, 0.4, p.alpha)
			_draw_pixel_circle(p.pos, p.size, color)

	# Draw soul wisps (ghostly green/white)
	for wisp in soul_wisps:
		if wisp.alpha > 0:
			var color = Color(0.6, 0.9, 0.7, wisp.alpha * 0.7)
			_draw_pixel_circle(wisp.pos, 6, color)
			# Trail
			var trail_color = Color(0.4, 0.8, 0.6, wisp.alpha * 0.3)
			var trail_offset = (wisp.target - wisp.pos).normalized() * -10
			_draw_pixel_circle(wisp.pos + trail_offset, 4, trail_color)

	# Draw dark slash
	if slash_progress > 0:
		var slash_end_angle = slash_angle + PI/2 * slash_progress
		# Dark edge
		var dark_color = Color(0.2, 0.05, 0.25, 0.9)
		_draw_slash_arc(Vector2.ZERO, 60, slash_angle, slash_end_angle, dark_color, 8)
		# Purple core
		var core_color = Color(0.5, 0.2, 0.6, 0.8)
		_draw_slash_arc(Vector2.ZERO, 50, slash_angle, slash_end_angle, core_color, 4)

	# Draw reaper mark (simplified skull)
	if mark_alpha > 0:
		var mark_color = Color(0.8, 0.2, 0.3, mark_alpha * 0.7)
		_draw_death_mark(Vector2(0, -10), mark_color)

func _draw_slash_arc(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color, width: int) -> void:
	var arc_length = abs(end_angle - start_angle)
	var steps = int(arc_length * radius / pixel_size) + 8
	for i in range(steps):
		var t = float(i) / steps
		var angle = start_angle + t * (end_angle - start_angle)
		var fade = 1.0 - t * 0.6
		for w in range(width / pixel_size):
			var r = radius - w * pixel_size
			var pos = center + Vector2(cos(angle), sin(angle)) * r
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), Color(color.r, color.g, color.b, color.a * fade))

func _draw_death_mark(center: Vector2, color: Color) -> void:
	# Simple skull shape
	# Head circle
	_draw_pixel_circle(center, 12, color)
	# Eyes (darker)
	var eye_color = Color(0.1, 0.05, 0.1, color.a)
	var left_eye = center + Vector2(-4, -2)
	var right_eye = center + Vector2(4, -2)
	_draw_pixel_circle(left_eye, 3, eye_color)
	_draw_pixel_circle(right_eye, 3, eye_color)
	# Jaw
	var jaw_color = Color(color.r * 0.8, color.g * 0.8, color.b * 0.8, color.a * 0.8)
	_draw_pixel_rect(Rect2(center + Vector2(-6, 6), Vector2(12, 6)), jaw_color)

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 2)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = center + pos
				draw_pos = (draw_pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)

func _draw_pixel_rect(rect: Rect2, color: Color) -> void:
	var snapped_pos = (rect.position / pixel_size).floor() * pixel_size
	var snapped_size = (rect.size / pixel_size).ceil() * pixel_size
	draw_rect(Rect2(snapped_pos, snapped_size), color)
