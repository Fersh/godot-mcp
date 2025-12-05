extends Node2D

# Deflection - T2 Parry with projectile reflection

var pixel_size := 4
var duration := 0.55
var elapsed := 0.0

# Deflection shield arc
var shield_alpha := 0.0
var shield_arc_progress := 0.0

# Reflected projectile trails
var reflections := []
var num_reflections := 3

# Shield sparks
var sparks := []
var num_sparks := 14

# Energy ripples
var ripples := []

func _ready() -> void:
	# Initialize reflections (projectiles bouncing back)
	for i in range(num_reflections):
		var incoming_angle = randf_range(PI * 0.6, PI * 1.4)  # Coming from left-ish
		var outgoing_angle = -incoming_angle + randf_range(-0.3, 0.3)  # Reflected
		reflections.append({
			"start": Vector2(cos(incoming_angle), sin(incoming_angle)) * 60,
			"mid": Vector2.ZERO,
			"end": Vector2(cos(outgoing_angle), sin(outgoing_angle)) * 70,
			"progress": 0.0,
			"trigger_time": i * 0.08,
			"alpha": 0.0
		})

	# Initialize sparks
	for i in range(num_sparks):
		var angle = randf() * TAU
		sparks.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(100, 180),
			"alpha": 0.0,
			"trigger_time": randf() * 0.15
		})

	# Initialize ripples
	for i in range(2):
		ripples.append({
			"radius": 0.0,
			"alpha": 0.0,
			"trigger_time": i * 0.1
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Shield appears
	shield_alpha = (1.0 - progress) * 0.8
	shield_arc_progress = ease(min(progress * 3, 1.0), 0.3)

	# Update reflections
	for ref in reflections:
		if elapsed > ref.trigger_time:
			var age = elapsed - ref.trigger_time
			ref.progress = min(age / 0.2, 1.0)
			if ref.alpha == 0:
				ref.alpha = 1.0
			ref.alpha = max(0, 1.0 - age / 0.3)

	# Update sparks
	for spark in sparks:
		if elapsed > spark.trigger_time and spark.alpha == 0:
			spark.alpha = 1.0
		if spark.alpha > 0:
			spark.pos += spark.velocity * delta
			spark.velocity *= 0.9
			spark.alpha = max(0, spark.alpha - delta * 2.5)

	# Update ripples
	for ripple in ripples:
		if elapsed > ripple.trigger_time:
			var age = elapsed - ripple.trigger_time
			ripple.radius = age * 150
			ripple.alpha = max(0, 0.6 - age * 1.5)

	queue_redraw()

func _draw() -> void:
	# Draw ripples
	for ripple in ripples:
		if ripple.alpha > 0:
			var color = Color(0.5, 0.7, 1.0, ripple.alpha * 0.4)
			_draw_pixel_ring(Vector2.ZERO, ripple.radius, color, 4)

	# Draw shield arc
	if shield_alpha > 0:
		var arc_color = Color(0.6, 0.8, 1.0, shield_alpha)
		_draw_shield_arc(Vector2.ZERO, 35, -PI/2, PI, shield_arc_progress, arc_color)
		# Inner glow
		var glow_color = Color(0.8, 0.9, 1.0, shield_alpha * 0.5)
		_draw_shield_arc(Vector2.ZERO, 28, -PI/2, PI * 0.8, shield_arc_progress, glow_color)

	# Draw reflections
	for ref in reflections:
		if ref.alpha > 0:
			# Incoming trail (faded)
			var incoming_color = Color(1.0, 0.5, 0.3, ref.alpha * 0.5)
			var incoming_end = ref.start.lerp(ref.mid, min(ref.progress * 2, 1.0))
			_draw_pixel_line(ref.start, incoming_end, incoming_color)

			# Outgoing trail (bright)
			if ref.progress > 0.5:
				var outgoing_progress = (ref.progress - 0.5) * 2
				var outgoing_color = Color(0.5, 0.8, 1.0, ref.alpha)
				var outgoing_end = ref.mid.lerp(ref.end, outgoing_progress)
				_draw_pixel_line(ref.mid, outgoing_end, outgoing_color)

	# Draw sparks
	for spark in sparks:
		if spark.alpha > 0:
			var color = Color(0.8, 0.9, 1.0, spark.alpha)
			var pos = (spark.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_shield_arc(center: Vector2, radius: float, start_angle: float, arc_span: float, progress: float, color: Color) -> void:
	var actual_span = arc_span * progress
	var steps = int(actual_span * radius / pixel_size) + 10
	for i in range(steps):
		var t = float(i) / steps
		var angle = start_angle + t * actual_span
		for r_off in range(3):
			var r = radius - r_off * pixel_size
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
