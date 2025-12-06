extends Node2D

# Ricochet Blade - T2 Throw that bounces between actual enemy targets
# Now properly tracks real enemies and bounces visually with delays

var pixel_size := 4
var damage := 40.0
var bounce_count := 4
var bounce_delay := 0.15  # Time between bounces
var travel_speed := 800.0  # Pixels per second

# State
var targets: Array = []  # Enemy nodes to hit
var current_target_idx := 0
var current_pos := Vector2.ZERO
var target_pos := Vector2.ZERO
var is_traveling := false
var waiting_for_next := false
var wait_timer := 0.0

# Trail particles
var trail_particles := []

# Blade rotation
var blade_rotation := 0.0

# Impact sparks
var impact_sparks := []

# Blood particles
var blood_particles := []

# Colors
const BLOOD_COLOR = Color(0.8, 0.1, 0.1, 1.0)
const BLOOD_DARK = Color(0.5, 0.05, 0.05, 0.9)

func _ready() -> void:
	# Auto-cleanup after max time
	await get_tree().create_timer(5.0).timeout
	queue_free()

func setup(start_pos: Vector2, enemy_targets: Array, dmg: float, bounces: int = 4) -> void:
	"""Setup the ricochet with actual enemy targets"""
	current_pos = start_pos
	global_position = start_pos
	damage = dmg
	bounce_count = bounces

	# Filter valid targets
	targets.clear()
	for enemy in enemy_targets:
		if is_instance_valid(enemy) and targets.size() < bounces:
			targets.append(enemy)

	if targets.size() > 0:
		_start_travel_to_next()
	else:
		queue_free()

func _start_travel_to_next() -> void:
	if current_target_idx >= targets.size():
		# All bounces complete
		await get_tree().create_timer(0.3).timeout
		queue_free()
		return

	var target = targets[current_target_idx]
	if not is_instance_valid(target):
		current_target_idx += 1
		_start_travel_to_next()
		return

	target_pos = target.global_position
	is_traveling = true
	waiting_for_next = false

func _process(delta: float) -> void:
	blade_rotation += delta * 25

	if waiting_for_next:
		wait_timer -= delta
		if wait_timer <= 0:
			current_target_idx += 1
			_start_travel_to_next()
		queue_redraw()
		return

	if is_traveling:
		# Move toward target
		var direction = (target_pos - current_pos).normalized()
		var dist_to_target = current_pos.distance_to(target_pos)
		var move_dist = travel_speed * delta

		if move_dist >= dist_to_target:
			# Reached target
			current_pos = target_pos
			is_traveling = false
			_on_hit_target()
		else:
			current_pos += direction * move_dist

			# Add trail particle
			trail_particles.append({
				"pos": current_pos,
				"alpha": 0.7,
				"size": pixel_size * 2
			})

	# Update trail particles
	for i in range(trail_particles.size() - 1, -1, -1):
		trail_particles[i].alpha -= delta * 4
		if trail_particles[i].alpha <= 0:
			trail_particles.remove_at(i)

	# Update impact sparks
	for i in range(impact_sparks.size() - 1, -1, -1):
		var spark = impact_sparks[i]
		spark.pos += spark.velocity * delta
		spark.velocity *= 0.92
		spark.alpha -= delta * 4
		if spark.alpha <= 0:
			impact_sparks.remove_at(i)

	# Update blood particles
	for i in range(blood_particles.size() - 1, -1, -1):
		var p = blood_particles[i]
		p.pos += p.velocity * delta
		p.velocity.y += 350 * delta  # Gravity
		p.velocity *= 0.97  # Drag
		p.alpha -= delta * 1.8
		p.size = max(p.size - delta * 3, 2)
		if p.alpha <= 0:
			blood_particles.remove_at(i)

	queue_redraw()

func _on_hit_target() -> void:
	if current_target_idx >= targets.size():
		return

	var target = targets[current_target_idx]
	if is_instance_valid(target):
		# Deal damage
		if target.has_method("take_damage"):
			target.take_damage(damage)

		# Spawn impact sparks
		for i in range(8):
			var angle = randf() * TAU
			impact_sparks.append({
				"pos": current_pos,
				"velocity": Vector2(cos(angle), sin(angle)) * randf_range(100, 180),
				"alpha": 1.0
			})

		# Spawn blood explosion!
		_spawn_blood_at(current_pos)

	# Wait before next bounce
	waiting_for_next = true
	wait_timer = bounce_delay

func _spawn_blood_at(pos: Vector2) -> void:
	# Burst of blood droplets in all directions
	for i in range(12):
		var angle = randf() * TAU
		var speed = randf_range(80, 200)
		blood_particles.append({
			"pos": pos,
			"velocity": Vector2(cos(angle), sin(angle)) * speed + Vector2(0, randf_range(-30, 0)),
			"alpha": 1.0,
			"size": randf_range(3, 8),
			"is_dark": randf() < 0.3
		})

func _draw() -> void:
	# Convert to local space
	var local_pos = current_pos - global_position

	# Draw trail
	for particle in trail_particles:
		if particle.alpha > 0:
			var color = Color(0.7, 0.75, 0.85, particle.alpha * 0.6)
			var pos = ((particle.pos - global_position) / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(particle.size, particle.size)), color)

	# Draw upcoming target indicators
	for i in range(current_target_idx, targets.size()):
		var target = targets[i]
		if is_instance_valid(target):
			var tgt_local = target.global_position - global_position
			var indicator_alpha = 0.4 if i == current_target_idx else 0.2
			var color = Color(1.0, 0.8, 0.3, indicator_alpha)
			_draw_target_indicator(tgt_local, color)

	# Draw impact sparks
	for spark in impact_sparks:
		if spark.alpha > 0:
			var color = Color(1.0, 0.85, 0.4, spark.alpha)
			var pos = ((spark.pos - global_position) / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Draw blood particles
	for p in blood_particles:
		if p.alpha > 0:
			var color = BLOOD_DARK if p.get("is_dark", false) else BLOOD_COLOR
			color.a = p.alpha
			var pos = ((p.pos - global_position) / pixel_size).floor() * pixel_size
			var size = int(p.size)
			draw_rect(Rect2(pos, Vector2(size, size)), color)

	# Draw blade at current position
	_draw_spinning_blade(local_pos, blade_rotation)

func _draw_target_indicator(center: Vector2, color: Color) -> void:
	# Small crosshair
	var size = 6
	_draw_pixel_line(center + Vector2(-size, 0), center + Vector2(size, 0), color)
	_draw_pixel_line(center + Vector2(0, -size), center + Vector2(0, size), color)

func _draw_spinning_blade(center: Vector2, rotation: float) -> void:
	var blade_length = 18
	var blade_color = Color(0.85, 0.87, 0.95, 1.0)
	var edge_color = Color(1.0, 1.0, 1.0, 0.9)

	# 4 blade points (spinning star)
	for i in range(4):
		var angle = rotation + i * PI / 2
		var end = center + Vector2(cos(angle), sin(angle)) * blade_length
		_draw_pixel_line(center, end, blade_color)
		# Tip highlight
		var tip_pos = (end / pixel_size).floor() * pixel_size
		draw_rect(Rect2(tip_pos, Vector2(pixel_size, pixel_size)), edge_color)

	# Center glow
	var center_pos = (center / pixel_size).floor() * pixel_size
	draw_rect(Rect2(center_pos, Vector2(pixel_size * 2, pixel_size * 2)), blade_color)

func _draw_pixel_line(from: Vector2, to: Vector2, color: Color) -> void:
	var dist = from.distance_to(to)
	var steps = int(dist / pixel_size) + 1
	for i in range(steps):
		var t = float(i) / max(steps - 1, 1)
		var pos = from.lerp(to, t)
		pos = (pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)
