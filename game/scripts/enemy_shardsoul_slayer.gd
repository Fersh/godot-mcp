extends EnemyBase

# Shardsoul Slayer - The ultimate melee threat
# Fast, powerful, relentless hunter that tears through players

# Frenzy mode - activated at low health
var is_frenzied: bool = false
var frenzy_threshold: float = 0.3  # 30% HP
var frenzy_speed_mult: float = 1.4
var frenzy_damage_mult: float = 1.3
var frenzy_cooldown_mult: float = 0.6

# Lunge attack
var lunge_distance: float = 150.0
var lunge_speed: float = 400.0
var is_lunging: bool = false
var lunge_cooldown: float = 5.0
var lunge_timer: float = 3.0  # Start partially ready

func _on_ready() -> void:
	enemy_type = "shardsoul_slayer"

	# Shardsoul Slayer stats - elite melee predator
	speed = 72.0            # Fast
	max_health = 120.0      # Very tanky
	attack_damage = 18.0    # High damage
	attack_cooldown = 0.8   # Fast attacks
	attack_range = 60.0     # Extended claws
	windup_duration = 0.25  # Quick strikes
	animation_speed = 12.0

	# Shardsoul Slayer sprite sheet: 8 columns x 5 rows (64x64 frames)
	# Row 0: Movement (8 frames)
	# Row 1: Attack (8 frames)
	# Row 2: Damaged (5 frames)
	# Row 3: Death (4 frames)
	# Row 4: Special/Lunge (6 frames)
	ROW_IDLE = 0
	ROW_MOVE = 0
	ROW_ATTACK = 1
	ROW_DAMAGE = 2
	ROW_DEATH = 3
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 8,   # MOVE/IDLE
		1: 8,   # ATTACK
		2: 5,   # DAMAGED
		3: 4,   # DEATH
		4: 6,   # SPECIAL
	}

	# Large, imposing sprite
	if sprite:
		sprite.scale = Vector2(1.8, 1.8)

func _process_behavior(delta: float) -> void:
	# Update lunge cooldown
	lunge_timer += delta

	# Check for frenzy activation
	if not is_frenzied and current_health <= max_health * frenzy_threshold:
		activate_frenzy()

	if player and is_instance_valid(player):
		var direction = player.global_position - global_position
		var distance = direction.length()
		var dir_normalized = direction.normalized()

		if is_lunging:
			# Continue lunge
			return

		# Check for lunge attack opportunity
		if lunge_timer >= lunge_cooldown and distance > attack_range * 2 and distance < lunge_distance * 1.5:
			start_lunge(dir_normalized)
			return

		if distance > attack_range:
			# Chase with relentless speed
			var chase_speed = speed
			if is_frenzied:
				chase_speed *= frenzy_speed_mult
			velocity = dir_normalized * chase_speed
			move_and_slide()
			update_animation(delta, ROW_MOVE, dir_normalized)
		else:
			# In range - savage attacks
			velocity = Vector2.ZERO
			update_animation(delta, ROW_ATTACK, dir_normalized)
			if can_attack:
				start_attack()
	else:
		velocity = Vector2.ZERO
		update_animation(delta, ROW_IDLE, Vector2.ZERO)

func activate_frenzy() -> void:
	is_frenzied = true

	# Visual feedback - red tint
	if sprite:
		sprite.modulate = Color(1.2, 0.7, 0.7, 1.0)

	# Stat boosts are applied through multipliers in behavior

	# Reduce attack cooldown
	attack_cooldown *= frenzy_cooldown_mult

func start_lunge(direction: Vector2) -> void:
	if is_attacking or is_dying or is_stunned or is_lunging:
		return

	is_lunging = true
	lunge_timer = 0.0

	# Brief windup
	await get_tree().create_timer(0.15).timeout

	if is_dying:
		is_lunging = false
		return

	# Lunge toward player
	var lunge_target = global_position + direction * lunge_distance
	var lunge_duration = lunge_distance / lunge_speed

	var tween = create_tween()
	tween.tween_property(self, "global_position", lunge_target, lunge_duration)

	await tween.finished

	# Attack at end of lunge
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= attack_range * 1.5:
			if player.has_method("take_damage"):
				var lunge_damage = attack_damage * 1.5
				if is_frenzied:
					lunge_damage *= frenzy_damage_mult
				player.take_damage(lunge_damage)

	is_lunging = false

func _on_attack_complete() -> void:
	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		if distance <= attack_range:
			if player.has_method("take_damage"):
				var damage = attack_damage
				if is_frenzied:
					damage *= frenzy_damage_mult
				player.take_damage(damage)
	can_attack = false
