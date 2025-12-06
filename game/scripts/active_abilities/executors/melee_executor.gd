extends BaseExecutor
class_name MeleeExecutor

# Handles execution of all melee abilities
# Supports tiered variants (base, branch, signature)

func execute(ability: ActiveAbilityData, player: Node2D) -> bool:
	"""Execute a melee ability. Returns true if handled."""
	match ability.id:
		# ============================================
		# CLEAVE TREE
		# ============================================
		"cleave":
			_execute_cleave(ability, player)
			return true
		"cleave_executioner":
			_execute_cleave_executioner(ability, player)
			return true
		"cleave_guillotine":
			_execute_cleave_guillotine(ability, player)
			return true
		"cleave_crowd":
			_execute_cleave_crowd(ability, player)
			return true
		"cleave_shockwave":
			_execute_cleave_shockwave(ability, player)
			return true

		# ============================================
		# BASH TREE
		# ============================================
		"shield_bash":
			_execute_shield_bash(ability, player)
			return true
		"bash_shockwave":
			_execute_bash_shockwave(ability, player)
			return true
		"bash_earthquake":
			_execute_bash_earthquake(ability, player)
			return true
		"bash_lockdown":
			_execute_bash_lockdown(ability, player)
			return true
		"bash_petrify":
			_execute_bash_petrify(ability, player)
			return true

		# ============================================
		# CHARGE TREE
		# ============================================
		"charge":
			_execute_charge(ability, player)
			return true
		"charge_trample":
			_execute_charge_trample(ability, player)
			return true
		"charge_stampede":
			_execute_charge_stampede(ability, player)
			return true
		"charge_shield":
			_execute_charge_shield(ability, player)
			return true
		"charge_unstoppable":
			_execute_charge_unstoppable(ability, player)
			return true

		# ============================================
		# WHIRLWIND TREE (formerly Spin Tree)
		# ============================================
		"whirlwind":
			_execute_whirlwind_base(ability, player)
			return true
		"spin_vortex":
			_execute_spin_vortex(ability, player)
			return true
		"spin_bladestorm":
			_execute_spin_bladestorm(ability, player)
			return true
		"spin_deflect":
			_execute_spin_deflect(ability, player)
			return true
		"spin_mirror":
			_execute_spin_mirror(ability, player)
			return true
		"spin_fiery":
			_execute_spin_fiery(ability, player)
			return true
		"spin_inferno":
			_execute_spin_inferno(ability, player)
			return true

		# ============================================
		# SLAM TREE
		# ============================================
		"ground_slam":
			_execute_ground_slam(ability, player)
			return true
		"slam_seismic":
			_execute_slam_seismic(ability, player)
			return true
		"slam_earthquake":
			_execute_slam_earthquake(ability, player)
			return true
		"slam_crater":
			_execute_slam_crater(ability, player)
			return true
		"slam_meteor":
			_execute_slam_meteor(ability, player)
			return true

		# ============================================
		# DASH TREE
		# ============================================
		"dash_strike":
			_execute_dash_strike(ability, player)
			return true
		"dash_blade_rush":
			_execute_dash_blade_rush(ability, player)
			return true
		"dash_omnislash":
			_execute_dash_omnislash(ability, player)
			return true
		"dash_afterimage":
			_execute_dash_afterimage(ability, player)
			return true
		"dash_shadow_legion":
			_execute_dash_shadow_legion(ability, player)
			return true

		# ============================================
		# OLD WHIRLWIND TREE (deprecated - merged into Spin/Whirlwind Tree above)
		# ============================================
		# "whirlwind" is now handled by _execute_whirlwind_base above
		# Old variants kept for backwards compatibility with saved games
		"whirlwind_vacuum":
			_execute_whirlwind_vacuum(ability, player)
			return true
		"whirlwind_singularity":
			_execute_whirlwind_singularity(ability, player)
			return true
		"whirlwind_flame":
			_execute_whirlwind_flame(ability, player)
			return true
		"whirlwind_inferno":
			_execute_whirlwind_inferno(ability, player)
			return true

		# ============================================
		# LEAP TREE
		# ============================================
		"savage_leap":
			_execute_savage_leap(ability, player)
			return true
		"leap_tremor":
			_execute_leap_tremor(ability, player)
			return true
		"leap_extinction":
			_execute_leap_extinction(ability, player)
			return true
		"leap_predator":
			_execute_leap_predator(ability, player)
			return true
		"leap_apex":
			_execute_leap_apex(ability, player)
			return true

		# ============================================
		# SHOUT TREE
		# ============================================
		"battle_cry":
			_execute_battle_cry(ability, player)
			return true
		"shout_rallying":
			_execute_shout_rallying(ability, player)
			return true
		"shout_warlord":
			_execute_shout_warlord(ability, player)
			return true
		"shout_berserk":
			_execute_shout_berserk(ability, player)
			return true
		"shout_rage_incarnate":
			_execute_shout_rage_incarnate(ability, player)
			return true

		# ============================================
		# ROAR TREE
		# ============================================
		"roar":
			_execute_roar(ability, player)
			return true
		"roar_intimidate":
			_execute_roar_intimidate(ability, player)
			return true
		"roar_crushing":
			_execute_roar_crushing(ability, player)
			return true
		"roar_enrage":
			_execute_roar_enrage(ability, player)
			return true
		"roar_blood_rage":
			_execute_roar_blood_rage(ability, player)
			return true

		# ============================================
		# THROW TREE
		# ============================================
		"throw_weapon":
			_execute_throw_weapon(ability, player)
			return true
		"throw_ricochet":
			_execute_throw_ricochet(ability, player)
			return true
		"throw_bladestorm":
			_execute_throw_bladestorm(ability, player)
			return true
		"throw_grapple":
			_execute_throw_grapple(ability, player)
			return true
		"throw_impaler":
			_execute_throw_impaler(ability, player)
			return true

		# ============================================
		# TAUNT TREE
		# ============================================
		"taunt":
			_execute_taunt(ability, player)
			return true
		"taunt_fortify":
			_execute_taunt_fortify(ability, player)
			return true
		"taunt_unstoppable":
			_execute_taunt_unstoppable(ability, player)
			return true
		"taunt_counter":
			_execute_taunt_counter(ability, player)
			return true
		"taunt_vengeance":
			_execute_taunt_vengeance(ability, player)
			return true

		# ============================================
		# EXECUTE TREE
		# ============================================
		"execute":
			_execute_execute(ability, player)
			return true
		"execute_reaper":
			_execute_execute_reaper(ability, player)
			return true
		"execute_harvest":
			_execute_execute_harvest(ability, player)
			return true
		"execute_brutal":
			_execute_execute_brutal(ability, player)
			return true
		"execute_decapitate":
			_execute_execute_decapitate(ability, player)
			return true

		# ============================================
		# BLOCK TREE
		# ============================================
		"block":
			_execute_block(ability, player)
			return true
		"block_reflect":
			_execute_block_reflect(ability, player)
			return true
		"block_mirror":
			_execute_block_mirror(ability, player)
			return true
		"block_parry":
			_execute_block_parry(ability, player)
			return true
		"block_riposte":
			_execute_block_riposte(ability, player)
			return true

		# ============================================
		# IMPALE TREE
		# ============================================
		"impale":
			_execute_impale(ability, player)
			return true
		"impale_skewer":
			_execute_impale_skewer(ability, player)
			return true
		"impale_kebab":
			_execute_impale_kebab(ability, player)
			return true
		"impale_pin":
			_execute_impale_pin(ability, player)
			return true
		"impale_crucify":
			_execute_impale_crucify(ability, player)
			return true

		# ============================================
		# UPPERCUT TREE
		# ============================================
		"uppercut":
			_execute_uppercut(ability, player)
			return true
		"uppercut_juggle":
			_execute_uppercut_juggle(ability, player)
			return true
		"uppercut_air_combo":
			_execute_uppercut_air_combo(ability, player)
			return true
		"uppercut_grab":
			_execute_uppercut_grab(ability, player)
			return true
		"uppercut_piledriver":
			_execute_uppercut_piledriver(ability, player)
			return true

		# ============================================
		# COMBO TREE
		# ============================================
		"combo_strike":
			_execute_combo_strike(ability, player)
			return true
		"combo_chain":
			_execute_combo_chain(ability, player)
			return true
		"combo_infinite":
			_execute_combo_infinite(ability, player)
			return true
		"combo_finisher":
			_execute_combo_finisher(ability, player)
			return true
		"combo_ultimate":
			_execute_combo_ultimate(ability, player)
			return true

		# ============================================
		# STOMP TREE
		# ============================================
		"stomp":
			_execute_stomp(ability, player)
			return true
		"stomp_quake":
			_execute_stomp_quake(ability, player)
			return true
		"stomp_tectonic":
			_execute_stomp_tectonic(ability, player)
			return true
		"stomp_thunder":
			_execute_stomp_thunder(ability, player)
			return true
		"stomp_thunderous":
			_execute_stomp_thunderous(ability, player)
			return true

		# ============================================
		# PARRY TREE
		# ============================================
		"parry":
			_execute_parry(ability, player)
			return true
		"parry_counter":
			_execute_parry_counter(ability, player)
			return true
		"parry_riposte":
			_execute_parry_riposte(ability, player)
			return true
		"parry_deflect":
			_execute_parry_deflect(ability, player)
			return true
		"parry_mirror":
			_execute_parry_mirror(ability, player)
			return true

		# ============================================
		# RAMPAGE TREE
		# ============================================
		"rampage":
			_execute_rampage(ability, player)
			return true
		"rampage_frenzy":
			_execute_rampage_frenzy(ability, player)
			return true
		"rampage_bloodlust":
			_execute_rampage_bloodlust(ability, player)
			return true
		"rampage_fury":
			_execute_rampage_fury(ability, player)
			return true
		"rampage_unstoppable":
			_execute_rampage_unstoppable(ability, player)
			return true

		# ============================================
		# LEGACY MELEE (for backwards compatibility)
		# ============================================
		"seismic_slam":
			_execute_seismic_slam(ability, player)
			return true
		"blade_rush":
			_execute_blade_rush(ability, player)
			return true
		"earthquake":
			_execute_earthquake(ability, player)
			return true
		"bladestorm":
			_execute_bladestorm(ability, player)
			return true
		"omnislash":
			_execute_omnislash(ability, player)
			return true
		"avatar_of_war":
			_execute_avatar_of_war(ability, player)
			return true
		"divine_shield":
			_execute_divine_shield(ability, player)
			return true

	return false

# ============================================
# CLEAVE TREE IMPLEMENTATIONS
# ============================================

func _execute_cleave(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.radius * 2.5)
	var direction = target.global_position - player.global_position if target else _get_attack_direction(player)
	direction = direction.normalized()

	var enemies = _get_enemies_in_arc(player.global_position, direction, ability.radius, PI * 0.85)
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)

	var effect = _spawn_effect("cleave", player.global_position)
	if effect and "direction" in effect:
		effect.direction = direction
	_play_sound("swing")
	_screen_shake("small")

func _execute_cleave_executioner(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: 2x damage to enemies below 50% HP"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.radius * 2.5)
	var direction = target.global_position - player.global_position if target else _get_attack_direction(player)
	direction = direction.normalized()

	var enemies = _get_enemies_in_arc(player.global_position, direction, ability.radius, PI * 0.85)
	for enemy in enemies:
		var final_damage = damage
		# Executioner bonus: 2x damage to low HP enemies
		if enemy.has_method("get_health_percent") and enemy.get_health_percent() < 0.5:
			final_damage *= 2.0
		_deal_damage_to_enemy(enemy, final_damage)

	# Use base cleave effect
	var effect = _spawn_effect("cleave", player.global_position)
	if effect and "direction" in effect:
		effect.direction = direction
	_play_sound("swing")
	_screen_shake("small")

func _execute_cleave_guillotine(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Execute enemies below 20% HP - uses base cleave effect"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.radius * 2.5)
	var direction = target.global_position - player.global_position if target else _get_attack_direction(player)
	direction = direction.normalized()

	var enemies = _get_enemies_in_arc(player.global_position, direction, ability.radius, PI * 0.85)
	for enemy in enemies:
		# SIGNATURE: Execute threshold
		if enemy.has_method("get_health_percent") and enemy.get_health_percent() < 0.2:
			# Instant kill
			if enemy.has_method("take_damage"):
				enemy.take_damage(99999.0)
		else:
			_deal_damage_to_enemy(enemy, damage)

	# Use base cleave effect
	var effect = _spawn_effect("cleave", player.global_position)
	if effect and "direction" in effect:
		effect.direction = direction
	_play_sound("swing")
	_screen_shake("large")
	_impact_pause(0.1)

func _execute_cleave_crowd(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Cleave with slow"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.radius * 2.5)
	var direction = target.global_position - player.global_position if target else _get_attack_direction(player)
	direction = direction.normalized()

	var enemies = _get_enemies_in_arc(player.global_position, direction, ability.radius, PI * 0.85)
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_slow(enemy, ability.slow_percent, ability.slow_duration)

	# Use base cleave effect
	var effect = _spawn_effect("cleave", player.global_position)
	if effect and "direction" in effect:
		effect.direction = direction
	_play_sound("swing")
	_screen_shake("small")

func _execute_cleave_shockwave(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Massive knockback wave with stun"""
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_stun(enemy, ability.stun_duration)
		_apply_slow(enemy, ability.slow_percent, ability.slow_duration)

		# SIGNATURE: Massive knockback
		var knockback_dir = (enemy.global_position - player.global_position).normalized()
		_apply_knockback(enemy, knockback_dir, ability.knockback_force)

	# Use base cleave effect
	_spawn_effect("cleave", player.global_position)
	_play_sound("swing")
	_screen_shake("large")
	_impact_pause(0.1)

# ============================================
# BASH TREE IMPLEMENTATIONS
# ============================================

func _execute_shield_bash(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, 150.0)
	var effect_pos = player.global_position

	if target:
		_deal_damage_to_enemy(target, damage)
		_apply_stun(target, ability.stun_duration)
		var knockback_dir = (target.global_position - player.global_position).normalized()
		_apply_knockback(target, knockback_dir, ability.knockback_force)
		effect_pos = target.global_position

	var effect = _spawn_effect("shield_bash", effect_pos)
	if effect and effect.has_method("setup"):
		effect.setup(80.0, 0.35)
	_play_sound("shield_hit")
	_screen_shake("small")

func _execute_bash_shockwave(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: AoE stun"""
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_stun(enemy, ability.stun_duration)
		var knockback_dir = (enemy.global_position - player.global_position).normalized()
		_apply_knockback(enemy, knockback_dir, ability.knockback_force)

	var effect = _spawn_effect("bash_shockwave", player.global_position)
	if effect and effect.has_method("setup"):
		effect.setup(ability.radius, 0.5)
	_play_sound("shield_hit")
	_screen_shake("medium")

func _execute_bash_earthquake(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Massive AoE stun with launch"""
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_stun(enemy, ability.stun_duration)
		# SIGNATURE: Launch enemies upward
		var knockback_dir = (enemy.global_position - player.global_position).normalized()
		knockback_dir.y = -0.5  # Add upward component
		_apply_knockback(enemy, knockback_dir.normalized(), ability.knockback_force)

	var effect = _spawn_effect("bash_earthquake", player.global_position)
	if effect and effect.has_method("setup"):
		effect.setup(ability.radius, 0.8)
	_play_sound("shield_hit")
	_screen_shake("large")
	_impact_pause(0.15)

func _execute_bash_lockdown(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Extended single-target stun"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, 150.0)
	var effect_pos = player.global_position

	if target:
		_deal_damage_to_enemy(target, damage)
		_apply_stun(target, ability.stun_duration)
		effect_pos = target.global_position

	var effect = _spawn_effect("bash_lockdown", effect_pos)
	if effect and effect.has_method("setup"):
		effect.setup(60.0, 0.6)
	_play_sound("shield_hit")
	_screen_shake("small")

func _execute_bash_petrify(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Petrify with damage amp"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, 150.0)
	var effect_pos = player.global_position

	if target:
		_deal_damage_to_enemy(target, damage)
		_apply_stun(target, ability.stun_duration)
		# SIGNATURE: Mark as petrified for 2x damage
		if target.has_method("apply_petrify"):
			target.apply_petrify(ability.stun_duration)
		elif target.has_method("apply_vulnerability"):
			target.apply_vulnerability(2.0, ability.stun_duration)
		effect_pos = target.global_position

	var effect = _spawn_effect("bash_petrify", effect_pos)
	if effect and effect.has_method("setup"):
		effect.setup(80.0, 0.7)
	_play_sound("shield_hit")
	_screen_shake("medium")
	_impact_pause(0.1)

# ============================================
# CHARGE TREE IMPLEMENTATIONS
# ============================================

func _execute_charge(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, 300.0)
	if target:
		direction = (target.global_position - player.global_position).normalized()

	_dash_player(player, direction, ability.range_distance, 0.2)

	# Hit first enemy in path
	var end_pos = player.global_position + direction * ability.range_distance
	var hit_enemy = _get_nearest_enemy(end_pos, 50.0)
	if hit_enemy:
		_deal_damage_to_enemy(hit_enemy, damage)

	_spawn_effect("charge", player.global_position)
	_play_sound("dash")

func _execute_charge_trample(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Hit all enemies in path"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, 400.0)
	if target:
		direction = (target.global_position - player.global_position).normalized()

	# Get all enemies in charge path
	var path_enemies = _get_enemies_in_arc(player.global_position, direction, ability.range_distance, PI * 0.3)
	for enemy in path_enemies:
		_deal_damage_to_enemy(enemy, damage)

	_dash_player(player, direction, ability.range_distance, 0.2)
	# Use base charge effect
	_spawn_effect("charge", player.global_position)
	_play_sound("dash")
	_screen_shake("small")

func _execute_charge_stampede(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: 3x distance with fire trail"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	# Get all enemies in long charge path
	var path_enemies = _get_enemies_in_arc(player.global_position, direction, ability.range_distance, PI * 0.25)
	for enemy in path_enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_burn(enemy, 3.0)

	_dash_player(player, direction, ability.range_distance, 0.4)

	# Use base charge effect
	_spawn_effect("charge", player.global_position)
	_play_sound("dash")
	_screen_shake("medium")

func _execute_charge_shield(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Immune during charge"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	# Grant invulnerability
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(ability.invulnerability_duration)

	var hit_enemy = _get_nearest_enemy(player.global_position + direction * ability.range_distance, 80.0)
	if hit_enemy:
		_deal_damage_to_enemy(hit_enemy, damage)
		var knockback_dir = (hit_enemy.global_position - player.global_position).normalized()
		_apply_knockback(hit_enemy, knockback_dir, ability.knockback_force)

	_dash_player(player, direction, ability.range_distance, 0.25)
	# Use base charge effect
	_spawn_effect("charge", player.global_position)
	_play_sound("dash")

func _execute_charge_unstoppable(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Stun all, destroy projectiles"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	# Grant invulnerability
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(ability.invulnerability_duration)

	# SIGNATURE: Hit and stun ALL enemies in path
	var path_enemies = _get_enemies_in_arc(player.global_position, direction, ability.range_distance, PI * 0.4)
	for enemy in path_enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_stun(enemy, ability.stun_duration)
		var knockback_dir = (enemy.global_position - player.global_position).normalized()
		_apply_knockback(enemy, knockback_dir, ability.knockback_force)

	# SIGNATURE: Destroy nearby projectiles
	var projectiles = player.get_tree().get_nodes_in_group("enemy_projectiles")
	for proj in projectiles:
		if is_instance_valid(proj) and player.global_position.distance_to(proj.global_position) < 150.0:
			proj.queue_free()

	_dash_player(player, direction, ability.range_distance, 0.3)
	# Use base charge effect
	_spawn_effect("charge", player.global_position)
	_play_sound("dash")
	_screen_shake("large")
	_impact_pause(0.1)

# ============================================
# WHIRLWIND TREE IMPLEMENTATIONS (formerly Spin Tree)
# ============================================

func _execute_whirlwind_base(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base Whirlwind - sustained spinning attack"""
	var damage = _get_damage(ability)

	# Allow player movement with -50% speed during whirlwind
	if ActiveAbilityManager:
		ActiveAbilityManager.start_channeling(ability.duration, 0.5)

	# Spawn whirlwind effect that follows player and deals damage over time
	var whirlwind = _spawn_effect("whirlwind", player.global_position)
	if whirlwind and whirlwind.has_method("setup"):
		whirlwind.setup(ability.duration, ability.radius, damage, 1.0)
	else:
		# Fallback: instant damage to all enemies in radius
		var enemies = _get_enemies_in_radius(player.global_position, ability.radius)
		for enemy in enemies:
			_deal_damage_to_enemy(enemy, damage)

	_play_sound("whirlwind")
	_screen_shake("small")

func _execute_spin_vortex(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Sustained spinning with pull - creates a vortex that pulls enemies"""
	var damage = _get_damage(ability)

	# Allow player movement with -50% speed during vortex
	if ActiveAbilityManager:
		ActiveAbilityManager.start_channeling(ability.duration, 0.5)

	# Spawn base whirlwind visual on top of vortex (follows player)
	var base_whirl = _spawn_effect("whirlwind_pixel", player.global_position)
	if base_whirl and base_whirl.has_method("setup"):
		base_whirl.setup(ability.radius, ability.duration)
	if base_whirl and base_whirl.has_method("set_follow_target"):
		base_whirl.set_follow_target(player)

	# Spawn sustained vortex effect that pulls enemies over time (follows player)
	var vortex_scene = load("res://scripts/active_abilities/effects/vortex_effect.gd")
	if vortex_scene:
		var vortex = Node2D.new()
		vortex.set_script(vortex_scene)
		vortex.global_position = player.global_position
		player.get_parent().add_child(vortex)
		# Setup: duration, radius, damage per second, pull strength, follow target (player)
		vortex.setup(ability.duration, ability.radius, damage / ability.duration, 120.0, player)

	_spawn_effect("spin", player.global_position)
	_play_sound("whirlwind")

func _execute_spin_bladestorm(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Move freely while spinning - vortex follows player"""
	var damage = _get_damage(ability)

	# Spawn base whirlwind visual that follows player
	var base_whirl = _spawn_effect("whirlwind_pixel", player.global_position)
	if base_whirl and base_whirl.has_method("setup"):
		base_whirl.setup(ability.radius, ability.duration)
	if base_whirl and base_whirl.has_method("set_follow_target"):
		base_whirl.set_follow_target(player)

	# Spawn sustained vortex effect that follows the player and pulls enemies
	var vortex_scene = load("res://scripts/active_abilities/effects/vortex_effect.gd")
	if vortex_scene:
		var vortex = Node2D.new()
		vortex.set_script(vortex_scene)
		vortex.global_position = player.global_position
		player.get_parent().add_child(vortex)
		# Setup: duration, radius, damage per second, pull strength, follow target (player)
		# Stronger pull and follows player for bladestorm
		vortex.setup(ability.duration, ability.radius, damage / ability.duration, 180.0, player)

	# Trigger bladestorm animation on player if available
	if player.has_method("start_bladestorm"):
		player.start_bladestorm(ability.duration)

	_spawn_effect("spin", player.global_position)
	_play_sound("whirlwind")
	_screen_shake("small")

func _execute_spin_deflect(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Deflect projectiles - uses base spin effect"""
	var damage = _get_damage(ability)

	# Allow player movement with -50% speed during deflect
	if ActiveAbilityManager:
		ActiveAbilityManager.start_channeling(ability.duration, 0.5)

	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)

	# Enable projectile deflection
	if player.has_method("enable_deflect"):
		player.enable_deflect(ability.duration)

	# Use base spin effect
	_spawn_effect("spin", player.global_position)
	_play_sound("swing")

func _execute_spin_mirror(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Reflected projectiles home in - uses base spin effect"""
	var damage = _get_damage(ability)

	# Allow player movement with -50% speed during mirror dance
	if ActiveAbilityManager:
		ActiveAbilityManager.start_channeling(ability.duration, 0.5)

	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)

	# Grant invulnerability during dance
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(ability.invulnerability_duration)

	# SIGNATURE: Enable homing reflect
	if player.has_method("enable_mirror_dance"):
		player.enable_mirror_dance(ability.duration)

	# Use base spin effect
	_spawn_effect("spin", player.global_position)
	_play_sound("swing")
	_screen_shake("medium")

func _execute_spin_fiery(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Fire trail whirlwind"""
	var damage = _get_damage(ability)

	# Allow player movement with -50% speed during fiery whirlwind
	if ActiveAbilityManager:
		ActiveAbilityManager.start_channeling(ability.duration, 0.5)

	# Spawn base whirlwind effect
	var base_whirl = _spawn_effect("whirlwind_pixel", player.global_position)
	if base_whirl and base_whirl.has_method("setup"):
		base_whirl.setup(ability.radius, ability.duration)

	# Spawn flame effect
	var whirl = _spawn_effect("flame_whirlwind", player.global_position)
	if whirl and whirl.has_method("setup"):
		whirl.setup(player, damage, ability.radius, ability.duration)

	_play_sound("whirlwind")

func _execute_spin_inferno(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Massive fire tornado"""
	var damage = _get_damage(ability)

	# Allow player movement with -50% speed during inferno
	if ActiveAbilityManager:
		ActiveAbilityManager.start_channeling(ability.duration, 0.5)

	# Spawn base whirlwind effect
	var base_whirl = _spawn_effect("whirlwind_pixel", player.global_position)
	if base_whirl and base_whirl.has_method("setup"):
		base_whirl.setup(ability.radius, ability.duration)

	# SIGNATURE: Fire tornado with burning ground
	var tornado = _spawn_effect("inferno_tornado", player.global_position)
	if tornado and tornado.has_method("setup"):
		tornado.setup(ability.duration, ability.radius, damage, 1.0)

	_play_sound("inferno_tornado")
	_screen_shake("medium")

# ============================================
# LEGACY MELEE IMPLEMENTATIONS (stubs - delegate to main executor)
# ============================================

func _execute_ground_slam(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_ground_slam"):
		_main_executor._execute_ground_slam(ability, player)

func _execute_dash_strike(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_dash_strike"):
		_main_executor._execute_dash_strike(ability, player)

func _execute_whirlwind(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_whirlwind"):
		_main_executor._execute_whirlwind(ability, player)

func _execute_seismic_slam(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_seismic_slam"):
		_main_executor._execute_seismic_slam(ability, player)

func _execute_savage_leap(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_savage_leap"):
		_main_executor._execute_savage_leap(ability, player)

func _execute_blade_rush(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_blade_rush"):
		_main_executor._execute_blade_rush(ability, player)

func _execute_battle_cry(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_battle_cry"):
		_main_executor._execute_battle_cry(ability, player)

func _execute_earthquake(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_earthquake"):
		_main_executor._execute_earthquake(ability, player)

func _execute_bladestorm(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_bladestorm"):
		_main_executor._execute_bladestorm(ability, player)

func _execute_omnislash(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_omnislash"):
		_main_executor._execute_omnislash(ability, player)

func _execute_avatar_of_war(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_avatar_of_war"):
		_main_executor._execute_avatar_of_war(ability, player)

func _execute_divine_shield(ability: ActiveAbilityData, player: Node2D) -> void:
	if _main_executor and _main_executor.has_method("_execute_divine_shield"):
		_main_executor._execute_divine_shield(ability, player)

# ============================================
# SLAM TREE IMPLEMENTATIONS
# ============================================

func _execute_slam_seismic(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Aftershock waves travel outward"""
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_stun(enemy, ability.stun_duration)

	# Spawn pixelated wave effect
	var effect = _spawn_effect("seismic_wave", player.global_position)
	if effect and effect.has_method("setup"):
		effect.setup(ability.radius, ability.duration)
	_play_sound("seismic_slam")
	_screen_shake("medium")

func _execute_slam_earthquake(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Screen-wide seismic devastation"""
	var damage = _get_damage(ability)

	# SIGNATURE: Damage the entire battlefield over time - use pixelated earthquake effect
	var earthquake_scene = load("res://scripts/active_abilities/effects/earthquake_pixel_effect.gd")
	if earthquake_scene:
		var quake = Node2D.new()
		quake.set_script(earthquake_scene)
		quake.global_position = player.global_position
		player.get_parent().add_child(quake)
		# Setup: damage, radius, duration, stun_duration
		quake.setup(damage, ability.radius, ability.duration, ability.stun_duration)

	_play_sound("earthquake")
	_screen_shake("large")
	_impact_pause(0.2)

func _execute_slam_crater(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Leave burning ground"""
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_burn(enemy, ability.duration)

	# Spawn burning crater
	var crater = _spawn_effect("burning_crater", player.global_position)
	if crater and crater.has_method("setup"):
		crater.setup(damage * 0.2, ability.radius, ability.duration)

	_play_sound("ground_slam")
	_screen_shake("small")

func _execute_slam_meteor(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Leap and crash like a meteor"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	var target_pos = player.global_position + direction * ability.range_distance
	if target:
		target_pos = target.global_position

	# SIGNATURE: Invulnerable leap
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(ability.invulnerability_duration)

	# Leap to target
	_dash_player(player, (target_pos - player.global_position).normalized(),
		player.global_position.distance_to(target_pos), 0.5)

	# Massive impact
	var enemies = _get_enemies_in_radius(target_pos, ability.radius)
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_stun(enemy, ability.stun_duration)
		_apply_knockback(enemy, (enemy.global_position - target_pos).normalized(), ability.knockback_force)

	# Spawn pixelated meteor slam effect
	var effect = _spawn_effect("meteor_slam", target_pos)
	if effect and effect.has_method("setup"):
		effect.setup(ability.radius, 0.8)
	_play_sound("meteor_impact")
	_screen_shake("large")
	_impact_pause(0.25)

# ============================================
# DASH TREE IMPLEMENTATIONS
# ============================================

func _execute_dash_blade_rush(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Chain 3 dashes to nearest enemies"""
	var damage = _get_damage(ability)
	var dash_duration = 0.12
	var dash_distance = ability.range_distance

	# Find up to 3 nearest enemies within range
	var all_enemies = _get_enemies_in_radius(player.global_position, dash_distance)
	all_enemies.sort_custom(func(a, b):
		return player.global_position.distance_to(a.global_position) < player.global_position.distance_to(b.global_position)
	)
	var target_enemies = all_enemies.slice(0, 3)

	# Track which enemies we've already targeted (to find new ones each dash)
	var targeted_enemies: Array = []

	# Chain 3 dashes using a tween for timing
	var tween = player.create_tween()

	for i in range(3):
		# Capture index for closure
		var dash_index = i
		tween.tween_callback(func():
			var start_pos = player.global_position
			var end_pos: Vector2

			# Find nearest untargeted enemy from current position
			var current_enemies = _get_enemies_in_radius(start_pos, dash_distance)
			current_enemies.sort_custom(func(a, b):
				return start_pos.distance_to(a.global_position) < start_pos.distance_to(b.global_position)
			)

			var target_enemy: Node2D = null
			for enemy in current_enemies:
				if enemy not in targeted_enemies and is_instance_valid(enemy):
					target_enemy = enemy
					targeted_enemies.append(enemy)
					break

			if target_enemy:
				# Dash to enemy position (slightly in front)
				var dir_to_enemy = (target_enemy.global_position - start_pos).normalized()
				var dist_to_enemy = start_pos.distance_to(target_enemy.global_position)
				end_pos = start_pos + dir_to_enemy * min(dist_to_enemy - 20, dash_distance)
			else:
				# No enemy found, dash in attack direction
				var direction = _get_attack_direction(player)
				end_pos = start_pos + direction * dash_distance

			# Clamp to arena bounds
			end_pos.x = clamp(end_pos.x, -60, 1596)
			end_pos.y = clamp(end_pos.y, 40, 1342)

			# Spawn effect at start
			_spawn_effect("blade_rush", start_pos)

			# Damage enemies near the dash endpoint
			var hit_enemies = _get_enemies_in_radius(end_pos, 60)
			for enemy in hit_enemies:
				_deal_damage_to_enemy(enemy, damage)

			# Move player
			var dash_tween = player.create_tween()
			dash_tween.tween_property(player, "global_position", end_pos, dash_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

			_play_sound("dash_strike")
		)
		# Wait for dash to complete before next one
		tween.tween_interval(dash_duration + 0.05)

func _execute_dash_omnislash(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Dash between enemies with anime katana slashes"""
	var damage = _get_damage(ability)

	# SIGNATURE: Invulnerable during omnislash
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(ability.invulnerability_duration)

	# Get up to 8 enemies, sorted by distance
	var enemies = _get_enemies_in_radius(player.global_position, ability.range_distance)
	enemies.sort_custom(func(a, b):
		return player.global_position.distance_to(a.global_position) < player.global_position.distance_to(b.global_position)
	)
	enemies = enemies.slice(0, 8)

	if enemies.size() > 0:
		# Spawn the omnislash sequence effect which handles all the dashing and slashing
		var sequence = _spawn_effect("omnislash_sequence", player.global_position)
		if sequence and sequence.has_method("setup"):
			sequence.setup(player, enemies, damage, 3)  # 3 hits per enemy
	else:
		# No enemies - just do a cool pose effect
		_spawn_effect("omnislash", player.global_position)

	_play_sound("omnislash")
	_screen_shake("large")

func _execute_dash_afterimage(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Leave exploding clone"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var start_pos = player.global_position

	# Dash
	_dash_player(player, direction, ability.range_distance, 0.2)

	# Spawn exploding clone at start
	var clone = _spawn_effect("afterimage", start_pos)
	if clone and clone.has_method("setup"):
		clone.setup(damage, ability.radius, ability.duration)

	_play_sound("dash_strike")

func _execute_dash_shadow_legion(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Create 4 shadow clones that attack"""
	var damage = _get_damage(ability)

	# SIGNATURE: Spawn 4 shadow clones
	for i in range(4):
		var offset = Vector2(cos(i * TAU / 4), sin(i * TAU / 4)) * 50.0
		var clone = _spawn_effect("shadow_clone", player.global_position + offset)
		if clone and clone.has_method("setup"):
			clone.setup(player, damage * 0.25, ability.duration)

	_spawn_effect("shadow_legion", player.global_position)
	_play_sound("shadow_legion")
	_screen_shake("small")

# ============================================
# OLD WHIRLWIND TREE IMPLEMENTATIONS (deprecated - kept for backwards compatibility)
# ============================================

func _execute_whirlwind_vacuum(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Pull enemies while spinning"""
	var damage = _get_damage(ability)

	# Spawn base whirlwind effect
	var base_whirl = _spawn_effect("whirlwind_pixel", player.global_position)
	if base_whirl and base_whirl.has_method("setup"):
		base_whirl.setup(ability.radius, ability.duration)

	# Spawn vacuum effect
	var whirl = _spawn_effect("vacuum_spin", player.global_position)
	if whirl and whirl.has_method("setup"):
		whirl.setup(player, damage, ability.radius, ability.duration, ability.knockback_force)

	_play_sound("whirlwind")

func _execute_whirlwind_singularity(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Become a black hole"""
	var damage = _get_damage(ability)

	# Spawn base whirlwind effect
	var base_whirl = _spawn_effect("whirlwind_pixel", player.global_position)
	if base_whirl and base_whirl.has_method("setup"):
		base_whirl.setup(ability.radius, ability.duration)

	# SIGNATURE: Massive pull, damage increases as enemies get closer
	var singularity = _spawn_effect("singularity", player.global_position)
	if singularity and singularity.has_method("setup"):
		singularity.setup(player, damage, ability.radius, ability.duration, ability.knockback_force)

	_play_sound("singularity")
	_screen_shake("medium")

func _execute_whirlwind_flame(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Fire trail whirlwind"""
	var damage = _get_damage(ability)

	# Spawn base whirlwind effect
	var base_whirl = _spawn_effect("whirlwind_pixel", player.global_position)
	if base_whirl and base_whirl.has_method("setup"):
		base_whirl.setup(ability.radius, ability.duration)

	# Spawn flame effect
	var whirl = _spawn_effect("flame_whirlwind", player.global_position)
	if whirl and whirl.has_method("setup"):
		whirl.setup(player, damage, ability.radius, ability.duration)

	_play_sound("whirlwind")

func _execute_whirlwind_inferno(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Massive fire tornado"""
	var damage = _get_damage(ability)

	# Spawn base whirlwind effect
	var base_whirl = _spawn_effect("whirlwind_pixel", player.global_position)
	if base_whirl and base_whirl.has_method("setup"):
		base_whirl.setup(ability.radius, ability.duration)

	# SIGNATURE: Fire tornado with burning ground
	var tornado = _spawn_effect("inferno_tornado", player.global_position)
	if tornado and tornado.has_method("setup"):
		tornado.setup(ability.duration, ability.radius, damage, 1.0)

	_play_sound("inferno_tornado")
	_screen_shake("medium")

# ============================================
# LEAP TREE IMPLEMENTATIONS
# ============================================

func _execute_leap_tremor(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Stun on landing"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	var target_pos = target.global_position if target else player.global_position + _get_attack_direction(player) * ability.range_distance

	# Leap
	_dash_player(player, (target_pos - player.global_position).normalized(),
		player.global_position.distance_to(target_pos), 0.4)

	# Impact with stun
	var enemies = _get_enemies_in_radius(target_pos, ability.radius)
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_stun(enemy, ability.stun_duration)

	# Spawn base landing effect first, then tremor effect on top
	_spawn_effect("savage_leap", target_pos)
	_spawn_effect("tremor_leap", target_pos)
	_play_sound("savage_leap")
	_screen_shake("medium")

func _execute_leap_extinction(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Meteors on landing"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	var target_pos = target.global_position if target else player.global_position + _get_attack_direction(player) * ability.range_distance

	# SIGNATURE: Invulnerable leap
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(ability.invulnerability_duration)

	# Leap
	_dash_player(player, (target_pos - player.global_position).normalized(),
		player.global_position.distance_to(target_pos), 0.5)

	# Impact
	var enemies = _get_enemies_in_radius(target_pos, ability.radius)
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_stun(enemy, ability.stun_duration)

	# SIGNATURE: Spawn 4 meteors around impact
	for i in range(4):
		var offset = Vector2(cos(i * TAU / 4), sin(i * TAU / 4)) * 100.0
		_spawn_effect("meteor_strike", target_pos + offset)

	# Layer effects: base landing + tremor shockwave + extinction event
	_spawn_effect("savage_leap", target_pos)
	_spawn_effect("tremor_leap", target_pos)
	_spawn_effect("extinction_event", target_pos)
	_play_sound("extinction_event")
	_screen_shake("large")
	_impact_pause(0.3)

func _execute_leap_predator(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Gain attack speed after leap"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)
	var target_pos = target.global_position if target else player.global_position + _get_attack_direction(player) * ability.range_distance

	# Leap
	_dash_player(player, (target_pos - player.global_position).normalized(),
		player.global_position.distance_to(target_pos), 0.4)

	# Impact
	var enemies = _get_enemies_in_radius(target_pos, ability.radius)
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)

	# Apply attack speed buff
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("predator_pounce", ability.duration, {
			"attack_speed_bonus": 0.3
		})

	# Spawn base landing effect first, then predator effect on top
	_spawn_effect("savage_leap", target_pos)
	_spawn_effect("predator_leap", target_pos)
	_play_sound("savage_leap")

func _execute_leap_apex(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Chain leaps with healing"""
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.range_distance)
	enemies = enemies.slice(0, 3)  # Max 3 targets

	var kills = 0
	for enemy in enemies:
		if is_instance_valid(enemy):
			# Leap to each target
			_dash_player(player, (enemy.global_position - player.global_position).normalized(),
				player.global_position.distance_to(enemy.global_position), 0.2)

			_deal_damage_to_enemy(enemy, damage)
			# Layer effects: predator pounce + apex strike for each hit
			_spawn_effect("predator_leap", enemy.global_position)
			_spawn_effect("apex_strike", enemy.global_position)

			# Check for kill (simplified)
			if enemy.has_method("is_dead") and enemy.is_dead():
				kills += 1

	# SIGNATURE: Heal per kill
	if kills > 0 and player.has_method("heal"):
		var max_hp = player.max_hp if "max_hp" in player else 100.0
		player.heal(max_hp * 0.15 * kills)

	_play_sound("apex_predator")
	_screen_shake("medium")

# ============================================
# SHOUT TREE IMPLEMENTATIONS
# ============================================

func _execute_shout_rallying(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Team buff aura"""
	var aura = _spawn_effect("rallying_cry", player.global_position)
	if aura and aura.has_method("setup"):
		aura.setup(player, ability.radius, ability.duration)

	# Apply buff to player
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("rallying_cry", ability.duration, {
			"damage_bonus": 0.25,
			"move_speed_bonus": 0.15
		})

	_play_sound("battle_cry")

func _execute_shout_warlord(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Massive buff + enemy fear"""
	# SIGNATURE: Fear enemies
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)
	for enemy in enemies:
		if enemy.has_method("apply_fear"):
			enemy.apply_fear(2.0)

	# Massive buff
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("warlords_command", ability.duration, {
			"damage_bonus": 0.5,
			"attack_speed_bonus": 0.3,
			"damage_reduction": 0.2
		})

	_spawn_effect("warlords_command", player.global_position)
	_play_sound("warlords_command")
	_screen_shake("medium")

func _execute_shout_berserk(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: More damage, take more damage"""
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("berserker_rage", ability.duration, {
			"damage_bonus": 0.5,
			"damage_taken_multiplier": 1.25
		})

	_spawn_effect("berserker_rage", player.global_position)
	_play_sound("battle_cry")

func _execute_shout_rage_incarnate(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Transform, immune to CC, drain HP"""
	# SIGNATURE: Rage transformation
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("rage_incarnate", ability.duration, {
			"damage_bonus": 1.0,
			"cc_immune": true,
			"hp_drain_percent": 0.03
		})

	_spawn_effect("rage_incarnate", player.global_position)
	_play_sound("rage_incarnate")
	_screen_shake("large")

# ============================================
# ROAR TREE IMPLEMENTATIONS
# ============================================

func _execute_roar(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Terrifying roar that fears enemies briefly"""
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		# Apply fear - enemies flee
		if enemy.has_method("apply_fear"):
			enemy.apply_fear(ability.duration)
		elif enemy.has_method("apply_knockback"):
			# Fallback: strong knockback away from player
			var dir = (enemy.global_position - player.global_position).normalized()
			_apply_knockback(enemy, dir, 300.0)

	_spawn_effect("roar", player.global_position)
	_play_sound("roar")
	_screen_shake("medium")

func _execute_roar_intimidate(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Feared enemies deal 30% less damage"""
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		# Apply fear
		if enemy.has_method("apply_fear"):
			enemy.apply_fear(ability.duration * 0.4)  # Shorter fear
		elif enemy.has_method("apply_knockback"):
			var dir = (enemy.global_position - player.global_position).normalized()
			_apply_knockback(enemy, dir, 250.0)

		# Apply damage reduction debuff
		if enemy.has_method("apply_damage_reduction_debuff"):
			enemy.apply_damage_reduction_debuff(0.3, ability.duration)
		elif enemy.has_method("apply_weaken"):
			enemy.apply_weaken(0.3, ability.duration)

	_spawn_effect("roar", player.global_position)
	_play_sound("roar")
	_screen_shake("medium")

func _execute_roar_crushing(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Crushing presence aura - permanent debuff aura"""
	# Initial fear burst
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)
	for enemy in enemies:
		if enemy.has_method("apply_fear"):
			enemy.apply_fear(2.0)
		elif enemy.has_method("apply_knockback"):
			var dir = (enemy.global_position - player.global_position).normalized()
			_apply_knockback(enemy, dir, 350.0)

	# SIGNATURE: Create crushing presence aura
	var aura = _spawn_effect("crushing_presence", player.global_position)
	if aura and aura.has_method("setup"):
		# Aura that follows player, weakens enemies (-40% damage, -30% speed), fears on contact
		aura.setup(player, ability.radius, ability.duration, 0.4, 0.3)
	else:
		# Fallback: Apply buff to player that creates the aura effect
		if player.has_method("add_temporary_buff"):
			player.add_temporary_buff("crushing_presence", ability.duration, {
				"aura_radius": ability.radius,
				"enemy_damage_reduction": 0.4,
				"enemy_speed_reduction": 0.3,
				"fear_on_contact": true
			})

	_spawn_effect("roar", player.global_position)
	_play_sound("crushing_presence")
	_screen_shake("large")
	_impact_pause(0.15)

func _execute_roar_enrage(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Roar buffs your damage by 40%"""
	# Fear enemies first
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)
	for enemy in enemies:
		if enemy.has_method("apply_fear"):
			enemy.apply_fear(1.5)
		elif enemy.has_method("apply_knockback"):
			var dir = (enemy.global_position - player.global_position).normalized()
			_apply_knockback(enemy, dir, 200.0)

	# Apply damage buff to self
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("enraging_roar", ability.duration, {
			"damage_bonus": 0.4
		})

	_spawn_effect("roar", player.global_position)
	_play_sound("roar")
	_screen_shake("medium")

func _execute_roar_blood_rage(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Blood rage - each hit increases power, lifesteal, attack speed"""
	# Fear enemies
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)
	for enemy in enemies:
		if enemy.has_method("apply_fear"):
			enemy.apply_fear(2.0)
		elif enemy.has_method("apply_knockback"):
			var dir = (enemy.global_position - player.global_position).normalized()
			_apply_knockback(enemy, dir, 300.0)

	# SIGNATURE: Blood rage buff - stacking damage, lifesteal, attack speed
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("blood_rage", ability.duration, {
			"damage_bonus_per_hit": 0.1,  # +10% per hit
			"max_damage_bonus": 1.0,       # Cap at +100%
			"lifesteal_percent": 0.15,     # 15% lifesteal
			"attack_speed_bonus": 0.25     # 25% attack speed
		})

	# Visual transformation
	if player.has_method("start_blood_rage"):
		player.start_blood_rage(ability.duration)

	_spawn_effect("blood_rage", player.global_position)
	_play_sound("blood_rage")
	_screen_shake("large")
	_impact_pause(0.2)

# ============================================
# THROW TREE IMPLEMENTATIONS
# ============================================

func _execute_throw_weapon(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Throw weapon at enemy for heavy damage"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	# Spawn thrown weapon projectile that flies to target
	var proj = _spawn_effect("throw_weapon", player.global_position)
	if proj and proj.has_method("setup"):
		var speed = ability.projectile_speed if ability.projectile_speed > 0 else 600.0
		proj.setup(player.global_position, target, damage, speed)
	else:
		# Fallback: instant damage to nearest
		if target:
			_deal_damage_to_enemy(target, damage)

	_play_sound("throw")
	_screen_shake("small")

func _execute_throw_ricochet(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Weapon bounces between 4 enemies"""
	var damage = _get_damage(ability)

	# Get enemies for the blade to bounce between
	var enemies = _get_enemies_in_radius(player.global_position, ability.range_distance * 1.5)

	# Sort by distance to prioritize nearest enemies first
	enemies.sort_custom(func(a, b):
		return player.global_position.distance_to(a.global_position) < player.global_position.distance_to(b.global_position)
	)

	# Limit to 4 bounce targets
	enemies = enemies.slice(0, 4)

	if enemies.size() > 0:
		var proj = _spawn_effect("ricochet_blade", player.global_position)
		if proj and proj.has_method("setup"):
			proj.setup(player.global_position, enemies, damage, 4)
	else:
		# No enemies - spawn effect anyway for visual feedback
		var direction = _get_attack_direction(player)
		var proj = _spawn_effect("ricochet_blade", player.global_position)
		if proj and proj.has_method("setup"):
			proj.setup(player.global_position, [], damage, 4)

	_play_sound("throw")

func _execute_throw_bladestorm(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Bouncing Throw Weapon of Storms
	Combines bouncing blade (4 enemies) with sustained orbiting blades (8 seconds)"""
	var damage = _get_damage(ability)

	# PART 1: Throw the bouncing blade at 4 enemies
	var enemies = _get_enemies_in_radius(player.global_position, ability.range_distance * 1.5)
	enemies.sort_custom(func(a, b):
		return player.global_position.distance_to(a.global_position) < player.global_position.distance_to(b.global_position)
	)
	enemies = enemies.slice(0, 4)

	if enemies.size() > 0:
		var ricochet = _spawn_effect("ricochet_blade", player.global_position)
		if ricochet and ricochet.has_method("setup"):
			ricochet.setup(player.global_position, enemies, damage, 4)

	# PART 2: Spawn sustained orbiting blades around player for 8 seconds
	var orbital_blades = _spawn_effect("sustained_orbital_blades", player.global_position)
	if orbital_blades and orbital_blades.has_method("setup"):
		var orbit_radius = ability.radius if ability.radius > 0 else 80.0
		var orbit_duration = ability.duration if ability.duration > 0 else 8.0
		var orbit_dps = damage * 0.5  # 50% of ability damage as DPS for the orbit
		orbital_blades.setup(player, orbit_dps, orbit_radius, orbit_duration)

	_play_sound("bladestorm")
	_screen_shake("medium")

func _execute_throw_grapple(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Throw weapon then pull yourself to it"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	var target_pos = player.global_position + direction * ability.range_distance
	if target:
		target_pos = target.global_position
		_deal_damage_to_enemy(target, damage)

	# Pull player to weapon location
	_dash_player(player, (target_pos - player.global_position).normalized(),
		player.global_position.distance_to(target_pos), 0.3)

	_spawn_effect("grapple_throw", player.global_position)
	_play_sound("grapple")

func _execute_throw_impaler(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Massive spear that pins enemies infinitely"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	# Get all enemies in line
	var enemies = _get_enemies_in_arc(player.global_position, direction, ability.range_distance, PI * 0.15)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_stun(enemy, ability.stun_duration)

	# Pull player to end point
	var end_pos = player.global_position + direction * ability.range_distance
	_dash_player(player, direction, ability.range_distance, 0.4)

	_spawn_effect("impaler", player.global_position)
	_play_sound("impale")
	_screen_shake("large")
	_impact_pause(0.15)

# ============================================
# TAUNT TREE IMPLEMENTATIONS
# ============================================

func _execute_taunt(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Force enemies to attack you for 3 seconds"""
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		if enemy.has_method("apply_taunt"):
			enemy.apply_taunt(player, ability.duration)
		elif enemy.has_method("set_target"):
			enemy.set_target(player)

	_spawn_effect("taunt", player.global_position)
	_play_sound("taunt")

func _execute_taunt_fortify(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Gain 40% damage reduction while taunted"""
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		if enemy.has_method("apply_taunt"):
			enemy.apply_taunt(player, ability.duration)
		elif enemy.has_method("set_target"):
			enemy.set_target(player)

	# Grant damage reduction
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("fortify", ability.duration, {
			"damage_reduction": 0.4
		})

	_spawn_effect("fortify_taunt", player.global_position)
	_play_sound("taunt")

func _execute_taunt_unstoppable(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Become immune to damage and CC"""
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		if enemy.has_method("apply_taunt"):
			enemy.apply_taunt(player, ability.duration)
		elif enemy.has_method("set_target"):
			enemy.set_target(player)

	# SIGNATURE: Full invulnerability
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(ability.invulnerability_duration)

	_spawn_effect("unstoppable", player.global_position)
	_play_sound("taunt")
	_screen_shake("medium")

func _execute_taunt_counter(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Auto-counter when hit during taunt"""
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		if enemy.has_method("apply_taunt"):
			enemy.apply_taunt(player, ability.duration)

	# Grant counter buff
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("counter_stance", ability.duration, {
			"counter_damage": damage,
			"counter_radius": ability.radius
		})

	_spawn_effect("counter_stance", player.global_position)
	_play_sound("taunt")

func _execute_taunt_vengeance(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Every hit causes explosion + lifesteal"""
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		if enemy.has_method("apply_taunt"):
			enemy.apply_taunt(player, ability.duration)

	# SIGNATURE: Vengeance buff
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("vengeance", ability.duration, {
			"explosion_damage": damage,
			"explosion_radius": ability.radius,
			"lifesteal_percent": 0.1
		})

	_spawn_effect("vengeance", player.global_position)
	_play_sound("vengeance")
	_screen_shake("medium")

# ============================================
# EXECUTE TREE IMPLEMENTATIONS
# ============================================

func _execute_execute(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: +100% damage to enemies below 30% HP"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		var final_damage = damage
		# Execute bonus
		if target.has_method("get_health_percent") and target.get_health_percent() < 0.3:
			final_damage *= 2.0
		_deal_damage_to_enemy(target, final_damage)

	_spawn_effect("execute", player.global_position)
	_play_sound("execute")
	_screen_shake("small")

func _execute_execute_reaper(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Instant kill enemies below 20% HP"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		if target.has_method("get_health_percent") and target.get_health_percent() < 0.2:
			# Instant kill
			if target.has_method("take_damage"):
				target.take_damage(99999.0)
		else:
			_deal_damage_to_enemy(target, damage)

	_spawn_effect("reaper_touch", player.global_position)
	_play_sound("execute")
	_screen_shake("medium")

func _execute_execute_harvest(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Kill below 25%, heal 20% per kill, reset CD"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		var killed = false
		if target.has_method("get_health_percent") and target.get_health_percent() < 0.25:
			if target.has_method("take_damage"):
				target.take_damage(99999.0)
				killed = true
		else:
			_deal_damage_to_enemy(target, damage)
			if target.has_method("is_dead") and target.is_dead():
				killed = true

		# SIGNATURE: Heal on kill
		if killed and player.has_method("heal"):
			var max_hp = player.max_hp if "max_hp" in player else 100.0
			player.heal(max_hp * 0.2)

	_spawn_effect("soul_harvest", player.global_position)
	_play_sound("soul_harvest")
	_screen_shake("medium")

func _execute_execute_brutal(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Massive damage, ignores armor on low HP"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		if target.has_method("get_health_percent") and target.get_health_percent() < 0.5:
			# Ignore armor
			if target.has_method("take_pure_damage"):
				target.take_pure_damage(damage)
			else:
				_deal_damage_to_enemy(target, damage * 1.5)
		else:
			_deal_damage_to_enemy(target, damage)

	_spawn_effect("brutal_strike", player.global_position)
	_play_sound("execute")
	_screen_shake("medium")

func _execute_execute_decapitate(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Guaranteed crit, 3x damage below 40%"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		var final_damage = damage * 2.0  # Guaranteed crit
		if target.has_method("get_health_percent") and target.get_health_percent() < 0.4:
			final_damage *= 3.0
		_deal_damage_to_enemy(target, final_damage)

	_spawn_effect("decapitate", player.global_position)
	_play_sound("decapitate")
	_screen_shake("large")
	_impact_pause(0.15)

# ============================================
# BLOCK TREE IMPLEMENTATIONS
# ============================================

func _execute_block(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Reduce incoming damage by 50%"""
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("block", ability.duration, {
			"damage_reduction": 0.5
		})

	_spawn_effect("block", player.global_position)
	_play_sound("block")

func _execute_block_reflect(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Also reflect projectiles"""
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("reflect_shield", ability.duration, {
			"damage_reduction": 0.5,
			"reflect_projectiles": true
		})

	_spawn_effect("reflect_shield", player.global_position)
	_play_sound("block")

func _execute_block_mirror(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: 100% damage reflection"""
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("mirror_shield", ability.duration, {
			"damage_reduction": 1.0,
			"damage_reflection": 1.0,
			"reflect_projectiles": true,
			"projectile_speed_multiplier": 2.0
		})

	_spawn_effect("mirror_shield", player.global_position)
	_play_sound("mirror_shield")
	_screen_shake("small")

func _execute_block_parry(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Brief window to negate damage and stun attacker"""
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("parry_block", ability.duration, {
			"damage_reduction": 1.0,
			"parry_stun": ability.stun_duration
		})

	_spawn_effect("parry", player.global_position)
	_play_sound("parry")

func _execute_block_riposte(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Perfect parry triggers devastating counter"""
	var damage = _get_damage(ability)

	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("riposte", ability.duration, {
			"damage_reduction": 1.0,
			"counter_damage": damage,
			"counter_stun": ability.stun_duration
		})

	_spawn_effect("riposte", player.global_position)
	_play_sound("riposte")
	_screen_shake("small")

# ============================================
# IMPALE TREE IMPLEMENTATIONS
# ============================================

func _execute_impale(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Thrust forward, impaling an enemy"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	# Get first enemy in thrust direction
	var enemies = _get_enemies_in_arc(player.global_position, direction, ability.range_distance, PI * 0.2)
	if enemies.size() > 0:
		_deal_damage_to_enemy(enemies[0], damage)

	_spawn_effect("impale", player.global_position)
	_play_sound("impale")
	_screen_shake("small")

func _execute_impale_skewer(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Pierce through up to 3 enemies"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	var enemies = _get_enemies_in_arc(player.global_position, direction, ability.range_distance, PI * 0.15)
	enemies = enemies.slice(0, 3)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)

	_spawn_effect("skewer", player.global_position)
	_play_sound("impale")
	_screen_shake("small")

func _execute_impale_kebab(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Carry enemies and slam them"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	var enemies = _get_enemies_in_arc(player.global_position, direction, ability.range_distance, PI * 0.2)
	enemies = enemies.slice(0, 5)

	# Move player forward (carrying enemies)
	_dash_player(player, direction, ability.range_distance * 0.5, 0.3)

	# Slam damage to all
	var slam_pos = player.global_position
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_stun(enemy, ability.stun_duration)
		# Move enemy to slam position
		if is_instance_valid(enemy):
			enemy.global_position = slam_pos + Vector2(randf_range(-50, 50), randf_range(-50, 50))

	# AoE at slam location
	var aoe_enemies = _get_enemies_in_radius(slam_pos, ability.radius)
	for enemy in aoe_enemies:
		if not enemies.has(enemy):
			_deal_damage_to_enemy(enemy, damage * 0.5)

	_spawn_effect("shish_kebab", slam_pos)
	_play_sound("slam")
	_screen_shake("large")
	_impact_pause(0.15)

func _execute_impale_pin(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Pin enemy in place for 2 seconds"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		_deal_damage_to_enemy(target, damage)
		_apply_stun(target, ability.stun_duration)

	_spawn_effect("pinning_strike", player.global_position)
	_play_sound("impale")
	_screen_shake("small")

func _execute_impale_crucify(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Thrust enemy into wall for 3x damage"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		var direction = (target.global_position - player.global_position).normalized()
		var final_damage = damage

		# SIGNATURE: 3x damage against wall (simplified - always apply bonus)
		final_damage *= 3.0

		_deal_damage_to_enemy(target, final_damage)
		_apply_stun(target, ability.stun_duration)

		# Knockback
		_apply_knockback(target, direction, 500.0)

		# Apply bleed
		if target.has_method("apply_bleed"):
			target.apply_bleed(damage * 0.2, 5.0)

	_spawn_effect("crucify", player.global_position)
	_play_sound("crucify")
	_screen_shake("large")
	_impact_pause(0.2)

# ============================================
# UPPERCUT TREE IMPLEMENTATIONS
# ============================================

func _execute_uppercut(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Launch enemy into the air"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		_deal_damage_to_enemy(target, damage)
		# Launch upward (knockback with upward bias)
		var knockback_dir = Vector2(0, -1).normalized()
		_apply_knockback(target, knockback_dir, ability.knockback_force)

	_spawn_effect("uppercut", player.global_position)
	_play_sound("punch")
	_screen_shake("small")

func _execute_uppercut_juggle(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Keep airborne enemies in the air"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		# Multiple hits
		for i in range(3):
			_deal_damage_to_enemy(target, damage)
			var knockback_dir = Vector2(randf_range(-0.3, 0.3), -1).normalized()
			_apply_knockback(target, knockback_dir, ability.knockback_force)

	_spawn_effect("juggle", player.global_position)
	_play_sound("punch")
	_screen_shake("small")

func _execute_uppercut_air_combo(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: 10-hit air combo, invulnerable"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	# SIGNATURE: Invulnerable during combo
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(ability.invulnerability_duration)

	if target:
		# 10 hits
		for i in range(10):
			_deal_damage_to_enemy(target, damage)

		# Final slam
		_deal_damage_to_enemy(target, damage * 2.0)
		_apply_stun(target, 1.0)

	_spawn_effect("air_combo", player.global_position)
	_play_sound("combo")
	_screen_shake("large")
	_impact_pause(0.2)

func _execute_uppercut_grab(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Grab and slam down"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		_deal_damage_to_enemy(target, damage)
		_apply_stun(target, ability.stun_duration)

		# AoE on slam
		var enemies = _get_enemies_in_radius(target.global_position, ability.radius)
		for enemy in enemies:
			if enemy != target:
				_deal_damage_to_enemy(enemy, damage * 0.5)

	_spawn_effect("grab_slam", player.global_position)
	_play_sound("slam")
	_screen_shake("medium")

func _execute_uppercut_piledriver(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Leap, grab, suplex into ground"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	# SIGNATURE: Invulnerable
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(ability.invulnerability_duration)

	if target:
		# Leap to target
		_dash_player(player, (target.global_position - player.global_position).normalized(),
			player.global_position.distance_to(target.global_position), 0.3)

		# Massive damage
		_deal_damage_to_enemy(target, damage)
		_apply_stun(target, ability.stun_duration)

		# AoE earthquake
		var enemies = _get_enemies_in_radius(target.global_position, ability.radius)
		for enemy in enemies:
			if enemy != target:
				_deal_damage_to_enemy(enemy, damage * 0.7)
				_apply_stun(enemy, ability.stun_duration * 0.5)

	_spawn_effect("piledriver", player.global_position)
	_play_sound("earthquake")
	_screen_shake("large")
	_impact_pause(0.25)

# ============================================
# COMBO TREE IMPLEMENTATIONS
# ============================================

func _execute_combo_strike(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: 3-hit combo attack"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		for i in range(3):
			_deal_damage_to_enemy(target, damage)

	_spawn_effect("combo_strike", player.global_position)
	_play_sound("combo")
	_screen_shake("small")

func _execute_combo_chain(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: 5-hit combo, each hit builds attack speed"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		for i in range(5):
			var hit_damage = damage * (1.0 + i * 0.1)  # Each hit does more
			_deal_damage_to_enemy(target, hit_damage)

	_spawn_effect("chain_combo", player.global_position)
	_play_sound("combo")
	_screen_shake("small")

func _execute_combo_infinite(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Rapid attacks with lifesteal"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		# Simulate rapid hits (15 hits for duration)
		var hits = 15
		for i in range(hits):
			var hit_damage = damage * (1.0 + i * 0.05)  # +5% per hit
			_deal_damage_to_enemy(target, hit_damage)

			# Lifesteal
			if player.has_method("heal"):
				player.heal(hit_damage * 0.05)

	_spawn_effect("infinite_combo", player.global_position)
	_play_sound("combo")
	_screen_shake("medium")
	_impact_pause(0.1)

func _execute_combo_finisher(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: 3-hit combo with powerful final strike"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		_deal_damage_to_enemy(target, damage)
		_deal_damage_to_enemy(target, damage)
		_deal_damage_to_enemy(target, damage * 2.0)  # Final hit does 2x

	_spawn_effect("combo_finisher", player.global_position)
	_play_sound("combo")
	_screen_shake("medium")

func _execute_combo_ultimate(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: 5-hit combo, 5th hit does 400% damage AoE"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	if target:
		# First 4 hits
		for i in range(4):
			_deal_damage_to_enemy(target, damage)

		# 5th hit - massive AoE
		var enemies = _get_enemies_in_radius(target.global_position, ability.radius)
		for enemy in enemies:
			_deal_damage_to_enemy(enemy, damage * 4.0)
			_apply_stun(enemy, ability.stun_duration)

	_spawn_effect("ultimate_finisher", player.global_position)
	_play_sound("ultimate")
	_screen_shake("large")
	_impact_pause(0.2)

# ============================================
# STOMP TREE IMPLEMENTATIONS
# ============================================

func _execute_stomp(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Stomp creating shockwave"""
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)

	_spawn_effect("stomp", player.global_position)
	_play_sound("stomp")
	_screen_shake("small")

func _execute_stomp_quake(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Larger waves with slow"""
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_slow(enemy, ability.slow_percent, ability.slow_duration)

	_spawn_effect("quake_stomp", player.global_position)
	_play_sound("earthquake")
	_screen_shake("medium")

func _execute_stomp_tectonic(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Create fissures, DoT zone"""
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_knockback(enemy, (enemy.global_position - player.global_position).normalized(), 200.0)

	# Create DoT zone
	var fissure = _spawn_effect("tectonic_shift", player.global_position)
	if fissure and fissure.has_method("setup"):
		fissure.setup(damage * 0.2, ability.radius, ability.duration)

	_play_sound("earthquake")
	_screen_shake("large")
	_impact_pause(0.15)

func _execute_stomp_thunder(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Stun enemies"""
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_stun(enemy, ability.stun_duration)

	_spawn_effect("thunder_stomp", player.global_position)
	_play_sound("thunder")
	_screen_shake("medium")

func _execute_stomp_thunderous(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Leap and stomp with massive stun"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var target = _get_nearest_enemy(player.global_position, ability.range_distance)

	var target_pos = player.global_position + direction * ability.range_distance
	if target:
		target_pos = target.global_position

	# Leap to target
	_dash_player(player, (target_pos - player.global_position).normalized(),
		player.global_position.distance_to(target_pos), 0.4)

	# Massive impact
	var enemies = _get_enemies_in_radius(target_pos, ability.radius)
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_stun(enemy, ability.stun_duration)
		_apply_knockback(enemy, (enemy.global_position - target_pos).normalized(), 300.0)

	_spawn_effect("thunderous_impact", target_pos)
	_play_sound("thunder")
	_screen_shake("large")
	_impact_pause(0.2)

# ============================================
# PARRY TREE IMPLEMENTATIONS
# ============================================

func _execute_parry(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Parry the next incoming attack"""
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("parry", ability.duration, {
			"parry_active": true
		})

	_spawn_effect("parry", player.global_position)
	_play_sound("parry")

func _execute_parry_counter(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Successful parry triggers counter attack"""
	var damage = _get_damage(ability)

	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("counter_parry", ability.duration, {
			"parry_active": true,
			"counter_damage": damage,
			"counter_range": ability.range_distance
		})

	_spawn_effect("counter_strike", player.global_position)
	_play_sound("parry")

func _execute_parry_riposte(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Perfect parry deals massive damage + stun"""
	var damage = _get_damage(ability)

	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("perfect_riposte", ability.duration, {
			"parry_active": true,
			"counter_damage": damage,
			"counter_crit": true,
			"counter_stun": ability.stun_duration,
			"counter_range": ability.range_distance
		})

	_spawn_effect("perfect_riposte", player.global_position)
	_play_sound("parry")
	_screen_shake("small")

func _execute_parry_deflect(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Also deflect projectiles"""
	var damage = _get_damage(ability)

	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("deflection", ability.duration, {
			"parry_active": true,
			"deflect_projectiles": true,
			"deflect_damage": damage
		})

	_spawn_effect("deflection", player.global_position)
	_play_sound("parry")

func _execute_parry_mirror(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Invulnerable, reflect all damage"""
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("mirror_guard", ability.duration, {
			"invulnerable": true,
			"damage_reflection": 1.0,
			"reflect_aoe_radius": ability.radius
		})

	_spawn_effect("mirror_guard", player.global_position)
	_play_sound("mirror")
	_screen_shake("medium")

# ============================================
# RAMPAGE TREE IMPLEMENTATIONS
# ============================================

func _execute_rampage(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Base: Enter rampage, increase attack speed"""
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("rampage", ability.duration, {
			"attack_speed_bonus": 0.4
		})

	_spawn_effect("rampage", player.global_position)
	_play_sound("roar")

func _execute_rampage_frenzy(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Attacks build frenzy stacks"""
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("frenzy", ability.duration, {
			"attack_speed_bonus": 0.5,
			"attack_speed_per_hit": 0.05,
			"max_attack_speed_bonus": 1.0
		})

	_spawn_effect("frenzy", player.global_position)
	_play_sound("roar")

func _execute_rampage_bloodlust(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Kills extend duration, increase power, lifesteal"""
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("bloodlust", ability.duration, {
			"attack_speed_bonus": 0.6,
			"damage_bonus": 0.3,
			"lifesteal_percent": 0.15,
			"duration_on_kill": 2.0,
			"damage_per_kill": 0.1
		})

	_spawn_effect("bloodlust", player.global_position)
	_play_sound("blood_rage")
	_screen_shake("medium")

func _execute_rampage_fury(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Also increases damage"""
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("fury", ability.duration, {
			"attack_speed_bonus": 0.4,
			"damage_bonus": 0.4
		})

	_spawn_effect("fury", player.global_position)
	_play_sound("roar")

func _execute_rampage_unstoppable(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Immune to CC, +100% damage, move through enemies"""
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("unstoppable_force", ability.duration, {
			"attack_speed_bonus": 0.5,
			"damage_bonus": 1.0,
			"cc_immune": true,
			"collision_damage": true
		})

	_spawn_effect("unstoppable_force", player.global_position)
	_play_sound("unstoppable")
	_screen_shake("large")
	_impact_pause(0.1)
