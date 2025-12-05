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
		# HEAL TREE
		# ============================================
		"healing_light":
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
		# TIME TREE
		# ============================================
		"time_slow":
			_execute_time_slow(ability, player)
			return true
		"time_stop":
			_execute_time_stop(ability, player)
			return true
		"time_prison":
			_execute_time_prison(ability, player)
			return true
		"time_rewind":
			_execute_time_rewind(ability, player)
			return true
		"time_chronoshift":
			_execute_chronoshift(ability, player)
			return true

		# ============================================
		# TELEPORT TREE
		# ============================================
		"teleport":
			_execute_teleport(ability, player)
			return true
		"teleport_blink":
			_execute_blink(ability, player)
			return true
		"teleport_dimension":
			_execute_dimension_shift(ability, player)
			return true
		"teleport_shadow":
			_execute_shadowstep(ability, player)
			return true
		"teleport_swap":
			_execute_shadow_swap(ability, player)
			return true

		# ============================================
		# SUMMON TREE
		# ============================================
		"summon":
			_execute_summon_minion(ability, player)
			return true
		"summon_golem":
			_execute_summon_golem(ability, player)
			return true
		"summon_titan":
			_execute_summon_titan(ability, player)
			return true
		"summon_swarm":
			_execute_summon_swarm(ability, player)
			return true
		"summon_army":
			_execute_army_of_the_dead(ability, player)
			return true

		# ============================================
		# GRAVITY TREE
		# ============================================
		"gravity_well":
			_execute_gravity_well(ability, player)
			return true
		"gravity_crush":
			_execute_crushing_gravity(ability, player)
			return true
		"gravity_singularity":
			_execute_singularity(ability, player)
			return true
		"gravity_repulse":
			_execute_repulse(ability, player)
			return true
		"gravity_supernova":
			_execute_supernova(ability, player)
			return true

		# ============================================
		# AURA TREE
		# ============================================
		"empower":
			_execute_empower(ability, player)
			return true
		"empower_might":
			_execute_empower_might(ability, player)
			return true
		"empower_avatar":
			_execute_empower_avatar(ability, player)
			return true
		"empower_speed":
			_execute_empower_speed(ability, player)
			return true
		"empower_haste":
			_execute_empower_haste(ability, player)
			return true

		# ============================================
		# SHIELD TREE
		# ============================================
		"barrier":
			_execute_barrier(ability, player)
			return true
		"barrier_absorb":
			_execute_barrier_absorb(ability, player)
			return true
		"barrier_retaliation":
			_execute_barrier_retaliation(ability, player)
			return true
		"barrier_bubble":
			_execute_barrier_bubble(ability, player)
			return true
		"barrier_fortress":
			_execute_barrier_fortress(ability, player)
			return true

		# ============================================
		# BOMB TREE
		# ============================================
		"bomb":
			_execute_bomb(ability, player)
			return true
		"bomb_cluster":
			_execute_bomb_cluster(ability, player)
			return true
		"bomb_carpet":
			_execute_bomb_carpet(ability, player)
			return true
		"bomb_sticky":
			_execute_bomb_sticky(ability, player)
			return true
		"bomb_remote":
			_execute_bomb_remote(ability, player)
			return true

		# ============================================
		# DRAIN TREE
		# ============================================
		"drain":
			_execute_drain(ability, player)
			return true
		"drain_siphon":
			_execute_drain_siphon(ability, player)
			return true
		"drain_feast":
			_execute_drain_feast(ability, player)
			return true
		"drain_transfer":
			_execute_drain_transfer(ability, player)
			return true
		"drain_sacrifice":
			_execute_drain_sacrifice(ability, player)
			return true

		# ============================================
		# CURSE TREE
		# ============================================
		"curse":
			_execute_curse(ability, player)
			return true
		"curse_weakness":
			_execute_curse_weakness(ability, player)
			return true
		"curse_doom":
			_execute_curse_doom(ability, player)
			return true
		"curse_spread":
			_execute_curse_spread(ability, player)
			return true
		"curse_plague":
			_execute_curse_plague(ability, player)
			return true

		# ============================================
		# BLINK TREE
		# ============================================
		"blink":
			_execute_blink_ability(ability, player)
			return true
		"blink_phase":
			_execute_blink_phase(ability, player)
			return true
		"blink_phantom":
			_execute_blink_phantom(ability, player)
			return true
		"blink_flash":
			_execute_blink_flash(ability, player)
			return true
		"blink_thunder":
			_execute_blink_thunder(ability, player)
			return true

		# ============================================
		# THORNS TREE
		# ============================================
		"thorns":
			_execute_thorns(ability, player)
			return true
		"thorns_flame":
			_execute_thorns_flame(ability, player)
			return true
		"thorns_inferno":
			_execute_thorns_inferno(ability, player)
			return true
		"thorns_lightning":
			_execute_thorns_lightning(ability, player)
			return true
		"thorns_storm":
			_execute_thorns_storm(ability, player)
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
	var distance = ability.range_distance

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
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		var prison = _spawn_effect("frost_nova", target.global_position)
		if prison and prison.has_method("setup"):
			prison.setup(damage, ability.stun_duration)
		_apply_stun(target, ability.stun_duration)

	_play_sound("ice_prison")

func _execute_shatter(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Imprisoned enemies explode, chaining to others"""
	var damage = _get_damage(ability)
	var targets = _get_enemies_in_radius(player.global_position, ability.range_distance)

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
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

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
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

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
# TIME TREE IMPLEMENTATIONS
# ============================================

func _execute_time_slow(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Slow enemies in radius (not the player)"""
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_apply_slow(enemy, ability.slow_percent, ability.slow_duration)

	# Create time bubble visual
	_spawn_time_bubble(player.global_position, ability.radius, ability.duration, Color(0.3, 0.5, 0.8, 0.3))

	_play_sound("time_slow")
	_screen_shake("small")

func _execute_time_stop(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Freeze all enemies completely"""
	var enemies = _main_executor.get_tree().get_nodes_in_group("enemies") if _main_executor else []

	for enemy in enemies:
		if is_instance_valid(enemy):
			_apply_stun(enemy, ability.stun_duration)

	_spawn_time_bubble(player.global_position, 800.0, ability.stun_duration, Color(0.2, 0.3, 0.9, 0.5))
	_play_sound("time_stop")
	_screen_shake("large")

func _execute_time_prison(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Trap enemies in time, damage when released"""
	var damage = _get_damage(ability)
	var enemies = _main_executor.get_tree().get_nodes_in_group("enemies") if _main_executor else []
	var trapped_enemies: Array = []

	for enemy in enemies:
		if is_instance_valid(enemy):
			_apply_stun(enemy, ability.stun_duration)
			trapped_enemies.append(enemy)

	# SIGNATURE: Damage when time resumes
	if _main_executor:
		_main_executor.get_tree().create_timer(ability.stun_duration).timeout.connect(func():
			for enemy in trapped_enemies:
				if is_instance_valid(enemy):
					_deal_damage_to_enemy(enemy, damage)
			_screen_shake("large")
		)

	_spawn_time_bubble(player.global_position, 800.0, ability.stun_duration, Color(0.5, 0.2, 0.8, 0.6))
	_play_sound("time_stop")
	_screen_shake("medium")

func _execute_time_rewind(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Restore player HP to value from 3 seconds ago"""
	# Store current HP, restore to higher of current or "past" HP
	var current_hp = player.current_hp if "current_hp" in player else 100
	var max_hp = player.max_hp if "max_hp" in player else 100
	var heal_amount = max_hp * 0.3  # Restore 30% HP

	if player.has_method("heal"):
		player.heal(heal_amount)

	_spawn_time_bubble(player.global_position, 100.0, 1.0, Color(0.8, 0.8, 0.2, 0.5))
	_play_sound("time_rewind")

func _execute_chronoshift(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Reset all ability cooldowns"""
	# SIGNATURE: Reset cooldowns
	if player.has_method("reset_all_cooldowns"):
		player.reset_all_cooldowns()

	# Also heal and grant brief invulnerability
	if player.has_method("heal"):
		player.heal(player.max_hp * 0.2 if "max_hp" in player else 20)

	if player.has_method("set_invulnerable"):
		player.set_invulnerable(ability.invulnerability_duration)

	_spawn_time_bubble(player.global_position, 150.0, 1.5, Color(1.0, 0.8, 0.2, 0.7))
	_play_sound("chronoshift")
	_screen_shake("medium")

func _spawn_time_bubble(pos: Vector2, radius: float, duration: float, color: Color) -> void:
	"""Create pixelated time bubble effect"""
	var bubble = Node2D.new()
	bubble.global_position = pos
	bubble.z_index = 5
	bubble.modulate.a = 0.9
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(bubble)

	# Pixelated circle effect
	var circle = Polygon2D.new()
	var points: PackedVector2Array = []
	var segments = 12  # Low poly for pixelated look
	for i in range(segments):
		var angle = TAU * i / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	circle.polygon = points
	circle.color = color
	bubble.add_child(circle)

	# Fade out
	var tween = bubble.create_tween()
	tween.tween_property(bubble, "modulate:a", 0.0, duration)
	tween.tween_callback(bubble.queue_free)

# ============================================
# TELEPORT TREE IMPLEMENTATIONS
# ============================================

func _execute_teleport(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Short range teleport"""
	var direction = _get_attack_direction(player)
	var start_pos = player.global_position
	var target_pos = start_pos + direction * ability.range_distance

	target_pos.x = clamp(target_pos.x, -60, 1596)
	target_pos.y = clamp(target_pos.y, 40, 1382 - 40)

	_spawn_teleport_effect(start_pos, Color(0.5, 0.5, 1.0, 0.7))
	player.global_position = target_pos
	_spawn_teleport_effect(target_pos, Color(0.5, 0.5, 1.0, 0.7))

	_play_sound("teleport")

func _execute_blink(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Instant blink with no telegraph"""
	var direction = _get_attack_direction(player)
	var start_pos = player.global_position
	var target_pos = start_pos + direction * ability.range_distance

	target_pos.x = clamp(target_pos.x, -60, 1596)
	target_pos.y = clamp(target_pos.y, 40, 1382 - 40)

	player.global_position = target_pos
	_spawn_teleport_effect(target_pos, Color(0.3, 0.8, 1.0, 0.8))

	if player.has_method("set_invulnerable"):
		player.set_invulnerable(ability.invulnerability_duration)

	_play_sound("blink")

func _execute_dimension_shift(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Phase through enemies, damaging all in path"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var start_pos = player.global_position
	var target_pos = start_pos + direction * ability.range_distance

	target_pos.x = clamp(target_pos.x, -60, 1596)
	target_pos.y = clamp(target_pos.y, 40, 1382 - 40)

	# SIGNATURE: Damage enemies in path
	var enemies = _main_executor.get_tree().get_nodes_in_group("enemies") if _main_executor else []
	for enemy in enemies:
		if is_instance_valid(enemy):
			var to_enemy = enemy.global_position - start_pos
			var proj_length = to_enemy.dot(direction)
			if proj_length > 0 and proj_length < ability.range_distance:
				var closest_point = start_pos + direction * proj_length
				if enemy.global_position.distance_to(closest_point) < 60.0:
					_deal_damage_to_enemy(enemy, damage)

	_spawn_teleport_effect(start_pos, Color(0.8, 0.2, 1.0, 0.8))
	player.global_position = target_pos
	_spawn_teleport_effect(target_pos, Color(0.8, 0.2, 1.0, 0.8))

	_play_sound("dimension_shift")
	_screen_shake("small")

func _execute_shadowstep(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Teleport to enemy with damage boost"""
	var start_pos = player.global_position
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	var target_pos: Vector2

	if target:
		var dir_to_player = (player.global_position - target.global_position).normalized()
		target_pos = target.global_position + dir_to_player * 50
	else:
		var direction = _get_attack_direction(player)
		target_pos = player.global_position + direction * ability.range_distance

	target_pos.x = clamp(target_pos.x, -60, 1596)
	target_pos.y = clamp(target_pos.y, 40, 1382 - 40)

	_spawn_teleport_effect(start_pos, Color(0.2, 0.2, 0.3, 0.8))
	player.global_position = target_pos
	_spawn_teleport_effect(target_pos, Color(0.2, 0.2, 0.3, 0.8))

	if player.has_method("apply_damage_boost"):
		player.apply_damage_boost(1.5, 3.0)

	_play_sound("shadowstep")
	_screen_shake("small")

func _execute_shadow_swap(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Swap positions with enemy"""
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	if not target:
		_execute_shadowstep(ability, player)
		return

	# SIGNATURE: Swap positions
	var player_pos = player.global_position
	var enemy_pos = target.global_position

	_spawn_teleport_effect(player_pos, Color(0.1, 0.1, 0.2, 0.9))
	_spawn_teleport_effect(enemy_pos, Color(0.1, 0.1, 0.2, 0.9))

	player.global_position = enemy_pos
	if target.has_method("set_position"):
		target.global_position = player_pos

	# Confuse the swapped enemy
	_apply_stun(target, ability.stun_duration)

	_play_sound("shadow_swap")
	_screen_shake("medium")

func _spawn_teleport_effect(pos: Vector2, color: Color) -> void:
	"""Create pixelated teleport effect"""
	var effect = Node2D.new()
	effect.global_position = pos
	effect.z_index = 10
	effect.modulate.a = 0.9
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(effect)

	# Pixelated burst
	for i in range(8):
		var particle = Polygon2D.new()
		var angle = TAU * i / 8
		var offset = Vector2(cos(angle), sin(angle)) * 20
		particle.polygon = PackedVector2Array([
			Vector2(-4, -4), Vector2(4, -4), Vector2(4, 4), Vector2(-4, 4)
		])
		particle.position = offset
		particle.color = color
		effect.add_child(particle)

		# Animate outward
		var tween = particle.create_tween()
		tween.tween_property(particle, "position", offset * 3, 0.3)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.3)

	if _main_executor:
		_main_executor.get_tree().create_timer(0.4).timeout.connect(func():
			if is_instance_valid(effect):
				effect.queue_free()
		)

# ============================================
# SUMMON TREE IMPLEMENTATIONS
# ============================================

func _execute_summon_minion(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Summon a basic minion"""
	var spawn_pos = player.global_position + Vector2(50, 0)
	spawn_pos.x = clamp(spawn_pos.x, -60, 1596)
	spawn_pos.y = clamp(spawn_pos.y, 40, 1382 - 40)

	_spawn_summon_visual(spawn_pos, ability.duration, _get_damage(ability), Color(0.6, 0.4, 0.8, 0.7))
	_play_sound("summon")

func _execute_summon_golem(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Summon a tanky golem"""
	var damage = _get_damage(ability)
	var golem_pos = player.global_position + Vector2(60, 0)
	golem_pos.x = clamp(golem_pos.x, -60, 1596)
	golem_pos.y = clamp(golem_pos.y, 40, 1382 - 40)

	# Create golem visual
	var golem = Node2D.new()
	golem.name = "SummonedGolem"
	golem.global_position = golem_pos
	golem.modulate.a = 0.9
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(golem)

	# Chunky golem shape
	var body = Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-25, -35), Vector2(25, -35), Vector2(30, 35), Vector2(-30, 35)
	])
	body.color = Color(0.5, 0.4, 0.3, 0.8)
	golem.add_child(body)

	# Golem attacks
	var attack_interval = 1.0
	var attacks = int(ability.duration / attack_interval)
	for i in range(attacks):
		if _main_executor:
			_main_executor.get_tree().create_timer(attack_interval * i).timeout.connect(func():
				if not is_instance_valid(golem):
					return
				var target = _get_nearest_enemy(golem.global_position, 150.0)
				if target and is_instance_valid(target):
					_deal_damage_to_enemy(target, damage / attacks)
					_spawn_effect("explosion", target.global_position)
			)

	if _main_executor:
		_main_executor.get_tree().create_timer(ability.duration).timeout.connect(func():
			if is_instance_valid(golem):
				golem.queue_free()
		)

	_spawn_effect("summon_burst", golem_pos)
	_play_sound("summon")
	_screen_shake("small")

func _execute_summon_titan(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Massive titan with AoE attacks"""
	var damage = _get_damage(ability)
	var titan_pos = player.global_position + Vector2(80, 0)
	titan_pos.x = clamp(titan_pos.x, -60, 1596)
	titan_pos.y = clamp(titan_pos.y, 40, 1382 - 40)

	var titan = Node2D.new()
	titan.name = "SummonedTitan"
	titan.global_position = titan_pos
	titan.modulate.a = 0.9
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(titan)

	# SIGNATURE: Huge titan
	var body = Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-40, -50), Vector2(40, -50), Vector2(45, 50), Vector2(-45, 50)
	])
	body.color = Color(0.7, 0.5, 0.2, 0.9)
	titan.add_child(body)

	# Titan AoE slam attacks
	var attack_interval = 1.5
	var attacks = int(ability.duration / attack_interval)
	for i in range(attacks):
		if _main_executor:
			_main_executor.get_tree().create_timer(attack_interval * i).timeout.connect(func():
				if not is_instance_valid(titan):
					return
				var enemies = _get_enemies_in_radius(titan.global_position, ability.radius)
				for enemy in enemies:
					_deal_damage_to_enemy(enemy, damage / attacks)
					_apply_stun(enemy, 0.3)
				_spawn_effect("explosion", titan.global_position)
				_screen_shake("small")
			)

	if _main_executor:
		_main_executor.get_tree().create_timer(ability.duration).timeout.connect(func():
			if is_instance_valid(titan):
				titan.queue_free()
		)

	_play_sound("summon")
	_screen_shake("medium")

func _execute_summon_swarm(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Summon multiple small minions"""
	var damage = _get_damage(ability)
	var count = 4

	for i in range(count):
		var angle = TAU * i / count
		var offset = Vector2(cos(angle), sin(angle)) * 50
		var spawn_pos = player.global_position + offset
		spawn_pos.x = clamp(spawn_pos.x, -60, 1596)
		spawn_pos.y = clamp(spawn_pos.y, 40, 1382 - 40)

		_spawn_swarm_minion(spawn_pos, ability.duration, damage / count, i)

	_play_sound("summon")

func _spawn_swarm_minion(pos: Vector2, duration: float, damage: float, index: int) -> void:
	"""Helper to spawn small swarm minion"""
	var minion = Node2D.new()
	minion.name = "SwarmMinion" + str(index)
	minion.global_position = pos
	minion.modulate.a = 0.9
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(minion)

	var body = Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-8, -12), Vector2(8, -12), Vector2(8, 12), Vector2(-8, 12)
	])
	body.color = Color(0.4, 0.6, 0.3, 0.8)
	minion.add_child(body)

	var attack_interval = 0.6
	var attacks = int(duration / attack_interval)
	for i in range(attacks):
		if _main_executor:
			_main_executor.get_tree().create_timer(attack_interval * i + index * 0.1).timeout.connect(func():
				if not is_instance_valid(minion):
					return
				var target = _get_nearest_enemy(minion.global_position, 200.0)
				if target and is_instance_valid(target):
					minion.global_position = minion.global_position.lerp(target.global_position, 0.3)
					_deal_damage_to_enemy(target, damage / attacks)
			)

	if _main_executor:
		_main_executor.get_tree().create_timer(duration).timeout.connect(func():
			if is_instance_valid(minion):
				minion.queue_free()
		)

func _execute_army_of_the_dead(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Summon skeleton army"""
	var damage = _get_damage(ability)
	var skeleton_count = 5

	for i in range(skeleton_count):
		var angle = TAU * i / skeleton_count
		var offset = Vector2(cos(angle), sin(angle)) * 80
		var spawn_pos = player.global_position + offset
		spawn_pos.x = clamp(spawn_pos.x, -60, 1596)
		spawn_pos.y = clamp(spawn_pos.y, 40, 1382 - 40)

		_spawn_skeleton(spawn_pos, ability.duration, damage / skeleton_count, i)

	_spawn_effect("dark_summon", player.global_position)
	_play_sound("summon")
	_screen_shake("large")

func _spawn_skeleton(pos: Vector2, duration: float, damage: float, index: int) -> void:
	"""Helper to spawn skeleton warrior"""
	var skeleton = Node2D.new()
	skeleton.name = "SkeletonWarrior" + str(index)
	skeleton.global_position = pos
	skeleton.modulate.a = 0.9
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(skeleton)

	var body = Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-10, -18), Vector2(10, -18), Vector2(10, 18), Vector2(-10, 18)
	])
	body.color = Color(0.8, 0.8, 0.7, 0.8)
	skeleton.add_child(body)

	var attack_interval = 0.8
	var attacks = int(duration / attack_interval)
	for i in range(attacks):
		if _main_executor:
			_main_executor.get_tree().create_timer(attack_interval * i + index * 0.1).timeout.connect(func():
				if not is_instance_valid(skeleton):
					return
				var target = _get_nearest_enemy(skeleton.global_position, 200.0)
				if target and is_instance_valid(target):
					skeleton.global_position = skeleton.global_position.lerp(target.global_position, 0.4)
					_deal_damage_to_enemy(target, damage / attacks)
			)

	if _main_executor:
		_main_executor.get_tree().create_timer(duration).timeout.connect(func():
			if is_instance_valid(skeleton):
				skeleton.queue_free()
		)

func _spawn_summon_visual(pos: Vector2, duration: float, damage: float, color: Color) -> void:
	"""Create basic summon visual with attacks"""
	var summon = Node2D.new()
	summon.global_position = pos
	summon.modulate.a = 0.9
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(summon)

	var body = Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-12, -18), Vector2(12, -18), Vector2(12, 18), Vector2(-12, 18)
	])
	body.color = color
	summon.add_child(body)

	var attack_interval = 1.0
	var attacks = int(duration / attack_interval)
	for i in range(attacks):
		if _main_executor:
			_main_executor.get_tree().create_timer(attack_interval * i).timeout.connect(func():
				if not is_instance_valid(summon):
					return
				var target = _get_nearest_enemy(summon.global_position, 180.0)
				if target and is_instance_valid(target):
					_deal_damage_to_enemy(target, damage / attacks)
			)

	if _main_executor:
		_main_executor.get_tree().create_timer(duration).timeout.connect(func():
			if is_instance_valid(summon):
				summon.queue_free()
		)

# ============================================
# GRAVITY TREE IMPLEMENTATIONS
# ============================================

func _execute_gravity_well(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Pull enemies toward a point"""
	var target_pos = _get_enemy_cluster_center(player.global_position, 300.0)
	var pull_force = 150.0

	_spawn_gravity_effect(target_pos, ability.radius, ability.duration, Color(0.3, 0.2, 0.5, 0.5), pull_force)
	_play_sound("gravity")
	_screen_shake("small")

func _execute_crushing_gravity(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Pull + damage over time"""
	var damage = _get_damage(ability)
	var target_pos = _get_enemy_cluster_center(player.global_position, 300.0)

	_spawn_gravity_effect(target_pos, ability.radius, ability.duration, Color(0.4, 0.1, 0.6, 0.6), 200.0, damage)
	_play_sound("gravity")
	_screen_shake("small")

func _execute_singularity(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Black hole - pull then explode"""
	var damage = _get_damage(ability)
	var target_pos = _get_enemy_cluster_center(player.global_position, 300.0)

	# Create black hole visual
	var hole = Node2D.new()
	hole.global_position = target_pos
	hole.z_index = 5
	hole.modulate.a = 0.9
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(hole)

	var core = Polygon2D.new()
	var points: PackedVector2Array = []
	for i in range(8):
		var angle = TAU * i / 8
		points.append(Vector2(cos(angle), sin(angle)) * 30)
	core.polygon = points
	core.color = Color(0.1, 0.0, 0.2, 0.9)
	hole.add_child(core)

	# Pull enemies
	var pull_interval = 0.1
	var pull_ticks = int(ability.duration / pull_interval)
	for i in range(pull_ticks):
		if _main_executor:
			_main_executor.get_tree().create_timer(pull_interval * i).timeout.connect(func():
				if not is_instance_valid(hole):
					return
				var enemies = _get_enemies_in_radius(target_pos, ability.radius)
				for enemy in enemies:
					if is_instance_valid(enemy):
						var to_center = (target_pos - enemy.global_position).normalized()
						if enemy.has_method("apply_knockback"):
							enemy.apply_knockback(to_center * 200.0 * pull_interval)
			)

	# SIGNATURE: Explode at end
	if _main_executor:
		_main_executor.get_tree().create_timer(ability.duration).timeout.connect(func():
			var enemies = _get_enemies_in_radius(target_pos, ability.radius)
			for enemy in enemies:
				_deal_damage_to_enemy(enemy, damage)
			_spawn_effect("explosion", target_pos)
			_screen_shake("large")
			if is_instance_valid(hole):
				hole.queue_free()
		)

	_play_sound("black_hole")
	_screen_shake("medium")

func _execute_repulse(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Push all enemies away"""
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		var away_dir = (enemy.global_position - player.global_position).normalized()
		if enemy.has_method("apply_knockback"):
			enemy.apply_knockback(away_dir * ability.knockback_force)
		_deal_damage_to_enemy(enemy, damage)

	# Expanding ring visual
	_spawn_repulse_wave(player.global_position, ability.radius, Color(0.6, 0.4, 0.8, 0.6))
	_play_sound("repulse")
	_screen_shake("medium")

func _execute_supernova(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Massive explosion pushing everything away"""
	var damage = _get_damage(ability)
	var enemies = _main_executor.get_tree().get_nodes_in_group("enemies") if _main_executor else []

	for enemy in enemies:
		if is_instance_valid(enemy):
			var away_dir = (enemy.global_position - player.global_position).normalized()
			if enemy.has_method("apply_knockback"):
				enemy.apply_knockback(away_dir * ability.knockback_force * 2.0)
			_deal_damage_to_enemy(enemy, damage)
			_apply_stun(enemy, ability.stun_duration)

	# SIGNATURE: Screen-wide explosion
	_spawn_repulse_wave(player.global_position, 800.0, Color(1.0, 0.8, 0.3, 0.7))
	_spawn_effect("explosion", player.global_position)
	_play_sound("supernova")
	_screen_shake("large")

func _spawn_gravity_effect(pos: Vector2, radius: float, duration: float, color: Color, pull_force: float, damage: float = 0.0) -> void:
	"""Create gravity well effect with pull"""
	var well = Node2D.new()
	well.global_position = pos
	well.z_index = 5
	well.modulate.a = 0.9
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(well)

	var circle = Polygon2D.new()
	var points: PackedVector2Array = []
	for i in range(10):
		var angle = TAU * i / 10
		points.append(Vector2(cos(angle), sin(angle)) * radius * 0.5)
	circle.polygon = points
	circle.color = color
	well.add_child(circle)

	# Pull + optional damage
	var tick_interval = 0.1
	var ticks = int(duration / tick_interval)
	var damage_per_tick = damage / ticks if damage > 0 else 0.0

	for i in range(ticks):
		if _main_executor:
			_main_executor.get_tree().create_timer(tick_interval * i).timeout.connect(func():
				if not is_instance_valid(well):
					return
				var enemies = _get_enemies_in_radius(pos, radius)
				for enemy in enemies:
					if is_instance_valid(enemy):
						var to_center = (pos - enemy.global_position).normalized()
						if enemy.has_method("apply_knockback"):
							enemy.apply_knockback(to_center * pull_force * tick_interval)
						if damage_per_tick > 0:
							_deal_damage_to_enemy(enemy, damage_per_tick)
			)

	if _main_executor:
		_main_executor.get_tree().create_timer(duration).timeout.connect(func():
			if is_instance_valid(well):
				well.queue_free()
		)

func _spawn_repulse_wave(pos: Vector2, radius: float, color: Color) -> void:
	"""Create expanding ring for repulse effect"""
	var wave = Node2D.new()
	wave.global_position = pos
	wave.z_index = 10
	wave.modulate.a = 0.9
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(wave)

	var ring = Polygon2D.new()
	var points: PackedVector2Array = []
	for i in range(16):
		var angle = TAU * i / 16
		points.append(Vector2(cos(angle), sin(angle)) * 20)
	ring.polygon = points
	ring.color = color
	wave.add_child(ring)

	var tween = wave.create_tween()
	tween.tween_property(wave, "scale", Vector2(radius / 20, radius / 20), 0.4)
	tween.parallel().tween_property(wave, "modulate:a", 0.0, 0.4)
	tween.tween_callback(wave.queue_free)

func _get_enemy_cluster_center(from_pos: Vector2, max_range: float) -> Vector2:
	"""Find center of enemy cluster"""
	var enemies = _get_enemies_in_radius(from_pos, max_range)
	if enemies.is_empty():
		return from_pos + _get_attack_direction(_get_player()) * 150.0

	var center = Vector2.ZERO
	for enemy in enemies:
		center += enemy.global_position
	return center / enemies.size()

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

# ============================================
# AURA TREE IMPLEMENTATIONS
# ============================================

func _execute_empower(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Buff yourself with increased damage"""
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("empower", ability.duration, {
			"damage_bonus": 0.3
		})

	_spawn_aura_effect(player, ability.duration, Color(0.8, 0.6, 0.2, 0.5))
	_play_sound("empower")

func _execute_empower_might(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Greater damage bonus"""
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("might", ability.duration, {
			"damage_bonus": 0.5,
			"crit_chance_bonus": 0.2
		})

	_spawn_aura_effect(player, ability.duration, Color(1.0, 0.7, 0.2, 0.6))
	_play_sound("empower")

func _execute_empower_avatar(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Become avatar of power"""
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("avatar", ability.duration, {
			"damage_bonus": 1.0,
			"attack_speed_bonus": 0.5,
			"size_increase": 0.5
		})

	_spawn_aura_effect(player, ability.duration, Color(1.0, 0.8, 0.3, 0.8))
	_play_sound("avatar")
	_screen_shake("medium")

func _execute_empower_speed(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Speed and attack speed buff"""
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("speed", ability.duration, {
			"move_speed_bonus": 0.4,
			"attack_speed_bonus": 0.4
		})

	_spawn_aura_effect(player, ability.duration, Color(0.3, 0.8, 1.0, 0.5))
	_play_sound("empower")

func _execute_empower_haste(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Maximum speed and attack speed"""
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("haste", ability.duration, {
			"move_speed_bonus": 0.8,
			"attack_speed_bonus": 1.0,
			"cooldown_reduction": 0.5
		})

	_spawn_aura_effect(player, ability.duration, Color(0.2, 0.9, 1.0, 0.7))
	_play_sound("haste")
	_screen_shake("small")

func _spawn_aura_effect(player: Node2D, duration: float, color: Color) -> void:
	"""Create visual aura around player"""
	var aura = Node2D.new()
	aura.name = "AuraEffect"
	aura.z_index = -1
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(aura)

	var ring = Polygon2D.new()
	var points: PackedVector2Array = []
	for i in range(12):
		var angle = TAU * i / 12
		points.append(Vector2(cos(angle), sin(angle)) * 40)
	ring.polygon = points
	ring.color = color
	aura.add_child(ring)

	# Follow player and animate
	var ticks = int(duration / 0.05)
	for i in range(ticks):
		if _main_executor:
			_main_executor.get_tree().create_timer(0.05 * i).timeout.connect(func():
				if is_instance_valid(aura) and is_instance_valid(player):
					aura.global_position = player.global_position
					aura.rotation += 0.1
			)

	if _main_executor:
		_main_executor.get_tree().create_timer(duration).timeout.connect(func():
			if is_instance_valid(aura):
				aura.queue_free()
		)

# ============================================
# SHIELD TREE IMPLEMENTATIONS
# ============================================

func _execute_barrier(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Create damage absorbing barrier"""
	var shield_amount = ability.base_damage * ability.damage_multiplier

	if player.has_method("add_shield"):
		player.add_shield(shield_amount)

	_spawn_shield_effect(player, ability.duration, Color(0.3, 0.6, 1.0, 0.5))
	_play_sound("shield")

func _execute_barrier_absorb(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Absorbs damage and converts to healing"""
	var shield_amount = ability.base_damage * ability.damage_multiplier

	if player.has_method("add_shield"):
		player.add_shield(shield_amount)

	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("absorb_barrier", ability.duration, {
			"damage_to_heal": 0.3
		})

	_spawn_shield_effect(player, ability.duration, Color(0.3, 0.8, 0.5, 0.6))
	_play_sound("shield")

func _execute_barrier_retaliation(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Reflects damage back to attackers"""
	var shield_amount = ability.base_damage * ability.damage_multiplier
	var damage = _get_damage(ability)

	if player.has_method("add_shield"):
		player.add_shield(shield_amount)

	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("retaliation_barrier", ability.duration, {
			"reflect_damage": damage,
			"reflect_percent": 1.0
		})

	_spawn_shield_effect(player, ability.duration, Color(1.0, 0.3, 0.3, 0.7))
	_play_sound("shield")
	_screen_shake("small")

func _execute_barrier_bubble(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Projectile immunity bubble"""
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("bubble", ability.duration, {
			"projectile_immunity": true
		})

	_spawn_shield_effect(player, ability.duration, Color(0.5, 0.8, 1.0, 0.4))
	_play_sound("shield")

func _execute_barrier_fortress(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Full invulnerability"""
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(ability.invulnerability_duration)

	_spawn_shield_effect(player, ability.invulnerability_duration, Color(1.0, 0.9, 0.3, 0.8))
	_play_sound("fortress")
	_screen_shake("medium")

func _spawn_shield_effect(player: Node2D, duration: float, color: Color) -> void:
	"""Create shield visual around player"""
	var shield = Node2D.new()
	shield.name = "ShieldEffect"
	shield.z_index = 5
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(shield)

	var hexagon = Polygon2D.new()
	var points: PackedVector2Array = []
	for i in range(6):
		var angle = TAU * i / 6
		points.append(Vector2(cos(angle), sin(angle)) * 50)
	hexagon.polygon = points
	hexagon.color = color
	shield.add_child(hexagon)

	# Follow player
	var ticks = int(duration / 0.05)
	for i in range(ticks):
		if _main_executor:
			_main_executor.get_tree().create_timer(0.05 * i).timeout.connect(func():
				if is_instance_valid(shield) and is_instance_valid(player):
					shield.global_position = player.global_position
			)

	if _main_executor:
		_main_executor.get_tree().create_timer(duration).timeout.connect(func():
			if is_instance_valid(shield):
				shield.queue_free()
		)

# ============================================
# BOMB TREE IMPLEMENTATIONS
# ============================================

func _execute_bomb(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Throw bomb that explodes"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target_pos = player.global_position + direction * 200.0

	var target = _get_nearest_enemy(player.global_position, 400.0)
	if target:
		target_pos = target.global_position

	# Delayed explosion
	if _main_executor:
		_main_executor.get_tree().create_timer(1.0).timeout.connect(func():
			var enemies = _get_enemies_in_radius(target_pos, ability.radius)
			for enemy in enemies:
				_deal_damage_to_enemy(enemy, damage)
			_spawn_effect("explosion", target_pos)
			_play_sound("explosion")
			_screen_shake("small")
		)

	_spawn_effect("bomb_throw", player.global_position)
	_play_sound("throw")

func _execute_bomb_cluster(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Splits into smaller bombs"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target_pos = player.global_position + direction * 200.0

	# Main explosion
	if _main_executor:
		_main_executor.get_tree().create_timer(1.0).timeout.connect(func():
			var enemies = _get_enemies_in_radius(target_pos, ability.radius * 0.5)
			for enemy in enemies:
				_deal_damage_to_enemy(enemy, damage * 0.5)
			_spawn_effect("explosion", target_pos)

			# Spawn 4 cluster bombs
			for i in range(4):
				var cluster_offset = Vector2(cos(i * TAU / 4), sin(i * TAU / 4)) * 80
				var cluster_pos = target_pos + cluster_offset
				_main_executor.get_tree().create_timer(0.5).timeout.connect(func():
					var cluster_enemies = _get_enemies_in_radius(cluster_pos, ability.radius * 0.3)
					for enemy in cluster_enemies:
						_deal_damage_to_enemy(enemy, damage * 0.25)
					_spawn_effect("explosion", cluster_pos)
				)
		)

	_play_sound("throw")

func _execute_bomb_carpet(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Line of explosions"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	for i in range(6):
		var bomb_pos = player.global_position + direction * (50.0 + i * 80.0)
		if _main_executor:
			_main_executor.get_tree().create_timer(0.5 + i * 0.3).timeout.connect(func():
				var enemies = _get_enemies_in_radius(bomb_pos, ability.radius)
				for enemy in enemies:
					_deal_damage_to_enemy(enemy, damage)
				_spawn_effect("explosion", bomb_pos)
				_play_sound("explosion")
			)

	_play_sound("throw")
	_screen_shake("medium")

func _execute_bomb_sticky(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Sticks to enemy"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, 400.0)

	if target:
		if _main_executor:
			_main_executor.get_tree().create_timer(2.0).timeout.connect(func():
				if is_instance_valid(target):
					var enemies = _get_enemies_in_radius(target.global_position, ability.radius)
					for enemy in enemies:
						_deal_damage_to_enemy(enemy, damage)
					_spawn_effect("explosion", target.global_position)
					_play_sound("explosion")
					_screen_shake("small")
			)

	_play_sound("throw")

func _execute_bomb_remote(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Place detonatable bombs"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	# Place 3 bombs
	for i in range(3):
		var bomb_pos = player.global_position + direction.rotated((i - 1) * 0.3) * 150.0
		var bomb = Node2D.new()
		bomb.name = "RemoteBomb" + str(i)
		bomb.global_position = bomb_pos
		bomb.add_to_group("remote_bombs")
		if _main_executor:
			_main_executor.get_tree().current_scene.add_child(bomb)

		var visual = Polygon2D.new()
		visual.polygon = PackedVector2Array([
			Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)
		])
		visual.color = Color(0.8, 0.2, 0.2, 0.8)
		bomb.add_child(visual)

		# Auto-detonate after duration
		if _main_executor:
			var bomb_ref = bomb
			_main_executor.get_tree().create_timer(ability.duration).timeout.connect(func():
				if is_instance_valid(bomb_ref):
					var enemies = _get_enemies_in_radius(bomb_ref.global_position, ability.radius)
					for enemy in enemies:
						_deal_damage_to_enemy(enemy, damage)
					_spawn_effect("explosion", bomb_ref.global_position)
					bomb_ref.queue_free()
			)

	_play_sound("deploy")
	_screen_shake("small")

# ============================================
# DRAIN TREE IMPLEMENTATIONS
# ============================================

func _execute_drain(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Drain life from enemy"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		_deal_damage_to_enemy(target, damage)
		if player.has_method("heal"):
			player.heal(damage * 0.5)

	_spawn_effect("drain", player.global_position)
	_play_sound("drain")

func _execute_drain_siphon(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Continuous drain beam"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		var ticks = int(ability.duration / 0.2)
		for i in range(ticks):
			if _main_executor:
				_main_executor.get_tree().create_timer(0.2 * i).timeout.connect(func():
					if is_instance_valid(target):
						_deal_damage_to_enemy(target, damage / ticks)
						if player.has_method("heal"):
							player.heal(damage * 0.3 / ticks)
				)

	_spawn_effect("siphon", player.global_position)
	_play_sound("drain")

func _execute_drain_feast(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Massive drain, full heal on kill"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		_deal_damage_to_enemy(target, damage)

		# Check for kill
		if target.has_method("is_dead") and target.is_dead():
			if player.has_method("heal"):
				var max_hp = player.max_hp if "max_hp" in player else 100.0
				player.heal(max_hp)
		else:
			if player.has_method("heal"):
				player.heal(damage)

	_spawn_effect("feast", player.global_position)
	_play_sound("feast")
	_screen_shake("medium")

func _execute_drain_transfer(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Steal enemy buffs"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		_deal_damage_to_enemy(target, damage)
		if player.has_method("heal"):
			player.heal(damage * 0.3)

		# Steal speed
		_apply_slow(target, 0.5, ability.duration)
		if player.has_method("add_temporary_buff"):
			player.add_temporary_buff("stolen_speed", ability.duration, {
				"move_speed_bonus": 0.3
			})

	_spawn_effect("transfer", player.global_position)
	_play_sound("drain")

func _execute_drain_sacrifice(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Sacrifice HP for massive damage"""
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	# Sacrifice HP
	var current_hp = player.current_hp if "current_hp" in player else 100
	var sacrifice = current_hp * 0.3
	if player.has_method("take_damage"):
		player.take_damage(sacrifice)

	# Massive damage based on sacrifice
	var boosted_damage = damage + sacrifice * 2
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, boosted_damage)

	_spawn_effect("sacrifice", player.global_position)
	_play_sound("sacrifice")
	_screen_shake("large")

# ============================================
# CURSE TREE IMPLEMENTATIONS
# ============================================

func _execute_curse(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Curse enemy to reduce their damage"""
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target and target.has_method("apply_curse"):
		target.apply_curse(ability.duration, 0.3)  # 30% damage reduction

	_spawn_effect("curse", target.global_position if target else player.global_position)
	_play_sound("curse")

func _execute_curse_weakness(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Cursed enemy takes more damage"""
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		if target.has_method("apply_curse"):
			target.apply_curse(ability.duration, 0.3)
		if target.has_method("apply_mark"):
			target.apply_mark(ability.duration, 1.5)  # Take 50% more damage

	_spawn_effect("weakness", target.global_position if target else player.global_position)
	_play_sound("curse")

func _execute_curse_doom(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: After delay, massive damage"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		_spawn_effect("doom_mark", target.global_position)

		# Track damage taken during countdown
		if _main_executor:
			_main_executor.get_tree().create_timer(ability.duration).timeout.connect(func():
				if is_instance_valid(target):
					_deal_damage_to_enemy(target, damage)
					_spawn_effect("explosion", target.global_position)
					_screen_shake("large")
			)

	_play_sound("doom")

func _execute_curse_spread(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Curse spreads to nearby"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		_deal_damage_to_enemy(target, damage)

		# Spread to nearby
		var nearby = _get_enemies_in_radius(target.global_position, ability.radius)
		for enemy in nearby:
			if enemy != target and enemy.has_method("apply_curse"):
				enemy.apply_curse(ability.duration, 0.2)

	_spawn_effect("spreading_curse", player.global_position)
	_play_sound("curse")

func _execute_curse_plague(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Curse jumps on death"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		_deal_damage_to_enemy(target, damage)
		if target.has_method("apply_plague_curse"):
			target.apply_plague_curse(ability.duration, damage * 0.5)

	_spawn_effect("plague", player.global_position)
	_play_sound("plague")
	_screen_shake("small")

# ============================================
# BLINK TREE IMPLEMENTATIONS
# ============================================

func _execute_blink_ability(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Short instant teleport"""
	var direction = _get_attack_direction(player)
	var start_pos = player.global_position
	var target_pos = start_pos + direction * ability.range_distance

	target_pos.x = clamp(target_pos.x, -60, 1596)
	target_pos.y = clamp(target_pos.y, 40, 1382 - 40)

	_spawn_teleport_effect(start_pos, Color(0.3, 0.5, 1.0, 0.7))
	player.global_position = target_pos
	_spawn_teleport_effect(target_pos, Color(0.3, 0.5, 1.0, 0.7))

	_play_sound("blink")

func _execute_blink_phase(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Blink with invulnerability"""
	var direction = _get_attack_direction(player)
	var start_pos = player.global_position
	var target_pos = start_pos + direction * ability.range_distance

	target_pos.x = clamp(target_pos.x, -60, 1596)
	target_pos.y = clamp(target_pos.y, 40, 1382 - 40)

	if player.has_method("set_invulnerable"):
		player.set_invulnerable(ability.duration)

	_spawn_teleport_effect(start_pos, Color(0.5, 0.3, 1.0, 0.8))
	player.global_position = target_pos
	_spawn_teleport_effect(target_pos, Color(0.5, 0.3, 1.0, 0.8))

	_play_sound("blink")

func _execute_blink_phantom(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Invulnerable dash through enemies"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var start_pos = player.global_position
	var target_pos = start_pos + direction * ability.range_distance

	target_pos.x = clamp(target_pos.x, -60, 1596)
	target_pos.y = clamp(target_pos.y, 40, 1382 - 40)

	if player.has_method("set_invulnerable"):
		player.set_invulnerable(ability.duration)

	# Damage enemies in path
	var all_enemies = player.get_tree().get_nodes_in_group("enemies")
	for enemy in all_enemies:
		if is_instance_valid(enemy):
			var to_enemy = enemy.global_position - start_pos
			var proj_length = to_enemy.dot(direction)
			if proj_length > 0 and proj_length < ability.range_distance:
				var closest = start_pos + direction * proj_length
				if enemy.global_position.distance_to(closest) < 60.0:
					_deal_damage_to_enemy(enemy, damage)

	_spawn_teleport_effect(start_pos, Color(0.8, 0.2, 1.0, 0.9))
	player.global_position = target_pos
	_spawn_teleport_effect(target_pos, Color(0.8, 0.2, 1.0, 0.9))

	_play_sound("phantom")
	_screen_shake("small")

func _execute_blink_flash(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Damage at start and end"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var start_pos = player.global_position
	var target_pos = start_pos + direction * ability.range_distance

	target_pos.x = clamp(target_pos.x, -60, 1596)
	target_pos.y = clamp(target_pos.y, 40, 1382 - 40)

	# Damage at start
	var start_enemies = _get_enemies_in_radius(start_pos, ability.radius)
	for enemy in start_enemies:
		_deal_damage_to_enemy(enemy, damage)

	_spawn_teleport_effect(start_pos, Color(1.0, 0.8, 0.2, 0.8))
	player.global_position = target_pos
	_spawn_teleport_effect(target_pos, Color(1.0, 0.8, 0.2, 0.8))

	# Damage at end
	var end_enemies = _get_enemies_in_radius(target_pos, ability.radius)
	for enemy in end_enemies:
		_deal_damage_to_enemy(enemy, damage)

	_play_sound("flash")

func _execute_blink_thunder(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: 3 rapid blinks with lightning"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	for i in range(3):
		if _main_executor:
			_main_executor.get_tree().create_timer(i * 0.2).timeout.connect(func():
				var start_pos = player.global_position
				var offset = direction.rotated((i - 1) * 0.3) * ability.range_distance
				var target_pos = start_pos + offset

				target_pos.x = clamp(target_pos.x, -60, 1596)
				target_pos.y = clamp(target_pos.y, 40, 1382 - 40)

				_spawn_teleport_effect(start_pos, Color(0.3, 0.5, 1.0, 0.9))
				player.global_position = target_pos
				_spawn_teleport_effect(target_pos, Color(0.3, 0.5, 1.0, 0.9))

				# Lightning at each point
				var enemies = _get_enemies_in_radius(target_pos, ability.radius)
				for enemy in enemies:
					_deal_damage_to_enemy(enemy, damage)
					_apply_stun(enemy, ability.stun_duration)
				_spawn_effect("chain_lightning", target_pos)
			)

	_play_sound("thunder")
	_screen_shake("medium")

# ============================================
# THORNS TREE IMPLEMENTATIONS
# ============================================

func _execute_thorns(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Reflect damage aura"""
	var damage = _get_damage(ability)

	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("thorns", ability.duration, {
			"reflect_damage": damage,
			"reflect_radius": ability.radius
		})

	_spawn_thorns_effect(player, ability.duration, Color(0.5, 0.8, 0.3, 0.5))
	_play_sound("thorns")

func _execute_thorns_flame(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Fire thorns burn attackers"""
	var damage = _get_damage(ability)

	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("flame_thorns", ability.duration, {
			"reflect_damage": damage,
			"burn_on_reflect": true,
			"burn_duration": 3.0
		})

	_spawn_thorns_effect(player, ability.duration, Color(1.0, 0.5, 0.2, 0.6))
	_play_sound("thorns")

func _execute_thorns_inferno(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Constant fire damage to nearby"""
	var damage = _get_damage(ability)

	# Constant burn aura
	var ticks = int(ability.duration / 0.5)
	for i in range(ticks):
		if _main_executor:
			_main_executor.get_tree().create_timer(0.5 * i).timeout.connect(func():
				var enemies = _get_enemies_in_radius(player.global_position, ability.radius)
				for enemy in enemies:
					_deal_damage_to_enemy(enemy, damage / ticks)
					_apply_burn(enemy, 1.0)
			)

	_spawn_thorns_effect(player, ability.duration, Color(1.0, 0.3, 0.1, 0.7))
	_play_sound("inferno")
	_screen_shake("small")

func _execute_thorns_lightning(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Lightning thorns chain"""
	var damage = _get_damage(ability)

	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("lightning_thorns", ability.duration, {
			"reflect_damage": damage,
			"chain_lightning": true,
			"chain_count": 3
		})

	_spawn_thorns_effect(player, ability.duration, Color(0.3, 0.5, 1.0, 0.6))
	_play_sound("thorns")

func _execute_thorns_storm(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Constant lightning strikes"""
	var damage = _get_damage(ability)

	# Constant lightning strikes
	var ticks = int(ability.duration / 0.3)
	for i in range(ticks):
		if _main_executor:
			_main_executor.get_tree().create_timer(0.3 * i).timeout.connect(func():
				var enemies = _get_enemies_in_radius(player.global_position, ability.radius)
				if enemies.size() > 0:
					var target = enemies[randi() % enemies.size()]
					_deal_damage_to_enemy(target, damage / ticks)
					_apply_stun(target, ability.stun_duration)
					_spawn_effect("chain_lightning", target.global_position)
			)

	_spawn_thorns_effect(player, ability.duration, Color(0.2, 0.3, 1.0, 0.8))
	_play_sound("storm")
	_screen_shake("medium")

func _spawn_thorns_effect(player: Node2D, duration: float, color: Color) -> void:
	"""Create thorns aura visual"""
	var thorns = Node2D.new()
	thorns.name = "ThornsEffect"
	thorns.z_index = 2
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(thorns)

	# Spiky ring
	var spike_count = 8
	for i in range(spike_count):
		var spike = Polygon2D.new()
		var angle = TAU * i / spike_count
		spike.polygon = PackedVector2Array([
			Vector2(0, -8), Vector2(6, 0), Vector2(0, 8)
		])
		spike.rotation = angle
		spike.position = Vector2(cos(angle), sin(angle)) * 35
		spike.color = color
		thorns.add_child(spike)

	# Follow player
	var ticks = int(duration / 0.05)
	for i in range(ticks):
		if _main_executor:
			_main_executor.get_tree().create_timer(0.05 * i).timeout.connect(func():
				if is_instance_valid(thorns) and is_instance_valid(player):
					thorns.global_position = player.global_position
					thorns.rotation += 0.05
			)

	if _main_executor:
		_main_executor.get_tree().create_timer(duration).timeout.connect(func():
			if is_instance_valid(thorns):
				thorns.queue_free()
		)
