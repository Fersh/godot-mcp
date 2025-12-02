extends EnemyBase

# Akaname - Poison tongue melee attacker
# A yokai creature that licks enemies with its poisonous tongue

# Poison configuration
var poison_damage: float = 3.0      # Damage per tick
var poison_duration: float = 4.0    # How long poison lasts
var poison_chance: float = 0.7      # 70% chance to poison on hit

func _on_ready() -> void:
	enemy_type = "akaname"

	# Akaname stats - fast, moderate damage, poison threat
	speed = 62.0            # Moderately fast
	max_health = 22.0       # Slightly tanky
	attack_damage = 6.0     # Moderate base damage
	attack_cooldown = 0.9   # Decent attack speed
	attack_range = 55.0     # Extended tongue range
	windup_duration = 0.25  # Quick lick attack
	animation_speed = 10.0

	# Akaname sprite sheet: 8 columns x 4 rows (32x32 frames)
	# Row 0: Idle (5 frames)
	# Row 1: Move (8 frames)
	# Row 2: Attack (8 frames)
	# Row 3: Death (6 frames)
	ROW_IDLE = 0
	ROW_MOVE = 1
	ROW_ATTACK = 2
	ROW_DAMAGE = 0  # Use idle for damage (no dedicated row)
	ROW_DEATH = 3
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 5,   # IDLE
		1: 8,   # MOVE
		2: 8,   # ATTACK
		3: 6,   # DEATH
	}

	# Scale sprite for visibility
	if sprite:
		sprite.scale = Vector2(2.0, 2.0)

func _on_attack_complete() -> void:
	# Poison tongue lick attack
	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		if distance <= attack_range:
			if player.has_method("take_damage"):
				player.take_damage(attack_damage)

			# Apply poison with a chance
			if randf() < poison_chance:
				apply_poison_to_player()

	can_attack = false

func apply_poison_to_player() -> void:
	if player and is_instance_valid(player):
		# Check if player has poison handling
		if player.has_method("apply_poison"):
			var total_poison_damage = poison_damage * (poison_duration / 0.5)  # Damage per tick * ticks
			player.apply_poison(total_poison_damage, poison_duration)
		elif player.has_method("apply_status_effect"):
			player.apply_status_effect("poison", poison_duration, poison_damage)
		else:
			# Fallback: just do extra damage over time by scheduling
			_apply_fallback_poison()

func _apply_fallback_poison() -> void:
	# Simple fallback poison implementation
	var ticks = int(poison_duration / 0.5)
	for i in range(ticks):
		var timer = get_tree().create_timer(0.5 * (i + 1))
		timer.timeout.connect(func():
			if player and is_instance_valid(player) and player.has_method("take_damage"):
				player.take_damage(poison_damage)
		)
