extends EnemyBase

# Golem - Extremely slow, extremely tanky, devastating hits
# A walking wall of stone that crushes anything it catches

# Ground slam AOE attack
var slam_range: float = 80.0
var slam_damage_mult: float = 1.5

func _on_ready() -> void:
	enemy_type = "golem"

	# Golem stats - ultimate tank, glacially slow
	speed = 28.0            # VERY slow
	max_health = 200.0      # EXTREMELY tanky
	attack_damage = 25.0    # DEVASTATING damage
	attack_cooldown = 2.0   # Slow but deadly attacks
	attack_range = 70.0     # Medium range (big arms)
	windup_duration = 0.6   # Long, telegraphed attacks
	animation_speed = 6.0   # Slow, heavy animations

	# Golem sprite sheet: 10 columns x 10 rows (32x32 frames)
	# Rows 0-4 are right-facing, rows 5-9 are left-facing mirrors
	# Row 0: Idle (10 frames)
	# Row 1: Move (5 frames)
	# Row 2: Attack (5 frames)
	# Row 3: Damaged (5 frames)
	# Row 4: Death (10 frames)
	ROW_IDLE = 0
	ROW_MOVE = 1
	ROW_ATTACK = 2
	ROW_DAMAGE = 3
	ROW_DEATH = 4
	COLS_PER_ROW = 10

	FRAME_COUNTS = {
		0: 10,  # IDLE
		1: 5,   # MOVE
		2: 5,   # ATTACK
		3: 5,   # DAMAGED
		4: 10,  # DEATH
	}

	# Scale up for imposing presence
	if sprite:
		sprite.scale = Vector2(2.5, 2.5)

func _process_behavior(delta: float) -> void:
	if player and is_instance_valid(player):
		var direction = player.global_position - global_position
		var distance = direction.length()
		var dir_normalized = direction.normalized()

		if distance > attack_range:
			# Slow, relentless pursuit
			velocity = dir_normalized * speed
			move_and_slide()
			update_animation(delta, ROW_MOVE, dir_normalized)
		else:
			# In range - ground slam attack
			velocity = Vector2.ZERO
			update_animation(delta, ROW_ATTACK, dir_normalized)
			if can_attack:
				start_attack()
	else:
		velocity = Vector2.ZERO
		update_animation(delta, ROW_IDLE, Vector2.ZERO)

func _on_attack_complete() -> void:
	# Devastating ground slam - AOE damage
	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)

		# Primary target takes full damage
		if distance <= attack_range:
			if player.has_method("take_damage"):
				player.take_damage(attack_damage)

		# Screen shake effect (if available)
		_trigger_screen_shake()

	can_attack = false

func _trigger_screen_shake() -> void:
	# Try to trigger screen shake for impact
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(0.2, 8.0)
	elif camera and camera.has_method("add_trauma"):
		camera.add_trauma(0.3)

# Golem takes reduced knockback
func apply_knockback(direction: Vector2, force: float) -> void:
	# Golem is too heavy for normal knockback
	super.apply_knockback(direction, force * 0.2)

# Golem has natural damage resistance
func take_damage(amount: float, knockback_dir: Vector2 = Vector2.ZERO, knockback_force: float = 0.0) -> void:
	# 20% damage reduction from stone body
	var reduced_damage = amount * 0.8
	super.take_damage(reduced_damage, knockback_dir, knockback_force)
