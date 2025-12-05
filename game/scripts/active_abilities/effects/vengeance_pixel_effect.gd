extends Node2D

# Vengeance - T3 Taunt return all damage taken

var pixel_size := 4
var duration := 1.1
var elapsed := 0.0

# Damage absorption
var absorbed_damage := []
var num_absorbed := 12

# Vengeance buildup
var vengeance_charge := 0.0
var charge_particles := []
var num_particles := 25

# Release wave
var release_wave_radius := 0.0
var release_wave_alpha := 0.0

# Blood pool beneath
var blood_pool_alpha := 0.0

# Damage counter
var counter_value := 0.0

func _ready() -> void:
	# Initialize absorbed damage visuals
	for i in range(num_absorbed):
		var angle = randf() * TAU
		absorbed_damage.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(60, 100),
			"velocity": Vector2.ZERO,
			"alpha": 0.0,
			"trigger_time": 0.1 + randf() * 0.4,
			"absorbed": false
		})

	# Initialize charge particles
	for i in range(num_particles):
		var angle = randf() * TAU
		charge_particles.append({
			"angle": angle,
			"radius": randf_range(30, 50),
			"orbit_speed": randf_range(3, 6),
			"alpha": 0.0
		})

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Blood pool forms
	blood_pool_alpha = ease(min(progress * 2, 1.0), 0.3) * (1.0 - progress * 0.3)

	# Vengeance charge builds
	vengeance_charge = ease(min(progress * 1.5, 1.0), 0.4)
	counter_value = vengeance_charge * 999  # Visual counter

	# Release wave near end
	if progress > 0.7:
		var release_progress = (progress - 0.7) / 0.3
		release_wave_radius = release_progress * 120
		release_wave_alpha = max(0, 1.0 - release_progress)

	# Update absorbed damage
	for dmg in absorbed_damage:
		if elapsed > dmg.trigger_time:
			if not dmg.absorbed:
				dmg.alpha = 1.0
				var dir_to_center = -dmg.pos.normalized()
				dmg.velocity = dir_to_center * 200
				dmg.pos += dmg.velocity * delta

				if dmg.pos.length() < 20:
					dmg.absorbed = true
					dmg.alpha = 0
			else:
				dmg.alpha = 0

	# Update charge particles
	for p in charge_particles:
		p.angle += p.orbit_speed * delta
		p.alpha = vengeance_charge * 0.8

	queue_redraw()

func _draw() -> void:
	# Draw blood pool
	if blood_pool_alpha > 0:
		var pool_color = Color(0.5, 0.1, 0.1, blood_pool_alpha * 0.5)
		_draw_ellipse(Vector2(0, 15), 50, 20, pool_color)

	# Draw absorbed damage incoming
	for dmg in absorbed_damage:
		if dmg.alpha > 0 and not dmg.absorbed:
			var color = Color(1.0, 0.3, 0.2, dmg.alpha)
			_draw_pixel_circle(dmg.pos, 6, color)
			# Trail
			var trail_color = Color(1.0, 0.2, 0.1, dmg.alpha * 0.5)
			var trail_pos = dmg.pos - dmg.velocity.normalized() * 15
			_draw_pixel_line(trail_pos, dmg.pos, trail_color)

	# Draw vengeance aura
	if vengeance_charge > 0:
		var outer_color = Color(0.8, 0.2, 0.1, vengeance_charge * 0.4)
		_draw_pixel_circle(Vector2.ZERO, 55, outer_color)
		var inner_color = Color(1.0, 0.4, 0.2, vengeance_charge * 0.6)
		_draw_pixel_circle(Vector2.ZERO, 30, inner_color)

	# Draw charge particles
	for p in charge_particles:
		if p.alpha > 0:
			var pos = Vector2(cos(p.angle), sin(p.angle)) * p.radius
			var color = Color(1.0, 0.5, 0.2, p.alpha)
			_draw_pixel_circle(pos, 5, color)

	# Draw release wave
	if release_wave_alpha > 0:
		var wave_color = Color(1.0, 0.3, 0.1, release_wave_alpha * 0.6)
		_draw_pixel_ring(Vector2.ZERO, release_wave_radius, wave_color, 12)

	# Draw damage counter
	if vengeance_charge > 0.2:
		_draw_damage_counter(Vector2(0, -50), counter_value, vengeance_charge)

func _draw_ellipse(center: Vector2, width: float, height: float, color: Color) -> void:
	var steps_x = int(width / pixel_size)
	var steps_y = int(height / pixel_size)
	for x in range(-steps_x, steps_x + 1):
		for y in range(-steps_y, steps_y + 1):
			var normalized = Vector2(float(x) / steps_x, float(y) / steps_y)
			if normalized.length() <= 1.0:
				var pos = center + Vector2(x, y) * pixel_size
				pos = (pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_damage_counter(center: Vector2, value: float, alpha: float) -> void:
	# Glowing damage number indicator
	var glow_color = Color(1.0, 0.3, 0.1, alpha * 0.5)
	_draw_pixel_circle(center, 20, glow_color)

	# Number represented as filled bar
	var bar_color = Color(1.0, 0.8, 0.3, alpha)
	var fill = min(value / 999.0, 1.0)
	for i in range(int(fill * 12)):
		var pos = center + Vector2(-22 + i * 4, 0)
		pos = (pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size * 2)), bar_color)

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
