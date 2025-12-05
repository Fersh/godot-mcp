extends Node2D

# Warlord's Command - T3 Shout ultimate battle cry

var pixel_size := 4
var duration := 1.2
var elapsed := 0.0

# Command waves
var command_waves := []
var num_waves := 6

# Banner/standard
var banner_alpha := 0.0

# Soldier spirits
var spirits := []
var num_spirits := 8

# Authority aura
var authority_aura := 0.0

# War drums visual
var drum_pulses := []
var num_pulses := 4

func _ready() -> void:
	# Initialize command waves
	for i in range(num_waves):
		command_waves.append({
			"radius": 0.0,
			"alpha": 0.0,
			"delay": i * 0.12
		})

	# Initialize soldier spirits
	for i in range(num_spirits):
		var angle = (i * TAU / num_spirits)
		var dist = 70
		spirits.append({
			"pos": Vector2(cos(angle), sin(angle)) * dist,
			"alpha": 0.0,
			"trigger_time": 0.3 + i * 0.08,
			"facing": angle + PI  # Face center
		})

	# Initialize drum pulses
	for i in range(num_pulses):
		drum_pulses.append({
			"alpha": 0.0,
			"trigger_time": i * 0.25
		})

	# Screen shake
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(10, 0.4)

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Authority aura
	authority_aura = ease(min(progress * 2, 1.0), 0.3) * (1.0 - progress * 0.2)

	# Banner rises
	if progress > 0.1:
		banner_alpha = min((progress - 0.1) / 0.3, 1.0) * (1.0 - max(0, progress - 0.8) * 5)

	# Update command waves
	for wave in command_waves:
		if elapsed > wave.delay:
			var wave_age = elapsed - wave.delay
			wave.radius = wave_age * 120
			wave.alpha = max(0, 0.7 - wave_age)

	# Update spirits
	for spirit in spirits:
		if elapsed > spirit.trigger_time:
			var age = elapsed - spirit.trigger_time
			if age < 0.2:
				spirit.alpha = age / 0.2 * 0.7
			else:
				spirit.alpha = max(0, 0.7 - (age - 0.2) / 0.5)

	# Update drum pulses
	for pulse in drum_pulses:
		if elapsed > pulse.trigger_time:
			var age = elapsed - pulse.trigger_time
			if age < 0.1:
				pulse.alpha = age / 0.1
			else:
				pulse.alpha = max(0, 1.0 - (age - 0.1) / 0.15)

	queue_redraw()

func _draw() -> void:
	# Draw authority aura
	if authority_aura > 0:
		var outer_color = Color(0.8, 0.7, 0.3, authority_aura * 0.3)
		_draw_pixel_circle(Vector2.ZERO, 80, outer_color)
		var inner_color = Color(1.0, 0.85, 0.4, authority_aura * 0.5)
		_draw_pixel_circle(Vector2.ZERO, 40, inner_color)

	# Draw command waves
	for wave in command_waves:
		if wave.alpha > 0:
			var color = Color(1.0, 0.8, 0.3, wave.alpha * 0.4)
			_draw_pixel_ring(Vector2.ZERO, wave.radius, color, 8)

	# Draw drum pulses
	for pulse in drum_pulses:
		if pulse.alpha > 0:
			var color = Color(1.0, 0.9, 0.5, pulse.alpha * 0.6)
			_draw_pixel_circle(Vector2.ZERO, 25 + pulse.alpha * 10, color)

	# Draw soldier spirits
	for spirit in spirits:
		if spirit.alpha > 0:
			_draw_soldier_spirit(spirit.pos, spirit.facing, spirit.alpha)

	# Draw banner
	if banner_alpha > 0:
		_draw_war_banner(Vector2(0, -40), banner_alpha)

func _draw_soldier_spirit(pos: Vector2, facing: float, alpha: float) -> void:
	var color = Color(0.9, 0.85, 0.6, alpha)

	# Simple soldier silhouette
	# Head
	_draw_pixel_circle(pos + Vector2(0, -12), 6, color)

	# Body
	for y in range(4):
		for x in range(-2, 3):
			var body_pos = pos + Vector2(x, -6 + y) * pixel_size
			body_pos = (body_pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(body_pos, Vector2(pixel_size, pixel_size)), Color(color.r, color.g, color.b, alpha * 0.8))

	# Spear
	var spear_color = Color(0.8, 0.75, 0.5, alpha)
	var spear_dir = Vector2(cos(facing), sin(facing))
	_draw_pixel_line(pos, pos + spear_dir * 20, spear_color)

func _draw_war_banner(pos: Vector2, alpha: float) -> void:
	var pole_color = Color(0.5, 0.4, 0.3, alpha)
	var banner_color = Color(0.9, 0.2, 0.2, alpha)
	var trim_color = Color(1.0, 0.8, 0.3, alpha)

	# Pole
	for y in range(35):
		var pole_pos = pos + Vector2(0, -15 + y)
		pole_pos = (pole_pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(pole_pos, Vector2(pixel_size, pixel_size)), pole_color)

	# Banner fabric
	for y in range(20):
		var wave = sin(elapsed * 5 + y * 0.3) * 3
		for x in range(20):
			var banner_pos = pos + Vector2(4 + x + wave * (x / 20.0), -12 + y)
			banner_pos = (banner_pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(banner_pos, Vector2(pixel_size, pixel_size)), banner_color)

	# Gold trim
	for y in [0, 19]:
		for x in range(20):
			var wave = sin(elapsed * 5 + y * 0.3) * 3
			var trim_pos = pos + Vector2(4 + x + wave * (x / 20.0), -12 + y)
			trim_pos = (trim_pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(trim_pos, Vector2(pixel_size, pixel_size)), trim_color)

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
