extends Node2D

# Pinning Strike - T2 Impale that pins enemy in place

var pixel_size := 4
var duration := 0.6
var elapsed := 0.0

# Impale thrust
var thrust_progress := 0.0
var thrust_length := 60.0

# Pin marker (stake in ground visual)
var pin_alpha := 0.0

# Ground cracks from pin
var cracks := []
var num_cracks := 4

# Impact dust
var dust := []
var num_dust := 8

# Sparks
var sparks := []
var num_sparks := 10

func _ready() -> void:
	# Initialize cracks
	for i in range(num_cracks):
		var angle = (i * TAU / num_cracks) + randf() * 0.3
		cracks.append({
			"angle": angle,
			"length": 0.0,
			"max_length": randf_range(20, 35)
		})

	# Initialize dust
	for i in range(num_dust):
		var angle = randf() * TAU
		dust.append({
			"pos": Vector2(thrust_length, 0),
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(30, 60),
			"size": randf_range(8, 14),
			"alpha": 0.0
		})

	# Initialize sparks
	for i in range(num_sparks):
		var angle = randf_range(PI/2, 3*PI/2)
		sparks.append({
			"pos": Vector2(thrust_length, 0),
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(100, 180),
			"alpha": 0.0
		})

	await get_tree().create_timer(duration + 0.15).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Thrust
	thrust_progress = ease(min(progress * 3.5, 1.0), 0.1)

	# Pin and effects appear after impact
	if progress > 0.28:
		var pin_progress = (progress - 0.28) / 0.72
		pin_alpha = min(pin_progress * 3, 1.0) * (1.0 - max(0, pin_progress - 0.5) * 2)

		# Trigger effects
		for crack in cracks:
			crack.length = min((progress - 0.28) / 0.2, 1.0) * crack.max_length
		for d in dust:
			if d.alpha == 0:
				d.alpha = 0.6
		for spark in sparks:
			if spark.alpha == 0:
				spark.alpha = 1.0

	# Update dust
	for d in dust:
		if d.alpha > 0:
			d.pos += d.velocity * delta
			d.velocity *= 0.93
			d.alpha = max(0, d.alpha - delta * 1.0)
			d.size += delta * 8

	# Update sparks
	for spark in sparks:
		if spark.alpha > 0:
			spark.pos += spark.velocity * delta
			spark.velocity *= 0.9
			spark.alpha = max(0, spark.alpha - delta * 2.5)

	queue_redraw()

func _draw() -> void:
	# Draw dust
	for d in dust:
		if d.alpha > 0:
			var color = Color(0.6, 0.55, 0.45, d.alpha * 0.5)
			_draw_pixel_circle(d.pos, d.size, color)

	# Draw cracks
	for crack in cracks:
		if crack.length > 0:
			var color = Color(0.25, 0.2, 0.15, 0.8)
			var start = Vector2(thrust_length, 0)
			var end = start + Vector2(cos(crack.angle), sin(crack.angle)) * crack.length
			_draw_pixel_line(start, end, color)

	# Draw thrust/stake
	if thrust_progress > 0:
		var stake_end = Vector2(thrust_progress * thrust_length, 0)
		# Shaft
		var shaft_color = Color(0.5, 0.4, 0.3, 0.9)
		_draw_pixel_line(Vector2.ZERO, stake_end, shaft_color)
		# Pointed end
		var point_color = Color(0.6, 0.55, 0.5, 1.0)
		_draw_stake_point(stake_end, point_color)

	# Draw pin marker (glowing ring around impact)
	if pin_alpha > 0:
		var pin_pos = Vector2(thrust_length, 0)
		# Binding ring
		var ring_color = Color(0.8, 0.4, 0.2, pin_alpha * 0.7)
		_draw_pixel_ring(pin_pos, 20, ring_color, 4)
		# Inner glow
		var glow_color = Color(1.0, 0.6, 0.3, pin_alpha * 0.4)
		_draw_pixel_circle(pin_pos, 12, glow_color)

	# Draw sparks
	for spark in sparks:
		if spark.alpha > 0:
			var color = Color(1.0, 0.8, 0.4, spark.alpha)
			var pos = (spark.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_stake_point(tip: Vector2, color: Color) -> void:
	# Simple triangular point
	for i in range(3):
		var width = 3 - i
		for y_off in range(-width, width + 1):
			var pos = tip + Vector2(-i * pixel_size, y_off * pixel_size)
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
