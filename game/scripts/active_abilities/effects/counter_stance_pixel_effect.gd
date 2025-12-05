extends Node2D

# Counter Stance - T2 Taunt with counter-attack buff

var pixel_size := 4
var duration := 0.65
var elapsed := 0.0

# Taunt aggro aura
var aggro_alpha := 0.0

# Counter-ready stance glow
var stance_alpha := 0.0
var stance_pulse := 0.0

# Warning particles (enemies should beware)
var warning_particles := []
var num_particles := 10

# Counter flash indicators
var counter_flashes := []
var num_flashes := 4

func _ready() -> void:
	# Initialize warning particles
	for i in range(num_particles):
		var angle = randf() * TAU
		warning_particles.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(30, 50),
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(20, 40),
			"alpha": 0.7
		})

	# Initialize counter flashes around perimeter
	for i in range(num_flashes):
		var angle = (i * TAU / num_flashes) + randf() * 0.3
		counter_flashes.append({
			"pos": Vector2(cos(angle), sin(angle)) * 45,
			"alpha": 0.0,
			"delay": i * 0.1,
			"angle": angle
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Aggro builds
	aggro_alpha = ease(min(progress * 2.5, 1.0), 0.3) * (1.0 - progress * 0.4)

	# Stance pulses (ready to counter)
	stance_pulse = sin(elapsed * 12) * 0.3 + 0.7
	stance_alpha = stance_pulse * (1.0 - progress * 0.5)

	# Update warning particles
	for p in warning_particles:
		p.pos += p.velocity * delta
		p.alpha = max(0, 0.7 - progress * 0.9)

	# Update counter flashes
	for flash in counter_flashes:
		if elapsed > flash.delay:
			var age = elapsed - flash.delay
			if age < 0.1:
				flash.alpha = age / 0.1
			else:
				flash.alpha = max(0, 1.0 - (age - 0.1) / 0.2)

	queue_redraw()

func _draw() -> void:
	# Draw aggro aura (red ring)
	if aggro_alpha > 0:
		var aggro_color = Color(1.0, 0.3, 0.2, aggro_alpha * 0.4)
		_draw_pixel_ring(Vector2.ZERO, 55, aggro_color, 6)

	# Draw warning particles (orange/yellow)
	for p in warning_particles:
		if p.alpha > 0:
			var color = Color(1.0, 0.7, 0.2, p.alpha)
			var pos = (p.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Draw counter stance glow (golden/orange pulsing)
	if stance_alpha > 0:
		# Outer glow
		var outer_color = Color(1.0, 0.6, 0.2, stance_alpha * 0.3)
		_draw_pixel_circle(Vector2.ZERO, 40 * stance_pulse, outer_color)
		# Inner ready glow
		var inner_color = Color(1.0, 0.8, 0.4, stance_alpha * 0.5)
		_draw_pixel_circle(Vector2.ZERO, 25, inner_color)

	# Draw counter flashes (quick slash indicators)
	for flash in counter_flashes:
		if flash.alpha > 0:
			var color = Color(1.0, 0.9, 0.5, flash.alpha)
			_draw_counter_slash(flash.pos, flash.angle, color)

	# Draw center stance symbol
	var symbol_alpha = 1.0 - elapsed / duration * 0.4
	_draw_stance_symbol(Vector2.ZERO, Color(1.0, 0.85, 0.4, symbol_alpha))

func _draw_counter_slash(pos: Vector2, angle: float, color: Color) -> void:
	# Small slash mark
	var length = 15
	var start = pos - Vector2(cos(angle), sin(angle)) * length / 2
	var end = pos + Vector2(cos(angle), sin(angle)) * length / 2
	_draw_pixel_line(start, end, color)

func _draw_stance_symbol(center: Vector2, color: Color) -> void:
	# Crossed swords stance symbol
	# Sword 1 (diagonal)
	_draw_pixel_line(center + Vector2(-10, -10), center + Vector2(10, 10), color)
	# Sword 2 (other diagonal)
	_draw_pixel_line(center + Vector2(10, -10), center + Vector2(-10, 10), color)
	# Guard circle
	_draw_pixel_ring(center, 8, Color(color.r, color.g, color.b, color.a * 0.6), pixel_size)

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
