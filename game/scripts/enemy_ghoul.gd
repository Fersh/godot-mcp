extends EnemyBase

# Ghoul - Tough, relentless undead melee attacker
# Stronger than basic enemies, straightforward aggression

func _on_ready() -> void:
	enemy_type = "ghoul"

	# Ghoul stats - tanky aggressive melee
	speed = 55.0            # Moderate speed
	max_health = 45.0       # Tanky
	attack_damage = 10.0    # High damage
	attack_cooldown = 1.0   # Moderate attack speed
	attack_range = 50.0     # Standard melee range
	windup_duration = 0.3   # Noticeable windup
	animation_speed = 9.0

	# Ghoul sprite sheet: 8 columns x 5 rows (32x32 frames)
	# Row 0: Idle (4 frames)
	# Row 1: Movement (8 frames)
	# Row 2: Attack (6 frames)
	# Row 3: Damaged (4 frames)
	# Row 4: Death (6 frames)
	ROW_IDLE = 0
	ROW_MOVE = 1
	ROW_ATTACK = 2
	ROW_DAMAGE = 3
	ROW_DEATH = 4
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 4,   # IDLE
		1: 8,   # MOVE
		2: 6,   # ATTACK
		3: 4,   # DAMAGED
		4: 6,   # DEATH
	}

	# Scale sprite for visibility
	if sprite:
		sprite.scale = Vector2(2.0, 2.0)
