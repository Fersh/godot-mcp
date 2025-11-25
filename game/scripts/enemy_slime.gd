extends EnemyBase

# Slime - Slow, tanky, high damage melee
# Big hitbox, lots of health, hits hard but slow

func _on_ready() -> void:
	enemy_type = "slime"

	# Slime stats - slow tank
	speed = 55.0           # Much slower than orc (90)
	max_health = 50.0      # 2.5x orc health
	attack_damage = 12.0   # 2.4x orc damage
	attack_cooldown = 1.2  # Slower attack than orc (0.8)
	attack_range = 60.0    # Bigger attack range (bigger body)
	windup_duration = 0.5  # Long telegraphed attack
	animation_speed = 6.0  # Slower animations

	# Slime uses simple animation - placeholder until proper sprite
	# Using 4x4 grid for now (will be single color rect if no sprite)
	ROW_IDLE = 0
	ROW_MOVE = 1
	ROW_ATTACK = 2
	ROW_DAMAGE = 2
	ROW_DEATH = 3
	COLS_PER_ROW = 4

	FRAME_COUNTS = {
		0: 4,  # IDLE - gentle bobbing
		1: 4,  # MOVE - squishing motion
		2: 4,  # ATTACK
		3: 4,  # DEATH - splat
	}

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

# Override animation for slime - use scale-based squish animation since we don't have a sprite
func update_animation(delta: float, new_row: int, direction: Vector2) -> void:
	if current_row != new_row:
		current_row = new_row
		animation_frame = 0.0

	# Slime faces direction but doesn't flip (blob)
	animation_frame += animation_speed * delta

	# Simple squish animation using scale
	var squish_amount = sin(animation_frame * 2.0) * 0.1

	if sprite:
		if current_row == ROW_MOVE:
			# Squish while moving
			sprite.scale = Vector2(1.8 + squish_amount, 1.8 - squish_amount)
		elif current_row == ROW_ATTACK:
			# Expand before attack
			var attack_progress = animation_frame / 4.0
			sprite.scale = Vector2(1.8 + attack_progress * 0.3, 1.8 + attack_progress * 0.3)
		else:
			# Gentle idle bob
			sprite.scale = Vector2(1.8 + squish_amount * 0.5, 1.8 - squish_amount * 0.5)

	var max_frames = FRAME_COUNTS.get(current_row, 4)
	if animation_frame >= max_frames:
		animation_frame = 0.0

# Override death animation for splat effect
func update_death_animation(delta: float) -> void:
	animation_frame += animation_speed * delta

	# Flatten and expand on death
	var death_progress = animation_frame / 4.0
	if sprite:
		sprite.scale = Vector2(1.8 + death_progress * 1.0, 1.8 - death_progress * 1.5)
		sprite.modulate.a = 1.0 - (death_progress * 0.8)

	if animation_frame >= 4.0:
		spawn_gold_coin()
		queue_free()
