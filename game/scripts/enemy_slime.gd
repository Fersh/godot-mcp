extends EnemyBase

# Slime - Slow, tanky, high damage melee
# Big hitbox, lots of health, hits hard but slow

func _on_ready() -> void:
	enemy_type = "slime"

	# Slime stats - slow tank
	speed = 44.5           # Much slower (reduced 20%)
	max_health = 100.0     # 5x orc health (doubled from 50)
	attack_damage = 12.0   # 2.4x orc damage
	attack_cooldown = 1.2  # Slower attack than orc (0.8)
	attack_range = 60.0    # Bigger attack range (bigger body)
	windup_duration = 0.5  # Long telegraphed attack
	animation_speed = 6.0  # Slower animations

	# Slime sprite sheet: 8 columns x 4 rows
	# Row 0: Idle
	# Row 1: Move
	# Row 2: Attack (and damage)
	# Row 3: Death
	ROW_IDLE = 0
	ROW_MOVE = 0      # Use idle row for move too (slime bounces)
	ROW_ATTACK = 2
	ROW_DAMAGE = 2
	ROW_DEATH = 3
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 4,  # IDLE - gentle bobbing
		1: 4,  # MOVE - same as idle
		2: 4,  # ATTACK
		3: 4,  # DEATH - splat
	}

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Double the size of slimes
	if sprite:
		sprite.scale = Vector2(2.0, 2.0)
