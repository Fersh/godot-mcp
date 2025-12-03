extends EnemyBase

# Bat - Fast, nimble, aggressive glass cannon
# Immediately dives at player from spawn, very fragile

# Dive attack behavior
var is_diving: bool = true  # Start diving immediately
var dive_speed_mult: float = 3.0  # Speed multiplier during dive
var dive_cooldown: float = 0.0
var dive_cooldown_time: float = 0.8  # Short time between dives
var dive_target: Vector2 = Vector2.ZERO

func _on_ready() -> void:
	enemy_type = "bat"

	# Bat stats - extremely fast aggressive glass cannon
	speed = 160.0           # Very fast base movement (aggressive)
	max_health = 6.0        # Extremely fragile
	attack_damage = 5.0     # Moderate damage per hit
	attack_cooldown = 0.4   # Very fast attacks
	attack_range = 35.0     # Close range (dive in)
	windup_duration = 0.1   # Almost instant attack
	animation_speed = 18.0  # Faster flapping animation

	# Bat sprite sheet: 5 columns x 3 rows (16x24 frames)
	# Row 0: Idle/Move (5 frames) - flapping
	# Row 1: Damage (5 frames)
	# Row 2: Death (5 frames)
	ROW_IDLE = 0
	ROW_MOVE = 0  # Same as idle (flapping)
	ROW_ATTACK = 0  # Attack during flight
	ROW_DAMAGE = 1
	ROW_DEATH = 2
	COLS_PER_ROW = 5

	FRAME_COUNTS = {
		0: 5,   # IDLE/MOVE/ATTACK
		1: 5,   # DAMAGE
		2: 5,   # DEATH
	}

	# Scale up the small sprite
	if sprite:
		sprite.scale = Vector2(2.5, 2.5)

func _process_behavior(delta: float) -> void:
	# Update dive cooldown
	if dive_cooldown > 0:
		dive_cooldown -= delta

	if player and is_instance_valid(player):
		var direction = player.global_position - global_position
		var distance = direction.length()
		var dir_normalized = direction.normalized()

		# Set initial dive target if not set (aggressive from spawn)
		if is_diving and dive_target == Vector2.ZERO:
			dive_target = player.global_position

		if is_diving:
			# Dive toward the position the player was at when dive started
			# This allows players to dodge by moving out of the way
			var dive_dir = (dive_target - global_position).normalized()
			velocity = dive_dir * speed * dive_speed_mult
			move_and_slide()
			update_animation(delta, ROW_MOVE, dive_dir)

			# End dive if we've reached the target position (even if player moved)
			var dist_to_target = global_position.distance_to(dive_target)
			if dist_to_target < 20.0:
				is_diving = false
				dive_cooldown = dive_cooldown_time

			# Attack if close to player during dive
			if distance < attack_range and can_attack:
				start_attack()
		else:
			# Brief pause then immediately dive again
			if dive_cooldown <= 0:
				# Start another dive attack!
				is_diving = true
				dive_target = player.global_position
			else:
				# Still approaching aggressively even between dives
				velocity = dir_normalized * speed
				move_and_slide()
				update_animation(delta, ROW_MOVE, dir_normalized)
				if distance < attack_range and can_attack:
					start_attack()
	else:
		velocity = Vector2.ZERO
		update_animation(delta, ROW_IDLE, Vector2.ZERO)

func game_time() -> float:
	# Get elapsed time for erratic movement
	return Time.get_ticks_msec() / 1000.0

func _on_attack_complete() -> void:
	# Quick melee hit
	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		if distance <= attack_range * 1.5:  # Generous range for dive attack
			if player.has_method("take_damage"):
				player.take_damage(attack_damage)
	can_attack = false
