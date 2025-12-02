extends EnemyBase

# Ratfolk Mage - Early game caster with big, slow-moving spells
# Appears earlier than other casters to introduce ranged threats

@export var spell_scene: PackedScene
@export var preferred_range: float = 180.0
@export var spell_speed: float = 80.0  # Slow moving spells

func _on_ready() -> void:
	enemy_type = "ratfolk_mage"

	# Ratfolk Mage stats - early game caster, squishy but threatening
	speed = 48.0            # Slow (cautious caster)
	max_health = 15.0       # Fragile
	attack_damage = 8.0     # Decent spell damage
	attack_cooldown = 2.5   # Slow cast rate (big spells take time)
	attack_range = 200.0    # Medium-long range
	windup_duration = 0.5   # Visible casting animation
	animation_speed = 8.0

	# Ratfolk Mage sprite sheet: 8 columns x 6 rows (32x32 frames)
	# Row 0: Idle (8 frames)
	# Row 1: Movement (8 frames)
	# Row 2: Cast 1 (6 frames)
	# Row 3: Cast 2 (6 frames)
	# Row 4: Damaged (4 frames)
	# Row 5: Death (5 frames)
	ROW_IDLE = 0
	ROW_MOVE = 1
	ROW_ATTACK = 2  # Primary cast
	ROW_DAMAGE = 4
	ROW_DEATH = 5
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 8,   # IDLE
		1: 8,   # MOVE
		2: 6,   # CAST 1
		3: 6,   # CAST 2
		4: 4,   # DAMAGED
		5: 5,   # DEATH
	}

	# Scale sprite for visibility
	if sprite:
		sprite.scale = Vector2(2.0, 2.0)

func _process_behavior(delta: float) -> void:
	if player and is_instance_valid(player):
		var direction = player.global_position - global_position
		var distance = direction.length()
		var dir_normalized = direction.normalized()

		# Maintain safe distance
		if distance < preferred_range * 0.5:
			# Too close - retreat!
			velocity = -dir_normalized * speed * 1.2  # Run away faster
			move_and_slide()
			update_animation(delta, ROW_MOVE, -dir_normalized)
		elif distance > attack_range:
			# Too far - move closer
			velocity = dir_normalized * speed
			move_and_slide()
			update_animation(delta, ROW_MOVE, dir_normalized)
		else:
			# In range - stop and cast
			velocity = Vector2.ZERO
			update_animation(delta, ROW_ATTACK, dir_normalized)
			if can_attack:
				start_attack()
	else:
		velocity = Vector2.ZERO
		update_animation(delta, ROW_IDLE, Vector2.ZERO)

func _on_attack_complete() -> void:
	fire_spell()
	can_attack = false

func fire_spell() -> void:
	if not player or not is_instance_valid(player):
		return

	var direction = (player.global_position - global_position).normalized()

	# Play spell sound
	if SoundManager and SoundManager.has_method("play_enemy_spell"):
		SoundManager.play_enemy_spell()

	if spell_scene:
		var spell = spell_scene.instantiate()
		spell.global_position = global_position + direction * 15
		spell.direction = direction
		spell.speed = spell_speed  # Big slow projectile
		spell.damage = attack_damage
		# Make the spell visually bigger
		if "scale" in spell:
			spell.scale = Vector2(1.8, 1.8)
		get_parent().add_child(spell)
