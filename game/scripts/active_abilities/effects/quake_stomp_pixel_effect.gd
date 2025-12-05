extends Node2D

# Quake Stomp - T2 Stomp upgrade with earthquake cracks and stronger shockwave

var pixel_size := 4
var duration := 0.6
var elapsed := 0.0

# Shockwave rings (more than T1)
var rings := []
var max_ring_radius := 90.0

# Earthquake cracks (new T2 feature)
var cracks := []
var num_cracks := 8

# Debris particles (more than T1)
var debris := []
var num_debris := 16

# Dust clouds
var dust_particles := []
var num_dust := 12

func _ready() -> void:
	# Initialize multiple rings
	for i in range(3):
		rings.append({
			"radius": 0.0,
			"alpha": 1.0,
			"delay": i * 0.08,
			"thickness": 12 - i * 2
		})

	# Initialize earthquake cracks
	for i in range(num_cracks):
		var angle = (i * TAU / num_cracks) + randf() * 0.3
		cracks.append({
			"angle": angle,
			"length": 0.0,
			"max_length": randf_range(50, 90),
			"width": randf_range(3, 6),
			"segments": []
		})
		# Generate jagged crack segments
		var seg_count = randi_range(4, 7)
		var current_pos = Vector2.ZERO
		for j in range(seg_count):
			var seg_angle = angle + randf_range(-0.4, 0.4)
			var seg_len = randf_range(10, 20)
			var end_pos = current_pos + Vector2(cos(seg_angle), sin(seg_angle)) * seg_len
			cracks[i].segments.append({"start": current_pos, "end": end_pos})
			current_pos = end_pos

	# Initialize debris
	for i in range(num_debris):
		var angle = randf() * TAU
		debris.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(120, 220),
			"size": Vector2(randi_range(2, 4) * pixel_size, randi_range(2, 4) * pixel_size),
			"alpha": 1.0,
			"rotation": randf() * TAU,
			"gravity": randf_range(300, 500)
		})

	# Initialize dust
	for i in range(num_dust):
		var angle = randf() * TAU
		dust_particles.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(10, 30),
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(40, 80),
			"size": randf_range(8, 16),
			"alpha": 0.7
		})

	# Screen shake
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(12, 0.4)

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
			ring.alpha = 1.0 - ease(ring_progress, 0.3)

	# Update cracks (grow outward)
	for crack in cracks:
		crack.length = min(progress * 2.0, 1.0) * crack.max_length

	# Update debris
	for d in debris:
		d.velocity.y += d.gravity * delta
		d.pos += d.velocity * delta
		d.alpha = max(0, 1.0 - progress * 1.2)
		d.rotation += delta * 5.0

	# Update dust
	for dust in dust_particles:
		dust.pos += dust.velocity * delta
		dust.velocity *= 0.96
		dust.alpha = max(0, 0.7 - progress)
		dust.size += delta * 15

	queue_redraw()

func _draw() -> void:
	# Draw earthquake cracks (dark brown/black)
	for crack in cracks:
		var crack_progress = crack.length / crack.max_length
		for i in range(crack.segments.size()):
			var seg = crack.segments[i]
			var seg_progress = clamp((crack_progress * crack.segments.size()) - i, 0, 1)
			if seg_progress > 0:
				var start = seg.start.normalized() * crack.length * (float(i) / crack.segments.size())
				var end = seg.start + (seg.end - seg.start) * seg_progress
				end = end.normalized() * min(end.length(), crack.length)
				var color = Color(0.2, 0.15, 0.1, 0.9)
				# Draw crack with width
				for w in range(int(crack.width)):
					var offset = Vector2(w - crack.width/2, 0).rotated(crack.angle)
					_draw_pixel_line(start + offset, end + offset, color)

	# Draw shockwave rings
	for ring in rings:
		if ring.alpha > 0:
			var color = Color(0.6, 0.5, 0.3, ring.alpha * 0.8)
			_draw_pixel_ring(Vector2.ZERO, ring.radius, color, ring.thickness)
			# Inner glow
			var inner_color = Color(0.8, 0.7, 0.4, ring.alpha * 0.5)
			_draw_pixel_ring(Vector2.ZERO, ring.radius * 0.7, inner_color, ring.thickness / 2)

	# Draw debris
	for d in debris:
		if d.alpha > 0:
			var color = Color(0.5, 0.4, 0.3, d.alpha)
			var rect = Rect2(d.pos - d.size / 2, d.size)
			_draw_pixelated_rect(rect, color)

	# Draw dust clouds
	for dust in dust_particles:
		if dust.alpha > 0:
			var color = Color(0.6, 0.55, 0.45, dust.alpha * 0.5)
			_draw_pixel_circle(dust.pos, dust.size, color)

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
