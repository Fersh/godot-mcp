extends Node2D

# Bloodlust - T3 Rampage with life steal and blood effects

var pixel_size := 4
var duration := 0.95
var elapsed := 0.0

# Blood aura
var blood_aura_alpha := 0.0
var aura_radius := 55.0

# Life steal streams
var life_streams := []
var num_streams := 8

# Blood particles orbiting
var blood_particles := []
var num_particles := 20

# Pulsing veins
var veins := []
var num_veins := 10

# Heartbeat pulse
var heartbeat_pulse := 0.0

func _ready() -> void:
	# Initialize life streams (converging toward center)
	for i in range(num_streams):
		var angle = (i * TAU / num_streams)
		life_streams.append({
			"angle": angle,
			"distance": randf_range(70, 100),
			"alpha": 0.7,
			"speed": randf_range(100, 160)
		})

	# Initialize blood particles
	for i in range(num_particles):
		var angle = randf() * TAU
		blood_particles.append({
			"angle": angle,
			"radius": randf_range(30, 50),
			"orbit_speed": randf_range(3, 6),
			"alpha": 0.8,
			"size": randf_range(4, 8)
		})

	# Initialize veins
	for i in range(num_veins):
		veins.append({
			"angle": (i * TAU / num_veins) + randf() * 0.2,
			"length": 0.0,
			"max_length": randf_range(35, 55),
			"pulse_offset": randf() * TAU
		})

	await get_tree().create_timer(duration + 0.15).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Blood aura intensifies
	blood_aura_alpha = ease(min(progress * 2, 1.0), 0.3) * (1.0 - progress * 0.3)

	# Heartbeat
	heartbeat_pulse = sin(elapsed * 8) * 0.2 + 0.8

	# Update life streams (converge to center)
	for stream in life_streams:
		stream.distance -= stream.speed * delta
		if stream.distance < 15:
			stream.distance = randf_range(80, 110)
			stream.angle = randf() * TAU
		stream.alpha = 0.7 * (1.0 - progress * 0.4)

	# Update blood particles (orbit)
	for p in blood_particles:
		p.angle += p.orbit_speed * delta
		p.alpha = 0.8 * (1.0 - progress * 0.4)

	# Update veins (pulse)
	for vein in veins:
		var pulse = sin(elapsed * 8 + vein.pulse_offset) * 0.3 + 0.7
		vein.length = vein.max_length * pulse * min(progress * 3, 1.0)

	queue_redraw()

func _draw() -> void:
	# Draw blood aura
	if blood_aura_alpha > 0:
		var aura_color = Color(0.7, 0.1, 0.1, blood_aura_alpha * 0.5 * heartbeat_pulse)
		_draw_pixel_circle(Vector2.ZERO, aura_radius * heartbeat_pulse, aura_color)

	# Draw veins
	for vein in veins:
		if vein.length > 5:
			var color = Color(0.6, 0.1, 0.1, 0.7 * (1.0 - elapsed/duration))
			var end = Vector2(cos(vein.angle), sin(vein.angle)) * vein.length
			_draw_pixel_line(Vector2.ZERO, end, color)

	# Draw life streams
	for stream in life_streams:
		if stream.alpha > 0:
			var pos = Vector2(cos(stream.angle), sin(stream.angle)) * stream.distance
			var color = Color(0.9, 0.2, 0.2, stream.alpha)
			# Stream line toward center
			var inner_pos = Vector2(cos(stream.angle), sin(stream.angle)) * (stream.distance - 20)
			_draw_pixel_line(inner_pos, pos, color)
			# Glowing tip
			_draw_pixel_circle(pos, 4, Color(1.0, 0.4, 0.4, stream.alpha))

	# Draw blood particles
	for p in blood_particles:
		if p.alpha > 0:
			var pos = Vector2(cos(p.angle), sin(p.angle)) * p.radius
			var color = Color(0.8, 0.15, 0.1, p.alpha)
			_draw_pixel_circle(pos, p.size, color)

	# Draw center core (pulsing with heartbeat)
	var core_alpha = blood_aura_alpha * heartbeat_pulse
	if core_alpha > 0:
		var core_color = Color(1.0, 0.3, 0.2, core_alpha * 0.7)
		_draw_pixel_circle(Vector2.ZERO, 18 * heartbeat_pulse, core_color)
		var bright_core = Color(1.0, 0.5, 0.4, core_alpha)
		_draw_pixel_circle(Vector2.ZERO, 10, bright_core)

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
