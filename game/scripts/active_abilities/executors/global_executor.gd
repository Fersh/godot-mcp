extends BaseExecutor
class_name GlobalExecutor

# Handles execution of all global (class-agnostic) abilities
# Supports tiered variants (base, branch, signature)

func execute(ability: ActiveAbilityData, player: Node2D) -> bool:
	"""Execute a global ability. Returns true if handled."""
	match ability.id:
		# ============================================
		# FIREBALL TREE
		# ============================================
		"fireball":
			_execute_fireball(ability, player)
			return true
		"fireball_meteor":
			_execute_meteor_strike(ability, player)
			return true
		"fireball_shower":
			_execute_meteor_shower(ability, player)
			return true
		"fireball_phoenix":
			_execute_phoenix_flame(ability, player)
			return true
		"fireball_dive":
			_execute_phoenix_dive(ability, player)
			return true

		# ============================================
		# FROST NOVA TREE (placeholder for future)
		# ============================================
		"frost_nova":
			_execute_frost_nova(ability, player)
			return true
		"frost_nova_blizzard":
			_execute_blizzard(ability, player)
			return true
		"frost_nova_absolute":
			_execute_absolute_zero(ability, player)
			return true
		"frost_nova_prison":
			_execute_ice_prison(ability, player)
			return true
		"frost_nova_shatter":
			_execute_shatter(ability, player)
			return true

		# ============================================
		# CHAIN LIGHTNING TREE (placeholder for future)
		# ============================================
		"chain_lightning":
			_execute_chain_lightning(ability, player)
			return true
		"chain_lightning_storm":
			_execute_thunderstorm(ability, player)
			return true
		"chain_lightning_overload":
			_execute_overload(ability, player)
			return true
		"chain_lightning_static":
			_execute_static_field(ability, player)
			return true
		"chain_lightning_surge":
			_execute_power_surge(ability, player)
			return true

		# ============================================
		# HEAL TREE (placeholder for future)
		# ============================================
		"heal":
			_execute_heal(ability, player)
			return true
		"heal_regen":
			_execute_regen_aura(ability, player)
			return true
		"heal_sanctuary":
			_execute_sanctuary(ability, player)
			return true
		"heal_emergency":
			_execute_emergency_heal(ability, player)
			return true
		"heal_martyr":
			_execute_martyrdom(ability, player)
			return true

		# ============================================
		# LEGACY GLOBAL (for backwards compatibility)
		# ============================================

	return false

# ============================================
# FIREBALL TREE IMPLEMENTATIONS
# ============================================

func _execute_fireball(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base Fireball - projectile that explodes on impact with AoE burn damage"""
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, 500.0)
	if target:
		direction = (target.global_position - player.global_position).normalized()

	# Use main executor's projectile spawner for proper fireball projectile
	if _main_executor and _main_executor.has_method("_spawn_projectile"):
		_main_executor._spawn_projectile("fireball", player.global_position, direction, ability)

	_play_sound("fireball")
	_screen_shake("small")

func _execute_meteor_strike(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Call down a meteor at target location after delay"""
	var damage = _get_damage(ability)
	var target_pos = player.global_position

	# Find cluster of enemies
	var target = _get_nearest_enemy(player.global_position, 600.0)
	if target:
		target_pos = target.global_position

	# Spawn warning indicator
	_spawn_effect("fireball", target_pos)
	_play_sound("meteor_incoming")

	# Delayed impact (handled by effect)
	# The meteor effect should handle the actual damage after cast_time
	var meteor = _spawn_effect("fireball", target_pos)
	if meteor and meteor.has_method("setup"):
		meteor.setup(damage, ability.radius, ability.stun_duration)

func _execute_meteor_shower(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Rain 5 meteors over 3 seconds"""
	var damage = _get_damage(ability)
	var center = player.global_position

	# SIGNATURE: Spawn multiple meteors in area (uses fireball effect)
	var shower = _spawn_effect("fireball", center)
	if shower and shower.has_method("setup"):
		shower.setup(damage, ability.radius, 5, ability.duration)

	_play_sound("meteor_shower")
	_screen_shake("large")
	_impact_pause(0.2)

func _execute_phoenix_flame(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Fire that heals you for damage dealt"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, 500.0)
	if target:
		direction = (target.global_position - player.global_position).normalized()

	# Use main executor's projectile spawner for proper fireball projectile
	if _main_executor and _main_executor.has_method("_spawn_projectile"):
		_main_executor._spawn_projectile("fireball", player.global_position, direction, ability)

	# Apply healing effect to player when projectile hits (handled by projectile callback)
	# For now, do immediate AoE damage with heal as fallback
	var enemies = _get_enemies_in_radius(player.global_position + direction * 150.0, ability.radius)
	var total_damage_dealt = 0.0
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_burn(enemy, 3.0)
		total_damage_dealt += damage

	# Heal 15% of damage dealt
	if total_damage_dealt > 0 and player.has_method("heal"):
		player.heal(total_damage_dealt * 0.15)

	_play_sound("fireball")
	_screen_shake("small")

func _execute_phoenix_dive(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Invulnerable dash, heal 10% max HP per enemy hit"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var distance = ability.range_value

	# SIGNATURE: Invulnerability during dash
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(ability.invulnerability_duration)

	# Dash through enemies
	_dash_player(player, direction, distance, 0.3)

	# Get enemies in dash path
	var start_pos = player.global_position
	var end_pos = start_pos + direction * distance
	var enemies_hit = 0

	var all_enemies = player.get_tree().get_nodes_in_group("enemies")
	for enemy in all_enemies:
		if is_instance_valid(enemy):
			# Check if enemy is near the dash line
			var to_enemy = enemy.global_position - start_pos
			var proj_length = to_enemy.dot(direction)
			if proj_length > 0 and proj_length < distance:
				var closest_point = start_pos + direction * proj_length
				if enemy.global_position.distance_to(closest_point) < ability.radius:
					_deal_damage_to_enemy(enemy, damage)
					_apply_burn(enemy, 3.0)
					enemies_hit += 1

	# SIGNATURE: Heal per enemy hit
	if enemies_hit > 0 and player.has_method("heal"):
		var max_hp = player.max_hp if "max_hp" in player else 100.0
		var heal_amount = max_hp * 0.10 * enemies_hit
		player.heal(heal_amount)

	_spawn_effect("fireball", start_pos)
	_spawn_effect("fireball", end_pos)
	_play_sound("fireball")
	_screen_shake("medium")

# ============================================
# FROST NOVA TREE IMPLEMENTATIONS
# ============================================

func _execute_frost_nova(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)
	var radius = ability.radius

	# Damage and slow all enemies in radius
	var enemies = _get_enemies_in_radius(player.global_position, radius)
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_slow(enemy, ability.slow_percent, ability.slow_duration)

	_spawn_effect("frost_nova", player.global_position)
	_play_sound("frost_nova")
	_screen_shake("small")

func _execute_blizzard(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Persistent AoE that damages and slows over time"""
	var damage = _get_damage(ability)

	var blizzard = _spawn_effect("frost_nova", player.global_position)
	if blizzard and blizzard.has_method("setup"):
		blizzard.setup(damage, ability.radius, ability.duration, ability.slow_percent)

	_play_sound("blizzard")

func _execute_absolute_zero(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Massive freeze, shattered enemies explode"""
	var damage = _get_damage(ability)
	var radius = ability.radius

	# SIGNATURE: All enemies frozen solid, then shatter for bonus damage
	var enemies = _get_enemies_in_radius(player.global_position, radius)
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_stun(enemy, ability.stun_duration)
		# Mark for shatter (if enemy dies while frozen, explode)
		if enemy.has_method("mark_for_shatter"):
			enemy.mark_for_shatter(damage * 0.5, ability.radius * 0.5)

	_spawn_effect("frost_nova", player.global_position)
	_play_sound("absolute_zero")
	_screen_shake("large")
	_impact_pause(0.2)

func _execute_ice_prison(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Trap enemies in ice, damage when broken"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_value)

	if target:
		var prison = _spawn_effect("frost_nova", target.global_position)
		if prison and prison.has_method("setup"):
			prison.setup(damage, ability.stun_duration)
		_apply_stun(target, ability.stun_duration)

	_play_sound("ice_prison")

func _execute_shatter(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Imprisoned enemies explode, chaining to others"""
	var damage = _get_damage(ability)
	var targets = _get_enemies_in_radius(player.global_position, ability.range_value)

	# SIGNATURE: Each frozen enemy shatters and damages nearby
	for target in targets:
		_apply_stun(target, ability.stun_duration)
		var prison = _spawn_effect("frost_nova", target.global_position)
		if prison and prison.has_method("setup"):
			prison.setup(damage, ability.stun_duration, ability.radius)

	_play_sound("shatter")
	_screen_shake("medium")

# ============================================
# CHAIN LIGHTNING TREE IMPLEMENTATIONS
# ============================================

func _execute_chain_lightning(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_value)

	if not target:
		_play_sound("lightning_fizzle")
		return

	var chain_count = 3
	var current_target = target
	var hit_enemies: Array = []

	for i in range(chain_count):
		if not is_instance_valid(current_target):
			break

		_deal_damage_to_enemy(current_target, damage)
		hit_enemies.append(current_target)
		_spawn_effect("chain_lightning", current_target.global_position)

		# Find next target
		var next_target = _get_nearest_enemy_excluding(current_target.global_position, 200.0, hit_enemies)
		if not next_target:
			break
		current_target = next_target
		damage *= 0.8  # Damage falls off per chain

	_play_sound("chain_lightning")

func _execute_thunderstorm(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Persistent storm that strikes random enemies"""
	var damage = _get_damage(ability)

	var storm = _spawn_effect("chain_lightning", player.global_position)
	if storm and storm.has_method("setup"):
		storm.setup(damage, ability.radius, ability.duration)

	_play_sound("thunderstorm")
	_screen_shake("small")

func _execute_overload(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Massive lightning strike, stunned enemies chain further"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_value)

	if not target:
		return

	# SIGNATURE: Initial massive strike
	_deal_damage_to_enemy(target, damage)
	_apply_stun(target, ability.stun_duration)
	_spawn_effect("chain_lightning", target.global_position)

	# Chain from stunned target to all nearby
	var nearby = _get_enemies_in_radius(target.global_position, ability.radius)
	for enemy in nearby:
		if enemy != target:
			_deal_damage_to_enemy(enemy, damage * 0.5)
			_apply_stun(enemy, ability.stun_duration * 0.5)
			_spawn_effect("chain_lightning", enemy.global_position)

	_play_sound("overload")
	_screen_shake("large")
	_impact_pause(0.15)

func _execute_static_field(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Aura that shocks nearby enemies"""
	var damage = _get_damage(ability)

	var field = _spawn_effect("chain_lightning", player.global_position)
	if field and field.has_method("setup"):
		field.setup(damage, ability.radius, ability.duration)
		# Attach to player
		if field.has_method("attach_to"):
			field.attach_to(player)

	_play_sound("static_field")

func _execute_power_surge(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Buff that electrifies all attacks"""
	var damage = _get_damage(ability)

	# SIGNATURE: Player gains lightning damage on all attacks
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("power_surge", ability.duration, {
			"bonus_lightning_damage": damage,
			"chain_on_hit": true,
			"chain_range": ability.radius
		})

	_spawn_effect("chain_lightning", player.global_position)
	_play_sound("power_surge")
	_screen_shake("medium")

# ============================================
# HEAL TREE IMPLEMENTATIONS
# ============================================

func _execute_heal(ability: ActiveAbilityData, player: Node2D) -> void:
	var heal_amount = ability.base_damage * ability.damage_multiplier  # Repurpose damage as heal

	if player.has_method("heal"):
		player.heal(heal_amount)

	_spawn_effect("healing_light", player.global_position)
	_play_sound("heal")

func _execute_regen_aura(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Create healing zone"""
	var heal_per_tick = ability.base_damage * 0.2

	var aura = _spawn_effect("healing_light", player.global_position)
	if aura and aura.has_method("setup"):
		aura.setup(heal_per_tick, ability.radius, ability.duration)

	_play_sound("regen_aura")

func _execute_sanctuary(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Massive heal zone + damage reduction"""
	var heal_per_tick = ability.base_damage * 0.3

	# SIGNATURE: Zone also grants damage reduction
	var sanctuary = _spawn_effect("healing_light", player.global_position)
	if sanctuary and sanctuary.has_method("setup"):
		sanctuary.setup(heal_per_tick, ability.radius, ability.duration, 0.3)  # 30% DR

	_play_sound("sanctuary")
	_screen_shake("small")

func _execute_emergency_heal(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Big heal when below 30% HP, otherwise smaller heal"""
	var heal_amount = ability.base_damage * ability.damage_multiplier

	var current_hp = player.current_hp if "current_hp" in player else 0
	var max_hp = player.max_hp if "max_hp" in player else 100
	var hp_percent = current_hp / max_hp

	if hp_percent < 0.3:
		heal_amount *= 2.5  # Bonus heal at low HP

	if player.has_method("heal"):
		player.heal(heal_amount)

	_spawn_effect("healing_light", player.global_position)
	_play_sound("emergency_heal")

func _execute_martyrdom(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Full heal, but take increased damage for duration"""
	# SIGNATURE: Full heal with drawback
	var max_hp = player.max_hp if "max_hp" in player else 100

	if player.has_method("heal"):
		player.heal(max_hp)

	# Apply vulnerability debuff
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("martyrdom_vulnerability", ability.duration, {
			"damage_taken_multiplier": 1.5
		})

	_spawn_effect("healing_light", player.global_position)
	_play_sound("martyrdom")
	_screen_shake("medium")

# ============================================
# HELPER FUNCTIONS
# ============================================

func _get_nearest_enemy_excluding(from_pos: Vector2, max_range: float, exclude: Array) -> Node2D:
	"""Find nearest enemy not in exclude list"""
	var player = _get_player()
	if not player:
		return null

	var enemies = player.get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist = max_range

	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy in exclude:
			var dist = from_pos.distance_to(enemy.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = enemy

	return nearest
