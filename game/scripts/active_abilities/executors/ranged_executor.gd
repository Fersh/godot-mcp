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
		# SMOKE TREE
		# ============================================
		"smoke_bomb":
			_execute_smoke_bomb(ability, player)
			return true
		"smoke_blind":
			_execute_smoke_blind(ability, player)
			return true
		"smoke_darkness":
			_execute_smoke_darkness(ability, player)
			return true
		"smoke_poison":
			_execute_smoke_poison(ability, player)
			return true
		"smoke_plague":
			_execute_smoke_plague(ability, player)
			return true

		# ============================================
		# DECOY TREE
		# ============================================
		"decoy":
			_execute_decoy(ability, player)
			return true
		"decoy_explosive":
			_execute_decoy_explosive(ability, player)
			return true
		"decoy_chain":
			_execute_decoy_chain(ability, player)
			return true
		"decoy_mirror":
			_execute_decoy_mirror(ability, player)
			return true
		"decoy_army":
			_execute_decoy_army(ability, player)
			return true

		# ============================================
		# EXPLOSIVE TREE
		# ============================================
		"explosive_arrow":
			_execute_explosive_arrow_new(ability, player)
			return true
		"explosive_cluster":
			_execute_explosive_cluster(ability, player)
			return true
		"explosive_carpet":
			_execute_explosive_carpet(ability, player)
			return true
		"explosive_sticky":
			_execute_explosive_sticky(ability, player)
			return true
		"explosive_walking":
			_execute_explosive_walking(ability, player)
			return true

		# ============================================
		# POISON TREE
		# ============================================
		"poison_arrow":
			_execute_poison_arrow(ability, player)
			return true
		"poison_plague":
			_execute_poison_plague(ability, player)
			return true
		"poison_pandemic":
			_execute_poison_pandemic(ability, player)
			return true
		"poison_toxic":
			_execute_poison_toxic(ability, player)
			return true
		"poison_venom":
			_execute_poison_venom(ability, player)
			return true

		# ============================================
		# FROST ARROW TREE
		# ============================================
		"frost_arrow":
			_execute_frost_arrow(ability, player)
			return true
		"frost_freezing":
			_execute_frost_freezing(ability, player)
			return true
		"frost_ice_age":
			_execute_frost_ice_age(ability, player)
			return true
		"frost_chilling":
			_execute_frost_chilling(ability, player)
			return true
		"frost_frostbite":
			_execute_frost_frostbite(ability, player)
			return true

		# ============================================
		# MARK TREE
		# ============================================
		"mark_target":
			_execute_mark_target(ability, player)
			return true
		"mark_hunter":
			_execute_mark_hunter(ability, player)
			return true
		"mark_death":
			_execute_mark_death(ability, player)
			return true
		"mark_focus":
			_execute_mark_focus(ability, player)
			return true
		"mark_kill_order":
			_execute_mark_kill_order(ability, player)
			return true

		# ============================================
		# SNIPE TREE
		# ============================================
		"snipe":
			_execute_snipe(ability, player)
			return true
		"snipe_headshot":
			_execute_snipe_headshot(ability, player)
			return true
		"snipe_assassinate":
			_execute_snipe_assassinate(ability, player)
			return true
		"snipe_pierce":
			_execute_snipe_pierce(ability, player)
			return true
		"snipe_obliterate":
			_execute_snipe_obliterate(ability, player)
			return true

		# ============================================
		# GRAPPLE TREE
		# ============================================
		"grapple":
			_execute_grapple(ability, player)
			return true
		"grapple_pull":
			_execute_grapple_pull(ability, player)
			return true
		"grapple_scorpion":
			_execute_grapple_scorpion(ability, player)
			return true
		"grapple_swing":
			_execute_grapple_swing(ability, player)
			return true
		"grapple_spider":
			_execute_grapple_spider(ability, player)
			return true

		# ============================================
		# BOOMERANG TREE
		# ============================================
		"boomerang":
			_execute_boomerang(ability, player)
			return true
		"boomerang_multi":
			_execute_boomerang_multi(ability, player)
			return true
		"boomerang_storm":
			_execute_boomerang_storm(ability, player)
			return true
		"boomerang_track":
			_execute_boomerang_track(ability, player)
			return true
		"boomerang_predator":
			_execute_boomerang_predator(ability, player)
			return true

		# ============================================
		# NET TREE
		# ============================================
		"net":
			_execute_net(ability, player)
			return true
		"net_electric":
			_execute_net_electric(ability, player)
			return true
		"net_tesla":
			_execute_net_tesla(ability, player)
			return true
		"net_barbed":
			_execute_net_barbed(ability, player)
			return true
		"net_razor":
			_execute_net_razor(ability, player)
			return true

		# ============================================
		# RICOCHET TREE
		# ============================================
		"ricochet":
			_execute_ricochet(ability, player)
			return true
		"ricochet_chain":
			_execute_ricochet_chain(ability, player)
			return true
		"ricochet_infinite":
			_execute_ricochet_infinite(ability, player)
			return true
		"ricochet_split":
			_execute_ricochet_split(ability, player)
			return true
		"ricochet_cascade":
			_execute_ricochet_cascade(ability, player)
			return true

		# ============================================
		# BARRAGE TREE
		# ============================================
		"barrage":
			_execute_barrage(ability, player)
			return true
		"barrage_focused":
			_execute_barrage_focused(ability, player)
			return true
		"barrage_bullet_storm":
			_execute_barrage_bullet_storm(ability, player)
			return true
		"barrage_spread":
			_execute_barrage_spread(ability, player)
			return true
		"barrage_lead_rain":
			_execute_barrage_lead_rain(ability, player)
			return true

		# ============================================
		# QUICKDRAW TREE
		# ============================================
		"quickdraw":
			_execute_quickdraw(ability, player)
			return true
		"quickdraw_reflex":
			_execute_quickdraw_reflex(ability, player)
			return true
		"quickdraw_gunslinger":
			_execute_quickdraw_gunslinger(ability, player)
			return true
		"quickdraw_execute":
			_execute_quickdraw_execute(ability, player)
			return true
		"quickdraw_deadeye":
			_execute_quickdraw_deadeye(ability, player)
			return true

		# ============================================
		# LEGACY RANGED (for backwards compatibility)
		# ============================================
		"explosive_arrow_legacy":
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
	"""Tier 2: Fan of Knives - 360-degree spray of projectiles"""
	var damage = _get_damage(ability)
	var angle_step = TAU / ability.projectile_count  # Full 360 degrees

	# Fire in ALL directions like original fan_of_knives
	for i in range(ability.projectile_count):
		var direction = Vector2.RIGHT.rotated(angle_step * i)
		var proj = _spawn_projectile(player, direction, ability.projectile_speed)
		if proj and "damage" in proj:
			proj.damage = damage

	_spawn_effect("fan_of_knives", player.global_position)
	_play_sound("throw")
	_screen_shake("small")

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
	"""Tier 2: Bear Trap - Root + heavy damage with visual trap"""
	var damage = _get_damage(ability)
	var trap_pos = player.global_position

	# Create trap visual inline (no external scene dependency)
	var trap = Node2D.new()
	trap.name = "BearTrap"
	trap.global_position = trap_pos
	trap.modulate.a = 0.9
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(trap)

	# Visual - metal trap jaws
	var base = Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-20, -5), Vector2(20, -5), Vector2(15, 5), Vector2(-15, 5)
	])
	base.color = Color(0.4, 0.4, 0.4, 0.9)
	trap.add_child(base)

	# Teeth
	for i in range(5):
		var tooth = Polygon2D.new()
		var x_offset = (i - 2) * 8
		tooth.polygon = PackedVector2Array([
			Vector2(x_offset - 2, -5), Vector2(x_offset + 2, -5), Vector2(x_offset, -15)
		])
		tooth.color = Color(0.5, 0.5, 0.5, 0.9)
		trap.add_child(tooth)

	# Check for enemies stepping on trap
	var check_interval = 0.1
	var max_duration = 30.0
	var checks = int(max_duration / check_interval)
	var triggered = [false]

	for i in range(checks):
		if _main_executor:
			_main_executor.get_tree().create_timer(check_interval * i).timeout.connect(func():
				if triggered[0] or not is_instance_valid(trap):
					return
				var enemies = _main_executor.get_tree().get_nodes_in_group("enemies")
				for enemy in enemies:
					if is_instance_valid(enemy) and trap_pos.distance_to(enemy.global_position) < 30:
						triggered[0] = true
						_deal_damage_to_enemy(enemy, damage)
						_apply_stun(enemy, ability.stun_duration)
						_spawn_effect("explosion", trap_pos)
						_play_sound("trap_trigger")
						trap.queue_free()
						return
			)

	# Remove trap after max duration
	if _main_executor:
		_main_executor.get_tree().create_timer(max_duration).timeout.connect(func():
			if is_instance_valid(trap):
				trap.queue_free()
		)

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
	"""Tier 2: Arrow Storm - Raining arrows over duration"""
	var damage = _get_damage(ability)
	var duration = ability.duration
	var radius = ability.radius

	# Spawn raining arrows for the duration (like standalone arrow_storm)
	var arrows_per_second = 15
	var total_arrows = int(duration * arrows_per_second)

	for i in range(total_arrows):
		var delay = duration * float(i) / float(total_arrows)
		if _main_executor:
			_main_executor.get_tree().create_timer(delay).timeout.connect(func():
				if not is_instance_valid(player):
					return
				_spawn_storm_arrow(player.global_position, radius, damage / 3.0)
			)

	_play_sound("arrow_storm")
	_screen_shake("large")

func _spawn_storm_arrow(center: Vector2, radius: float, damage: float) -> void:
	"""Helper: Spawn a single storm arrow at random position in radius"""
	var target_pos = center + Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
	target_pos.x = clamp(target_pos.x, -60, 1596)
	target_pos.y = clamp(target_pos.y, 40, 1382 - 40)

	# Deal damage to enemies near landing spot
	var enemies = _get_enemies_in_radius(target_pos, 40.0)
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)

	_spawn_effect("arrow_impact", target_pos)

func _execute_rain_apocalypse(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Rain of Vengeance - Screen-wide arrow rain with slow"""
	var damage = _get_damage(ability)

	# Massive arrow storm covering most of the screen (like standalone rain_of_vengeance)
	var waves = 10
	var arrows_per_wave = 15

	for wave in range(waves):
		if _main_executor:
			_main_executor.get_tree().create_timer(ability.duration * wave / waves).timeout.connect(func():
				for i in range(arrows_per_wave):
					var random_offset = Vector2(
						randf_range(-ability.radius, ability.radius),
						randf_range(-ability.radius, ability.radius)
					)
					var arrow_pos = player.global_position + random_offset
					arrow_pos.x = clamp(arrow_pos.x, -60, 1596)
					arrow_pos.y = clamp(arrow_pos.y, 40, 1382 - 40)

					# Deal damage and apply slow
					var enemies = _get_enemies_in_radius(arrow_pos, 50.0)
					for enemy in enemies:
						_deal_damage_to_enemy(enemy, damage / (waves * 2))
						_apply_slow(enemy, ability.slow_percent, ability.slow_duration)

					_spawn_effect("arrow_impact", arrow_pos)
			)

	_play_sound("arrow_storm")
	_screen_shake("large")

func _execute_rain_focused(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Concentrated barrage on target area"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, 500.0)
	var target_pos = target.global_position if target else player.global_position + _get_attack_direction(player) * 200.0

	# Focused barrage on single area
	var arrows = 20
	for i in range(arrows):
		var delay = ability.duration * float(i) / float(arrows)
		if _main_executor:
			_main_executor.get_tree().create_timer(delay).timeout.connect(func():
				var offset = Vector2(randf_range(-ability.radius * 0.5, ability.radius * 0.5),
									 randf_range(-ability.radius * 0.5, ability.radius * 0.5))
				var arrow_pos = target_pos + offset
				var enemies = _get_enemies_in_radius(arrow_pos, 30.0)
				for enemy in enemies:
					_deal_damage_to_enemy(enemy, damage / 5.0)
				_spawn_effect("arrow_impact", arrow_pos)
			)

	_play_sound("rain_of_arrows")

func _execute_rain_orbital(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Orbital Strike - Devastating delayed strike"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, 600.0)
	var target_pos = target.global_position if target else player.global_position + _get_attack_direction(player) * 200.0

	# Warning indicator (like standalone orbital_strike)
	var warning = Node2D.new()
	warning.global_position = target_pos
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(warning)

	var indicator = Polygon2D.new()
	var points: PackedVector2Array = []
	for i in range(16):
		var angle = TAU * i / 16
		points.append(Vector2(cos(angle), sin(angle)) * ability.radius)
	indicator.polygon = points
	indicator.color = Color(1.0, 0.0, 0.0, 0.3)
	warning.add_child(indicator)

	# Blink warning
	var blink = warning.create_tween().set_loops(int(ability.cast_time * 4))
	blink.tween_property(indicator, "modulate:a", 0.1, 0.125)
	blink.tween_property(indicator, "modulate:a", 1.0, 0.125)

	_play_sound("orbital_incoming")

	# Strike after cast time
	if _main_executor:
		_main_executor.get_tree().create_timer(ability.cast_time).timeout.connect(func():
			if is_instance_valid(warning):
				warning.queue_free()

			# Massive damage in area
			var enemies = _get_enemies_in_radius(target_pos, ability.radius)
			for enemy in enemies:
				_deal_damage_to_enemy(enemy, damage)
				_apply_stun(enemy, ability.stun_duration)

			_spawn_effect("explosion", target_pos)
			_screen_shake("large")
		)

	_impact_pause(0.2)

# ============================================
# TURRET TREE IMPLEMENTATIONS
# ============================================

func _execute_turret_rapid(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Fast-firing turret"""
	var damage = _get_damage(ability)
	var turret_pos = player.global_position
	turret_pos.x = clamp(turret_pos.x, -60, 1596)
	turret_pos.y = clamp(turret_pos.y, 40, 1382 - 40)

	var turret = _spawn_effect("sentry_turret", turret_pos)
	if turret and turret.has_method("setup"):
		turret.setup(ability.duration, damage)
	else:
		# Fallback: faster shooting (0.2s interval)
		_start_turret_shooting(turret_pos, damage, ability.duration, 0.2)

	_play_sound("deploy")

func _execute_turret_gatling(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Sentry Network - 3 synced rapid-fire turrets"""
	var damage = _get_damage(ability)

	# Deploy 3 turrets in triangle formation (like standalone sentry_network)
	var turret_positions = [
		player.global_position + Vector2(-80, 0),
		player.global_position + Vector2(80, 0),
		player.global_position + Vector2(0, -80)
	]

	for pos in turret_positions:
		pos.x = clamp(pos.x, -60, 1596)
		pos.y = clamp(pos.y, 40, 1382 - 40)
		var turret = _spawn_effect("sentry_turret", pos)
		if turret and turret.has_method("setup"):
			turret.setup(ability.duration, damage)
		else:
			# Fallback: manual turret shooting
			_start_turret_shooting(pos, damage, ability.duration, 0.3)

	_play_sound("deploy")
	_screen_shake("small")

func _execute_turret_heavy(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Slow but powerful shots"""
	var damage = _get_damage(ability)
	var turret_pos = player.global_position
	turret_pos.x = clamp(turret_pos.x, -60, 1596)
	turret_pos.y = clamp(turret_pos.y, 40, 1382 - 40)

	var turret = _spawn_effect("sentry_turret", turret_pos)
	if turret and turret.has_method("setup"):
		turret.setup(ability.duration, damage * 2.0)  # Double damage
	else:
		# Fallback: slower but stronger shots (1.5s interval)
		_start_turret_shooting(turret_pos, damage * 2.0, ability.duration, 1.5)

	_play_sound("deploy")

func _execute_turret_artillery(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Explosive cannon with AoE"""
	var damage = _get_damage(ability)
	var turret_pos = player.global_position
	turret_pos.x = clamp(turret_pos.x, -60, 1596)
	turret_pos.y = clamp(turret_pos.y, 40, 1382 - 40)

	var turret = _spawn_effect("sentry_turret", turret_pos)
	if turret and turret.has_method("setup"):
		turret.setup(ability.duration, damage)
	else:
		# Fallback: AoE turret shots
		_start_artillery_shooting(turret_pos, damage, ability.duration, ability.radius, ability.stun_duration)

	_play_sound("deploy")
	_screen_shake("medium")

func _start_turret_shooting(position: Vector2, damage: float, duration: float, interval: float) -> void:
	"""Manual turret shooting fallback"""
	var shots = int(duration / interval)
	var damage_per_shot = damage / shots

	for i in range(shots):
		if _main_executor:
			_main_executor.get_tree().create_timer(interval * i).timeout.connect(func():
				var target = _get_nearest_enemy(position, 300.0)
				if target and is_instance_valid(target):
					_deal_damage_to_enemy(target, damage_per_shot)
					_spawn_effect("turret_shot", position)
			)

func _start_artillery_shooting(position: Vector2, damage: float, duration: float, radius: float, stun_duration: float) -> void:
	"""Manual artillery shooting with AoE"""
	var interval = 2.0  # Slow but powerful
	var shots = int(duration / interval)
	var damage_per_shot = damage / shots

	for i in range(shots):
		if _main_executor:
			_main_executor.get_tree().create_timer(interval * i).timeout.connect(func():
				var target = _get_nearest_enemy(position, 400.0)
				if target and is_instance_valid(target):
					# AoE damage at target position
					var enemies = _get_enemies_in_radius(target.global_position, radius)
					for enemy in enemies:
						_deal_damage_to_enemy(enemy, damage_per_shot)
						_apply_stun(enemy, stun_duration * 0.5)
					_spawn_effect("explosion", target.global_position)
			)

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

# ============================================
# SMOKE TREE IMPLEMENTATIONS
# ============================================

func _execute_smoke_bomb(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Create smoke cloud for cover (like standalone smoke_bomb)"""
	var smoke_pos = player.global_position

	# Create smoke cloud
	var smoke = Node2D.new()
	smoke.name = "SmokeCloud"
	smoke.global_position = smoke_pos
	smoke.z_index = 10
	smoke.modulate.a = 0.9
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(smoke)

	# Visual - multiple semi-transparent circles
	for i in range(5):
		var cloud = Polygon2D.new()
		var radius = ability.radius * (0.5 + randf() * 0.5)
		var offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
		var points: PackedVector2Array = []
		for j in range(12):
			var angle = TAU * j / 12
			points.append(Vector2(cos(angle), sin(angle)) * radius + offset)
		cloud.polygon = points
		cloud.color = Color(0.3, 0.3, 0.3, 0.4)
		smoke.add_child(cloud)

	# Make player semi-invisible
	if player.has_node("Sprite2D"):
		var sprite = player.get_node("Sprite2D")
		sprite.modulate.a = 0.3
		if _main_executor:
			_main_executor.get_tree().create_timer(ability.duration).timeout.connect(func():
				if is_instance_valid(sprite):
					sprite.modulate.a = 1.0
			)

	# Slow enemies inside
	var tick_interval = 0.5
	var ticks = int(ability.duration / tick_interval)
	for i in range(ticks):
		if _main_executor:
			_main_executor.get_tree().create_timer(tick_interval * i).timeout.connect(func():
				if not is_instance_valid(smoke):
					return
				var enemies = _get_enemies_in_radius(smoke_pos, ability.radius)
				for enemy in enemies:
					_apply_slow(enemy, 0.4, 1.0)
			)

	# Remove smoke after duration
	if _main_executor:
		_main_executor.get_tree().create_timer(ability.duration).timeout.connect(func():
			if is_instance_valid(smoke):
				smoke.queue_free()
		)

	_play_sound("smoke_bomb")

func _execute_smoke_blind(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Blinding Smoke - enemies lose accuracy"""
	_execute_smoke_bomb(ability, player)  # Base smoke effect
	# Additional: blind enemies (could disable enemy attacks/targeting)

func _execute_smoke_darkness(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Total Darkness - enemies blind, you gain crit"""
	var smoke_pos = player.global_position

	# Create massive dark cloud
	var darkness = Node2D.new()
	darkness.name = "TotalDarkness"
	darkness.global_position = smoke_pos
	darkness.z_index = 10
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(darkness)

	# SIGNATURE: Dark visual
	for i in range(8):
		var cloud = Polygon2D.new()
		var radius = ability.radius * (0.6 + randf() * 0.4)
		var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
		var points: PackedVector2Array = []
		for j in range(16):
			var angle = TAU * j / 16
			points.append(Vector2(cos(angle), sin(angle)) * radius + offset)
		cloud.polygon = points
		cloud.color = Color(0.1, 0.1, 0.1, 0.7)
		darkness.add_child(cloud)

	# SIGNATURE: Player gets crit boost while in darkness
	if player.has_method("add_temp_crit_boost"):
		player.add_temp_crit_boost(0.5, ability.duration)

	# Stun enemies in darkness
	var enemies = _get_enemies_in_radius(smoke_pos, ability.radius)
	for enemy in enemies:
		_apply_stun(enemy, ability.duration * 0.5)

	if _main_executor:
		_main_executor.get_tree().create_timer(ability.duration).timeout.connect(func():
			if is_instance_valid(darkness):
				darkness.queue_free()
		)

	_play_sound("smoke_bomb")
	_screen_shake("small")

func _execute_smoke_poison(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Poison Cloud - DoT damage"""
	var damage = _get_damage(ability)
	var smoke_pos = player.global_position

	# Create poison cloud
	var cloud = Node2D.new()
	cloud.name = "PoisonCloud"
	cloud.global_position = smoke_pos
	cloud.z_index = 10
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(cloud)

	# Green poison visual
	for i in range(5):
		var particle = Polygon2D.new()
		var radius = ability.radius * (0.5 + randf() * 0.5)
		var offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
		var points: PackedVector2Array = []
		for j in range(12):
			var angle = TAU * j / 12
			points.append(Vector2(cos(angle), sin(angle)) * radius + offset)
		particle.polygon = points
		particle.color = Color(0.2, 0.6, 0.1, 0.5)
		cloud.add_child(particle)

	# DoT damage
	var tick_interval = 0.5
	var ticks = int(ability.duration / tick_interval)
	var damage_per_tick = damage / ticks

	for i in range(ticks):
		if _main_executor:
			_main_executor.get_tree().create_timer(tick_interval * i).timeout.connect(func():
				if not is_instance_valid(cloud):
					return
				var enemies = _get_enemies_in_radius(smoke_pos, ability.radius)
				for enemy in enemies:
					_deal_damage_to_enemy(enemy, damage_per_tick)
			)

	if _main_executor:
		_main_executor.get_tree().create_timer(ability.duration).timeout.connect(func():
			if is_instance_valid(cloud):
				cloud.queue_free()
		)

	_play_sound("poison")

func _execute_smoke_plague(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Plague Cloud - spreads and grows"""
	var damage = _get_damage(ability)
	var smoke_pos = player.global_position

	# SIGNATURE: Growing plague cloud
	var cloud = Node2D.new()
	cloud.name = "PlagueCloud"
	cloud.global_position = smoke_pos
	cloud.z_index = 10
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(cloud)

	# Dark green plague visual
	var current_radius = [ability.radius * 0.5]  # Start smaller, grow

	for i in range(6):
		var particle = Polygon2D.new()
		var points: PackedVector2Array = []
		for j in range(12):
			var angle = TAU * j / 12
			points.append(Vector2(cos(angle), sin(angle)) * current_radius[0])
		particle.polygon = points
		particle.color = Color(0.1, 0.4, 0.05, 0.6)
		cloud.add_child(particle)

	# SIGNATURE: Cloud grows over time
	var growth_tween = cloud.create_tween()
	growth_tween.tween_property(cloud, "scale", Vector2(2.0, 2.0), ability.duration)

	# DoT + stacking poison
	var tick_interval = 0.4
	var ticks = int(ability.duration / tick_interval)
	var damage_per_tick = damage / ticks
	var poison_stacks: Dictionary = {}

	for i in range(ticks):
		if _main_executor:
			_main_executor.get_tree().create_timer(tick_interval * i).timeout.connect(func():
				if not is_instance_valid(cloud):
					return
				var effective_radius = current_radius[0] * cloud.scale.x
				var enemies = _get_enemies_in_radius(smoke_pos, effective_radius)
				for enemy in enemies:
					var enemy_id = enemy.get_instance_id()
					poison_stacks[enemy_id] = poison_stacks.get(enemy_id, 0) + 1
					_deal_damage_to_enemy(enemy, damage_per_tick * poison_stacks[enemy_id])
			)

	if _main_executor:
		_main_executor.get_tree().create_timer(ability.duration).timeout.connect(func():
			if is_instance_valid(cloud):
				cloud.queue_free()
		)

	_play_sound("poison")
	_screen_shake("small")

# ============================================
# DECOY TREE IMPLEMENTATIONS
# ============================================

func _execute_decoy(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Deploy a decoy that draws aggro"""
	var decoy_pos = player.global_position

	# Create decoy visual (looks like player)
	var decoy = Node2D.new()
	decoy.name = "Decoy"
	decoy.global_position = decoy_pos
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(decoy)

	# Simple decoy visual
	var body = Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-15, -25), Vector2(15, -25), Vector2(15, 25), Vector2(-15, 25)
	])
	body.color = Color(0.5, 0.5, 0.8, 0.7)
	decoy.add_child(body)

	# Make decoy draw aggro (add to enemies group temporarily)
	decoy.add_to_group("decoys")

	if _main_executor:
		_main_executor.get_tree().create_timer(ability.duration).timeout.connect(func():
			if is_instance_valid(decoy):
				decoy.queue_free()
		)

	_play_sound("deploy")

func _execute_decoy_explosive(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Explosive Decoy (like standalone explosive_decoy)"""
	var damage = _get_damage(ability)
	var decoy_pos = player.global_position

	# Create decoy
	var decoy = Node2D.new()
	decoy.name = "ExplosiveDecoy"
	decoy.global_position = decoy_pos
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(decoy)

	# Decoy visual with red tint (explosive)
	var body = Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-15, -25), Vector2(15, -25), Vector2(15, 25), Vector2(-15, 25)
	])
	body.color = Color(0.8, 0.3, 0.3, 0.7)
	decoy.add_child(body)

	decoy.add_to_group("decoys")

	# Make player briefly invisible
	if player.has_node("Sprite2D"):
		var sprite = player.get_node("Sprite2D")
		sprite.modulate.a = 0.3
		if _main_executor:
			_main_executor.get_tree().create_timer(2.0).timeout.connect(func():
				if is_instance_valid(sprite):
					sprite.modulate.a = 1.0
			)

	# Explode after duration
	if _main_executor:
		_main_executor.get_tree().create_timer(ability.duration).timeout.connect(func():
			if is_instance_valid(decoy):
				var enemies = _get_enemies_in_radius(decoy_pos, ability.radius)
				for enemy in enemies:
					_deal_damage_to_enemy(enemy, damage)
				_spawn_effect("explosion", decoy_pos)
				_play_sound("explosion")
				decoy.queue_free()
		)

	_play_sound("deploy")

func _execute_decoy_chain(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Chain Reaction - 3 decoys explode in sequence"""
	var damage = _get_damage(ability)

	# SIGNATURE: Deploy 3 decoys in triangle
	var positions = [
		player.global_position + Vector2(-60, 40),
		player.global_position + Vector2(60, 40),
		player.global_position + Vector2(0, -60)
	]

	for idx in range(3):
		var decoy = Node2D.new()
		decoy.name = "ChainDecoy" + str(idx)
		decoy.global_position = positions[idx]
		if _main_executor:
			_main_executor.get_tree().current_scene.add_child(decoy)

		var body = Polygon2D.new()
		body.polygon = PackedVector2Array([
			Vector2(-12, -20), Vector2(12, -20), Vector2(12, 20), Vector2(-12, 20)
		])
		body.color = Color(0.9, 0.4, 0.1, 0.7)
		decoy.add_child(body)

		# SIGNATURE: Chain explosions with delay
		var delay = ability.duration + (idx * 0.5)
		var final_multiplier = 2.0 if idx == 2 else 1.0  # Final blast is 2x

		if _main_executor:
			_main_executor.get_tree().create_timer(delay).timeout.connect(func():
				if is_instance_valid(decoy):
					var enemies = _get_enemies_in_radius(positions[idx], ability.radius)
					for enemy in enemies:
						_deal_damage_to_enemy(enemy, damage * final_multiplier)
					_spawn_effect("explosion", positions[idx])
					_play_sound("explosion")
					decoy.queue_free()
			)

	_play_sound("deploy")
	_screen_shake("small")

func _execute_decoy_mirror(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Mirror Image - decoy copies attacks at 50% damage"""
	var decoy_pos = player.global_position + Vector2(40, 0)

	var decoy = Node2D.new()
	decoy.name = "MirrorImage"
	decoy.global_position = decoy_pos
	if _main_executor:
		_main_executor.get_tree().current_scene.add_child(decoy)

	# Mirror visual (looks like player but transparent)
	var body = Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-15, -25), Vector2(15, -25), Vector2(15, 25), Vector2(-15, 25)
	])
	body.color = Color(0.7, 0.7, 1.0, 0.5)
	decoy.add_child(body)

	# Mirror attacks player's target
	var shoot_interval = 1.0
	var shots = int(ability.duration / shoot_interval)

	for i in range(shots):
		if _main_executor:
			_main_executor.get_tree().create_timer(shoot_interval * i).timeout.connect(func():
				if not is_instance_valid(decoy):
					return
				var target = _get_nearest_enemy(decoy_pos, 400.0)
				if target and is_instance_valid(target):
					# Fire arrow at target (50% player damage)
					var direction = (target.global_position - decoy_pos).normalized()
					var proj = _spawn_projectile_at(decoy_pos, direction, 450.0)
					if proj and "damage" in proj:
						proj.damage = 15.0  # Fixed low damage for mirror
					_spawn_effect("arrow_shot", decoy_pos)
			)

	if _main_executor:
		_main_executor.get_tree().create_timer(ability.duration).timeout.connect(func():
			if is_instance_valid(decoy):
				decoy.queue_free()
		)

	_play_sound("deploy")

func _execute_decoy_army(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Army of Me - 3 permanent clones"""
	# SIGNATURE: Create 3 permanent mirror images
	var offsets = [
		Vector2(-50, -30),
		Vector2(50, -30),
		Vector2(0, 50)
	]

	for idx in range(3):
		var clone = Node2D.new()
		clone.name = "ArmyClone" + str(idx)
		clone.global_position = player.global_position + offsets[idx]
		if _main_executor:
			_main_executor.get_tree().current_scene.add_child(clone)

		var body = Polygon2D.new()
		body.polygon = PackedVector2Array([
			Vector2(-12, -20), Vector2(12, -20), Vector2(12, 20), Vector2(-12, 20)
		])
		body.color = Color(0.6, 0.8, 1.0, 0.6)
		clone.add_child(body)

		clone.add_to_group("player_clones")

		# SIGNATURE: Clones attack continuously
		var shoot_interval = 1.5
		var clone_idx = idx
		var clone_pos = clone.global_position

		for i in range(100):  # "Permanent" - very long duration
			if _main_executor:
				_main_executor.get_tree().create_timer(shoot_interval * i).timeout.connect(func():
					if not is_instance_valid(clone):
						return
					var target = _get_nearest_enemy(clone.global_position, 350.0)
					if target and is_instance_valid(target):
						var direction = (target.global_position - clone.global_position).normalized()
						var proj = _spawn_projectile_at(clone.global_position, direction, 400.0)
						if proj and "damage" in proj:
							proj.damage = 10.0  # 35% of normal damage
				)

	_play_sound("deploy")
	_screen_shake("small")

func _spawn_projectile_at(pos: Vector2, direction: Vector2, speed: float) -> Node2D:
	"""Helper to spawn projectile from arbitrary position"""
	if _main_executor and _main_executor.has_method("_spawn_projectile_at_position"):
		return _main_executor._spawn_projectile_at_position(pos, direction, speed)
	return null

# ============================================
# EXPLOSIVE TREE IMPLEMENTATIONS
# ============================================

func _execute_explosive_arrow_new(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Fire arrow that explodes on impact"""
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

	_spawn_effect("explosive_arrow", player.global_position)
	_play_sound("power_shot")

func _execute_explosive_cluster(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Spawns 4 mini bombs"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, 500.0)
	var target_pos = target.global_position if target else player.global_position + direction * 300.0

	# Impact at target, spawn cluster
	var enemies = _get_enemies_in_radius(target_pos, ability.radius * 0.5)
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage * 0.5)

	# Spawn 4 mini explosions around impact
	for i in range(4):
		var offset = Vector2(cos(i * TAU / 4), sin(i * TAU / 4)) * 60.0
		var mini_pos = target_pos + offset
		if _main_executor:
			_main_executor.get_tree().create_timer(0.3).timeout.connect(func():
				var mini_enemies = _get_enemies_in_radius(mini_pos, ability.radius * 0.3)
				for enemy in mini_enemies:
					_deal_damage_to_enemy(enemy, damage * 0.3)
				_spawn_effect("explosion", mini_pos)
			)

	_spawn_effect("explosion", target_pos)
	_play_sound("explosion")

func _execute_explosive_carpet(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Line of explosions"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	# Fire 8 explosions in a line
	for i in range(8):
		var bomb_pos = player.global_position + direction * (50.0 + i * 70.0)
		if _main_executor:
			_main_executor.get_tree().create_timer(i * 0.15).timeout.connect(func():
				var enemies = _get_enemies_in_radius(bomb_pos, ability.radius)
				for enemy in enemies:
					_deal_damage_to_enemy(enemy, damage)
				_spawn_effect("explosion", bomb_pos)
				_play_sound("explosion")
			)

	_screen_shake("large")

func _execute_explosive_sticky(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Sticks to enemies, explodes after delay"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		# Stick bomb to enemy
		if _main_executor:
			_main_executor.get_tree().create_timer(2.0).timeout.connect(func():
				if is_instance_valid(target):
					var enemies = _get_enemies_in_radius(target.global_position, ability.radius)
					for enemy in enemies:
						_deal_damage_to_enemy(enemy, damage)
					_spawn_effect("explosion", target.global_position)
					_play_sound("explosion")
			)

	_spawn_effect("sticky_bomb", player.global_position)
	_play_sound("deploy")

func _execute_explosive_walking(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Walking bomb chases enemies"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var bomb_pos = [player.global_position + direction * 50.0]

	# Bomb walks toward nearest enemy
	var ticks = 30
	for i in range(ticks):
		if _main_executor:
			_main_executor.get_tree().create_timer(i * 0.2).timeout.connect(func():
				var target = _get_nearest_enemy(bomb_pos[0], 400.0)
				if target and is_instance_valid(target):
					var to_target = (target.global_position - bomb_pos[0]).normalized()
					bomb_pos[0] += to_target * 30.0

					# Check if close enough to explode
					if bomb_pos[0].distance_to(target.global_position) < 50.0:
						var enemies = _get_enemies_in_radius(bomb_pos[0], ability.radius)
						for enemy in enemies:
							_deal_damage_to_enemy(enemy, damage)
						_spawn_effect("explosion", bomb_pos[0])
						_play_sound("explosion")
						_screen_shake("medium")
			)

	_spawn_effect("walking_bomb", player.global_position)
	_play_sound("deploy")

# ============================================
# POISON TREE IMPLEMENTATIONS
# ============================================

func _execute_poison_arrow(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Arrow that applies poison DoT"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, 500.0)
	if target:
		direction = (target.global_position - player.global_position).normalized()
		_deal_damage_to_enemy(target, damage)
		if target.has_method("apply_poison"):
			target.apply_poison(damage * 0.3, ability.duration)

	_spawn_effect("poison_arrow", player.global_position)
	_play_sound("power_shot")

func _execute_poison_plague(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Poison spreads to nearby enemies"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, 500.0)

	if target:
		_deal_damage_to_enemy(target, damage)
		# Spread poison to nearby enemies
		var nearby = _get_enemies_in_radius(target.global_position, 150.0)
		for enemy in nearby:
			if enemy.has_method("apply_poison"):
				enemy.apply_poison(damage * 0.2, ability.duration)

	_spawn_effect("plague", player.global_position)
	_play_sound("poison")

func _execute_poison_pandemic(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Infinite poison spread on death"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, 500.0)

	if target:
		_deal_damage_to_enemy(target, damage)
		# Mark for pandemic spread
		if target.has_method("apply_pandemic"):
			target.apply_pandemic(damage * 0.5, ability.duration)

	_spawn_effect("pandemic", player.global_position)
	_play_sound("poison")
	_screen_shake("small")

func _execute_poison_toxic(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Stronger poison with slow"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, 500.0)

	if target:
		_deal_damage_to_enemy(target, damage)
		if target.has_method("apply_poison"):
			target.apply_poison(damage * 0.5, ability.duration)
		_apply_slow(target, ability.slow_percent, ability.slow_duration)

	_spawn_effect("toxic_shot", player.global_position)
	_play_sound("poison")

func _execute_poison_venom(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Stacking venom, instant kill at 10 stacks"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, 500.0)

	if target:
		_deal_damage_to_enemy(target, damage)
		if target.has_method("apply_venom_stack"):
			target.apply_venom_stack()

	_spawn_effect("venom", player.global_position)
	_play_sound("poison")
	_screen_shake("small")

# ============================================
# FROST ARROW TREE IMPLEMENTATIONS
# ============================================

func _execute_frost_arrow(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Arrow that slows enemy"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, 500.0)
	if target:
		direction = (target.global_position - player.global_position).normalized()
		_deal_damage_to_enemy(target, damage)
		_apply_slow(target, ability.slow_percent, ability.slow_duration)

	_spawn_effect("frost_arrow", player.global_position)
	_play_sound("ice")

func _execute_frost_freezing(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Chance to freeze solid"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, 500.0)

	if target:
		_deal_damage_to_enemy(target, damage)
		# 30% chance to freeze
		if randf() < 0.3:
			_apply_stun(target, ability.stun_duration)
		else:
			_apply_slow(target, ability.slow_percent, ability.slow_duration)

	_spawn_effect("freezing_arrow", player.global_position)
	_play_sound("ice")

func _execute_frost_ice_age(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Freeze all enemies in area"""
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_stun(enemy, ability.stun_duration)

	_spawn_effect("ice_age", player.global_position)
	_play_sound("ice")
	_screen_shake("large")
	_impact_pause(0.2)

func _execute_frost_chilling(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Creates chilling ground"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target_pos = player.global_position + direction * 200.0

	var enemies = _get_enemies_in_radius(target_pos, ability.radius)
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_slow(enemy, ability.slow_percent, ability.slow_duration)

	# Create chilling zone
	var zone = _spawn_effect("frost_zone", target_pos)
	if zone and zone.has_method("setup"):
		zone.setup(damage * 0.1, ability.radius, ability.duration)

	_play_sound("ice")

func _execute_frost_frostbite(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Stacking chill, frozen enemies shatter for bonus damage"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, 500.0)

	if target:
		var final_damage = damage
		# Check for shatter bonus
		if target.has_method("is_frozen") and target.is_frozen():
			final_damage *= 3.0  # Shatter bonus
		_deal_damage_to_enemy(target, final_damage)
		_apply_stun(target, ability.stun_duration)

	_spawn_effect("frostbite", player.global_position)
	_play_sound("ice")
	_screen_shake("medium")

# ============================================
# MARK TREE IMPLEMENTATIONS
# ============================================

func _execute_mark_target(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Mark enemy for bonus damage"""
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target and target.has_method("apply_mark"):
		target.apply_mark(ability.duration, 1.3)  # 30% bonus damage

	_spawn_effect("mark", target.global_position if target else player.global_position)
	_play_sound("mark")

func _execute_mark_hunter(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Mark increases damage taken by 50%"""
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		if target.has_method("apply_mark"):
			target.apply_mark(ability.duration, 1.5)  # 50% bonus damage
		# Also reveal hidden enemies
		if target.has_method("reveal"):
			target.reveal(ability.duration)

	_spawn_effect("hunter_mark", target.global_position if target else player.global_position)
	_play_sound("mark")

func _execute_mark_death(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Mark of death - instant kill on timer"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		# After delay, deal massive damage or instant kill low HP
		if _main_executor:
			_main_executor.get_tree().create_timer(ability.duration).timeout.connect(func():
				if is_instance_valid(target):
					if target.has_method("get_health_percent") and target.get_health_percent() < 0.3:
						if target.has_method("take_damage"):
							target.take_damage(99999.0)
					else:
						_deal_damage_to_enemy(target, damage * 2.0)
					_spawn_effect("death_mark_trigger", target.global_position)
			)

	_spawn_effect("death_mark", target.global_position if target else player.global_position)
	_play_sound("mark")
	_screen_shake("small")

func _execute_mark_focus(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: All attacks home to marked target"""
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target and target.has_method("apply_focus_mark"):
		target.apply_focus_mark(ability.duration)

	_spawn_effect("focus_mark", target.global_position if target else player.global_position)
	_play_sound("mark")

func _execute_mark_kill_order(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Mark enemy, all damage doubled, allies focus"""
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		if target.has_method("apply_mark"):
			target.apply_mark(ability.duration, 2.0)  # Double damage
		if target.has_method("set_priority_target"):
			target.set_priority_target(true)

	_spawn_effect("kill_order", target.global_position if target else player.global_position)
	_play_sound("mark")
	_screen_shake("medium")

# ============================================
# SNIPE TREE IMPLEMENTATIONS
# ============================================

func _execute_snipe(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Long range precision shot"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		_deal_damage_to_enemy(target, damage)

	_spawn_effect("snipe", player.global_position)
	_play_sound("sniper_shot")

func _execute_snipe_headshot(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: 50% chance for critical headshot"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		var is_crit = randf() < 0.5
		var final_damage = damage * (2.0 if is_crit else 1.0)
		_deal_damage_to_enemy(target, final_damage, is_crit)

	_spawn_effect("headshot", player.global_position)
	_play_sound("sniper_shot")

func _execute_snipe_assassinate(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Guaranteed kill on low HP, resets on kill"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		if target.has_method("get_health_percent") and target.get_health_percent() < 0.4:
			if target.has_method("take_damage"):
				target.take_damage(99999.0)
		else:
			_deal_damage_to_enemy(target, damage, true)  # Always crit

	_spawn_effect("assassinate", player.global_position)
	_play_sound("sniper_shot")
	_screen_shake("medium")
	_impact_pause(0.1)

func _execute_snipe_pierce(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Shot pierces through enemies"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	if target:
		direction = (target.global_position - player.global_position).normalized()

	# Hit all enemies in line
	var start = player.global_position
	var end = start + direction * ability.range_distance
	var all_enemies = player.get_tree().get_nodes_in_group("enemies")
	for enemy in all_enemies:
		if is_instance_valid(enemy):
			var to_enemy = enemy.global_position - start
			var proj_len = to_enemy.dot(direction)
			if proj_len > 0 and proj_len < ability.range_distance:
				var closest = start + direction * proj_len
				if enemy.global_position.distance_to(closest) < 40.0:
					_deal_damage_to_enemy(enemy, damage)

	_spawn_effect("piercing_snipe", player.global_position)
	_play_sound("sniper_shot")

func _execute_snipe_obliterate(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Massive damage, ignores all armor"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		if target.has_method("take_pure_damage"):
			target.take_pure_damage(damage)
		else:
			_deal_damage_to_enemy(target, damage, true)

	_spawn_effect("obliterate", player.global_position)
	_play_sound("railgun")
	_screen_shake("large")
	_impact_pause(0.15)

# ============================================
# GRAPPLE TREE IMPLEMENTATIONS
# ============================================

func _execute_grapple(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Pull enemy to you"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		# Pull enemy to player
		target.global_position = player.global_position + (target.global_position - player.global_position).normalized() * 50.0
		_deal_damage_to_enemy(target, damage)

	_spawn_effect("grapple", player.global_position)
	_play_sound("grapple")

func _execute_grapple_pull(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Pull multiple enemies"""
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.range_distance)
	enemies = enemies.slice(0, 4)

	for enemy in enemies:
		# Pull to player
		enemy.global_position = player.global_position + (enemy.global_position - player.global_position).normalized() * 60.0
		_deal_damage_to_enemy(enemy, damage)

	_spawn_effect("mass_pull", player.global_position)
	_play_sound("grapple")

func _execute_grapple_scorpion(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Pull and impale"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		# Pull enemy
		target.global_position = player.global_position + Vector2(50, 0)
		# Massive damage + stun
		_deal_damage_to_enemy(target, damage)
		_apply_stun(target, ability.stun_duration)

	_spawn_effect("scorpion_pull", player.global_position)
	_play_sound("grapple")
	_screen_shake("medium")

func _execute_grapple_swing(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Pull yourself to enemy"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		var target_pos = target.global_position
		_dash_player(player, (target_pos - player.global_position).normalized(),
			player.global_position.distance_to(target_pos) - 30.0, 0.3)
		_deal_damage_to_enemy(target, damage)

	_spawn_effect("swing", player.global_position)
	_play_sound("grapple")

func _execute_grapple_spider(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Web all enemies in area, immobilize"""
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_stun(enemy, ability.stun_duration)

	_spawn_effect("spider_web", player.global_position)
	_play_sound("grapple")
	_screen_shake("medium")

# ============================================
# BOOMERANG TREE IMPLEMENTATIONS
# ============================================

func _execute_boomerang(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Throw returning projectile"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	if target:
		direction = (target.global_position - player.global_position).normalized()

	var proj = _spawn_projectile(player, direction, ability.projectile_speed)
	if proj:
		if "damage" in proj:
			proj.damage = damage
		if "returns" in proj:
			proj.returns = true

	_spawn_effect("boomerang", player.global_position)
	_play_sound("throw")

func _execute_boomerang_multi(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Throw 3 boomerangs"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	for i in range(3):
		var offset = (i - 1) * 0.3
		var proj = _spawn_projectile(player, direction.rotated(offset), ability.projectile_speed)
		if proj:
			if "damage" in proj:
				proj.damage = damage
			if "returns" in proj:
				proj.returns = true

	_spawn_effect("multi_boomerang", player.global_position)
	_play_sound("throw")

func _execute_boomerang_storm(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: 6 orbiting blades"""
	var damage = _get_damage(ability)

	for i in range(6):
		var angle = i * TAU / 6
		var blade = _spawn_effect("orbital_blade", player.global_position)
		if blade and blade.has_method("setup"):
			blade.setup(player, damage, ability.radius, ability.duration, angle)

	_play_sound("bladestorm")
	_screen_shake("medium")

func _execute_boomerang_track(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Homing boomerang"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	var direction = (target.global_position - player.global_position).normalized() if target else _get_attack_direction(player)

	var proj = _spawn_projectile(player, direction, ability.projectile_speed)
	if proj:
		if "damage" in proj:
			proj.damage = damage
		if "homing" in proj:
			proj.homing = true
		if "target" in proj:
			proj.target = target

	_spawn_effect("tracking_boomerang", player.global_position)
	_play_sound("throw")

func _execute_boomerang_predator(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Hunts enemies until 5 kills"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	var proj = _spawn_projectile(player, direction, ability.projectile_speed)
	if proj:
		if "damage" in proj:
			proj.damage = damage
		if "predator_mode" in proj:
			proj.predator_mode = true
			proj.kills_remaining = 5

	_spawn_effect("predator_disc", player.global_position)
	_play_sound("throw")
	_screen_shake("small")

# ============================================
# NET TREE IMPLEMENTATIONS
# ============================================

func _execute_net(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Throw net to slow enemies"""
	var direction = _get_attack_direction(player)
	var target_pos = player.global_position + direction * 200.0
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	if target:
		target_pos = target.global_position

	var enemies = _get_enemies_in_radius(target_pos, ability.radius)
	for enemy in enemies:
		_apply_slow(enemy, ability.slow_percent, ability.slow_duration)

	_spawn_effect("net", target_pos)
	_play_sound("net")

func _execute_net_electric(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Electrified net, damages and stuns"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target_pos = player.global_position + direction * 200.0
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	if target:
		target_pos = target.global_position

	var enemies = _get_enemies_in_radius(target_pos, ability.radius)
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_slow(enemy, ability.slow_percent, ability.slow_duration)
		_apply_stun(enemy, ability.stun_duration)

	_spawn_effect("electric_net", target_pos)
	_play_sound("lightning")

func _execute_net_tesla(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Chains lightning between trapped enemies"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target_pos = player.global_position + direction * 200.0
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	if target:
		target_pos = target.global_position

	var enemies = _get_enemies_in_radius(target_pos, ability.radius)
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_slow(enemy, ability.slow_percent, ability.slow_duration)
		_apply_stun(enemy, ability.stun_duration)

	# Chain lightning DoT
	var ticks = int(ability.duration / 0.5)
	for i in range(ticks):
		if _main_executor:
			_main_executor.get_tree().create_timer(i * 0.5).timeout.connect(func():
				var trapped = _get_enemies_in_radius(target_pos, ability.radius)
				for enemy in trapped:
					_deal_damage_to_enemy(enemy, damage * 0.2)
				_spawn_effect("chain_lightning", target_pos)
			)

	_spawn_effect("tesla_net", target_pos)
	_play_sound("lightning")
	_screen_shake("medium")

func _execute_net_barbed(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Net damages when enemies move"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target_pos = player.global_position + direction * 200.0
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	if target:
		target_pos = target.global_position

	var enemies = _get_enemies_in_radius(target_pos, ability.radius)
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_slow(enemy, ability.slow_percent, ability.slow_duration)
		if enemy.has_method("apply_barbed"):
			enemy.apply_barbed(damage * 0.1, ability.duration)

	_spawn_effect("barbed_net", target_pos)
	_play_sound("net")

func _execute_net_razor(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Constricting net, increasing damage"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target_pos = player.global_position + direction * 200.0
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	if target:
		target_pos = target.global_position

	var enemies = _get_enemies_in_radius(target_pos, ability.radius)
	for enemy in enemies:
		_apply_slow(enemy, ability.slow_percent, ability.slow_duration)

	# Increasing damage over time
	var ticks = int(ability.duration / 0.4)
	for i in range(ticks):
		if _main_executor:
			_main_executor.get_tree().create_timer(i * 0.4).timeout.connect(func():
				var trapped = _get_enemies_in_radius(target_pos, ability.radius)
				var tick_damage = damage * (0.1 + i * 0.05)  # Increasing damage
				for enemy in trapped:
					_deal_damage_to_enemy(enemy, tick_damage)
			)

	_spawn_effect("razor_net", target_pos)
	_play_sound("net")
	_screen_shake("small")

# ============================================
# RICOCHET TREE IMPLEMENTATIONS
# ============================================

func _execute_ricochet(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Bouncing projectile"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	if target:
		direction = (target.global_position - player.global_position).normalized()

	var proj = _spawn_projectile(player, direction, ability.projectile_speed)
	if proj:
		if "damage" in proj:
			proj.damage = damage
		if "bounce_count" in proj:
			proj.bounce_count = 3

	_spawn_effect("ricochet", player.global_position)
	_play_sound("ricochet")

func _execute_ricochet_chain(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: More bounces"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	if target:
		direction = (target.global_position - player.global_position).normalized()

	var proj = _spawn_projectile(player, direction, ability.projectile_speed)
	if proj:
		if "damage" in proj:
			proj.damage = damage
		if "bounce_count" in proj:
			proj.bounce_count = 6

	_spawn_effect("chain_ricochet", player.global_position)
	_play_sound("ricochet")

func _execute_ricochet_infinite(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Infinite bounces"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	if target:
		direction = (target.global_position - player.global_position).normalized()

	var proj = _spawn_projectile(player, direction, ability.projectile_speed)
	if proj:
		if "damage" in proj:
			proj.damage = damage
		if "bounce_count" in proj:
			proj.bounce_count = 999
		if "damage_increase_per_bounce" in proj:
			proj.damage_increase_per_bounce = 0.05

	_spawn_effect("endless_ricochet", player.global_position)
	_play_sound("ricochet")
	_screen_shake("small")

func _execute_ricochet_split(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Splits on bounce"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	if target:
		direction = (target.global_position - player.global_position).normalized()

	var proj = _spawn_projectile(player, direction, ability.projectile_speed)
	if proj:
		if "damage" in proj:
			proj.damage = damage
		if "splits_on_bounce" in proj:
			proj.splits_on_bounce = true

	_spawn_effect("splitting_shot", player.global_position)
	_play_sound("ricochet")

func _execute_ricochet_cascade(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Exponential splitting"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	var proj = _spawn_projectile(player, direction, ability.projectile_speed)
	if proj:
		if "damage" in proj:
			proj.damage = damage
		if "cascade_mode" in proj:
			proj.cascade_mode = true

	_spawn_effect("cascade", player.global_position)
	_play_sound("ricochet")
	_screen_shake("medium")

# ============================================
# BARRAGE TREE IMPLEMENTATIONS
# ============================================

func _execute_barrage(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Rapid fire barrage"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	if target:
		direction = (target.global_position - player.global_position).normalized()

	var shots = 10
	for i in range(shots):
		if _main_executor:
			_main_executor.get_tree().create_timer(ability.duration * i / shots).timeout.connect(func():
				var proj = _spawn_projectile(player, direction + Vector2(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1)), ability.projectile_speed)
				if proj and "damage" in proj:
					proj.damage = damage / shots
			)

	_play_sound("barrage")

func _execute_barrage_focused(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: All shots on single target"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	if not target:
		return

	var shots = 15
	for i in range(shots):
		if _main_executor:
			_main_executor.get_tree().create_timer(ability.duration * i / shots).timeout.connect(func():
				if is_instance_valid(target):
					_deal_damage_to_enemy(target, damage / shots)
					_spawn_effect("hit", target.global_position)
			)

	_play_sound("barrage")

func _execute_barrage_bullet_storm(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: 50+ projectiles"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	if not target:
		return

	var shots = 50
	for i in range(shots):
		if _main_executor:
			_main_executor.get_tree().create_timer(ability.duration * i / shots).timeout.connect(func():
				if is_instance_valid(target):
					_deal_damage_to_enemy(target, damage / shots)
					_spawn_effect("hit", target.global_position)
			)

	_play_sound("barrage")
	_screen_shake("medium")

func _execute_barrage_spread(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Wide spread of projectiles"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	var shots = 15
	for i in range(shots):
		if _main_executor:
			_main_executor.get_tree().create_timer(ability.duration * i / shots).timeout.connect(func():
				var spread = randf_range(-0.5, 0.5)
				var proj = _spawn_projectile(player, direction.rotated(spread), ability.projectile_speed)
				if proj and "damage" in proj:
					proj.damage = damage / shots
			)

	_play_sound("barrage")

func _execute_barrage_lead_rain(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Suppression zone"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var center = player.global_position + direction * 200.0

	var shots = 40
	for i in range(shots):
		if _main_executor:
			_main_executor.get_tree().create_timer(ability.duration * i / shots).timeout.connect(func():
				var offset = Vector2(randf_range(-ability.radius, ability.radius), randf_range(-ability.radius, ability.radius))
				var hit_pos = center + offset
				var enemies = _get_enemies_in_radius(hit_pos, 30.0)
				for enemy in enemies:
					_deal_damage_to_enemy(enemy, damage / shots)
					_apply_slow(enemy, ability.slow_percent, 0.5)
				_spawn_effect("bullet_impact", hit_pos)
			)

	_play_sound("barrage")
	_screen_shake("large")

# ============================================
# QUICKDRAW TREE IMPLEMENTATIONS
# ============================================

func _execute_quickdraw(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Instant shot with brief invulnerability"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if player.has_method("set_invulnerable"):
		player.set_invulnerable(0.3)

	if target:
		_deal_damage_to_enemy(target, damage)

	_spawn_effect("quickdraw", player.global_position)
	_play_sound("quickdraw")

func _execute_quickdraw_reflex(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Two quick shots"""
	var damage = _get_damage(ability)

	if player.has_method("set_invulnerable"):
		player.set_invulnerable(0.4)

	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	if target:
		_deal_damage_to_enemy(target, damage)
		if _main_executor:
			_main_executor.get_tree().create_timer(0.15).timeout.connect(func():
				if is_instance_valid(target):
					_deal_damage_to_enemy(target, damage)
			)

	_spawn_effect("reflex_shot", player.global_position)
	_play_sound("quickdraw")

func _execute_quickdraw_gunslinger(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: 6 instant shots at different targets"""
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.range_distance)
	enemies = enemies.slice(0, 6)

	if player.has_method("set_invulnerable"):
		player.set_invulnerable(0.6)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_spawn_effect("quickdraw_hit", enemy.global_position)

	_spawn_effect("gunslinger", player.global_position)
	_play_sound("quickdraw")
	_screen_shake("medium")

func _execute_quickdraw_execute(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Massive damage to low HP"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if player.has_method("set_invulnerable"):
		player.set_invulnerable(0.3)

	if target:
		var final_damage = damage
		if target.has_method("get_health_percent") and target.get_health_percent() < 0.5:
			final_damage *= 2.0
		_deal_damage_to_enemy(target, final_damage)

	_spawn_effect("execution_shot", player.global_position)
	_play_sound("quickdraw")

func _execute_quickdraw_deadeye(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Time slow, guaranteed crit, instant kill low HP"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if player.has_method("set_invulnerable"):
		player.set_invulnerable(1.0)

	if player.has_method("trigger_time_slow"):
		player.trigger_time_slow(0.5, 0.2)

	if target:
		if target.has_method("get_health_percent") and target.get_health_percent() < 0.3:
			if target.has_method("take_damage"):
				target.take_damage(99999.0)
		else:
			_deal_damage_to_enemy(target, damage, true)  # Guaranteed crit

	_spawn_effect("deadeye", player.global_position)
	_play_sound("quickdraw")
	_screen_shake("large")
	_impact_pause(0.2)
