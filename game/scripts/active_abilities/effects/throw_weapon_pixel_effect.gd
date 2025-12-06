extends Node2D

# Throw Weapon - Sword flies to target enemy with blood explosion on impact
# Visually shows a spinning sword traveling to the enemy and hitting them

var pixel_size := 4
var travel_speed := 600.0
var damage := 50.0

# State
var start_pos := Vector2.ZERO
var target_enemy: Node2D = null
var target_pos := Vector2.ZERO
var current_pos := Vector2.ZERO
var is_traveling := true
var hit_complete := false

# Animation
var blade_rotation := 0.0
var elapsed := 0.0

# Trail particles
var trail_particles := []

# Blood/impact particles
var blood_particles := []
var impact_sparks := []

# Colors
const BLADE_COLOR = Color(0.85, 0.85, 0.92, 1.0)
const BLADE_EDGE = Color(1.0, 1.0, 1.0, 0.95)
const TRAIL_COLOR = Color(0.6, 0.65, 0.8, 0.5)
const BLOOD_COLOR = Color(0.8, 0.1, 0.1, 1.0)
const BLOOD_DARK = Color(0.5, 0.05, 0.05, 0.9)
const IMPACT_FLASH = Color(1.0, 0.3, 0.2, 0.8)

func _ready() -> void:
	# Auto-cleanup after max time
	await get_tree().create_timer(3.0).timeout
	queue_free()

func setup(p_start_pos: Vector2, p_target: Node2D, p_damage: float, p_speed: float = 600.0) -> void:
	"""Setup the thrown weapon with a target enemy"""
	start_pos = p_start_pos
	current_pos = p_start_pos
	global_position = p_start_pos
	damage = p_damage
	travel_speed = p_speed

	if is_instance_valid(p_target):
		target_enemy = p_target
		target_pos = p_target.global_position
	else:
		# No target - just throw forward a fixed distance
		var direction = Vector2.RIGHT.rotated(randf() * TAU)
		target_pos = p_start_pos + direction * 200
		is_traveling = true

func _process(delta: float) -> void:
	elapsed += delta
	blade_rotation += delta * 25  # Fast spin

	if is_traveling:
		# Update target position if enemy is still valid (track moving enemies)
		if is_instance_valid(target_enemy):
			target_pos = target_enemy.global_position

		# Move toward target
		var direction = (target_pos - current_pos).normalized()
		var dist_to_target = current_pos.distance_to(target_pos)
		var move_dist = travel_speed * delta

		if move_dist >= dist_to_target:
			# Hit the target!
			current_pos = target_pos
			is_traveling = false
			_on_hit_target()
		else:
			current_pos += direction * move_dist

			# Spawn trail particles
			if randf() < 0.8:
				trail_particles.append({
					"pos": current_pos + Vector2(randf_range(-4, 4), randf_range(-4, 4)),
					"alpha": 0.7,
					"size": pixel_size
				})

	# Update trail particles (fade out)
	for i in range(trail_particles.size() - 1, -1, -1):
		var p = trail_particles[i]
		p.alpha -= delta * 4
		if p.alpha <= 0:
			trail_particles.remove_at(i)

	# Update blood particles
	for i in range(blood_particles.size() - 1, -1, -1):
		var p = blood_particles[i]
		p.pos += p.velocity * delta
		p.velocity.y += 400 * delta  # Gravity
		p.velocity *= 0.98  # Drag
		p.alpha -= delta * 1.5
		p.size = max(p.size - delta * 4, 2)
		if p.alpha <= 0:
			blood_particles.remove_at(i)

	# Update impact sparks
	for i in range(impact_sparks.size() - 1, -1, -1):
		var s = impact_sparks[i]
		s.pos += s.velocity * delta
		s.velocity *= 0.9
		s.alpha -= delta * 5
		if s.alpha <= 0:
			impact_sparks.remove_at(i)

	# Cleanup when all effects are done
	if hit_complete and blood_particles.size() == 0 and impact_sparks.size() == 0:
		queue_free()

	queue_redraw()

func _on_hit_target() -> void:
	hit_complete = true

	# Deal damage to enemy
	if is_instance_valid(target_enemy) and target_enemy.has_method("take_damage"):
		target_enemy.take_damage(damage)

	# Spawn blood explosion!
	_spawn_blood_explosion()

	# Spawn impact sparks
	_spawn_impact_sparks()

func _spawn_blood_explosion() -> void:
	# Main blood spray (directional, away from sword travel)
	var hit_dir = (target_pos - start_pos).normalized()

	# Burst of blood droplets
	for i in range(20):
		var spread_angle = hit_dir.angle() + randf_range(-0.8, 0.8)
		var speed = randf_range(100, 300)
		blood_particles.append({
			"pos": current_pos,
			"velocity": Vector2(cos(spread_angle), sin(spread_angle)) * speed + Vector2(0, randf_range(-50, 0)),
			"alpha": 1.0,
			"size": randf_range(4, 10),
			"is_dark": randf() < 0.3
		})

	# Some blood going other directions
	for i in range(8):
		var angle = randf() * TAU
		var speed = randf_range(50, 150)
		blood_particles.append({
			"pos": current_pos,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"alpha": 0.9,
			"size": randf_range(3, 6),
			"is_dark": randf() < 0.5
		})

func _spawn_impact_sparks() -> void:
	# Bright impact flash particles
	for i in range(12):
		var angle = randf() * TAU
		var speed = randf_range(150, 250)
		impact_sparks.append({
			"pos": current_pos,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"alpha": 1.0
		})

func _draw() -> void:
	# Draw relative to global position
	var offset = -global_position

	# Draw trail
	for p in trail_particles:
		if p.alpha > 0:
			var color = TRAIL_COLOR
			color.a = p.alpha
			var pos = _snap_pixel(p.pos + offset)
			draw_rect(Rect2(pos, Vector2(p.size, p.size)), color)

	# Draw blood particles
	for p in blood_particles:
		if p.alpha > 0:
			var color = BLOOD_DARK if p.get("is_dark", false) else BLOOD_COLOR
			color.a = p.alpha
			var pos = _snap_pixel(p.pos + offset)
			var size = int(p.size)
			draw_rect(Rect2(pos, Vector2(size, size)), color)

	# Draw impact sparks
	for s in impact_sparks:
		if s.alpha > 0:
			var color = IMPACT_FLASH
			color.a = s.alpha
			var pos = _snap_pixel(s.pos + offset)
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Draw spinning sword (if still traveling or just hit)
	if is_traveling or elapsed < 0.2:
		var sword_alpha = 1.0 if is_traveling else max(0, 1.0 - (elapsed * 5))
		if sword_alpha > 0:
			_draw_sword(current_pos + offset, blade_rotation, sword_alpha)

func _draw_sword(center: Vector2, rotation: float, alpha: float) -> void:
	var blade_length := 24.0
	var blade_width := 6.0

	# Direction the blade points
	var dir = Vector2(cos(rotation), sin(rotation))
	var perp = dir.rotated(PI / 2)

	# Blade body
	var tip = center + dir * blade_length
	var base = center - dir * blade_length * 0.3

	var blade_color = BLADE_COLOR
	blade_color.a = alpha
	_draw_pixel_line(base, tip, blade_color)

	# Cross guard
	var guard_size = 8.0
	var guard_start = center - perp * guard_size
	var guard_end = center + perp * guard_size
	_draw_pixel_line(guard_start, guard_end, blade_color)

	# Handle
	var handle_end = center - dir * blade_length * 0.5
	var handle_color = Color(0.4, 0.3, 0.2, alpha)
	_draw_pixel_line(center - dir * blade_length * 0.2, handle_end, handle_color)

	# Bright edge on blade tip
	var edge_color = BLADE_EDGE
	edge_color.a = alpha
	var tip_pos = _snap_pixel(tip)
	draw_rect(Rect2(tip_pos, Vector2(pixel_size, pixel_size)), edge_color)

	# Glint effect
	var glint_t = fmod(elapsed * 8, 1.0)
	var glint_pos = base.lerp(tip, glint_t)
	var glint_color = Color(1.0, 1.0, 1.0, alpha * 0.7 * sin(glint_t * PI))
	if glint_color.a > 0.1:
		var gp = _snap_pixel(glint_pos)
		draw_rect(Rect2(gp, Vector2(pixel_size, pixel_size)), glint_color)

func _draw_pixel_line(from: Vector2, to: Vector2, color: Color) -> void:
	var dist = from.distance_to(to)
	var steps = int(dist / pixel_size) + 1
	for i in range(steps + 1):
		var t = float(i) / max(steps, 1)
		var pos = from.lerp(to, t)
		pos = _snap_pixel(pos)
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _snap_pixel(pos: Vector2) -> Vector2:
	return (pos / pixel_size).floor() * pixel_size
