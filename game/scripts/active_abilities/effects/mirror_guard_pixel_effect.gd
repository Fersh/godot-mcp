extends Node2D

# Mirror Guard - T3 Parry reflect all damage back

var pixel_size := 4
var duration := 1.0
var elapsed := 0.0

# Mirror shield
var mirror_alpha := 0.0
var mirror_segments := []
var num_segments := 12

# Reflection rays
var reflection_rays := []
var num_rays := 16

# Shattered mirror pieces (on reflect)
var mirror_shards := []
var num_shards := 25

# Central mirror glow
var mirror_glow := 0.0

func _ready() -> void:
	# Initialize mirror segments
	for i in range(num_segments):
		var angle = (i * TAU / num_segments)
		mirror_segments.append({
			"angle": angle,
			"radius": 45,
			"alpha": 0.0,
			"reflect_time": randf_range(0.3, 0.7)
		})

	# Initialize reflection rays
	for i in range(num_rays):
		var angle = randf() * TAU
		reflection_rays.append({
			"angle": angle,
			"length": 0.0,
			"max_length": randf_range(60, 100),
			"alpha": 0.0,
			"trigger_time": randf_range(0.2, 0.6)
		})

	# Initialize mirror shards
	for i in range(num_shards):
		var angle = randf() * TAU
		mirror_shards.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(100, 200),
			"alpha": 0.0,
			"rotation": randf() * TAU,
			"size": randf_range(4, 10)
		})

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Mirror forms
	mirror_alpha = ease(min(progress * 3, 1.0), 0.3)
	mirror_glow = mirror_alpha * (0.8 + sin(elapsed * 10) * 0.2)

	# Update mirror segments
	for seg in mirror_segments:
		seg.alpha = mirror_alpha * (0.7 + sin(elapsed * 8 + seg.angle) * 0.3)
		if elapsed > seg.reflect_time and elapsed < seg.reflect_time + 0.1:
			seg.alpha = 1.0  # Flash on reflect

	# Update reflection rays
	for ray in reflection_rays:
		if elapsed > ray.trigger_time:
			var age = elapsed - ray.trigger_time
			ray.length = min(age * 300, ray.max_length)
			ray.alpha = max(0, 1.0 - age / 0.3)

	# Shards fly out near end
	if progress > 0.7:
		for shard in mirror_shards:
			if shard.alpha == 0:
				shard.alpha = 0.9
			shard.pos += shard.velocity * delta
			shard.velocity *= 0.96
			shard.rotation += delta * 8
			shard.alpha = max(0, shard.alpha - delta * 2)

	queue_redraw()

func _draw() -> void:
	# Draw mirror glow
	if mirror_glow > 0:
		var glow_color = Color(0.7, 0.8, 1.0, mirror_glow * 0.3)
		_draw_pixel_circle(Vector2.ZERO, 55, glow_color)

	# Draw mirror segments
	for seg in mirror_segments:
		if seg.alpha > 0:
			var color = Color(0.8, 0.85, 1.0, seg.alpha)
			var inner = Vector2(cos(seg.angle), sin(seg.angle)) * 30
			var outer = Vector2(cos(seg.angle), sin(seg.angle)) * seg.radius
			_draw_mirror_segment(inner, outer, seg.angle, color)

	# Draw central mirror
	if mirror_alpha > 0:
		var center_color = Color(0.9, 0.92, 1.0, mirror_alpha * 0.6)
		_draw_pixel_circle(Vector2.ZERO, 25, center_color)
		# Reflective highlight
		var highlight_color = Color(1.0, 1.0, 1.0, mirror_alpha * 0.8)
		_draw_pixel_circle(Vector2(-8, -8), 8, highlight_color)

	# Draw reflection rays
	for ray in reflection_rays:
		if ray.alpha > 0:
			var color = Color(0.9, 0.95, 1.0, ray.alpha)
			var start = Vector2(cos(ray.angle), sin(ray.angle)) * 40
			var end = Vector2(cos(ray.angle), sin(ray.angle)) * (40 + ray.length)
			_draw_pixel_line(start, end, color)

	# Draw shards
	for shard in mirror_shards:
		if shard.alpha > 0:
			var color = Color(0.85, 0.9, 1.0, shard.alpha)
			_draw_shard(shard.pos, shard.size, shard.rotation, color)

func _draw_mirror_segment(inner: Vector2, outer: Vector2, angle: float, color: Color) -> void:
	# Draw segment with some width
	var perp = Vector2(cos(angle + PI/2), sin(angle + PI/2))
	for w in range(-1, 2):
		var offset = perp * w * pixel_size
		_draw_pixel_line(inner + offset, outer + offset, color)

func _draw_shard(center: Vector2, size: float, rotation: float, color: Color) -> void:
	# Diamond-shaped shard
	var points = [
		Vector2(0, -size).rotated(rotation),
		Vector2(size * 0.5, 0).rotated(rotation),
		Vector2(0, size).rotated(rotation),
		Vector2(-size * 0.5, 0).rotated(rotation)
	]
	for i in range(4):
		_draw_pixel_line(center + points[i], center + points[(i + 1) % 4], color)

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
