extends EliteBase

# Elite Eye Monster - "The All-Seeing"
# A massive floating eye with devastating gaze attacks
# Inspired by Beholders from D&D and Hades Megaera
#
# Three attack types:
# 1. Acid Spray - Multiple acid projectiles in a cone
# 2. Petrifying Gaze - Lock-on beam that slows, then stuns
# 3. Eye Storm - Spawns smaller eyes that orbit and fire
#
# Eye Monster Sprite Sheet: 8 cols x 5 rows, 32x32 per frame
# Row 0: Idle/Move (8 frames)
# Row 1: Detect (4 frames)
# Row 2: Look around (8 frames)
# Row 3: Prep (4 frames)
# Row 4: Drip Acid/Attack (6 frames)

@export var acid_projectile_scene: PackedScene

# Attack-specific stats
@export var acid_spray_damage: float = 10.0
@export var acid_spray_range: float = 250.0
@export var acid_spray_speed: float = 130.0
@export var acid_spray_count: int = 5
@export var acid_spray_cone: float = 45.0  # Degrees

@export var gaze_damage: float = 5.0  # Per tick
@export var gaze_range: float = 280.0
@export var gaze_lock_time: float = 1.5  # Time to lock on
@export var gaze_stun_duration: float = 1.5
@export var gaze_telegraph_time: float = 0.8

@export var eye_storm_count: int = 4
@export var eye_storm_telegraph_time: float = 1.2
@export var eye_storm_duration: float = 8.0
@export var eye_storm_range: float = 300.0

# Animation rows
var ROW_DETECT: int = 1
var ROW_LOOK: int = 2
var ROW_PREP: int = 3
var ROW_ACID: int = 4

# Attack states
var acid_spray_active: bool = false
var acid_spray_windup_timer: float = 0.0
const ACID_SPRAY_WINDUP: float = 0.5

var gaze_active: bool = false
var gaze_windup_timer: float = 0.0
var gaze_lock_timer: float = 0.0
var gaze_line: Line2D = null
var gaze_target_locked: bool = false

var eye_storm_active: bool = false
var eye_storm_telegraphing: bool = false
var eye_storm_telegraph_timer: float = 0.0
var eye_storm_warning_label: Label = null
var eye_storm_warning_tween: Tween = null
var orbiting_eyes: Array[Node2D] = []

# Preferred range
var preferred_range: float = 180.0

func _setup_elite() -> void:
	elite_name = "The All-Seeing"
	enemy_type = "eye_monster_elite"

	# Stats - ranged glass cannon
	speed = 45.0  # Slow floating
	max_health = 520.0
	attack_damage = acid_spray_damage
	attack_cooldown = 1.0
	windup_duration = 0.4
	animation_speed = 8.0

	# Eye Monster spritesheet: 8 cols x 5 rows
	ROW_IDLE = 0
	ROW_MOVE = 0
	ROW_DETECT = 1
	ROW_LOOK = 2
	ROW_PREP = 3
	ROW_ACID = 4
	ROW_ATTACK = 4
	ROW_DAMAGE = 1
	ROW_DEATH = 4
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 8,   # IDLE/MOVE
		1: 4,   # DETECT
		2: 8,   # LOOK
		3: 4,   # PREP
		4: 6,   # ACID DRIP
	}

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Scale up for elite size - giant floating eye
	if sprite:
		sprite.scale = Vector2(5.0, 5.0)
		# Eerie glow
		sprite.modulate = Color(1.0, 0.95, 1.1, 1.0)

	# Define available attacks with priorities
	available_attacks = [
		{
			"type": AttackType.RANGED,
			"name": "acid_spray",
			"range": acid_spray_range,
			"cooldown": 4.0,
			"priority": 5
		},
		{
			"type": AttackType.RANGED,
			"name": "petrifying_gaze",
			"range": gaze_range,
			"cooldown": 8.0,
			"priority": 6
		},
		{
			"type": AttackType.SPECIAL,
			"name": "eye_storm",
			"range": eye_storm_range,
			"cooldown": 18.0,
			"priority": 7
		}
	]

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"acid_spray":
			_start_acid_spray()
		"petrifying_gaze":
			_start_petrifying_gaze()
		"eye_storm":
			_start_eye_storm()

# Override behavior for kiting
func _process_behavior(delta: float) -> void:
	if is_using_special or gaze_active:
		if gaze_active:
			_process_gaze(delta)
		else:
			_process_special_attack(delta)
		return

	if player and is_instance_valid(player):
		var direction = player.global_position - global_position
		var distance = direction.length()
		var dir_normalized = direction.normalized()

		# Maintain safe distance
		if distance < preferred_range * 0.6:
			velocity = -dir_normalized * speed
			move_and_slide()
			update_animation(delta, ROW_MOVE, -dir_normalized)
		elif distance > acid_spray_range:
			velocity = dir_normalized * speed * 0.8
			move_and_slide()
			update_animation(delta, ROW_MOVE, dir_normalized)
		else:
			velocity = Vector2.ZERO

			var best_attack = _select_best_attack(distance)
			if not best_attack.is_empty() and can_attack and attack_cooldowns[best_attack.name] <= 0:
				current_attack = best_attack
				_start_elite_attack(best_attack)
			else:
				update_animation(delta, ROW_IDLE, dir_normalized)
	else:
		velocity = Vector2.ZERO
		update_animation(delta, ROW_IDLE, Vector2.ZERO)

# ============================================
# ACID SPRAY
# ============================================

func _start_acid_spray() -> void:
	acid_spray_active = true
	acid_spray_windup_timer = ACID_SPRAY_WINDUP

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ACID, dir)
	animation_frame = 0

func _execute_acid_spray() -> void:
	if not player or not is_instance_valid(player):
		return

	var base_dir = (player.global_position - global_position).normalized()
	var half_cone = deg_to_rad(acid_spray_cone / 2.0)

	# Fire multiple acid projectiles in cone
	for i in range(acid_spray_count):
		var angle_offset = lerp(-half_cone, half_cone, float(i) / float(acid_spray_count - 1))
		var proj_dir = base_dir.rotated(angle_offset)
		_spawn_acid_projectile(proj_dir)

func _spawn_acid_projectile(direction: Vector2) -> void:
	var proj_scene = acid_projectile_scene
	if proj_scene == null:
		proj_scene = load("res://scenes/enemy_projectile.tscn")

	if proj_scene:
		var proj = proj_scene.instantiate()
		proj.global_position = global_position + direction * 25

		if "direction" in proj:
			proj.direction = direction
		if "speed" in proj:
			proj.speed = acid_spray_speed
		if "damage" in proj:
			proj.damage = acid_spray_damage

		# Green acid color
		if proj.has_node("Sprite2D"):
			proj.get_node("Sprite2D").modulate = Color(0.4, 1.0, 0.3)
		elif proj.has_node("Sprite"):
			proj.get_node("Sprite").modulate = Color(0.4, 1.0, 0.3)

		get_parent().add_child(proj)

# ============================================
# PETRIFYING GAZE
# ============================================

func _start_petrifying_gaze() -> void:
	gaze_active = true
	gaze_windup_timer = gaze_telegraph_time
	gaze_lock_timer = 0.0
	gaze_target_locked = false
	show_warning()

	_create_gaze_line()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_DETECT, dir)
	animation_frame = 0

func _create_gaze_line() -> void:
	if gaze_line == null:
		gaze_line = Line2D.new()
		gaze_line.width = 6.0
		gaze_line.default_color = Color(0.8, 0.8, 0.2, 0.5)
		gaze_line.z_index = 10
		add_child(gaze_line)

	gaze_line.clear_points()
	gaze_line.visible = true

func _process_gaze(delta: float) -> void:
	if not player or not is_instance_valid(player):
		_end_gaze()
		return

	# Telegraph phase
	if gaze_windup_timer > 0:
		gaze_windup_timer -= delta

		# Track player during telegraph
		var direction = (player.global_position - global_position).normalized()

		# Update gaze line
		if gaze_line:
			gaze_line.clear_points()
			gaze_line.add_point(Vector2.ZERO)
			gaze_line.add_point(direction * gaze_range)
			gaze_line.default_color = Color(0.8, 0.8, 0.2, 0.5)

		update_animation(delta, ROW_DETECT, direction)
		return

	# Lock-on phase
	gaze_lock_timer += delta

	var direction = (player.global_position - global_position).normalized()
	var distance = global_position.distance_to(player.global_position)

	# Update gaze line - intensify color
	if gaze_line:
		gaze_line.clear_points()
		gaze_line.add_point(Vector2.ZERO)
		gaze_line.add_point(direction * gaze_range)

		var intensity = gaze_lock_timer / gaze_lock_time
		gaze_line.default_color = Color(1.0, 0.3 + intensity * 0.3, 0.2, 0.7 + intensity * 0.3)
		gaze_line.width = 6.0 + intensity * 6.0

	# Check if player is in gaze
	if distance <= gaze_range:
		# Deal damage over time while in gaze
		if player.has_method("take_damage"):
			player.take_damage(gaze_damage * delta)

		# Apply slowing effect
		if player.has_method("apply_slow"):
			player.apply_slow(0.5, 0.2)

		# Check for full lock-on (stun)
		if gaze_lock_timer >= gaze_lock_time:
			_execute_gaze_stun()
			return
	else:
		# Player escaped gaze - reset lock timer
		gaze_lock_timer = max(0, gaze_lock_timer - delta * 2)

	update_animation(delta, ROW_LOOK, direction)

func _execute_gaze_stun() -> void:
	if player and is_instance_valid(player):
		# Full stun
		if player.has_method("apply_stun"):
			player.apply_stun(gaze_stun_duration)
		elif player.has_method("apply_slow"):
			player.apply_slow(0.9, gaze_stun_duration)

		# Bonus damage on stun
		if player.has_method("take_damage"):
			player.take_damage(gaze_damage * 5)
			_on_elite_attack_hit(gaze_damage * 5)

	if JuiceManager:
		JuiceManager.shake_medium()

	_end_gaze()

func _end_gaze() -> void:
	gaze_active = false
	hide_warning()
	if gaze_line:
		gaze_line.visible = false
	can_attack = false

# ============================================
# EYE STORM (Special Attack)
# ============================================

func _start_eye_storm() -> void:
	show_warning()
	is_using_special = true

	eye_storm_telegraphing = true
	eye_storm_telegraph_timer = eye_storm_telegraph_time
	special_timer = eye_storm_telegraph_time + eye_storm_duration + 1.0

	_show_eye_storm_warning()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_PREP, dir)
	animation_frame = 0

func _execute_eye_storm() -> void:
	eye_storm_telegraphing = false
	eye_storm_active = true
	_hide_eye_storm_warning()

	# Spawn orbiting eyes
	for i in range(eye_storm_count):
		var angle = (TAU / eye_storm_count) * i
		_spawn_orbiting_eye(angle, i)

	if JuiceManager:
		JuiceManager.shake_medium()

	# End storm after duration
	await get_tree().create_timer(eye_storm_duration).timeout
	_end_eye_storm()

func _spawn_orbiting_eye(initial_angle: float, index: int) -> void:
	var eye = Node2D.new()
	eye.z_index = 5
	eye.set_meta("angle", initial_angle)
	eye.set_meta("orbit_radius", 100.0 + index * 15)
	eye.set_meta("fire_cooldown", 0.0)

	var visual = ColorRect.new()
	visual.size = Vector2(25, 25)
	visual.position = Vector2(-12.5, -12.5)
	visual.color = Color(0.9, 0.8, 0.3, 1.0)
	eye.add_child(visual)

	add_child(eye)
	orbiting_eyes.append(eye)

	_process_orbiting_eye(eye)

func _process_orbiting_eye(eye: Node2D) -> void:
	var orbit_speed = 2.0

	while is_instance_valid(eye) and eye_storm_active:
		var delta = get_process_delta_time()

		var angle = eye.get_meta("angle") + orbit_speed * delta
		eye.set_meta("angle", angle)

		var radius = eye.get_meta("orbit_radius")
		eye.position = Vector2(cos(angle), sin(angle)) * radius

		# Fire at player periodically
		var cooldown = eye.get_meta("fire_cooldown") - delta
		if cooldown <= 0 and player and is_instance_valid(player):
			cooldown = 1.5 + randf() * 0.5
			_eye_fire_projectile(eye.global_position)
		eye.set_meta("fire_cooldown", cooldown)

		await get_tree().process_frame

func _eye_fire_projectile(from_pos: Vector2) -> void:
	if not player or not is_instance_valid(player):
		return

	var direction = (player.global_position - from_pos).normalized()

	var proj_scene = acid_projectile_scene
	if proj_scene == null:
		proj_scene = load("res://scenes/enemy_projectile.tscn")

	if proj_scene:
		var proj = proj_scene.instantiate()
		proj.global_position = from_pos

		if "direction" in proj:
			proj.direction = direction
		if "speed" in proj:
			proj.speed = 100.0
		if "damage" in proj:
			proj.damage = 6.0

		# Yellow eye color
		if proj.has_node("Sprite2D"):
			proj.get_node("Sprite2D").modulate = Color(1.0, 0.9, 0.3)
			proj.get_node("Sprite2D").scale = Vector2(0.8, 0.8)
		elif proj.has_node("Sprite"):
			proj.get_node("Sprite").modulate = Color(1.0, 0.9, 0.3)
			proj.get_node("Sprite").scale = Vector2(0.8, 0.8)

		get_parent().add_child(proj)

func _show_eye_storm_warning() -> void:
	if eye_storm_warning_label == null:
		eye_storm_warning_label = Label.new()
		eye_storm_warning_label.text = "EYE STORM!"
		eye_storm_warning_label.add_theme_font_size_override("font_size", 16)
		eye_storm_warning_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
		eye_storm_warning_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		eye_storm_warning_label.add_theme_constant_override("shadow_offset_x", 2)
		eye_storm_warning_label.add_theme_constant_override("shadow_offset_y", 2)
		eye_storm_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		eye_storm_warning_label.z_index = 100

		if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
			var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
			eye_storm_warning_label.add_theme_font_override("font", pixel_font)

		add_child(eye_storm_warning_label)

	eye_storm_warning_label.position = Vector2(-50, -100)
	eye_storm_warning_label.visible = true

	if eye_storm_warning_tween and eye_storm_warning_tween.is_valid():
		eye_storm_warning_tween.kill()

	eye_storm_warning_tween = create_tween().set_loops()
	eye_storm_warning_tween.tween_property(eye_storm_warning_label, "modulate:a", 0.5, 0.15)
	eye_storm_warning_tween.tween_property(eye_storm_warning_label, "modulate:a", 1.0, 0.15)

func _hide_eye_storm_warning() -> void:
	if eye_storm_warning_tween and eye_storm_warning_tween.is_valid():
		eye_storm_warning_tween.kill()
		eye_storm_warning_tween = null
	if eye_storm_warning_label:
		eye_storm_warning_label.visible = false

func _end_eye_storm() -> void:
	eye_storm_active = false

	for eye in orbiting_eyes:
		if is_instance_valid(eye):
			eye.queue_free()
	orbiting_eyes.clear()

# ============================================
# PHYSICS AND SPECIAL PROCESSING
# ============================================

func _physics_process(delta: float) -> void:
	# Handle acid spray windup
	if acid_spray_active:
		acid_spray_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_ACID, 6)
		sprite.frame = ROW_ACID * COLS_PER_ROW + int(animation_frame) % max_frames

		if acid_spray_windup_timer <= 0:
			_execute_acid_spray()
			acid_spray_active = false
			can_attack = false
		return

	super._physics_process(delta)

func _process_special_attack(delta: float) -> void:
	if eye_storm_telegraphing:
		eye_storm_telegraph_timer -= delta

		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * 0.5 * delta
		var max_frames = FRAME_COUNTS.get(ROW_PREP, 4)
		if animation_frame >= max_frames:
			animation_frame = 0.0
		var clamped_frame = clampi(int(animation_frame), 0, max_frames - 1)
		sprite.frame = ROW_PREP * COLS_PER_ROW + clamped_frame

		# Pulsing effect
		var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.01) * 0.15
		if sprite:
			sprite.scale = Vector2(5.0, 5.0) * pulse

		if eye_storm_telegraph_timer <= 0:
			if sprite:
				sprite.scale = Vector2(5.0, 5.0)
			_execute_eye_storm()
		return

func _on_special_complete() -> void:
	super._on_special_complete()
	_end_eye_storm()
	_hide_eye_storm_warning()
	if sprite:
		sprite.scale = Vector2(5.0, 5.0)

func die() -> void:
	_end_gaze()
	_end_eye_storm()
	_hide_eye_storm_warning()
	super.die()
