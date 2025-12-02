extends EnemyBase

# Intellect Devourer - Brain creature that disrupts player abilities
# Special attack disables player abilities temporarily

# Ability drain configuration
var devour_cooldown: float = 8.0      # Cooldown for special attack
var devour_timer: float = 0.0
var devour_duration: float = 3.0       # How long abilities are disabled
var devour_range: float = 60.0         # Range for special attack
var ROW_DEVOUR: int = 3                # Special intellect devour animation

func _on_ready() -> void:
	enemy_type = "intellect_devourer"

	# Intellect Devourer stats - fast, dangerous special attacker
	speed = 68.0            # Fast
	max_health = 35.0       # Moderate HP
	attack_damage = 8.0     # Normal attacks moderate
	attack_cooldown = 1.1   # Decent attack speed
	attack_range = 45.0     # Close range
	windup_duration = 0.3   # Quick
	animation_speed = 10.0

	# Intellect Devourer sprite sheet: 8 columns x 6 rows (32x32 frames)
	# Row 0: Idle (4 frames)
	# Row 1: Movement (8 frames)
	# Row 2: Attack (6 frames)
	# Row 3: Intellect Devour (8 frames) - Special
	# Row 4: Damage (4 frames)
	# Row 5: Death (4 frames)
	ROW_IDLE = 0
	ROW_MOVE = 1
	ROW_ATTACK = 2
	ROW_DEVOUR = 3
	ROW_DAMAGE = 4
	ROW_DEATH = 5
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 4,   # IDLE
		1: 8,   # MOVE
		2: 6,   # ATTACK
		3: 8,   # INTELLECT DEVOUR
		4: 4,   # DAMAGE
		5: 4,   # DEATH
	}

	# Scale sprite for visibility
	if sprite:
		sprite.scale = Vector2(2.0, 2.0)

func _process_behavior(delta: float) -> void:
	# Update devour cooldown
	devour_timer += delta

	if player and is_instance_valid(player):
		var direction = player.global_position - global_position
		var distance = direction.length()
		var dir_normalized = direction.normalized()

		if distance > attack_range:
			# Chase player
			velocity = dir_normalized * speed
			move_and_slide()
			update_animation(delta, ROW_MOVE, dir_normalized)
		else:
			# In range - decide between normal attack and devour
			velocity = Vector2.ZERO

			if devour_timer >= devour_cooldown and distance <= devour_range:
				# Use special intellect devour attack
				update_animation(delta, ROW_DEVOUR, dir_normalized)
				if can_attack:
					start_devour_attack()
			else:
				# Normal attack
				update_animation(delta, ROW_ATTACK, dir_normalized)
				if can_attack:
					start_attack()
	else:
		velocity = Vector2.ZERO
		update_animation(delta, ROW_IDLE, Vector2.ZERO)

var is_devouring: bool = false

func start_devour_attack() -> void:
	if is_attacking or is_dying or is_stunned:
		return

	is_attacking = true
	is_devouring = true
	can_attack = false
	animation_frame = 0.0

	# Longer windup for special attack
	await get_tree().create_timer(windup_duration * 1.5).timeout

	if not is_dying:
		_on_devour_complete()

	is_attacking = false
	is_devouring = false

	# Start attack cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _on_devour_complete() -> void:
	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		if distance <= devour_range:
			# Deal damage
			if player.has_method("take_damage"):
				player.take_damage(attack_damage * 1.5)  # Bonus damage

			# Apply ability disruption
			apply_ability_drain()

			# Reset cooldown
			devour_timer = 0.0

func apply_ability_drain() -> void:
	if not player or not is_instance_valid(player):
		return

	# Try different methods to disrupt player abilities
	if player.has_method("disable_abilities"):
		player.disable_abilities(devour_duration)
	elif player.has_method("apply_silence"):
		player.apply_silence(devour_duration)
	elif player.has_method("apply_status_effect"):
		player.apply_status_effect("silence", devour_duration, 0)
	elif player.has_method("increase_cooldowns"):
		player.increase_cooldowns(2.0)  # Double all current cooldowns
	else:
		# Fallback: Apply a slow effect as disruption
		if player.has_method("apply_slow"):
			player.apply_slow(0.3, devour_duration)

func _on_attack_complete() -> void:
	# Normal melee attack
	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		if distance <= attack_range:
			if player.has_method("take_damage"):
				player.take_damage(attack_damage)
	can_attack = false
