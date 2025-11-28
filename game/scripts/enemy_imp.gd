extends EnemyBase

# Imp - Ranged attacker with low health
# Keeps distance and fires projectiles

@export var projectile_scene: PackedScene
@export var preferred_range: float = 200.0  # Distance to maintain from player
@export var projectile_speed: float = 150.0

func _on_ready() -> void:
	enemy_type = "imp"

	# Imp stats - glass cannon ranged attacker
	speed = 67.5           # Slower ranged (reduced 10%)
	max_health = 8.0       # Very fragile (40% of orc)
	attack_damage = 6.0    # Good damage per hit
	attack_cooldown = 1.875  # Reduced 20% from 1.5 (slower attack rate)
	attack_range = 250.0   # Long attack range for ranged combat
	windup_duration = 0.4  # Longer windup - telegraphed attack
	animation_speed = 10.0

	# Imp spritesheet: 8 cols x 16 rows based on image analysis
	# Row 0-1: Idle variations (4 frames each)
	# Row 2-3: Move (8 frames)
	# Row 4-5: Flying/hover
	# Row 6: Cast/Attack with projectile visible
	# Row 7: Attack follow-through
	# Row 8-11: Various actions
	# Row 12-13: Damage
	# Row 14-15: Death
	ROW_IDLE = 0
	ROW_MOVE = 2
	ROW_ATTACK = 6
	ROW_DAMAGE = 12
	ROW_DEATH = 14
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 4,   # IDLE
		2: 8,   # MOVE
		6: 8,   # ATTACK
		12: 4,  # DAMAGE
		14: 6,  # DEATH
	}

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

# Override behavior for ranged combat - maintain distance
func _process_behavior(delta: float) -> void:
	if player and is_instance_valid(player):
		var direction = (player.global_position - global_position)
		var distance = direction.length()
		var dir_normalized = direction.normalized()

		if distance < preferred_range * 0.7:
			# Too close - back away
			velocity = -dir_normalized * speed
			move_and_slide()
			update_animation(delta, ROW_MOVE, -dir_normalized)
		elif distance > attack_range:
			# Too far - move closer
			velocity = dir_normalized * speed
			move_and_slide()
			update_animation(delta, ROW_MOVE, dir_normalized)
		else:
			# In range - stop and attack
			velocity = Vector2.ZERO
			update_animation(delta, ROW_ATTACK, dir_normalized)
			if can_attack:
				start_attack()
	else:
		velocity = Vector2.ZERO
		update_animation(delta, ROW_IDLE, Vector2.ZERO)

# Override to fire projectile instead of melee damage
func _on_attack_complete() -> void:
	if player and is_instance_valid(player) and projectile_scene:
		fire_projectile()
	can_attack = false

func fire_projectile() -> void:
	if projectile_scene == null:
		return

	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position

	var direction = (player.global_position - global_position).normalized()
	projectile.direction = direction
	projectile.speed = projectile_speed
	projectile.damage = attack_damage

	get_parent().add_child(projectile)
