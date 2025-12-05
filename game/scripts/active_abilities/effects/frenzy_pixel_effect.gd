extends Node2D

# Frenzy - T2 Rampage with fast attack speed aura

var pixel_size := 4
var duration := 0.8
var elapsed := 0.0

# Pulsing speed aura
var aura_pulse := 0.0
var aura_radius := 45.0

# Speed lines (radial)
var speed_lines := []
var num_lines := 12

# Energy sparks
var sparks := []
var num_sparks := 14

# Attack streak visuals
var attack_streaks := []
var num_streaks := 4

func _ready() -> void:
	# Initialize speed lines
	for i in range(num_lines):
		var angle = (i * TAU / num_lines) + randf() * 0.2
		speed_lines.append({
			"angle": angle,
			"inner_radius": randf_range(25, 35),
			"outer_radius": randf_range(50, 70),
			"alpha": 0.7,
			"pulse_offset": randf() * TAU
		})

	# Initialize sparks
	for i in range(num_sparks):
		var angle = randf() * TAU
		sparks.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(20, 45),
			"velocity": Vector2(randf_range(-50, 50), randf_range(-80, -40)),
			"alpha": 0.8
		})

	# Initialize attack streaks
	for i in range(num_streaks):
		attack_streaks.append({
			"angle": randf() * TAU,
			"progress": 0.0,
			"trigger_time": i * 0.15,
			"length": randf_range(40, 60)
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Aura pulses rapidly
	aura_pulse = sin(elapsed * 15) * 0.3 + 0.7

	# Update speed lines (pulse)
	for line in speed_lines:
		line.alpha = (0.5 + 0.3 * sin(elapsed * 12 + line.pulse_offset)) * (1.0 - progress * 0.5)

	# Update sparks
	for spark in sparks:
		spark.pos += spark.velocity * delta
		spark.velocity.y += delta * 50
		spark.alpha = max(0, 0.8 - progress)

	# Update attack streaks
	for streak in attack_streaks:
		if elapsed > streak.trigger_time:
			streak.progress = min((elapsed - streak.trigger_time) / 0.1, 1.0)
			if elapsed > streak.trigger_time + 0.15:
				streak.progress = max(0, 1.0 - (elapsed - streak.trigger_time - 0.15) / 0.1)

	queue_redraw()

func _draw() -> void:
	# Draw aura ring (red/orange pulsing)
	var aura_color = Color(1.0, 0.4, 0.2, aura_pulse * 0.4 * (1.0 - elapsed/duration))
	_draw_pixel_ring(Vector2.ZERO, aura_radius * aura_pulse, aura_color, 8)

	# Draw inner glow
	var glow_color = Color(1.0, 0.6, 0.3, aura_pulse * 0.3 * (1.0 - elapsed/duration))
	_draw_pixel_circle(Vector2.ZERO, 25, glow_color)

	# Draw speed lines
	for line in speed_lines:
		if line.alpha > 0:
			var color = Color(1.0, 0.7, 0.4, line.alpha)
			var inner_pos = Vector2(cos(line.angle), sin(line.angle)) * line.inner_radius
			var outer_pos = Vector2(cos(line.angle), sin(line.angle)) * line.outer_radius
			_draw_pixel_line(inner_pos, outer_pos, color)

	# Draw attack streaks (fast slashes)
	for streak in attack_streaks:
		if streak.progress > 0:
			var color = Color(1.0, 0.9, 0.6, streak.progress * 0.8)
			var start = Vector2(cos(streak.angle), sin(streak.angle)) * 15
			var end = Vector2(cos(streak.angle), sin(streak.angle)) * (15 + streak.length * streak.progress)
			_draw_pixel_line(start, end, color)

	# Draw sparks
	for spark in sparks:
		if spark.alpha > 0:
			var color = Color(1.0, 0.6, 0.2, spark.alpha)
			var pos = (spark.pos / pixel_size).floor() * pixel_size
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
	var steps = max(int(radius / pixel_size), 3)
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
