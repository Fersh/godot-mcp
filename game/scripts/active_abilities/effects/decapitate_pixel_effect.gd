extends Node2D

# Decapitate - T3 Execute instant kill strike

var pixel_size := 4
var duration := 0.55
var elapsed := 0.0

# Swift horizontal slash
var slash_progress := 0.0
var slash_width := 100.0

# Blood fountain
var blood_fountain := []
var num_blood := 30

# Death mark
var death_mark_alpha := 0.0

# Impact flash
var flash_alpha := 0.0

# Execution complete indicator
var complete_alpha := 0.0

func _ready() -> void:
	# Initialize blood fountain (sprays upward)
	for i in range(num_blood):
		var angle = randf_range(-PI * 0.8, -PI * 0.2)
		blood_fountain.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(150, 300),
			"size": randi_range(1, 4) * pixel_size,
			"alpha": 0.0,
			"gravity": randf_range(400, 700)
		})

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Swift slash
	slash_progress = ease(min(progress * 4, 1.0), 0.1)

	# Death mark appears
	if progress > 0.2 and progress < 0.6:
		death_mark_alpha = min((progress - 0.2) / 0.1, 1.0)
	else:
		death_mark_alpha = max(0, death_mark_alpha - delta * 3)

	# Flash on hit
	if progress > 0.25 and progress < 0.35:
		flash_alpha = 1.0 - (progress - 0.25) / 0.1
	else:
		flash_alpha = 0

	# Blood triggers after slash
	if progress > 0.25:
		for b in blood_fountain:
			if b.alpha == 0:
				b.alpha = 1.0

	# Execution complete
	if progress > 0.5:
		complete_alpha = min((progress - 0.5) / 0.2, 1.0) * max(0, 1.0 - (progress - 0.7) / 0.3)

	# Update blood
	for b in blood_fountain:
		if b.alpha > 0:
			b.velocity.y += b.gravity * delta
			b.pos += b.velocity * delta
			b.alpha = max(0, b.alpha - delta * 1.5)

	queue_redraw()

func _draw() -> void:
	# Draw slash
	if slash_progress > 0:
		var slash_x = -slash_width/2 + slash_progress * slash_width
		# Trail
		var trail_color = Color(0.8, 0.2, 0.2, 0.6 * (1.0 - elapsed/duration))
		for y_off in range(-2, 3):
			_draw_pixel_line(
				Vector2(-slash_width/2, y_off * pixel_size),
				Vector2(slash_x, y_off * pixel_size),
				trail_color
			)
		# Blade edge
		var edge_color = Color(1.0, 0.95, 0.9, 1.0)
		for y_off in range(-1, 2):
			var pos = Vector2(slash_x, y_off * pixel_size)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), edge_color)

	# Draw flash
	if flash_alpha > 0:
		var flash_color = Color(1.0, 0.9, 0.8, flash_alpha)
		_draw_pixel_circle(Vector2.ZERO, 35, flash_color)

	# Draw death mark
	if death_mark_alpha > 0:
		_draw_death_mark(Vector2(0, -30), death_mark_alpha)

	# Draw blood fountain
	for b in blood_fountain:
		if b.alpha > 0:
			var color = Color(0.7, 0.1, 0.1, b.alpha)
			var pos = (b.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(b.size, b.size)), color)

	# Draw execution complete
	if complete_alpha > 0:
		_draw_execution_complete(Vector2(0, 20), complete_alpha)

func _draw_death_mark(center: Vector2, alpha: float) -> void:
	var color = Color(0.8, 0.1, 0.1, alpha)
	# X mark
	var size = 12
	_draw_pixel_line(center + Vector2(-size, -size), center + Vector2(size, size), color)
	_draw_pixel_line(center + Vector2(size, -size), center + Vector2(-size, size), color)

func _draw_execution_complete(center: Vector2, alpha: float) -> void:
	var color = Color(0.9, 0.2, 0.2, alpha)
	# Skull symbol
	_draw_pixel_circle(center, 10, color)
	# Eyes
	var eye_color = Color(0.1, 0.05, 0.05, alpha)
	draw_rect(Rect2((center + Vector2(-4, -2)) / pixel_size * pixel_size, Vector2(pixel_size, pixel_size)), eye_color)
	draw_rect(Rect2((center + Vector2(3, -2)) / pixel_size * pixel_size, Vector2(pixel_size, pixel_size)), eye_color)

func _draw_pixel_line(from: Vector2, to: Vector2, color: Color) -> void:
	var dist = from.distance_to(to)
	var steps = int(dist / pixel_size) + 1
	for i in range(steps):
		var t = float(i) / max(steps - 1, 1)
		var pos = from.lerp(to, t)
		pos = (pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 2)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = center + pos
				draw_pos = (draw_pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)
