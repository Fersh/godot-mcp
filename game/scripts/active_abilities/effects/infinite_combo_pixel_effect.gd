extends Node2D

# Infinite Combo - T3 Combo with endless hit chain

var pixel_size := 4
var duration := 1.2
var elapsed := 0.0

# Infinite hit counter display
var hit_count := 0
var max_display_hits := 99

# Rapid strike impacts
var strikes := []
var num_strikes := 40

# Energy buildup
var energy_level := 0.0
var energy_particles := []
var num_particles := 35

# Combo chain visual
var chain_links := []
var num_links := 12

func _ready() -> void:
	# Initialize strikes (rapid successive hits)
	for i in range(num_strikes):
		var angle = randf() * TAU
		var dist = randf_range(15, 45)
		strikes.append({
			"pos": Vector2(cos(angle), sin(angle)) * dist,
			"alpha": 0.0,
			"trigger_time": i * 0.025,
			"size": randf_range(8, 16)
		})

	# Initialize energy particles
	for i in range(num_particles):
		var angle = randf() * TAU
		energy_particles.append({
			"angle": angle,
			"radius": randf_range(20, 50),
			"speed": randf_range(4, 8),
			"alpha": 0.0,
			"size": randf_range(4, 8)
		})

	# Initialize chain links
	for i in range(num_links):
		chain_links.append({
			"angle": (i * TAU / num_links),
			"radius": 60,
			"alpha": 0.0,
			"trigger_time": i * 0.05
		})

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Energy buildup
	energy_level = ease(min(progress * 1.5, 1.0), 0.3)

	# Hit counter increases
	hit_count = int(progress * max_display_hits)

	# Update strikes
	for strike in strikes:
		if elapsed > strike.trigger_time:
			var age = elapsed - strike.trigger_time
			if age < 0.04:
				strike.alpha = age / 0.04
			else:
				strike.alpha = max(0, 1.0 - (age - 0.04) / 0.08)

	# Update energy particles (orbit faster over time)
	for p in energy_particles:
		p.angle += p.speed * delta * (1.0 + progress * 2)
		p.alpha = energy_level * 0.8

	# Update chain links
	for link in chain_links:
		if elapsed > link.trigger_time:
			var age = elapsed - link.trigger_time
			link.alpha = min(age / 0.1, 1.0) * (1.0 - progress * 0.3)
			link.angle += delta * 2

	queue_redraw()

func _draw() -> void:
	# Draw chain links (connecting ring)
	for link in chain_links:
		if link.alpha > 0:
			var pos = Vector2(cos(link.angle), sin(link.angle)) * link.radius
			var color = Color(1.0, 0.8, 0.3, link.alpha * 0.7)
			_draw_pixel_circle(pos, 8, color)

	# Draw energy particles
	for p in energy_particles:
		if p.alpha > 0:
			var pos = Vector2(cos(p.angle), sin(p.angle)) * p.radius
			var color = Color(1.0, 0.9, 0.5, p.alpha)
			_draw_pixel_circle(pos, p.size, color)

	# Draw strikes
	for strike in strikes:
		if strike.alpha > 0:
			var color = Color(1.0, 1.0, 0.9, strike.alpha)
			_draw_impact_star(strike.pos, strike.size, color)

	# Draw hit counter
	if hit_count > 0:
		_draw_hit_counter(Vector2(0, -50), hit_count)

	# Draw central energy core
	var core_alpha = energy_level * (1.0 - elapsed / duration * 0.3)
	if core_alpha > 0:
		var core_color = Color(1.0, 0.95, 0.7, core_alpha)
		_draw_pixel_circle(Vector2.ZERO, 20 + energy_level * 10, core_color)

func _draw_impact_star(center: Vector2, size: float, color: Color) -> void:
	# 4-point star impact
	for i in range(4):
		var angle = i * PI/2
		var end = center + Vector2(cos(angle), sin(angle)) * size
		_draw_pixel_line(center, end, color)

func _draw_hit_counter(pos: Vector2, count: int) -> void:
	# Simple pixelated number display
	var color = Color(1.0, 0.8, 0.2, 0.9)
	var glow_color = Color(1.0, 0.6, 0.1, 0.5)
	_draw_pixel_circle(pos, 18, glow_color)
	# Draw "x" symbol
	_draw_pixel_line(pos + Vector2(-12, 0), pos + Vector2(-8, 0), color)
	# Number indicator (filled based on count)
	var fill = min(count / 99.0, 1.0)
	var bar_color = Color(1.0, 0.9, 0.3, 0.8)
	for i in range(int(fill * 10)):
		var bar_pos = pos + Vector2(-6 + i * 3, 0)
		bar_pos = (bar_pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(bar_pos, Vector2(pixel_size, pixel_size * 2)), bar_color)

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
