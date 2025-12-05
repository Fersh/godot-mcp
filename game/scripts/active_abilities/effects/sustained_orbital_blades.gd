extends Node2D

# Sustained Orbital Blades - T3 Throw Weapon of Storms
# 6 blades orbit the player for 8 seconds, dealing damage to nearby enemies

var pixel_size := 4
var duration := 8.0
var radius := 80.0
var damage_per_second := 25.0
var num_blades := 6

var player: Node2D = null
var elapsed := 0.0
var spin_angle := 0.0

# Individual blade data
var blades := []

# Damage tick tracking
var damage_tick_interval := 0.25
var damage_tick_timer := 0.0
var hit_enemies_this_tick: Array = []

# Visual effects
var energy_particles := []

func _ready() -> void:
	pass

func setup(p_player: Node2D, p_damage: float, p_radius: float, p_duration: float) -> void:
	player = p_player
	damage_per_second = p_damage
	radius = p_radius
	duration = p_duration

	# Initialize blades with slight variations
	blades.clear()
	for i in range(num_blades):
		var angle = (float(i) / num_blades) * TAU
		blades.append({
			"base_angle": angle,
			"radius_offset": randf_range(-8, 8),
			"rotation": randf() * TAU,
			"spin_speed": randf_range(12, 18)
		})

func _process(delta: float) -> void:
	elapsed += delta

	if elapsed >= duration:
		queue_free()
		return

	if not is_instance_valid(player):
		queue_free()
		return

	# Follow player
	global_position = player.global_position

	# Spin the orbit
	var base_spin_speed = 3.0 + elapsed * 0.2  # Gradually speeds up
	spin_angle += base_spin_speed * delta

	# Update individual blade rotations
	for blade in blades:
		blade.rotation += blade.spin_speed * delta

	# Damage tick
	damage_tick_timer += delta
	if damage_tick_timer >= damage_tick_interval:
		damage_tick_timer = 0.0
		_deal_damage_tick()
		hit_enemies_this_tick.clear()

	# Spawn energy particles
	if randf() < 0.3:
		var angle = randf() * TAU
		var r = radius * randf_range(0.5, 1.2)
		energy_particles.append({
			"pos": Vector2(cos(angle), sin(angle)) * r,
			"alpha": 0.6,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(-20, 20)
		})

	# Update particles
	for i in range(energy_particles.size() - 1, -1, -1):
		var p = energy_particles[i]
		p.pos += p.velocity * delta
		p.alpha -= delta * 2
		if p.alpha <= 0:
			energy_particles.remove_at(i)

	queue_redraw()

func _deal_damage_tick() -> void:
	var tick_damage = damage_per_second * damage_tick_interval

	# Get all enemies in blade orbit area
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy in hit_enemies_this_tick:
			continue

		var dist = global_position.distance_to(enemy.global_position)
		if dist <= radius + 30:  # Slight extra range for blade reach
			if enemy.has_method("take_damage"):
				enemy.take_damage(tick_damage)
				hit_enemies_this_tick.append(enemy)

				# Spawn hit spark
				var hit_dir = (enemy.global_position - global_position).normalized()
				for j in range(3):
					var angle = hit_dir.angle() + randf_range(-0.5, 0.5)
					energy_particles.append({
						"pos": enemy.global_position - global_position,
						"alpha": 1.0,
						"velocity": Vector2(cos(angle), sin(angle)) * randf_range(80, 150)
					})

func _draw() -> void:
	# Fade in/out
	var alpha_mult = 1.0
	if elapsed < 0.3:
		alpha_mult = elapsed / 0.3
	elif elapsed > duration - 0.5:
		alpha_mult = (duration - elapsed) / 0.5

	# Draw orbit ring (faint)
	var ring_color = Color(0.5, 0.6, 0.9, 0.15 * alpha_mult)
	_draw_pixel_ring(Vector2.ZERO, radius, ring_color)

	# Draw energy particles
	for p in energy_particles:
		if p.alpha > 0:
			var color = Color(0.6, 0.7, 1.0, p.alpha * 0.5 * alpha_mult)
			var pos = (p.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Draw blades
	for blade in blades:
		var angle = blade.base_angle + spin_angle
		var r = radius + blade.radius_offset
		var pos = Vector2(cos(angle), sin(angle)) * r
		_draw_blade(pos, blade.rotation, alpha_mult)

	# Draw center vortex
	var vortex_color = Color(0.7, 0.8, 1.0, 0.3 * alpha_mult)
	for i in range(3):
		var vortex_angle = spin_angle * 2 + i * TAU / 3
		var end = Vector2(cos(vortex_angle), sin(vortex_angle)) * 25
		_draw_pixel_line(Vector2.ZERO, end, vortex_color)

func _draw_blade(center: Vector2, rotation: float, alpha_mult: float) -> void:
	var blade_color = Color(0.85, 0.9, 1.0, 0.9 * alpha_mult)
	var edge_color = Color(1.0, 1.0, 1.0, alpha_mult)
	var glow_color = Color(0.6, 0.7, 1.0, 0.4 * alpha_mult)

	var blade_length = 20

	# Blade body
	var dir = Vector2(cos(rotation), sin(rotation))
	var tip = center + dir * blade_length
	var back = center - dir * blade_length * 0.4

	# Glow behind blade
	_draw_pixel_circle(center, 8, glow_color)

	# Main blade line
	_draw_pixel_line(back, tip, blade_color)

	# Cross guard
	var perp = dir.rotated(PI / 2)
	_draw_pixel_line(center - perp * 5, center + perp * 5, blade_color)

	# Bright tip
	var tip_pos = (tip / pixel_size).floor() * pixel_size
	draw_rect(Rect2(tip_pos, Vector2(pixel_size, pixel_size)), edge_color)

func _draw_pixel_ring(center: Vector2, ring_radius: float, color: Color) -> void:
	var steps = max(int(TAU * ring_radius / pixel_size / 2), 16)
	for i in range(steps):
		var angle = (float(i) / steps) * TAU
		var pos = center + Vector2(cos(angle), sin(angle)) * ring_radius
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

func _draw_pixel_circle(center: Vector2, circle_radius: float, color: Color) -> void:
	var steps = max(int(circle_radius / pixel_size), 2)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= circle_radius:
				var draw_pos = center + pos
				draw_pos = (draw_pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)
