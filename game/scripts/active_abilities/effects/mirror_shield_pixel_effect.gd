extends Node2D

# Mirror Shield - T3 Block reflect projectiles

var pixel_size := 4
var duration := 1.0
var elapsed := 0.0

# Shield formation
var shield_alpha := 0.0
var shield_width := 50.0
var shield_height := 70.0

# Mirror surface shimmer
var shimmer_lines := []
var num_shimmer := 8

# Reflected projectiles
var reflected_projectiles := []
var num_projectiles := 6

# Shield pulse
var pulse := 0.0

# Protective aura
var aura_alpha := 0.0

func _ready() -> void:
	# Initialize shimmer lines
	for i in range(num_shimmer):
		shimmer_lines.append({
			"y": -shield_height/2 + i * (shield_height / num_shimmer),
			"offset": randf() * 100,
			"speed": randf_range(50, 100)
		})

	# Initialize reflected projectiles
	for i in range(num_projectiles):
		var start_y = randf_range(-30, 30)
		reflected_projectiles.append({
			"pos": Vector2(-60, start_y),
			"velocity": Vector2(0, 0),
			"alpha": 0.0,
			"trigger_time": 0.2 + i * 0.12,
			"reflected": false
		})

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Shield forms
	shield_alpha = ease(min(progress * 4, 1.0), 0.3) * (1.0 - max(0, progress - 0.8) * 5)

	# Pulse effect
	pulse = sin(elapsed * 8) * 0.2 + 0.8

	# Aura
	aura_alpha = shield_alpha * 0.5

	# Update shimmer
	for shimmer in shimmer_lines:
		shimmer.offset += shimmer.speed * delta

	# Update projectiles
	for proj in reflected_projectiles:
		if elapsed > proj.trigger_time:
			if not proj.reflected:
				# Incoming
				proj.alpha = 1.0
				proj.velocity = Vector2(200, 0)
				proj.pos += proj.velocity * delta

				# Hit shield
				if proj.pos.x >= -10:
					proj.reflected = true
					proj.velocity = Vector2(-250, randf_range(-50, 50))
					# Shield flash
					pulse = 1.2
			else:
				# Reflected outward
				proj.pos += proj.velocity * delta
				proj.alpha = max(0, proj.alpha - delta * 1.5)

	queue_redraw()

func _draw() -> void:
	# Draw protective aura
	if aura_alpha > 0:
		var aura_color = Color(0.6, 0.7, 1.0, aura_alpha * 0.3)
		_draw_pixel_circle(Vector2.ZERO, 60, aura_color)

	# Draw shield
	if shield_alpha > 0:
		# Shield body
		var shield_color = Color(0.7, 0.8, 1.0, shield_alpha * pulse)
		_draw_rounded_rect(Vector2(-10, 0), shield_width * 0.3, shield_height, shield_color)

		# Mirror surface
		var mirror_color = Color(0.85, 0.9, 1.0, shield_alpha * 0.8)
		_draw_rounded_rect(Vector2(-8, 0), shield_width * 0.25, shield_height * 0.9, mirror_color)

		# Shimmer effect
		for shimmer in shimmer_lines:
			var shimmer_x = fmod(shimmer.offset, shield_width * 0.3) - shield_width * 0.15
			var shimmer_color = Color(1.0, 1.0, 1.0, shield_alpha * 0.5)
			var pos = Vector2(-10 + shimmer_x, shimmer.y)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size * 2, pixel_size)), shimmer_color)

	# Draw projectiles
	for proj in reflected_projectiles:
		if proj.alpha > 0:
			var color = Color(1.0, 0.5, 0.3, proj.alpha) if not proj.reflected else Color(0.3, 0.8, 1.0, proj.alpha)
			_draw_projectile(proj.pos, proj.velocity.normalized(), color)

	# Draw reflection flash
	if pulse > 1.0:
		var flash_alpha = (pulse - 1.0) / 0.2
		var flash_color = Color(1.0, 1.0, 1.0, flash_alpha)
		_draw_pixel_circle(Vector2(-5, 0), 20, flash_color)

func _draw_rounded_rect(center: Vector2, width: float, height: float, color: Color) -> void:
	var half_w = width / 2
	var half_h = height / 2
	for y in range(-int(half_h / pixel_size), int(half_h / pixel_size) + 1):
		for x in range(-int(half_w / pixel_size), int(half_w / pixel_size) + 1):
			var pos = center + Vector2(x, y) * pixel_size
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_projectile(pos: Vector2, dir: Vector2, color: Color) -> void:
	# Arrow-like projectile
	var back = pos - dir * 12
	_draw_pixel_line(back, pos, color)
	# Head
	var head_color = Color(color.r, color.g, color.b, color.a * 1.2)
	_draw_pixel_circle(pos, 4, head_color)

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
