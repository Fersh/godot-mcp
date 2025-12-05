extends BaseExecutor
class_name RangedExecutor

# Handles execution of all ranged abilities
# Supports tiered variants (base, branch, signature)

func execute(ability: ActiveAbilityData, player: Node2D) -> bool:
	"""Execute a ranged ability. Returns true if handled."""
	match ability.id:
		# ============================================
		# POWER SHOT TREE
		# ============================================
		"power_shot":
			_execute_power_shot(ability, player)
			return true
		"power_shot_pierce":
			_execute_power_shot_pierce(ability, player)
			return true
		"power_shot_railgun":
			_execute_power_shot_railgun(ability, player)
			return true
		"power_shot_explosive":
			_execute_power_shot_explosive(ability, player)
			return true
		"power_shot_nuke":
			_execute_power_shot_nuke(ability, player)
			return true

		# ============================================
		# MULTI SHOT TREE
		# ============================================
		"multi_shot":
			_execute_multi_shot(ability, player)
			return true
		"multi_fan":
			_execute_multi_fan(ability, player)
			return true
		"multi_tornado":
			_execute_multi_tornado(ability, player)
			return true
		"multi_focused":
			_execute_multi_focused(ability, player)
			return true
		"multi_triple":
			_execute_multi_triple(ability, player)
			return true

		# ============================================
		# TRAP TREE
		# ============================================
		"trap":
			_execute_trap(ability, player)
			return true
		"trap_bear":
			_execute_trap_bear(ability, player)
			return true
		"trap_chain":
			_execute_trap_chain(ability, player)
			return true
		"trap_explosive":
			_execute_trap_explosive(ability, player)
			return true
		"trap_cluster":
			_execute_trap_cluster(ability, player)
			return true

		# ============================================
		# RAIN TREE
		# ============================================
		"rain_of_arrows":
			_execute_rain_of_arrows(ability, player)
			return true
		"rain_storm":
			_execute_rain_storm(ability, player)
			return true
		"rain_apocalypse":
			_execute_rain_apocalypse(ability, player)
			return true
		"rain_focused":
			_execute_rain_focused(ability, player)
			return true
		"rain_orbital":
			_execute_rain_orbital(ability, player)
			return true

		# ============================================
		# TURRET TREE
		# ============================================
		"sentry_turret":
			_execute_sentry_turret(ability, player)
			return true
		"turret_rapid":
			_execute_turret_rapid(ability, player)
			return true
		"turret_gatling":
			_execute_turret_gatling(ability, player)
			return true
		"turret_heavy":
			_execute_turret_heavy(ability, player)
			return true
		"turret_artillery":
			_execute_turret_artillery(ability, player)
			return true

		# ============================================
		# VOLLEY TREE
		# ============================================
		"piercing_volley":
			_execute_piercing_volley(ability, player)
			return true
		"volley_ricochet":
			_execute_volley_ricochet(ability, player)
			return true
		"volley_chaos":
			_execute_volley_chaos(ability, player)
			return true
		"volley_sniper":
			_execute_volley_sniper(ability, player)
			return true
		"volley_rail":
			_execute_volley_rail(ability, player)
			return true

		# ============================================
		# EVASION TREE
		# ============================================
		"quick_roll":
			_execute_quick_roll(ability, player)
			return true
		"roll_shadow":
			_execute_roll_shadow(ability, player)
			return true
		"roll_dance":
			_execute_roll_dance(ability, player)
			return true
		"roll_counter":
			_execute_roll_counter(ability, player)
			return true
		"roll_perfect":
			_execute_roll_perfect(ability, player)
			return true

		# ============================================
		# LEGACY RANGED (for backwards compatibility)
		# ============================================
		"explosive_arrow":
			_execute_explosive_arrow(ability, player)
			return true
		"cluster_bomb":
			_execute_cluster_bomb(ability, player)
			return true
		"fan_of_knives":
			_execute_fan_of_knives(ability, player)
			return true
		"arrow_storm":
			_execute_arrow_storm(ability, player)
			return true
		"ballista_strike":
			_execute_ballista_strike(ability, player)
			return true
		"sentry_network":
			_execute_sentry_network(ability, player)
			return true
		"rain_of_vengeance":
			_execute_rain_of_vengeance(ability, player)
			return true
		"explosive_decoy":
			_execute_explosive_decoy(ability, player)
			return true

	return false

# ============================================
# POWER SHOT TREE IMPLEMENTATIONS
# ============================================

func _execute_power_shot(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, 500.0)
	if target:
		direction = (target.global_position - player.global_position).normalized()

	var proj = _spawn_projectile(player, direction, ability.projectile_speed)
	if proj:
		if "damage" in proj:
			proj.damage = damage
		if "is_power_shot" in proj:
			proj.is_power_shot = true

	_spawn_effect("power_shot", player.global_position)
	_play_sound("power_shot")

func _execute_power_shot_pierce(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Pierces through 5 enemies"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, 500.0)
	if target:
		direction = (target.global_position - player.global_position).normalized()

	var proj = _spawn_projectile(player, direction, ability.projectile_speed)
	if proj:
		if "damage" in proj:
			proj.damage = damage
		if "pierce_count" in proj:
			proj.pierce_count = 5
		elif "piercing" in proj:
			proj.piercing = true

	_spawn_effect("piercing_shot", player.global_position)
	_play_sound("power_shot")

func _execute_power_shot_railgun(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Infinite pierce beam across screen"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	# SIGNATURE: Instant hitscan beam that hits everything in line
	var start_pos = player.global_position
	var end_pos = start_pos + direction * 2000.0  # Screen-wide

	# Get all enemies in the line
	var all_enemies = player.get_tree().get_nodes_in_group("enemies")
	for enemy in all_enemies:
		if is_instance_valid(enemy):
			# Check if enemy is close to the line
			var to_enemy = enemy.global_position - start_pos
			var proj_length = to_enemy.dot(direction)
			if proj_length > 0:
				var closest_point = start_pos + direction * proj_length
				if enemy.global_position.distance_to(closest_point) < 50.0:
					_deal_damage_to_enemy(enemy, damage)

	# SIGNATURE: Epic beam visual
	_spawn_effect("railgun", player.global_position)
	_play_sound("railgun")
	_screen_shake("large")
	_impact_pause(0.15)

func _execute_power_shot_explosive(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Explodes on impact"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, 500.0)
	if target:
		direction = (target.global_position - player.global_position).normalized()

	var proj = _spawn_projectile(player, direction, ability.projectile_speed)
	if proj:
		if "damage" in proj:
			proj.damage = damage
		if "explosion_radius" in proj:
			proj.explosion_radius = ability.radius
		if "explodes" in proj:
			proj.explodes = true

	_spawn_effect("explosive_shot", player.global_position)
	_play_sound("power_shot")

func _execute_power_shot_nuke(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Massive explosion with stun and knockback"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, 600.0)
	if target:
		direction = (target.global_position - player.global_position).normalized()

	# Spawn nuke projectile
	var proj = _spawn_projectile(player, direction, ability.projectile_speed)
	if proj:
		if "damage" in proj:
			proj.damage = damage
		if "explosion_radius" in proj:
			proj.explosion_radius = ability.radius
		if "is_nuke" in proj:
			proj.is_nuke = true
		# SIGNATURE: Stun and knockback on explosion
		if "stun_duration" in proj:
			proj.stun_duration = ability.stun_duration
		if "knockback_force" in proj:
			proj.knockback_force = ability.knockback_force

	_spawn_effect("nuke_launch", player.global_position)
	_play_sound("nuke_launch")
	_screen_shake("medium")

# ============================================
# MULTI SHOT TREE IMPLEMENTATIONS
# ============================================

func _execute_multi_shot(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var spread_angle = PI / 6.0  # 30 degrees total spread

	for i in range(ability.projectile_count):
		var offset = (i - 1) * (spread_angle / 2.0)
		var proj_dir = direction.rotated(offset)
		var proj = _spawn_projectile(player, proj_dir, ability.projectile_speed)
		if proj and "damage" in proj:
			proj.damage = damage

	_play_sound("multi_shot")

func _execute_multi_fan(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: 5 projectiles in wider spread"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var spread_angle = PI / 3.0  # 60 degrees spread

	for i in range(ability.projectile_count):
		var t = float(i) / float(ability.projectile_count - 1) - 0.5
		var offset = t * spread_angle
		var proj_dir = direction.rotated(offset)
		var proj = _spawn_projectile(player, proj_dir, ability.projectile_speed)
		if proj and "damage" in proj:
			proj.damage = damage

	_spawn_effect("fan_of_knives", player.global_position)
	_play_sound("multi_shot")

func _execute_multi_tornado(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: 360-degree blade storm, 12 projectiles"""
	var damage = _get_damage(ability)
	var angle_step = TAU / ability.projectile_count

	# SIGNATURE: Fire in all directions
	for i in range(ability.projectile_count):
		var angle = i * angle_step
		var proj_dir = Vector2(cos(angle), sin(angle))
		var proj = _spawn_projectile(player, proj_dir, ability.projectile_speed)
		if proj and "damage" in proj:
			proj.damage = damage

	_spawn_effect("blade_tornado", player.global_position)
	_play_sound("blade_tornado")
	_screen_shake("medium")

func _execute_multi_focused(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: All arrows converge on single target"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, 500.0)
	if not target:
		# Fallback to regular multi-shot
		_execute_multi_shot(ability, player)
		return

	var direction = (target.global_position - player.global_position).normalized()

	# All projectiles aim at the same target
	for i in range(ability.projectile_count):
		var slight_offset = Vector2(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1))
		var proj = _spawn_projectile(player, (direction + slight_offset).normalized(), ability.projectile_speed)
		if proj:
			if "damage" in proj:
				proj.damage = damage
			if "target" in proj:
				proj.target = target

	_spawn_effect("focused_volley", player.global_position)
	_play_sound("multi_shot")

func _execute_multi_triple(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Each arrow spawns 3 more on hit"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, 500.0)
	var direction = (target.global_position - player.global_position).normalized() if target else _get_attack_direction(player)

	for i in range(ability.projectile_count):
		var slight_offset = Vector2(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1))
		var proj = _spawn_projectile(player, (direction + slight_offset).normalized(), ability.projectile_speed)
		if proj:
			if "damage" in proj:
				proj.damage = damage
			# SIGNATURE: Split on hit
			if "splits_on_hit" in proj:
				proj.splits_on_hit = true
				proj.split_count = 3

	_spawn_effect("triple_threat", player.global_position)
	_play_sound("multi_shot")
	_screen_shake("small")

# ============================================
# TRAP TREE IMPLEMENTATIONS
# ============================================

func _execute_trap(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)

	var trap = _spawn_effect("trap", player.global_position)
	if trap and trap.has_method("setup"):
		trap.setup(damage, ability.slow_percent, ability.slow_duration)

	_play_sound("trap_place")

func _execute_trap_bear(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Root + heavy damage"""
	var damage = _get_damage(ability)

	var trap = _spawn_effect("bear_trap", player.global_position)
	if trap and trap.has_method("setup"):
		trap.setup(damage, ability.stun_duration)

	_play_sound("trap_place")

func _execute_trap_chain(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Pulls nearby enemies into trap"""
	var damage = _get_damage(ability)

	var trap = _spawn_effect("chain_trap", player.global_position)
	if trap and trap.has_method("setup"):
		# SIGNATURE: Pull radius
		trap.setup(damage, ability.stun_duration, ability.radius)

	_play_sound("trap_place")
	_screen_shake("small")

func _execute_trap_explosive(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: AoE explosion"""
	var damage = _get_damage(ability)

	var trap = _spawn_effect("explosive_trap", player.global_position)
	if trap and trap.has_method("setup"):
		trap.setup(damage, ability.radius)

	_play_sound("trap_place")

func _execute_trap_cluster(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Spawns 4 more traps on detonation"""
	var damage = _get_damage(ability)

	var trap = _spawn_effect("cluster_mine", player.global_position)
	if trap and trap.has_method("setup"):
		# SIGNATURE: Cluster spawn
		trap.setup(damage, ability.radius, 4)

	_play_sound("trap_place")
	_screen_shake("small")

# ============================================
# LEGACY RANGED IMPLEMENTATIONS (delegate to main)
# ============================================

func _execute_explosive_arrow(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_explosive_arrow"):
		_main_executor._execute_explosive_arrow(ability, player)

func _execute_quick_roll(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_quick_roll"):
		_main_executor._execute_quick_roll(ability, player)

func _execute_rain_of_arrows(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_rain_of_arrows"):
		_main_executor._execute_rain_of_arrows(ability, player)

func _execute_piercing_volley(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_piercing_volley"):
		_main_executor._execute_piercing_volley(ability, player)

func _execute_cluster_bomb(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_cluster_bomb"):
		_main_executor._execute_cluster_bomb(ability, player)

func _execute_fan_of_knives(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_fan_of_knives"):
		_main_executor._execute_fan_of_knives(ability, player)

func _execute_sentry_turret(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_sentry_turret"):
		_main_executor._execute_sentry_turret(ability, player)

func _execute_arrow_storm(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_arrow_storm"):
		_main_executor._execute_arrow_storm(ability, player)

func _execute_ballista_strike(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_ballista_strike"):
		_main_executor._execute_ballista_strike(ability, player)

func _execute_sentry_network(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_sentry_network"):
		_main_executor._execute_sentry_network(ability, player)

func _execute_rain_of_vengeance(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_rain_of_vengeance"):
		_main_executor._execute_rain_of_vengeance(ability, player)

func _execute_explosive_decoy(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_explosive_decoy"):
		_main_executor._execute_explosive_decoy(ability, player)

# ============================================
# RAIN TREE IMPLEMENTATIONS
# ============================================

func _execute_rain_storm(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Larger area, more arrows"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, 500.0)
	var target_pos = target.global_position if target else player.global_position + _get_attack_direction(player) * 200.0

	var storm = _spawn_effect("arrow_storm", target_pos)
	if storm and storm.has_method("setup"):
		storm.setup(damage, ability.radius, ability.duration)

	_play_sound("rain_of_arrows")

func _execute_rain_apocalypse(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Screen-wide arrow rain"""
	var damage = _get_damage(ability)

	# SIGNATURE: Cover entire battlefield
	var apocalypse = _spawn_effect("arrow_apocalypse", player.global_position)
	if apocalypse and apocalypse.has_method("setup"):
		apocalypse.setup(damage, ability.radius, ability.duration, ability.slow_percent)

	_play_sound("arrow_apocalypse")
	_screen_shake("large")

func _execute_rain_focused(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Concentrated barrage"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, 500.0)
	var target_pos = target.global_position if target else player.global_position + _get_attack_direction(player) * 200.0

	var barrage = _spawn_effect("focused_barrage", target_pos)
	if barrage and barrage.has_method("setup"):
		barrage.setup(damage, ability.radius, ability.duration)

	_play_sound("rain_of_arrows")

func _execute_rain_orbital(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Massive orbital strike"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, 600.0)
	var target_pos = target.global_position if target else player.global_position + _get_attack_direction(player) * 200.0

	# SIGNATURE: Delayed massive strike
	_spawn_effect("orbital_warning", target_pos)
	_play_sound("orbital_incoming")

	var strike = _spawn_effect("orbital_strike", target_pos)
	if strike and strike.has_method("setup"):
		strike.setup(damage, ability.radius, ability.cast_time, ability.stun_duration)

	_screen_shake("large")
	_impact_pause(0.2)

# ============================================
# TURRET TREE IMPLEMENTATIONS
# ============================================

func _execute_turret_rapid(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Fast-firing turret"""
	var damage = _get_damage(ability)

	var turret = _spawn_effect("rapid_sentry", player.global_position)
	if turret and turret.has_method("setup"):
		turret.setup(damage, ability.range_distance, ability.duration, 0.2)  # 0.2s between shots

	_play_sound("sentry_deploy")

func _execute_turret_gatling(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: 3 synced rapid-fire turrets"""
	var damage = _get_damage(ability)

	# SIGNATURE: Deploy 3 turrets in triangle formation
	for i in range(3):
		var offset = Vector2(cos(i * TAU / 3), sin(i * TAU / 3)) * 60.0
		var turret = _spawn_effect("gatling_turret", player.global_position + offset)
		if turret and turret.has_method("setup"):
			turret.setup(damage, ability.range_distance, ability.duration, ability.slow_percent)

	_play_sound("gatling_deploy")
	_screen_shake("small")

func _execute_turret_heavy(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Slow but powerful shots"""
	var damage = _get_damage(ability)

	var turret = _spawn_effect("heavy_sentry", player.global_position)
	if turret and turret.has_method("setup"):
		turret.setup(damage, ability.range_distance, ability.duration, 1.5)  # 1.5s between shots

	_play_sound("sentry_deploy")

func _execute_turret_artillery(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Explosive cannon"""
	var damage = _get_damage(ability)

	# SIGNATURE: Massive artillery cannon
	var cannon = _spawn_effect("artillery_cannon", player.global_position)
	if cannon and cannon.has_method("setup"):
		cannon.setup(damage, ability.range_distance, ability.duration, ability.radius, ability.stun_duration)

	_play_sound("artillery_deploy")
	_screen_shake("medium")

# ============================================
# VOLLEY TREE IMPLEMENTATIONS
# ============================================

func _execute_volley_ricochet(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Bouncing arrows"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	for i in range(ability.projectile_count):
		var offset = (i - 1) * 0.15
		var proj_dir = direction.rotated(offset)
		var proj = _spawn_projectile(player, proj_dir, ability.projectile_speed)
		if proj:
			if "damage" in proj:
				proj.damage = damage
			if "bounce_count" in proj:
				proj.bounce_count = 3
			if "bounces" in proj:
				proj.bounces = true

	_play_sound("piercing_volley")

func _execute_volley_chaos(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: 8 infinite-bounce projectiles"""
	var damage = _get_damage(ability)

	# SIGNATURE: Fire 8 chaos bolts in all directions
	for i in range(8):
		var angle = i * TAU / 8
		var proj_dir = Vector2(cos(angle), sin(angle))
		var proj = _spawn_projectile(player, proj_dir, ability.projectile_speed)
		if proj:
			if "damage" in proj:
				proj.damage = damage
			if "bounce_count" in proj:
				proj.bounce_count = 999
			if "lifetime" in proj:
				proj.lifetime = ability.duration
			if "damage_increase_per_bounce" in proj:
				proj.damage_increase_per_bounce = 0.05

	_spawn_effect("chaos_bolts", player.global_position)
	_play_sound("chaos_bolts")
	_screen_shake("small")

func _execute_volley_sniper(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Single powerful piercing shot"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, 600.0)
	if target:
		direction = (target.global_position - player.global_position).normalized()

	var proj = _spawn_projectile(player, direction, ability.projectile_speed)
	if proj:
		if "damage" in proj:
			proj.damage = damage
		if "pierce_count" in proj:
			proj.pierce_count = 999

	_spawn_effect("sniper_shot", player.global_position)
	_play_sound("sniper_shot")

func _execute_volley_rail(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Instant hitscan beam"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	# SIGNATURE: Instant hitscan across screen
	var start_pos = player.global_position
	var end_pos = start_pos + direction * ability.range_distance

	# Hit all enemies in line
	var all_enemies = player.get_tree().get_nodes_in_group("enemies")
	for enemy in all_enemies:
		if is_instance_valid(enemy):
			var to_enemy = enemy.global_position - start_pos
			var proj_length = to_enemy.dot(direction)
			if proj_length > 0 and proj_length < ability.range_distance:
				var closest_point = start_pos + direction * proj_length
				if enemy.global_position.distance_to(closest_point) < 50.0:
					# SIGNATURE: +25% crit chance
					var is_crit = randf() < 0.25
					var final_damage = damage * (2.0 if is_crit else 1.0)
					_deal_damage_to_enemy(enemy, final_damage, is_crit)

	_spawn_effect("rail_shot", player.global_position)
	_play_sound("rail_shot")
	_screen_shake("medium")
	_impact_pause(0.1)

# ============================================
# EVASION TREE IMPLEMENTATIONS
# ============================================

func _execute_roll_shadow(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Leave exploding decoy"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var start_pos = player.global_position

	# Set invulnerable during roll
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(ability.invulnerability_duration)

	# Dash
	_dash_player(player, direction, ability.range_distance, 0.2)

	# Spawn exploding decoy
	var decoy = _spawn_effect("shadow_decoy", start_pos)
	if decoy and decoy.has_method("setup"):
		decoy.setup(damage, ability.radius, 1.0)  # Explode after 1 second

	_play_sound("quick_roll")

func _execute_roll_dance(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: 3 chain rolls with attacking clones"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	# SIGNATURE: Long invulnerability
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(ability.invulnerability_duration)

	# Perform 3 rolls with clones
	for i in range(3):
		var start_pos = player.global_position
		_dash_player(player, direction, ability.range_distance, 0.15)

		# Spawn attacking clone
		var clone = _spawn_effect("shadow_dancer", start_pos)
		if clone and clone.has_method("setup"):
			clone.setup(damage, ability.duration, 3)  # 3 attacks before vanishing

		# Rotate direction slightly for variety
		direction = direction.rotated(0.3)

	_spawn_effect("shadow_dance", player.global_position)
	_play_sound("shadow_dance")
	_screen_shake("small")

func _execute_roll_counter(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Counter-attack after roll"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	# Set invulnerable during roll
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(ability.invulnerability_duration)

	# Dash
	_dash_player(player, direction, ability.range_distance, 0.2)

	# Counter-attack nearest enemy
	var target = _get_nearest_enemy(player.global_position, 200.0)
	if target:
		_deal_damage_to_enemy(target, damage)
		_spawn_effect("counter_strike", target.global_position)

	_play_sound("quick_roll")

func _execute_roll_perfect(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Time slow + devastating counter"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	# SIGNATURE: Time slow effect
	if player.has_method("trigger_time_slow"):
		player.trigger_time_slow(0.5, 0.3)  # 0.5 seconds at 30% speed

	# Extended invulnerability
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(ability.invulnerability_duration)

	# Dash
	_dash_player(player, direction, ability.range_distance, 0.3)

	# SIGNATURE: Guaranteed crit counter
	var target = _get_nearest_enemy(player.global_position, 250.0)
	if target:
		_deal_damage_to_enemy(target, damage, true)  # Always crit
		_apply_stun(target, ability.stun_duration)
		_spawn_effect("perfect_counter", target.global_position)

	_play_sound("perfect_dodge")
	_screen_shake("medium")
	_impact_pause(0.15)
