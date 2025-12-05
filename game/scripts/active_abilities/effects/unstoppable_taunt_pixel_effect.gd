extends Node2D

# Unstoppable (Taunt) - T3 Taunt become immune while taunting

var pixel_size := 4
var duration := 1.1
var elapsed := 0.0

# Immunity barrier
var barrier_alpha := 0.0
var barrier_pulse := 0.0

# Force field layers
var field_layers := []
var num_layers := 4

# Deflected attacks
var deflections := []
var num_deflections := 8

# Unstoppable aura
var aura_alpha := 0.0

# Status indicator
var status_alpha := 0.0

func _ready() -> void:
	# Initialize force field layers
	for i in range(num_layers):
		field_layers.append({
			"radius": 35 + i * 12,
			"rotation": randf() * TAU,
			"speed": randf_range(1, 3) * (1 if i % 2 == 0 else -1),
			"alpha": 0.0
		})

	# Initialize deflections (projectiles bouncing off)
	for i in range(num_deflections):
		var angle = randf() * TAU
		deflections.append({
			"incoming_angle": angle,
			"pos": Vector2(cos(angle), sin(angle)) * 100,
			"velocity": Vector2.ZERO,
			"alpha": 0.0,
			"trigger_time": 0.2 + randf() * 0.5,
			"deflected": false
		})

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Barrier forms
	barrier_alpha = ease(min(progress * 3, 1.0), 0.3) * (1.0 - max(0, progress - 0.8) * 5)
	barrier_pulse = sin(elapsed * 6) * 0.2 + 0.8

	# Aura
	aura_alpha = barrier_alpha * 0.6

	# Status indicator
	if progress > 0.2:
		status_alpha = min((progress - 0.2) / 0.2, 1.0) * (1.0 - max(0, progress - 0.7) / 0.3)

	# Update field layers
	for layer in field_layers:
		layer.rotation += layer.speed * delta
		layer.alpha = barrier_alpha * (0.5 + barrier_pulse * 0.3)

	# Update deflections
	for deflection in deflections:
		if elapsed > deflection.trigger_time:
			if not deflection.deflected:
				# Move toward center
				var dir_to_center = -deflection.pos.normalized()
				deflection.velocity = dir_to_center * 150
				deflection.pos += deflection.velocity * delta
				deflection.alpha = 1.0

				# Hit barrier
				if deflection.pos.length() < 45:
					deflection.deflected = true
					var reflect_angle = deflection.pos.angle() + PI + randf_range(-0.5, 0.5)
					deflection.velocity = Vector2(cos(reflect_angle), sin(reflect_angle)) * 200
			else:
				# Deflected outward
				deflection.pos += deflection.velocity * delta
				deflection.alpha = max(0, deflection.alpha - delta * 2)

	queue_redraw()

func _draw() -> void:
	# Draw aura
	if aura_alpha > 0:
		var aura_color = Color(0.3, 0.6, 0.9, aura_alpha * 0.3)
		_draw_pixel_circle(Vector2.ZERO, 65, aura_color)

	# Draw force field layers
	for layer in field_layers:
		if layer.alpha > 0:
			var color = Color(0.4, 0.7, 1.0, layer.alpha * 0.4)
			_draw_hex_barrier(Vector2.ZERO, layer.radius, layer.rotation, color)

	# Draw main barrier
	if barrier_alpha > 0:
		var barrier_color = Color(0.5, 0.8, 1.0, barrier_alpha * barrier_pulse * 0.6)
		_draw_pixel_ring(Vector2.ZERO, 40, barrier_color, 8)

		# Inner glow
		var glow_color = Color(0.7, 0.9, 1.0, barrier_alpha * 0.4)
		_draw_pixel_circle(Vector2.ZERO, 35, glow_color)

	# Draw deflections
	for deflection in deflections:
		if deflection.alpha > 0:
			var color = Color(1.0, 0.5, 0.3, deflection.alpha) if not deflection.deflected else Color(0.3, 0.8, 1.0, deflection.alpha)
			_draw_pixel_circle(deflection.pos, 5, color)

	# Draw status indicator
	if status_alpha > 0:
		_draw_unstoppable_indicator(Vector2(0, -55), status_alpha)

func _draw_hex_barrier(center: Vector2, radius: float, rotation: float, color: Color) -> void:
	# Hexagonal barrier pattern
	for i in range(6):
		var angle1 = rotation + i * TAU / 6
		var angle2 = rotation + (i + 1) * TAU / 6
		var p1 = center + Vector2(cos(angle1), sin(angle1)) * radius
		var p2 = center + Vector2(cos(angle2), sin(angle2)) * radius
		_draw_pixel_line(p1, p2, color)

func _draw_unstoppable_indicator(center: Vector2, alpha: float) -> void:
	# Shield icon with infinity symbol
	var color = Color(0.4, 0.8, 1.0, alpha)

	# Shield outline
	_draw_pixel_circle(center, 15, color)

	# Infinity symbol (simplified as figure 8)
	var inf_color = Color(1.0, 1.0, 1.0, alpha)
	for t in range(16):
		var angle = t * TAU / 16
		var x = cos(angle) * 8
		var y = sin(angle * 2) * 4
		var pos = center + Vector2(x, y)
		pos = (pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), inf_color)

func _draw_pixel_ring(center: Vector2, radius: float, color: Color, thickness: float) -> void:
	var circumference = TAU * radius
	var steps = max(int(circumference / pixel_size), 16)
	for i in range(steps):
		var angle = (float(i) / steps) * TAU
		for t in range(int(thickness / pixel_size)):
			var r = radius - t * pixel_size
			if r > 0:
				var pos = center + Vector2(cos(angle), sin(angle)) * r
				pos = (pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

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
