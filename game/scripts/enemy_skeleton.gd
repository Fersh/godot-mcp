extends EnemyBase

# Skeleton Warrior - Fast, hard-hitting, tanky melee enemy
# Spawns after slimes, provides a formidable mid-game threat

func _on_ready() -> void:
	enemy_type = "skeleton"

	# Skeleton stats - fast, hits hard, tanky
	speed = 110.0          # Decently fast (faster than orc 90, slower than ratfolk 120)
	max_health = 80.0      # Tanky (4x orc, less than slime 100)
	attack_damage = 15.0   # Hits hard (3x orc damage)
	attack_cooldown = 0.9  # Slightly slower than orc
	attack_range = 55.0    # Standard melee range
	windup_duration = 0.35 # Medium telegraph
	animation_speed = 10.0 # Standard animation speed

	# Skeleton sprite sheet: 10 columns x 10 rows (using first 5 rows)
	# Row 0: Idle (10 frames)
	# Row 1: Walk (5 frames)
	# Row 2: Attack (10 frames)
	# Row 3: Damaged (5 frames)
	# Row 4: Death (10 frames)
	# Rows 5+ are flipped versions (ignored)
	ROW_IDLE = 0
	ROW_MOVE = 1
	ROW_ATTACK = 2
	ROW_DAMAGE = 3
	ROW_DEATH = 4
	COLS_PER_ROW = 10

	FRAME_COUNTS = {
		0: 10,  # IDLE
		1: 5,   # MOVE/WALK
		2: 10,  # ATTACK
		3: 5,   # DAMAGE
		4: 10,  # DEATH
	}

	current_health = max_health
	base_speed = speed
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Scale sprite appropriately
	if sprite:
		sprite.scale = Vector2(2.0, 2.0)
