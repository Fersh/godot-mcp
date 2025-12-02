extends EnemyBase

# Bandit Necromancer - Summons undead minions to fight for it
# Dangerous support enemy that creates additional threats

@export var summon_scene: PackedScene  # What to summon (skeleton/ghoul)

# Summoning configuration
var summon_cooldown: float = 12.0      # Time between summons
var summon_timer: float = 6.0          # Start halfway ready
var max_summons: int = 3               # Maximum active summons
var summon_count: int = 0              # Current summon count
var summons: Array = []                # Track active summons

var preferred_range: float = 200.0     # Stay back and summon

func _on_ready() -> void:
	enemy_type = "bandit_necromancer"

	# Bandit Necromancer stats - fragile but dangerous summoner
	speed = 40.0            # Slow (casting focused)
	max_health = 28.0       # Fragile
	attack_damage = 7.0     # Weak direct damage
	attack_cooldown = 2.5   # Slow attacks
	attack_range = 180.0    # Ranged
	windup_duration = 0.6   # Long casting time
	animation_speed = 8.0

	# Bandit Necromancer sprite sheet: 8 columns x 6 rows (32x32 frames)
	# Row 0: Idle (8 frames)
	# Row 1: Move (8 frames)
	# Row 2: Cast 1 (8 frames) - Summon
	# Row 3: Cast 2 (8 frames) - Attack spell
	# Row 4: Damaged (4 frames)
	# Row 5: Death (8 frames)
	ROW_IDLE = 0
	ROW_MOVE = 1
	ROW_ATTACK = 3      # Attack spell
	ROW_DAMAGE = 4
	ROW_DEATH = 5
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 8,   # IDLE
		1: 8,   # MOVE
		2: 8,   # CAST (SUMMON)
		3: 8,   # CAST (ATTACK)
		4: 4,   # DAMAGED
		5: 8,   # DEATH
	}

	# Scale sprite for visibility
	if sprite:
		sprite.scale = Vector2(2.0, 2.0)

func _process_behavior(delta: float) -> void:
	# Update summon timer
	summon_timer += delta

	# Clean up dead summons from tracking
	_cleanup_dead_summons()

	if player and is_instance_valid(player):
		var direction = player.global_position - global_position
		var distance = direction.length()
		var dir_normalized = direction.normalized()

		# Maintain safe distance
		if distance < preferred_range * 0.5:
			# Too close - retreat!
			velocity = -dir_normalized * speed * 1.3
			move_and_slide()
			update_animation(delta, ROW_MOVE, -dir_normalized)
		elif distance > attack_range * 1.2:
			# Too far - move closer
			velocity = dir_normalized * speed
			move_and_slide()
			update_animation(delta, ROW_MOVE, dir_normalized)
		else:
			# In range - summon or attack
			velocity = Vector2.ZERO

			# Prioritize summoning if possible
			if summon_timer >= summon_cooldown and summon_count < max_summons:
				update_animation(delta, 2, dir_normalized)  # Summon cast animation
				if can_attack:
					start_summon()
			else:
				update_animation(delta, ROW_ATTACK, dir_normalized)
				if can_attack:
					start_attack()
	else:
		velocity = Vector2.ZERO
		update_animation(delta, ROW_IDLE, Vector2.ZERO)

func _cleanup_dead_summons() -> void:
	var alive_summons: Array = []
	for summon in summons:
		if is_instance_valid(summon) and not summon.is_dying:
			alive_summons.append(summon)
	summons = alive_summons
	summon_count = summons.size()

func start_summon() -> void:
	if is_winding_up or is_dying or is_stunned:
		return

	is_winding_up = true
	can_attack = false
	animation_frame = 0.0

	# Longer cast for summon
	await get_tree().create_timer(windup_duration * 1.2).timeout

	if not is_dying:
		_on_summon_complete()

	is_winding_up = false

	# Start attack cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _on_summon_complete() -> void:
	summon_timer = 0.0

	if summon_scene:
		# Summon behind the necromancer
		var summon = summon_scene.instantiate()
		var offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
		summon.global_position = global_position + offset

		# Make summoned enemies weaker
		if "max_health" in summon:
			summon.max_health *= 0.5
		if "current_health" in summon:
			summon.current_health = summon.max_health
		if "attack_damage" in summon:
			summon.attack_damage *= 0.6

		# Visual indicator - darker tint
		if summon.has_node("Sprite"):
			summon.get_node("Sprite").modulate = Color(0.6, 0.5, 0.7, 1.0)
		elif summon.has_node("Sprite2D"):
			summon.get_node("Sprite2D").modulate = Color(0.6, 0.5, 0.7, 1.0)

		get_parent().add_child(summon)
		summons.append(summon)
		summon_count += 1

func _on_attack_complete() -> void:
	# Weak ranged attack
	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		if distance <= attack_range:
			if player.has_method("take_damage"):
				player.take_damage(attack_damage)
	can_attack = false

# When necromancer dies, summons become weaker
func die() -> void:
	# Damage all active summons when necromancer dies
	for summon in summons:
		if is_instance_valid(summon) and not summon.is_dying:
			if summon.has_method("take_damage"):
				summon.take_damage(summon.max_health * 0.3)  # 30% HP damage

	super.die()
