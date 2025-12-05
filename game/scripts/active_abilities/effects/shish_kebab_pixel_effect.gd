extends Node2D

# Shish Kebab - T3 Impale multi-target skewer

var pixel_size := 4
var duration := 0.9
var elapsed := 0.0

# Giant skewer
var skewer_progress := 0.0
var skewer_length := 150.0

# Impaled targets (silhouettes)
var targets := []
var num_targets := 5

# Blood drips
var blood_drips := []
var num_drips := 25

# Skewer glow
var skewer_glow := 0.0

func _ready() -> void:
	# Initialize targets on skewer
	for i in range(num_targets):
		targets.append({
			"offset": 25 + i * 25,
			"alpha": 0.0,
			"trigger_time": 0.1 + i * 0.1,
			"wobble": randf() * TAU
		})

	# Initialize blood drips
	for i in range(num_drips):
		blood_drips.append({
			"pos": Vector2(randf_range(20, 130), randf_range(-20, 20)),
			"velocity": Vector2(0, randf_range(50, 150)),
			"alpha": 0.0,
			"trigger_time": randf_range(0.2, 0.6)
		})

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Skewer thrust
	skewer_progress = ease(min(progress * 2.5, 1.0), 0.15)
	skewer_glow = (1.0 - progress * 0.5) * 0.8

	# Update targets
	for target in targets:
		if elapsed > target.trigger_time:
			var age = elapsed - target.trigger_time
			if age < 0.1:
				target.alpha = age / 0.1
			else:
				target.alpha = max(0, 1.0 - (progress - 0.5))
			target.wobble += delta * 10

	# Update blood drips
	for drip in blood_drips:
		if elapsed > drip.trigger_time:
			if drip.alpha == 0:
				drip.alpha = 0.9
			drip.pos += drip.velocity * delta
			drip.velocity.y += 200 * delta
			drip.alpha = max(0, drip.alpha - delta * 1.5)

	queue_redraw()

func _draw() -> void:
	# Draw skewer
	if skewer_progress > 0:
		var skewer_end = skewer_progress * skewer_length

		# Skewer glow
		if skewer_glow > 0:
			var glow_color = Color(0.8, 0.7, 0.5, skewer_glow * 0.3)
			for y_off in range(-3, 4):
				_draw_pixel_line(
					Vector2(-10, y_off * pixel_size),
					Vector2(skewer_end, y_off * pixel_size),
					glow_color
				)

		# Main skewer shaft
		var shaft_color = Color(0.6, 0.5, 0.4, 0.9)
		for y_off in range(-1, 2):
			_draw_pixel_line(
				Vector2(-10, y_off * pixel_size),
				Vector2(skewer_end, y_off * pixel_size),
				shaft_color
			)

		# Skewer tip
		var tip_color = Color(0.8, 0.75, 0.7, 1.0)
		var tip_pos = Vector2(skewer_end, 0)
		for i in range(3):
			var pos = tip_pos + Vector2(i * pixel_size, 0)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), tip_color)

	# Draw impaled targets
	for target in targets:
		if target.alpha > 0 and target.offset < skewer_progress * skewer_length:
			var wobble_y = sin(target.wobble) * 2
			_draw_impaled_target(Vector2(target.offset, wobble_y), target.alpha)

	# Draw blood drips
	for drip in blood_drips:
		if drip.alpha > 0:
			var color = Color(0.7, 0.1, 0.1, drip.alpha)
			var pos = (drip.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size * 2)), color)

func _draw_impaled_target(center: Vector2, alpha: float) -> void:
	var color = Color(0.4, 0.3, 0.35, alpha)
	var pain_color = Color(0.7, 0.2, 0.2, alpha * 0.5)

	# Body (torso)
	for y in range(-3, 4):
		for x in range(-2, 3):
			var pos = center + Vector2(x, y) * pixel_size
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Head
	_draw_pixel_circle(center + Vector2(0, -16), 6, color)

	# Pain indicator
	_draw_pixel_circle(center, 8, pain_color)

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
