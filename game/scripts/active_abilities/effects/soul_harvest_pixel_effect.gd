extends Node2D

# Soul Harvest - T3 Execute that steals souls

var pixel_size := 4
var duration := 0.9
var elapsed := 0.0

# Death scythe slash
var scythe_progress := 0.0

# Souls being harvested (flying toward caster)
var souls := []
var num_souls := 12

# Dark energy vortex
var vortex_rotation := 0.0
var vortex_radius := 50.0

# Death mist
var death_mist := []
var num_mist := 16

# Soul container glow
var container_alpha := 0.0

func _ready() -> void:
	# Initialize souls (start at impact, fly toward center)
	for i in range(num_souls):
		var angle = randf() * TAU
		var dist = randf_range(50, 90)
		souls.append({
			"pos": Vector2(cos(angle), sin(angle)) * dist,
			"target": Vector2.ZERO,
			"alpha": 0.0,
			"delay": 0.2 + randf() * 0.3,
			"speed": randf_range(80, 140),
			"wobble_phase": randf() * TAU
		})

	# Initialize death mist
	for i in range(num_mist):
		var angle = randf() * TAU
		death_mist.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(20, 50),
			"size": randf_range(10, 20),
			"alpha": 0.5,
			"float_offset": randf() * TAU
		})

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Scythe sweeps
	scythe_progress = ease(min(progress * 2.5, 1.0), 0.2)

	# Vortex rotates
	vortex_rotation += delta * 6

	# Container glows as souls arrive
	var souls_collected = 0
	for soul in souls:
		if soul.pos.length() < 20:
			souls_collected += 1
	container_alpha = float(souls_collected) / num_souls * 0.8

	# Update souls
	for soul in souls:
		if elapsed > soul.delay and soul.alpha == 0:
			soul.alpha = 0.9
		if soul.alpha > 0:
			var dir = (soul.target - soul.pos).normalized()
			soul.wobble_phase += delta * 5
			var wobble = Vector2(sin(soul.wobble_phase), cos(soul.wobble_phase)) * 15
			soul.pos += (dir * soul.speed + wobble * 0.3) * delta
			if soul.pos.length() < 15:
				soul.alpha = max(0, soul.alpha - delta * 5)

	# Update death mist
	for mist in death_mist:
		mist.float_offset += delta * 2
		mist.pos.y += sin(mist.float_offset) * delta * 10
		mist.alpha = max(0, 0.5 - progress * 0.5)

	queue_redraw()

func _draw() -> void:
	# Draw death mist
	for mist in death_mist:
		if mist.alpha > 0:
			var color = Color(0.2, 0.1, 0.25, mist.alpha * 0.4)
			_draw_pixel_circle(mist.pos, mist.size, color)

	# Draw vortex
	var vortex_alpha = 0.5 * (1.0 - elapsed / duration)
	if vortex_alpha > 0:
		_draw_soul_vortex(Vector2.ZERO, vortex_radius, vortex_rotation, vortex_alpha)

	# Draw scythe slash
	if scythe_progress > 0:
		_draw_scythe_slash(scythe_progress)

	# Draw souls
	for soul in souls:
		if soul.alpha > 0:
			var color = Color(0.5, 0.9, 0.6, soul.alpha)
			_draw_soul_wisp(soul.pos, color)

	# Draw soul container glow at center
	if container_alpha > 0:
		var glow_color = Color(0.4, 0.8, 0.5, container_alpha)
		_draw_pixel_circle(Vector2.ZERO, 20, glow_color)
		var bright_color = Color(0.6, 1.0, 0.7, container_alpha * 0.6)
		_draw_pixel_circle(Vector2.ZERO, 10, bright_color)

func _draw_soul_vortex(center: Vector2, radius: float, rotation: float, alpha: float) -> void:
	var color = Color(0.3, 0.15, 0.4, alpha * 0.5)
	# Spiral arms
	for arm in range(3):
		var arm_rotation = rotation + arm * TAU / 3
		var steps = 20
		for i in range(steps):
			var t = float(i) / steps
			var angle = arm_rotation + t * PI
			var r = radius * t
			var pos = center + Vector2(cos(angle), sin(angle)) * r
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_scythe_slash(progress: float) -> void:
	var arc_span = PI * 0.8
	var radius = 70.0
	var steps = int(arc_span * progress * 15)

	for i in range(steps):
		var t = float(i) / max(steps, 1)
		var angle = -PI/2 - arc_span/2 + t * arc_span * progress
		var fade = 1.0 - t * 0.5

		# Dark blade
		var blade_color = Color(0.2, 0.1, 0.25, fade * 0.8)
		for r in range(4):
			var pos = Vector2(cos(angle), sin(angle)) * (radius - r * pixel_size)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), blade_color)

		# Purple edge
		var edge_color = Color(0.5, 0.2, 0.6, fade)
		var edge_pos = Vector2(cos(angle), sin(angle)) * radius
		edge_pos = (edge_pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(edge_pos, Vector2(pixel_size, pixel_size)), edge_color)

func _draw_soul_wisp(pos: Vector2, color: Color) -> void:
	# Ghostly soul shape
	_draw_pixel_circle(pos, 6, color)
	# Trail
	var trail_color = Color(color.r, color.g, color.b, color.a * 0.5)
	var trail_pos = pos + Vector2(0, 5)
	_draw_pixel_circle(trail_pos, 4, trail_color)

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 2)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = center + pos
				draw_pos = (draw_pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)
