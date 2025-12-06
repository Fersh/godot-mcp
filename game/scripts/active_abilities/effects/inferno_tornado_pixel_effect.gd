extends Node2D

# Inferno Tornado - T3 Whirlwind with massive fire tornado

var pixel_size := 4
var duration := 1.0
var elapsed := 0.0
var follow_target: Node2D = null

# Tornado structure
var tornado_height := 100.0
var tornado_rotation := 0.0
var rotation_speed := 15.0

# Fire layers at different heights
var fire_layers := []
var num_layers := 8

# Flying embers
var embers := []
var num_embers := 40

# Ground fire ring
var ground_fire_radius := 0.0
var max_ground_fire := 80.0

# Heat distortion
var heat_waves := []

func _ready() -> void:
	# Initialize fire layers
	for i in range(num_layers):
		var height_ratio = float(i) / num_layers
		fire_layers.append({
			"y_offset": -height_ratio * tornado_height,
			"radius": 40 - height_ratio * 25,
			"rotation_offset": randf() * TAU,
			"intensity": 1.0 - height_ratio * 0.3
		})

	# Initialize embers
	for i in range(num_embers):
		var angle = randf() * TAU
		var height = randf_range(0, tornado_height)
		embers.append({
			"angle": angle,
			"height": height,
			"radius": randf_range(20, 60),
			"velocity_up": randf_range(80, 150),
			"orbit_speed": randf_range(8, 15),
			"alpha": 0.9
		})

	# Initialize heat waves
	for i in range(3):
		heat_waves.append({
			"radius": 0.0,
			"delay": i * 0.2
		})

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func set_follow_target(target: Node2D) -> void:
	follow_target = target

func _process(delta: float) -> void:
	# Follow target if set
	if follow_target and is_instance_valid(follow_target):
		global_position = follow_target.global_position

	elapsed += delta
	var progress = elapsed / duration

	# Tornado rotates
	tornado_rotation += rotation_speed * delta

	# Ground fire expands
	ground_fire_radius = ease(min(progress * 2, 1.0), 0.3) * max_ground_fire

	# Update embers
	for ember in embers:
		ember.angle += ember.orbit_speed * delta
		ember.height += ember.velocity_up * delta
		if ember.height > tornado_height:
			ember.height = 0
			ember.angle = randf() * TAU
		ember.alpha = 0.9 * (1.0 - progress * 0.4)

	# Update heat waves
	for wave in heat_waves:
		if elapsed > wave.delay:
			wave.radius = (elapsed - wave.delay) * 100

	queue_redraw()

func _draw() -> void:
	# Draw heat waves
	for wave in heat_waves:
		if wave.radius > 10 and wave.radius < 150:
			var wave_alpha = max(0, 0.2 - wave.radius / 750)
			var color = Color(1.0, 0.5, 0.2, wave_alpha)
			_draw_pixel_ring(Vector2.ZERO, wave.radius, color, 4)

	# Draw ground fire ring
	if ground_fire_radius > 10:
		var fire_alpha = 0.6 * (1.0 - elapsed / duration * 0.4)
		var outer_color = Color(1.0, 0.3, 0.1, fire_alpha)
		_draw_pixel_ring(Vector2.ZERO, ground_fire_radius, outer_color, 10)
		var inner_color = Color(1.0, 0.6, 0.2, fire_alpha * 0.7)
		_draw_pixel_ring(Vector2.ZERO, ground_fire_radius * 0.7, inner_color, 6)

	# Draw tornado fire layers
	for layer in fire_layers:
		var rotation = tornado_rotation + layer.rotation_offset
		var alpha = layer.intensity * (1.0 - elapsed / duration * 0.3)

		# Draw rotating fire arc at this layer
		_draw_fire_layer(Vector2(0, layer.y_offset), layer.radius, rotation, alpha)

	# Draw embers
	for ember in embers:
		if ember.alpha > 0:
			var x = cos(ember.angle) * ember.radius * (1.0 - ember.height / tornado_height * 0.5)
			var y = -ember.height
			var pos = Vector2(x, y)

			# Color based on height (yellow at bottom, orange/red at top)
			var heat = ember.height / tornado_height
			var r = 1.0
			var g = 0.8 - heat * 0.5
			var b = 0.2 - heat * 0.15
			var color = Color(r, g, b, ember.alpha)

			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Draw bright core
	var core_alpha = 0.8 * (1.0 - elapsed / duration * 0.5)
	var core_color = Color(1.0, 0.9, 0.5, core_alpha)
	_draw_pixel_circle(Vector2(0, -tornado_height * 0.3), 15, core_color)

func _draw_fire_layer(center: Vector2, radius: float, rotation: float, alpha: float) -> void:
	# Draw multiple fire arcs
	for arc in range(3):
		var arc_start = rotation + arc * TAU / 3
		var arc_length = 0.8

		# Outer flame (orange)
		var outer_color = Color(1.0, 0.4, 0.1, alpha * 0.7)
		_draw_fire_arc(center, radius, arc_start, arc_length, outer_color)

		# Core flame (yellow)
		var core_color = Color(1.0, 0.8, 0.3, alpha)
		_draw_fire_arc(center, radius * 0.7, arc_start + 0.1, arc_length * 0.7, core_color)

func _draw_fire_arc(center: Vector2, radius: float, start_angle: float, arc_length: float, color: Color) -> void:
	var steps = int(arc_length * radius / pixel_size) + 8
	for i in range(steps):
		var t = float(i) / steps
		var angle = start_angle + t * arc_length
		var flicker = sin(elapsed * 20 + angle * 3) * 3
		var pos = center + Vector2(cos(angle), sin(angle)) * (radius + flicker)
		pos = (pos / pixel_size).floor() * pixel_size
		var fade = 1.0 - abs(t - 0.5) * 0.6
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), Color(color.r, color.g, color.b, color.a * fade))

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

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 3)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = center + pos
				draw_pos = (draw_pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)
