extends Node2D

# Chain Combo - T2 Combo with extended hit chains

var pixel_size := 4
var duration := 0.7
var elapsed := 0.0

# Sequential hit markers
var hits := []
var num_hits := 5

# Chain links connecting hits
var chain_links := []

# Combo counter particles
var combo_particles := []
var num_particles := 10

func _ready() -> void:
	# Initialize hits (spread pattern)
	var positions = [
		Vector2(-20, -10), Vector2(15, -5), Vector2(-10, 10),
		Vector2(20, 5), Vector2(0, -15)
	]
	for i in range(num_hits):
		hits.append({
			"pos": positions[i],
			"alpha": 0.0,
			"trigger_time": i * 0.1,
			"size": 18 - i * 2
		})
		if i > 0:
			chain_links.append({
				"from": positions[i-1],
				"to": positions[i],
				"alpha": 0.0,
				"trigger_time": i * 0.1
			})

	# Initialize combo particles
	for i in range(num_particles):
		combo_particles.append({
			"pos": Vector2(randf_range(-30, 30), randf_range(-20, 20)),
			"velocity": Vector2(randf_range(-40, 40), randf_range(-60, -30)),
			"alpha": 0.0
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Update hits
	for hit in hits:
		if elapsed > hit.trigger_time:
			var age = elapsed - hit.trigger_time
			if age < 0.08:
				hit.alpha = age / 0.08
			else:
				hit.alpha = max(0, 1.0 - (age - 0.08) / 0.25)

	# Update chain links
	for link in chain_links:
		if elapsed > link.trigger_time:
			var age = elapsed - link.trigger_time
			if age < 0.05:
				link.alpha = age / 0.05
			else:
				link.alpha = max(0, 1.0 - (age - 0.05) / 0.2)

	# Update combo particles
	for p in combo_particles:
		if elapsed > 0.2:
			if p.alpha == 0:
				p.alpha = 0.8
			p.pos += p.velocity * delta
			p.velocity.y += delta * 80
			p.alpha = max(0, p.alpha - delta * 1.5)

	queue_redraw()

func _draw() -> void:
	# Draw chain links (golden lines)
	for link in chain_links:
		if link.alpha > 0:
			var color = Color(1.0, 0.85, 0.3, link.alpha * 0.7)
			_draw_pixel_line(link.from, link.to, color)

	# Draw hit markers
	for i in range(hits.size()):
		var hit = hits[i]
		if hit.alpha > 0:
			# Color shifts from yellow to orange to red as combo builds
			var hue_shift = float(i) / hits.size()
			var r = 1.0
			var g = 0.9 - hue_shift * 0.5
			var b = 0.3 - hue_shift * 0.2
			var color = Color(r, g, b, hit.alpha)
			_draw_hit_burst(hit.pos, hit.size, color)
			# Combo number
			_draw_combo_number(hit.pos + Vector2(0, -hit.size - 5), i + 1, Color(1.0, 1.0, 1.0, hit.alpha))

	# Draw combo particles
	for p in combo_particles:
		if p.alpha > 0:
			var color = Color(1.0, 0.8, 0.2, p.alpha)
			var pos = (p.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_hit_burst(center: Vector2, size: float, color: Color) -> void:
	# 4-point star
	var directions = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
	for dir in directions:
		var end_pos = center + dir * size
		_draw_pixel_line(center, end_pos, color)
	# Diagonal smaller
	var diag_dirs = [Vector2(0.7, 0.7), Vector2(-0.7, 0.7), Vector2(0.7, -0.7), Vector2(-0.7, -0.7)]
	for dir in diag_dirs:
		var end_pos = center + dir * size * 0.6
		_draw_pixel_line(center, end_pos, Color(color.r, color.g, color.b, color.a * 0.7))
	# Center
	_draw_pixel_circle(center, size * 0.25, color)

func _draw_combo_number(pos: Vector2, num: int, color: Color) -> void:
	# Simple pixel number display
	var snapped_pos = (pos / pixel_size).floor() * pixel_size
	# Just draw a small indicator for the number
	for i in range(num):
		var dot_pos = snapped_pos + Vector2((i - num/2.0) * pixel_size * 1.5, 0)
		draw_rect(Rect2(dot_pos, Vector2(pixel_size, pixel_size)), color)

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
