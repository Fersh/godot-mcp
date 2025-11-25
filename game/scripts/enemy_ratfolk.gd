extends EnemyBase

# Ratfolk - Fast, agile melee attacker
# Faster movement, faster attacks, less health than orc

func _on_ready() -> void:
	enemy_type = "ratfolk"

	# Ratfolk stats - fast and aggressive but fragile
	speed = 120.0          # 33% faster than orc (90)
	max_health = 12.0      # 40% less health than orc (20)
	attack_damage = 4.0    # Slightly less damage than orc (5)
	attack_cooldown = 0.5  # 37% faster attack speed than orc (0.8)
	attack_range = 45.0    # Slightly shorter range than orc (50)
	windup_duration = 0.15 # Faster windup than orc (0.25)
	animation_speed = 14.0 # Faster animations

	# Ratfolk spritesheet: 768x160 = 12 cols x 5 rows (64x32 per frame)
	# Row 0: Idle (4 frames)
	# Row 1: Move (8 frames)
	# Row 2: Attack sequence (12 frames)
	# Row 3: Damage/hit (4 frames)
	# Row 4: Death (5 frames)
	ROW_IDLE = 0
	ROW_MOVE = 1
	ROW_ATTACK = 2
	ROW_DAMAGE = 3
	ROW_DEATH = 4
	COLS_PER_ROW = 12

	FRAME_COUNTS = {
		0: 4,   # IDLE
		1: 8,   # MOVE
		2: 12,  # ATTACK
		3: 4,   # DAMAGE
		4: 5,   # DEATH
	}

	# Reset health to new max
	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)
