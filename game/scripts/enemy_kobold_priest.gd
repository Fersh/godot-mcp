extends EnemyBase

# Kobold Priest - Ranged spell caster that heals nearby enemies
# High damage spells, but most dangerous for its healing ability

@export var spell_effect_scene: PackedScene
@export var heal_effect_scene: PackedScene

# Ranged behavior
var preferred_range: float = 180.0  # Distance to maintain from player
var spell_projectile_speed: float = 200.0

# Healing ability
var heal_cooldown: float = 4.0  # Time between heals
var heal_timer: float = 0.0
var heal_range: float = 200.0   # Range to find hurt allies
var heal_percent: float = 0.80  # Heal up to 80% of max HP for normal enemies
var elite_heal_percent: float = 0.10  # Only 10% per cast for elites/bosses
var min_heal_threshold: float = 0.95  # Only heal enemies below 95% HP

func _on_ready() -> void:
	enemy_type = "kobold_priest"

	# Kobold Priest stats - squishy caster
	speed = 63.0           # Slow caster (reduced 10%)
	max_health = 25.0      # Squishy (slightly more than orc)
	attack_damage = 12.0   # High spell damage
	attack_cooldown = 2.0  # Slow attack rate
	attack_range = 220.0   # Long range for spells
	windup_duration = 0.4  # Casting time
	animation_speed = 10.0

	# Kobold Priest sprite sheet: 8 columns x 5 rows
	# Row 0: Idle (4 frames)
	# Row 1: Move (8 frames)
	# Row 2: Attack (8 frames)
	# Row 3: Hurt (4 frames)
	# Row 4: Death (7 frames)
	ROW_IDLE = 0
	ROW_MOVE = 1
	ROW_ATTACK = 2
	ROW_DAMAGE = 3
	ROW_DEATH = 4
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 4,   # IDLE
		1: 8,   # MOVE
		2: 8,   # ATTACK
		3: 4,   # HURT/DAMAGE
		4: 7,   # DEATH
	}

	current_health = max_health
	base_speed = speed
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Scale sprite appropriately
	if sprite:
		sprite.scale = Vector2(2.0, 2.0)

func _process_behavior(delta: float) -> void:
	# Update heal timer
	heal_timer += delta

	# Try to heal nearby hurt allies periodically
	if heal_timer >= heal_cooldown:
		try_heal_allies()

	# Ranged behavior - maintain distance from player
	if player and is_instance_valid(player):
		var direction = player.global_position - global_position
		var distance = direction.length()
		var dir_normalized = direction.normalized()

		# If too close, back away
		if distance < preferred_range * 0.6:
			velocity = -dir_normalized * speed
			move_and_slide()
			update_animation(delta, ROW_MOVE, -dir_normalized)
		# If too far, move closer
		elif distance > attack_range:
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

func _on_attack_complete() -> void:
	# Fire spell projectile instead of melee
	fire_spell()
	can_attack = false

func fire_spell() -> void:
	if not player or not is_instance_valid(player):
		return

	var direction = (player.global_position - global_position).normalized()

	# Play spell sound
	if SoundManager and SoundManager.has_method("play_enemy_spell"):
		SoundManager.play_enemy_spell()

	# Spawn spell projectile
	if spell_effect_scene:
		var spell = spell_effect_scene.instantiate()
		spell.global_position = global_position + direction * 20
		spell.direction = direction
		spell.speed = spell_projectile_speed
		spell.damage = attack_damage
		get_parent().add_child(spell)
	else:
		# Fallback: direct damage if no projectile scene
		if player.has_method("take_damage"):
			var dist_to_player = global_position.distance_to(player.global_position)
			if dist_to_player <= attack_range:
				player.take_damage(attack_damage)

func try_heal_allies() -> void:
	# Find nearby hurt enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	var healed_someone = false

	for enemy in enemies:
		if enemy == self:
			continue
		if not is_instance_valid(enemy):
			continue
		if enemy.is_dying:
			continue

		# Check if in range
		var distance = global_position.distance_to(enemy.global_position)
		if distance > heal_range:
			continue

		# Check if hurt (below threshold)
		var health_percent = enemy.current_health / enemy.max_health
		if health_percent >= min_heal_threshold:
			continue

		# Determine heal amount based on enemy type
		var target_heal_percent = heal_percent
		if enemy.enemy_rarity == "elite" or enemy.enemy_rarity == "boss":
			target_heal_percent = elite_heal_percent

		# Calculate heal amount (heal UP TO target percent, not BY that percent)
		var target_health = enemy.max_health * target_heal_percent
		var heal_amount = 0.0

		if enemy.enemy_rarity == "elite" or enemy.enemy_rarity == "boss":
			# For elites/bosses: heal BY 10% of max HP per cast
			heal_amount = enemy.max_health * elite_heal_percent
		else:
			# For normal enemies: heal UP TO 80% of max HP
			if enemy.current_health < target_health:
				heal_amount = target_health - enemy.current_health

		if heal_amount <= 0:
			continue

		# Apply heal
		enemy.current_health = min(enemy.current_health + heal_amount, enemy.max_health)
		if enemy.health_bar:
			enemy.health_bar.set_health(enemy.current_health, enemy.max_health)

		# Spawn heal visual effect
		spawn_heal_effect(enemy)
		healed_someone = true

	# Reset timer only if we healed someone (otherwise keep trying)
	if healed_someone:
		heal_timer = 0.0
		# Play heal sound
		if SoundManager and SoundManager.has_method("play_heal"):
			SoundManager.play_heal()

func spawn_heal_effect(target: Node2D) -> void:
	# Spawn visual effect on healed enemy
	if heal_effect_scene:
		var effect = heal_effect_scene.instantiate()
		effect.global_position = target.global_position
		get_parent().add_child(effect)
	else:
		# Fallback: spawn a green damage number showing heal
		if damage_number_scene:
			var heal_num = damage_number_scene.instantiate()
			heal_num.global_position = target.global_position + Vector2(0, -30)
			get_parent().add_child(heal_num)
			if heal_num.has_method("set_heal"):
				var healed = target.max_health * (heal_percent if target.enemy_rarity == "normal" else elite_heal_percent)
				heal_num.set_heal(healed)
