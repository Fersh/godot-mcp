extends Node2D

# Berserker Rage - T2 Battle Cry with intense damage buff

var pixel_size := 4
var duration := 0.85
var elapsed := 0.0

# Intense red aura
var rage_aura_alpha := 0.0
var aura_radius := 50.0

# Rage flames
var rage_flames := []
var num_flames := 14

# Blood/power veins (pulsing lines)
var veins := []
var num_veins := 8

# Berserker symbols
var symbols := []

# Power burst
var burst_radius := 0.0
var max_burst := 70.0

func _ready() -> void:
	# Initialize rage flames
	for i in range(num_flames):
		var angle = (i * TAU / num_flames)
		rage_flames.append({
			"base_angle": angle,
			"radius": randf_range(30, 45),
			"height": randf_range(20, 35),
			"flicker": randf() * TAU
		})

	# Initialize veins (radial from center)
	for i in range(num_veins):
		veins.append({
			"angle": (i * TAU / num_veins) + randf() * 0.2,
			"length": 0.0,
			"max_length": randf_range(40, 60),
			"pulse": randf() * TAU
		})

	# Initialize berserker symbols (at random positions)
	for i in range(3):
		var angle = randf() * TAU
		symbols.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(30, 50),
			"alpha": 0.0,
			"delay": 0.1 + i * 0.15
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Rage aura intensifies
	rage_aura_alpha = (0.8 + 0.15 * sin(elapsed * 15)) * (1.0 - progress * 0.3)

	# Power burst
	burst_radius = ease(min(progress * 2, 1.0), 0.3) * max_burst

	# Update flames
	for flame in rage_flames:
		flame.flicker += delta * 12

	# Update veins (pulse outward)
	for vein in veins:
		vein.pulse += delta * 10
		var pulse_factor = sin(vein.pulse) * 0.2 + 0.8
		vein.length = vein.max_length * pulse_factor * min(progress * 3, 1.0)

	# Update symbols
	for symbol in symbols:
		if elapsed > symbol.delay:
			var age = elapsed - symbol.delay
			if age < 0.2:
				symbol.alpha = age / 0.2
			else:
				symbol.alpha = max(0, 1.0 - (age - 0.2) / 0.4)

	queue_redraw()

func _draw() -> void:
	# Draw power burst ring
	if burst_radius > 10:
		var ring_alpha = max(0, 1.0 - burst_radius / max_burst) * 0.5
		var ring_color = Color(0.9, 0.2, 0.1, ring_alpha)
		_draw_pixel_ring(Vector2.ZERO, burst_radius, ring_color, 8)

	# Draw rage aura (intense red)
	if rage_aura_alpha > 0:
		var aura_color = Color(0.9, 0.15, 0.1, rage_aura_alpha * 0.5)
		_draw_pixel_circle(Vector2.ZERO, aura_radius, aura_color)

	# Draw veins (blood-red pulsing lines)
	for vein in veins:
		if vein.length > 5:
			var pulse_brightness = sin(vein.pulse) * 0.2 + 0.8
			var color = Color(0.8 * pulse_brightness, 0.1, 0.1, 0.7)
			var end = Vector2(cos(vein.angle), sin(vein.angle)) * vein.length
			_draw_pixel_line(Vector2.ZERO, end, color)

	# Draw rage flames
	for flame in rage_flames:
		var base_pos = Vector2(cos(flame.base_angle), sin(flame.base_angle)) * flame.radius
		var flicker_height = flame.height * (0.7 + 0.3 * sin(flame.flicker))
		var flame_alpha = 1.0 - elapsed / duration * 0.4

		# Draw flame layers
		var outer_color = Color(0.8, 0.1, 0.05, flame_alpha * 0.6)
		var mid_color = Color(1.0, 0.3, 0.1, flame_alpha * 0.8)
		var core_color = Color(1.0, 0.7, 0.3, flame_alpha)

		_draw_flame(base_pos, flicker_height, outer_color, 1.3)
		_draw_flame(base_pos, flicker_height * 0.7, mid_color, 1.0)
		_draw_flame(base_pos, flicker_height * 0.4, core_color, 0.7)

	# Draw berserker symbols
	for symbol in symbols:
		if symbol.alpha > 0:
			var color = Color(1.0, 0.3, 0.2, symbol.alpha)
			_draw_berserker_mark(symbol.pos, color)

func _draw_flame(base: Vector2, height: float, color: Color, width_scale: float) -> void:
	var base_width = 10 * width_scale
	for y in range(int(height / pixel_size)):
		var t = float(y) / (height / pixel_size)
		var row_width = base_width * (1.0 - t)
		for x in range(int(-row_width / pixel_size), int(row_width / pixel_size) + 1):
			var pos = base + Vector2(x * pixel_size, -y * pixel_size)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_berserker_mark(center: Vector2, color: Color) -> void:
	# Crossed axes symbol
	_draw_pixel_line(center + Vector2(-8, -8), center + Vector2(8, 8), color)
	_draw_pixel_line(center + Vector2(8, -8), center + Vector2(-8, 8), color)
	# Center dot
	var snapped = (center / pixel_size).floor() * pixel_size
	draw_rect(Rect2(snapped, Vector2(pixel_size, pixel_size)), color)

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
