extends Node2D

# Shadow Legion - T3 Dash with army of shadow clones

var pixel_size := 4
var duration := 0.9
var elapsed := 0.0

# Shadow clones
var shadows := []
var num_shadows := 8

# Shadow trail
var shadow_trail := []
var num_trail := 20

# Dark energy aura
var dark_aura_alpha := 0.0

# Clone attack slashes
var clone_slashes := []

func _ready() -> void:
	# Initialize shadow clones (formation)
	for i in range(num_shadows):
		var row = i / 4
		var col = i % 4
		var x = (col - 1.5) * 30
		var y = row * 25 + 20
		shadows.append({
			"pos": Vector2(x, y),
			"alpha": 0.0,
			"trigger_time": i * 0.08,
			"attack_time": 0.4 + i * 0.05
		})
		# Add slash for each clone
		clone_slashes.append({
			"pos": Vector2(x, y),
			"angle": randf_range(-PI/4, PI/4),
			"alpha": 0.0,
			"trigger_time": 0.4 + i * 0.05
		})

	# Initialize shadow trail
	for i in range(num_trail):
		shadow_trail.append({
			"pos": Vector2(randf_range(-50, 50), randf_range(-30, 30)),
			"alpha": 0.5,
			"size": randf_range(8, 16)
		})

	await get_tree().create_timer(duration + 0.15).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Dark aura
	dark_aura_alpha = ease(min(progress * 2, 1.0), 0.3) * (1.0 - progress * 0.4)

	# Update shadows
	for shadow in shadows:
		if elapsed > shadow.trigger_time:
			var age = elapsed - shadow.trigger_time
			if age < 0.15:
				shadow.alpha = age / 0.15 * 0.7
			else:
				shadow.alpha = max(0, 0.7 - (age - 0.15) / 0.5)

	# Update clone slashes
	for slash in clone_slashes:
		if elapsed > slash.trigger_time:
			var age = elapsed - slash.trigger_time
			if age < 0.08:
				slash.alpha = age / 0.08
			else:
				slash.alpha = max(0, 1.0 - (age - 0.08) / 0.2)

	# Update shadow trail
	for trail in shadow_trail:
		trail.alpha = max(0, 0.5 - progress * 0.6)

	queue_redraw()

func _draw() -> void:
	# Draw shadow trail
	for trail in shadow_trail:
		if trail.alpha > 0:
			var color = Color(0.15, 0.1, 0.2, trail.alpha * 0.4)
			_draw_pixel_circle(trail.pos, trail.size, color)

	# Draw dark aura
	if dark_aura_alpha > 0:
		var aura_color = Color(0.2, 0.15, 0.3, dark_aura_alpha * 0.4)
		_draw_pixel_circle(Vector2.ZERO, 70, aura_color)

	# Draw shadow clones
	for shadow in shadows:
		if shadow.alpha > 0:
			_draw_shadow_clone(shadow.pos, shadow.alpha)

	# Draw clone slashes
	for slash in clone_slashes:
		if slash.alpha > 0:
			var color = Color(0.6, 0.5, 0.8, slash.alpha)
			var length = 35
			var dir = Vector2(cos(slash.angle), sin(slash.angle))
			_draw_pixel_line(slash.pos - dir * length/2, slash.pos + dir * length/2, color)

	# Draw main figure at center (brighter)
	var main_alpha = 1.0 - elapsed / duration * 0.3
	if main_alpha > 0:
		_draw_shadow_clone(Vector2.ZERO, main_alpha, true)

func _draw_shadow_clone(pos: Vector2, alpha: float, is_main: bool = false) -> void:
	var base_color = Color(0.3, 0.25, 0.4, alpha) if not is_main else Color(0.5, 0.45, 0.6, alpha)

	# Head
	_draw_pixel_circle(pos + Vector2(0, -18), 8, base_color)

	# Body
	for y in range(5):
		var width = 4 if y < 2 else 6
		for x in range(-width, width + 1, pixel_size):
			var body_pos = pos + Vector2(x, -10 + y * pixel_size)
			body_pos = (body_pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(body_pos, Vector2(pixel_size, pixel_size)), base_color)

	# Legs
	for y in range(3):
		var left = pos + Vector2(-4, 10 + y * pixel_size)
		var right = pos + Vector2(4, 10 + y * pixel_size)
		left = (left / pixel_size).floor() * pixel_size
		right = (right / pixel_size).floor() * pixel_size
		draw_rect(Rect2(left, Vector2(pixel_size, pixel_size)), base_color)
		draw_rect(Rect2(right, Vector2(pixel_size, pixel_size)), base_color)

	# Eyes (glowing)
	if is_main:
		var eye_color = Color(0.8, 0.6, 1.0, alpha)
		draw_rect(Rect2((pos + Vector2(-3, -20)) / pixel_size * pixel_size, Vector2(pixel_size, pixel_size)), eye_color)
		draw_rect(Rect2((pos + Vector2(2, -20)) / pixel_size * pixel_size, Vector2(pixel_size, pixel_size)), eye_color)

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
