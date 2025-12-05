extends Node2D

# Stampede - T3 Charge with devastating multi-impact

var pixel_size := 4
var duration := 0.8
var elapsed := 0.0

# Multiple charge impacts
var impacts := []
var num_impacts := 6

# Stampede dust trail
var dust_trail := []
var num_dust := 30

# Ground shake cracks
var cracks := []

# Hoof/impact marks
var hoof_marks := []

# Debris
var debris := []
var num_debris := 20

func _ready() -> void:
	# Initialize impacts along charge path
	for i in range(num_impacts):
		var x_offset = (i - num_impacts/2.0) * 30
		impacts.append({
			"pos": Vector2(x_offset, randf_range(-8, 8)),
			"radius": 0.0,
			"max_radius": randf_range(35, 50),
			"alpha": 1.0,
			"delay": i * 0.08
		})

		# Hoof mark at each impact
		hoof_marks.append({
			"pos": Vector2(x_offset, randf_range(-5, 5)),
			"alpha": 0.0,
			"delay": i * 0.08
		})

		# Cracks from each impact
		for j in range(4):
			var angle = randf() * TAU
			cracks.append({
				"origin": Vector2(x_offset, 0),
				"angle": angle,
				"length": 0.0,
				"max_length": randf_range(25, 50),
				"delay": i * 0.08
			})

	# Initialize dust trail
	for i in range(num_dust):
		dust_trail.append({
			"pos": Vector2(randf_range(-100, 100), randf_range(-20, 20)),
			"velocity": Vector2(randf_range(-50, 50), randf_range(-80, -30)),
			"size": randf_range(10, 22),
			"alpha": 0.5
		})

	# Initialize debris
	for i in range(num_debris):
		var impact_idx = randi() % num_impacts
		var base_pos = Vector2((impact_idx - num_impacts/2.0) * 30, 0)
		var angle = randf() * TAU
		debris.append({
			"pos": base_pos,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(100, 200),
			"size": Vector2(randi_range(1, 3) * pixel_size, randi_range(1, 3) * pixel_size),
			"alpha": 0.0,
			"gravity": randf_range(250, 450),
			"delay": impact_idx * 0.08
		})

	# Screen shake
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(15, 0.5)

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Update impacts
	for impact in impacts:
		if elapsed > impact.delay:
			var t = (elapsed - impact.delay) / 0.25
			impact.radius = min(t, 1.0) * impact.max_radius
			impact.alpha = max(0, 1.0 - (elapsed - impact.delay) / 0.4)

	# Update hoof marks
	for mark in hoof_marks:
		if elapsed > mark.delay:
			mark.alpha = min((elapsed - mark.delay) / 0.1, 1.0) * max(0, 1.0 - progress * 0.5)

	# Update cracks
	for crack in cracks:
		if elapsed > crack.delay:
			var t = (elapsed - crack.delay) / 0.2
			crack.length = min(t, 1.0) * crack.max_length

	# Update dust
	for dust in dust_trail:
		dust.pos += dust.velocity * delta
		dust.velocity *= 0.95
		dust.alpha = max(0, 0.5 - progress * 0.6)
		dust.size += delta * 12

	# Update debris
	for d in debris:
		if elapsed > d.delay:
			if d.alpha == 0:
				d.alpha = 1.0
			d.velocity.y += d.gravity * delta
			d.pos += d.velocity * delta
			d.alpha = max(0, d.alpha - delta * 1.5)

	queue_redraw()

func _draw() -> void:
	# Draw dust trail
	for dust in dust_trail:
		if dust.alpha > 0:
			var color = Color(0.6, 0.55, 0.45, dust.alpha * 0.4)
			_draw_pixel_circle(dust.pos, dust.size, color)

	# Draw cracks
	for crack in cracks:
		if crack.length > 0:
			var color = Color(0.2, 0.15, 0.1, 0.8)
			var end = crack.origin + Vector2(cos(crack.angle), sin(crack.angle)) * crack.length
			_draw_pixel_line(crack.origin, end, color)

	# Draw impact rings
	for impact in impacts:
		if impact.alpha > 0 and impact.radius > 0:
			var outer_color = Color(0.55, 0.45, 0.35, impact.alpha * 0.6)
			_draw_pixel_ring(impact.pos, impact.radius, outer_color, 8)
			var inner_color = Color(0.8, 0.7, 0.5, impact.alpha * 0.4)
			_draw_pixel_circle(impact.pos, impact.radius * 0.4, inner_color)

	# Draw hoof marks
	for mark in hoof_marks:
		if mark.alpha > 0:
			var color = Color(0.3, 0.25, 0.2, mark.alpha)
			_draw_hoof_mark(mark.pos, color)

	# Draw debris
	for d in debris:
		if d.alpha > 0:
			var color = Color(0.5, 0.4, 0.3, d.alpha)
			var pos = (d.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos - d.size/2, d.size), color)

func _draw_hoof_mark(center: Vector2, color: Color) -> void:
	# U-shaped hoof print
	var size = 12
	# Bottom curve
	for i in range(-2, 3):
		var pos = center + Vector2(i * pixel_size, size/2)
		pos = (pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)
	# Sides
	for i in range(3):
		var left = center + Vector2(-2 * pixel_size, i * pixel_size)
		var right = center + Vector2(2 * pixel_size, i * pixel_size)
		left = (left / pixel_size).floor() * pixel_size
		right = (right / pixel_size).floor() * pixel_size
		draw_rect(Rect2(left, Vector2(pixel_size, pixel_size)), color)
		draw_rect(Rect2(right, Vector2(pixel_size, pixel_size)), color)

func _draw_pixel_line(from: Vector2, to: Vector2, color: Color) -> void:
	var dist = from.distance_to(to)
	var steps = int(dist / pixel_size) + 1
	for i in range(steps):
		var t = float(i) / max(steps - 1, 1)
		var pos = from.lerp(to, t)
		pos = (pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_pixel_ring(center: Vector2, radius: float, color: Color, thickness: float) -> void:
	var circumference = TAU * radius
	var steps = max(int(circumference / pixel_size), 12)
	for i in range(steps):
		var angle = (float(i) / steps) * TAU
		for t in range(int(thickness / pixel_size)):
			var r = radius - t * pixel_size
			if r > 0:
				var pos = center + Vector2(cos(angle), sin(angle)) * r
				pos = (pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 3)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = center + pos
				draw_pos = (draw_pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)
