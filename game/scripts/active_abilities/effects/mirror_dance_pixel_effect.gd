extends Node2D

# Mirror Dance - T3 Spin with reflective damage and afterimages

var pixel_size := 4
var duration := 0.8
var elapsed := 0.0

# Spinning mirror shards
var mirror_shards := []
var num_shards := 8
var rotation_speed := 14.0

# Afterimage positions
var afterimages := []
var num_images := 5

# Reflection sparkles
var sparkles := []
var num_sparkles := 20

# Mirror shield ring
var shield_alpha := 0.0
var shield_radius := 55.0

func _ready() -> void:
	# Initialize mirror shards
	for i in range(num_shards):
		mirror_shards.append({
			"angle": (float(i) / num_shards) * TAU,
			"radius": randf_range(35, 50),
			"size": randf_range(12, 20),
			"alpha": 0.9,
			"shine_offset": randf() * TAU
		})

	# Initialize afterimages
	for i in range(num_images):
		var angle = (float(i) / num_images) * TAU
		afterimages.append({
			"pos": Vector2(cos(angle), sin(angle)) * 35,
			"alpha": 0.0,
			"delay": i * 0.1
		})

	# Initialize sparkles
	for i in range(num_sparkles):
		var angle = randf() * TAU
		sparkles.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(30, 60),
			"alpha": 0.0,
			"trigger_time": randf() * 0.5,
			"duration": randf_range(0.1, 0.2)
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Shield
	shield_alpha = ease(min(progress * 3, 1.0), 0.3) * (1.0 - progress * 0.4)

	# Update mirror shards (rotate)
	for shard in mirror_shards:
		shard.angle += rotation_speed * delta
		shard.alpha = 0.9 * (1.0 - progress * 0.3)

	# Update afterimages
	for img in afterimages:
		if elapsed > img.delay:
			var age = elapsed - img.delay
			img.alpha = max(0, 0.6 - age * 1.5)
			img.pos = img.pos.rotated(delta * 8)

	# Update sparkles
	for sparkle in sparkles:
		if elapsed > sparkle.trigger_time:
			var age = elapsed - sparkle.trigger_time
			if age < sparkle.duration:
				sparkle.alpha = 1.0 - age / sparkle.duration
			else:
				sparkle.alpha = 0

	queue_redraw()

func _draw() -> void:
	# Draw shield ring
	if shield_alpha > 0:
		var shield_color = Color(0.7, 0.8, 1.0, shield_alpha * 0.4)
		_draw_pixel_ring(Vector2.ZERO, shield_radius, shield_color, 6)

	# Draw afterimages
	for img in afterimages:
		if img.alpha > 0:
			var color = Color(0.6, 0.7, 0.9, img.alpha)
			_draw_afterimage_silhouette(img.pos, color)

	# Draw mirror shards
	for shard in mirror_shards:
		if shard.alpha > 0:
			var pos = Vector2(cos(shard.angle), sin(shard.angle)) * shard.radius
			_draw_mirror_shard(pos, shard.angle, shard.size, shard.alpha, shard.shine_offset)

	# Draw sparkles
	for sparkle in sparkles:
		if sparkle.alpha > 0:
			var color = Color(1.0, 1.0, 1.0, sparkle.alpha)
			_draw_sparkle(sparkle.pos, color)

	# Draw center glow
	var center_alpha = shield_alpha * 0.6
	if center_alpha > 0:
		var center_color = Color(0.8, 0.85, 1.0, center_alpha)
		_draw_pixel_circle(Vector2.ZERO, 15, center_color)

func _draw_mirror_shard(pos: Vector2, angle: float, size: float, alpha: float, shine_offset: float) -> void:
	# Diamond-shaped mirror shard
	var mirror_color = Color(0.75, 0.8, 0.95, alpha)
	var shine_color = Color(1.0, 1.0, 1.0, alpha * (0.5 + 0.3 * sin(elapsed * 10 + shine_offset)))

	# Draw diamond shape
	var half = size / 2
	var points = [
		pos + Vector2(0, -half).rotated(angle),
		pos + Vector2(half * 0.6, 0).rotated(angle),
		pos + Vector2(0, half).rotated(angle),
		pos + Vector2(-half * 0.6, 0).rotated(angle)
	]

	# Fill with lines
	for i in range(4):
		_draw_pixel_line(points[i], points[(i + 1) % 4], mirror_color)

	# Center shine
	pos = (pos / pixel_size).floor() * pixel_size
	draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), shine_color)

func _draw_afterimage_silhouette(pos: Vector2, color: Color) -> void:
	# Simple ghostly figure
	_draw_pixel_circle(pos, 10, color)
	# Body hint
	for y in range(3):
		var body_pos = pos + Vector2(0, 8 + y * pixel_size)
		body_pos = (body_pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(body_pos, Vector2(pixel_size, pixel_size)), Color(color.r, color.g, color.b, color.a * 0.7))

func _draw_sparkle(pos: Vector2, color: Color) -> void:
	var snapped = (pos / pixel_size).floor() * pixel_size
	# 4-point star
	draw_rect(Rect2(snapped, Vector2(pixel_size, pixel_size)), color)
	draw_rect(Rect2(snapped + Vector2(pixel_size, 0), Vector2(pixel_size, pixel_size)), Color(color.r, color.g, color.b, color.a * 0.6))
	draw_rect(Rect2(snapped + Vector2(-pixel_size, 0), Vector2(pixel_size, pixel_size)), Color(color.r, color.g, color.b, color.a * 0.6))
	draw_rect(Rect2(snapped + Vector2(0, pixel_size), Vector2(pixel_size, pixel_size)), Color(color.r, color.g, color.b, color.a * 0.6))
	draw_rect(Rect2(snapped + Vector2(0, -pixel_size), Vector2(pixel_size, pixel_size)), Color(color.r, color.g, color.b, color.a * 0.6))

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
