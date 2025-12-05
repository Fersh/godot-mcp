extends Node2D

# Afterimage - T2 Dash that leaves shadow clones

var pixel_size := 4
var duration := 0.6
var elapsed := 0.0

# Afterimage ghosts
var afterimages := []
var num_images := 4

# Shadow particles
var shadow_particles := []
var num_particles := 12

# Main dash blur
var dash_alpha := 1.0

func _ready() -> void:
	# Initialize afterimages (positions along path)
	for i in range(num_images):
		var x_pos = -50 + i * 25
		afterimages.append({
			"pos": Vector2(x_pos, 0),
			"alpha": 0.0,
			"trigger_time": i * 0.08,
			"fade_time": 0.3
		})

	# Initialize shadow particles
	for i in range(num_particles):
		shadow_particles.append({
			"pos": Vector2(randf_range(-60, 20), randf_range(-20, 20)),
			"velocity": Vector2(randf_range(-30, -60), randf_range(-10, 10)),
			"alpha": 0.6,
			"size": randf_range(6, 12)
		})

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Main dash fades
	dash_alpha = max(0, 1.0 - progress * 1.5)

	# Update afterimages
	for img in afterimages:
		if elapsed > img.trigger_time:
			var age = elapsed - img.trigger_time
			if age < 0.1:
				img.alpha = age / 0.1 * 0.8
			else:
				img.alpha = max(0, 0.8 - (age - 0.1) / img.fade_time)

	# Update shadow particles
	for p in shadow_particles:
		p.pos += p.velocity * delta
		p.alpha = max(0, 0.6 - progress * 0.8)
		p.size = max(4, p.size - delta * 5)

	queue_redraw()

func _draw() -> void:
	# Draw shadow particles
	for p in shadow_particles:
		if p.alpha > 0:
			var color = Color(0.2, 0.15, 0.3, p.alpha * 0.5)
			_draw_pixel_circle(p.pos, p.size, color)

	# Draw afterimages (silhouette shapes)
	for img in afterimages:
		if img.alpha > 0:
			var color = Color(0.3, 0.25, 0.5, img.alpha)
			_draw_character_silhouette(img.pos, color)
			# Ghostly outline
			var outline_color = Color(0.5, 0.4, 0.7, img.alpha * 0.5)
			_draw_character_outline(img.pos, outline_color)

	# Draw main dash blur
	if dash_alpha > 0:
		var blur_color = Color(0.4, 0.35, 0.6, dash_alpha * 0.6)
		# Motion blur lines
		for y_off in range(-3, 4):
			var start = Vector2(-60, y_off * pixel_size * 2)
			var end = Vector2(40, y_off * pixel_size * 2)
			_draw_pixel_line(start, end, blur_color)

func _draw_character_silhouette(center: Vector2, color: Color) -> void:
	# Simple humanoid silhouette
	# Head
	_draw_pixel_circle(center + Vector2(0, -20), 8, color)
	# Body
	for y in range(6):
		var width = 6 if y < 3 else 8
		for x in range(-width, width + 1, pixel_size):
			var pos = center + Vector2(x, -12 + y * pixel_size)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)
	# Legs
	for y in range(4):
		var pos_left = center + Vector2(-4, 12 + y * pixel_size)
		var pos_right = center + Vector2(4, 12 + y * pixel_size)
		pos_left = (pos_left / pixel_size).floor() * pixel_size
		pos_right = (pos_right / pixel_size).floor() * pixel_size
		draw_rect(Rect2(pos_left, Vector2(pixel_size, pixel_size)), color)
		draw_rect(Rect2(pos_right, Vector2(pixel_size, pixel_size)), color)

func _draw_character_outline(center: Vector2, color: Color) -> void:
	# Just draw outline edges
	# Head outline
	_draw_pixel_ring(center + Vector2(0, -20), 10, color, pixel_size)

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

func _draw_pixel_ring(center: Vector2, radius: float, color: Color, thickness: float) -> void:
	var circumference = TAU * radius
	var steps = max(int(circumference / pixel_size), 12)
	for i in range(steps):
		var angle = (float(i) / steps) * TAU
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		pos = (pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)
