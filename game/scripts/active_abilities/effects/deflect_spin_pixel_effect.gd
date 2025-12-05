extends Node2D

# Deflect Spin - T2 Spin with defensive deflection sparks

var pixel_size := 4
var duration := 0.7
var elapsed := 0.0

# Spinning blade arcs
var blade_arcs := []
var num_blades := 4
var rotation_speed := 12.0

# Deflection sparks (outward)
var deflect_sparks := []
var num_sparks := 16

# Shield shimmer ring
var shield_ring_alpha := 0.0
var shield_ring_radius := 55.0

# Deflection flashes
var flashes := []

func _ready() -> void:
	# Initialize blade arcs
	for i in range(num_blades):
		blade_arcs.append({
			"base_angle": (i * TAU / num_blades),
			"radius": randf_range(45, 60),
			"arc_length": randf_range(0.6, 0.9),
			"alpha": 0.9
		})

	# Initialize deflection sparks
	for i in range(num_sparks):
		var angle = randf() * TAU
		deflect_sparks.append({
			"pos": Vector2(cos(angle), sin(angle)) * shield_ring_radius,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(80, 160),
			"alpha": 0.0,
			"trigger_time": randf() * 0.4
		})

	# Initialize random flashes around perimeter
	for i in range(5):
		var angle = randf() * TAU
		flashes.append({
			"pos": Vector2(cos(angle), sin(angle)) * shield_ring_radius,
			"alpha": 0.0,
			"trigger_time": randf() * 0.5,
			"size": randf_range(10, 18)
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Shield ring pulses
	shield_ring_alpha = (0.5 + 0.3 * sin(elapsed * 15)) * (1.0 - progress)

	# Update blade arcs
	for arc in blade_arcs:
		arc.base_angle += rotation_speed * delta
		arc.alpha = 0.9 * (1.0 - progress * 0.3)

	# Update deflection sparks
	for spark in deflect_sparks:
		if elapsed > spark.trigger_time and spark.alpha == 0:
			spark.alpha = 1.0
		if spark.alpha > 0:
			spark.pos += spark.velocity * delta
			spark.velocity *= 0.92
			spark.alpha = max(0, spark.alpha - delta * 2.5)

	# Update flashes
	for flash in flashes:
		if elapsed > flash.trigger_time:
			var flash_progress = (elapsed - flash.trigger_time) / 0.15
			if flash_progress < 1.0:
				flash.alpha = 1.0 - flash_progress
			else:
				flash.alpha = 0

	queue_redraw()

func _draw() -> void:
	# Draw shield ring
	if shield_ring_alpha > 0:
		var ring_color = Color(0.5, 0.7, 1.0, shield_ring_alpha * 0.4)
		_draw_pixel_ring(Vector2.ZERO, shield_ring_radius, ring_color, 6)
		# Inner glow
		var glow_color = Color(0.6, 0.8, 1.0, shield_ring_alpha * 0.2)
		_draw_pixel_ring(Vector2.ZERO, shield_ring_radius - 8, glow_color, 4)

	# Draw blade arcs
	for arc in blade_arcs:
		if arc.alpha > 0:
			# Main blade (silver)
			var blade_color = Color(0.85, 0.88, 0.95, arc.alpha)
			_draw_pixel_arc(Vector2.ZERO, arc.radius, arc.base_angle, arc.arc_length, blade_color)
			# Blue tint for defensive
			var blue_color = Color(0.6, 0.75, 1.0, arc.alpha * 0.5)
			_draw_pixel_arc(Vector2.ZERO, arc.radius - pixel_size * 2, arc.base_angle + 0.1, arc.arc_length * 0.7, blue_color)

	# Draw deflection flashes
	for flash in flashes:
		if flash.alpha > 0:
			var color = Color(1.0, 1.0, 1.0, flash.alpha)
			_draw_pixel_circle(flash.pos, flash.size, color)
			var outer_color = Color(0.6, 0.8, 1.0, flash.alpha * 0.5)
			_draw_pixel_circle(flash.pos, flash.size * 1.5, outer_color)

	# Draw deflection sparks
	for spark in deflect_sparks:
		if spark.alpha > 0:
			var color = Color(0.8, 0.9, 1.0, spark.alpha)
			var pos = (spark.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_pixel_arc(center: Vector2, radius: float, start_angle: float, arc_length: float, color: Color) -> void:
	var steps = int(arc_length * radius / pixel_size) + 6
	for i in range(steps):
		var t = float(i) / steps
		var angle = start_angle + t * arc_length
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		pos = (pos / pixel_size).floor() * pixel_size
		var fade = 1.0 - t * 0.4
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), Color(color.r, color.g, color.b, color.a * fade))

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 4)
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
