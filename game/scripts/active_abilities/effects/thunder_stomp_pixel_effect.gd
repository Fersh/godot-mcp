extends Node2D

# Thunder Stomp - T2 Stomp upgrade with lightning and electric shockwave

var pixel_size := 4
var duration := 0.7
var elapsed := 0.0

# Electric shockwave rings
var rings := []
var max_ring_radius := 85.0

# Lightning bolts from impact
var lightning_bolts := []
var num_bolts := 6

# Electric sparks
var sparks := []
var num_sparks := 20

# Ground debris
var debris := []
var num_debris := 10

func _ready() -> void:
	# Initialize rings with electric color
	for i in range(3):
		rings.append({
			"radius": 0.0,
			"alpha": 1.0,
			"delay": i * 0.06,
			"thickness": 10 - i * 2
		})

	# Initialize lightning bolts
	for i in range(num_bolts):
		var angle = (i * TAU / num_bolts) + randf() * 0.2
		var bolt_segments = []
		var current_pos = Vector2.ZERO
		var bolt_length = randf_range(60, 100)
		var seg_count = randi_range(5, 8)

		for j in range(seg_count):
			var seg_angle = angle + randf_range(-0.5, 0.5)
			var seg_len = bolt_length / seg_count
			var end_pos = current_pos + Vector2(cos(seg_angle), sin(seg_angle)) * seg_len
			bolt_segments.append({"start": current_pos, "end": end_pos})
			current_pos = end_pos

		lightning_bolts.append({
			"segments": bolt_segments,
			"alpha": 1.0,
			"flash_timer": 0.0
		})

	# Initialize sparks
	for i in range(num_sparks):
		var angle = randf() * TAU
		sparks.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(100, 200),
			"alpha": 1.0,
			"size": pixel_size
		})

	# Initialize debris
	for i in range(num_debris):
		var angle = randf() * TAU
		debris.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(80, 150),
			"size": Vector2(randi_range(1, 3) * pixel_size, randi_range(1, 3) * pixel_size),
			"alpha": 1.0,
			"gravity": randf_range(250, 400)
		})

	# Screen shake
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(10, 0.35)

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Update rings
	for ring in rings:
		if elapsed > ring.delay:
			var ring_progress = (elapsed - ring.delay) / (duration - ring.delay)
			ring.radius = ring_progress * max_ring_radius
			ring.alpha = 1.0 - ease(ring_progress, 0.4)

	# Update lightning
	for bolt in lightning_bolts:
		bolt.flash_timer += delta
		bolt.alpha = (1.0 - progress) * (0.5 + 0.5 * sin(bolt.flash_timer * 30))

	# Update sparks
	for spark in sparks:
		spark.velocity *= 0.95
		spark.pos += spark.velocity * delta
		spark.alpha = max(0, 1.0 - progress * 1.5)

	# Update debris
	for d in debris:
		d.velocity.y += d.gravity * delta
		d.pos += d.velocity * delta
		d.alpha = max(0, 1.0 - progress * 1.3)

	queue_redraw()

func _draw() -> void:
	# Draw electric shockwave rings (cyan/yellow)
	for ring in rings:
		if ring.alpha > 0:
			var color = Color(0.3, 0.8, 1.0, ring.alpha * 0.7)
			_draw_pixel_ring(Vector2.ZERO, ring.radius, color, ring.thickness)
			# Yellow inner ring
			var inner_color = Color(1.0, 1.0, 0.4, ring.alpha * 0.5)
			_draw_pixel_ring(Vector2.ZERO, ring.radius * 0.6, inner_color, ring.thickness / 2)

	# Draw lightning bolts
	for bolt in lightning_bolts:
		if bolt.alpha > 0:
			# Core (white)
			var core_color = Color(1.0, 1.0, 1.0, bolt.alpha)
			# Glow (cyan)
			var glow_color = Color(0.4, 0.9, 1.0, bolt.alpha * 0.6)

			for seg in bolt.segments:
				_draw_pixel_line(seg.start, seg.end, glow_color, 3)
				_draw_pixel_line(seg.start, seg.end, core_color, 1)

	# Draw sparks (yellow/white)
	for spark in sparks:
		if spark.alpha > 0:
			var color = Color(1.0, 1.0, 0.6, spark.alpha)
			var pos = (spark.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Draw debris
	for d in debris:
		if d.alpha > 0:
			var color = Color(0.5, 0.45, 0.35, d.alpha)
			var rect = Rect2(d.pos - d.size / 2, d.size)
			_draw_pixelated_rect(rect, color)

	# Center flash
	if elapsed < 0.15:
		var flash_alpha = 1.0 - (elapsed / 0.15)
		var flash_color = Color(1.0, 1.0, 0.8, flash_alpha * 0.8)
		_draw_pixel_circle(Vector2.ZERO, 20, flash_color)

func _draw_pixel_line(from: Vector2, to: Vector2, color: Color, width: int = 1) -> void:
	var dist = from.distance_to(to)
	var steps = int(dist / pixel_size) + 1
	for i in range(steps):
		var t = float(i) / max(steps - 1, 1)
		var pos = from.lerp(to, t)
		pos = (pos / pixel_size).floor() * pixel_size
		for w in range(width):
			var offset = Vector2(0, (w - width/2) * pixel_size)
			draw_rect(Rect2(pos + offset, Vector2(pixel_size, pixel_size)), color)

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

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 4)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = center + pos
				draw_pos = (draw_pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)

func _draw_pixelated_rect(rect: Rect2, color: Color) -> void:
	var snapped_pos = (rect.position / pixel_size).floor() * pixel_size
	var snapped_size = (rect.size / pixel_size).ceil() * pixel_size
	snapped_size = snapped_size.max(Vector2(pixel_size, pixel_size))
	draw_rect(Rect2(snapped_pos, snapped_size), color)
