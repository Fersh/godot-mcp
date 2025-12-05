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
		# SPIN TREE
		# ============================================
		"spinning_attack":
			_execute_spinning_attack(ability, player)
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
		# WHIRLWIND TREE
		# ============================================
		"whirlwind":
			_execute_whirlwind(ability, player)
			return true
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

	if target:
		_deal_damage_to_enemy(target, damage)
		_apply_stun(target, ability.stun_duration)
		var knockback_dir = (target.global_position - player.global_position).normalized()
		_apply_knockback(target, knockback_dir, ability.knockback_force)

	_spawn_effect("shield_bash", player.global_position)
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

	# Use base bash effect
	_spawn_effect("shield_bash", player.global_position)
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

	# Use base bash effect
	_spawn_effect("shield_bash", player.global_position)
	_play_sound("shield_hit")
	_screen_shake("large")
	_impact_pause(0.15)

func _execute_bash_lockdown(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Extended single-target stun"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, 150.0)

	if target:
		_deal_damage_to_enemy(target, damage)
		_apply_stun(target, ability.stun_duration)

	# Use base bash effect
	_spawn_effect("shield_bash", player.global_position)
	_play_sound("shield_hit")
	_screen_shake("small")

func _execute_bash_petrify(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Petrify with damage amp"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, 150.0)

	if target:
		_deal_damage_to_enemy(target, damage)
		_apply_stun(target, ability.stun_duration)
		# SIGNATURE: Mark as petrified for 2x damage
		if target.has_method("apply_petrify"):
			target.apply_petrify(ability.stun_duration)
		elif target.has_method("apply_vulnerability"):
			target.apply_vulnerability(2.0, ability.stun_duration)

	# Use base bash effect
	_spawn_effect("shield_bash", player.global_position)
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
# SPIN TREE IMPLEMENTATIONS
# ============================================

func _execute_spinning_attack(ability: ActiveAbilityData, player: Node2D) -> void:
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.radius)

	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)

	_spawn_effect("spin", player.global_position)
	_play_sound("swing")

func _execute_spin_vortex(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Sustained spinning with pull - creates a vortex that pulls enemies"""
	var damage = _get_damage(ability)

	# Spawn sustained vortex effect that pulls enemies over time
	var vortex_scene = load("res://scripts/active_abilities/effects/vortex_effect.gd")
	if vortex_scene:
		var vortex = Node2D.new()
		vortex.set_script(vortex_scene)
		vortex.global_position = player.global_position
		player.get_parent().add_child(vortex)
		# Setup: duration, radius, damage per second, pull strength, follow target (null = stationary)
		vortex.setup(ability.duration, ability.radius, damage / ability.duration, 120.0, null)

	_spawn_effect("spin", player.global_position)
	_play_sound("swing")

func _execute_spin_bladestorm(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Move freely while spinning - vortex follows player"""
	var damage = _get_damage(ability)

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
	_play_sound("swing")
	_screen_shake("small")

func _execute_spin_deflect(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Deflect projectiles - uses base spin effect"""
	var damage = _get_damage(ability)
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

	# Spawn wave effects
	_spawn_effect("seismic_wave", player.global_position)
	_play_sound("seismic_slam")
	_screen_shake("medium")

func _execute_slam_earthquake(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Screen-wide seismic devastation"""
	var damage = _get_damage(ability)

	# SIGNATURE: Damage the entire battlefield over time
	var earthquake_scene = load("res://scripts/active_abilities/effects/earthquake_effect.gd")
	if earthquake_scene:
		var quake = Node2D.new()
		quake.set_script(earthquake_scene)
		quake.global_position = player.global_position
		player.get_parent().add_child(quake)
		# Setup: damage, radius, duration, stun_duration
		quake.setup(damage, ability.radius, ability.duration, ability.stun_duration)

	_spawn_effect("ground_slam", player.global_position)  # Visual feedback
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
	var target = _get_nearest_enemy(player.global_position, ability.range_value)

	var target_pos = player.global_position + direction * ability.range_value
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

	_spawn_effect("meteor_slam", target_pos)
	_play_sound("meteor_impact")
	_screen_shake("large")
	_impact_pause(0.25)

# ============================================
# DASH TREE IMPLEMENTATIONS
# ============================================

func _execute_dash_blade_rush(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Chain 3 dashes"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)

	# Perform 3 quick dashes
	for i in range(3):
		var start = player.global_position
		_dash_player(player, direction, ability.range_value, 0.15)

		# Damage enemies in path
		var enemies = _get_enemies_in_radius(start + direction * ability.range_value * 0.5, ability.range_value)
		for enemy in enemies:
			_deal_damage_to_enemy(enemy, damage)

		_spawn_effect("blade_rush", start)

	_play_sound("blade_rush")

func _execute_dash_omnislash(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Teleport between enemies, massive damage"""
	var damage = _get_damage(ability)

	# SIGNATURE: Invulnerable during omnislash
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(ability.invulnerability_duration)

	# Get up to 8 enemies
	var enemies = _get_enemies_in_radius(player.global_position, ability.range_value)
	enemies = enemies.slice(0, 8)

	for enemy in enemies:
		if is_instance_valid(enemy):
			# Teleport to enemy
			player.global_position = enemy.global_position
			# Strike 3 times
			for j in range(3):
				_deal_damage_to_enemy(enemy, damage)
			_spawn_effect("omnislash_hit", enemy.global_position)

	_play_sound("omnislash")
	_screen_shake("large")
	_impact_pause(0.2)

func _execute_dash_afterimage(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Leave exploding clone"""
	var damage = _get_damage(ability)
	var direction = _get_attack_direction(player)
	var start_pos = player.global_position

	# Dash
	_dash_player(player, direction, ability.range_value, 0.2)

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
# WHIRLWIND TREE IMPLEMENTATIONS
# ============================================

func _execute_whirlwind_vacuum(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Pull enemies while spinning"""
	var damage = _get_damage(ability)

	var whirl = _spawn_effect("vacuum_spin", player.global_position)
	if whirl and whirl.has_method("setup"):
		whirl.setup(player, damage, ability.radius, ability.duration, ability.knockback_force)

	_play_sound("whirlwind")

func _execute_whirlwind_singularity(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Become a black hole"""
	var damage = _get_damage(ability)

	# SIGNATURE: Massive pull, damage increases as enemies get closer
	var singularity = _spawn_effect("singularity", player.global_position)
	if singularity and singularity.has_method("setup"):
		singularity.setup(player, damage, ability.radius, ability.duration, ability.knockback_force)

	_play_sound("singularity")
	_screen_shake("medium")

func _execute_whirlwind_flame(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Fire trail whirlwind"""
	var damage = _get_damage(ability)

	var whirl = _spawn_effect("flame_whirlwind", player.global_position)
	if whirl and whirl.has_method("setup"):
		whirl.setup(player, damage, ability.radius, ability.duration)

	_play_sound("whirlwind")

func _execute_whirlwind_inferno(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Massive fire tornado"""
	var damage = _get_damage(ability)

	# SIGNATURE: Fire tornado with burning ground
	var tornado = _spawn_effect("inferno_tornado", player.global_position)
	if tornado and tornado.has_method("setup"):
		tornado.setup(player, damage, ability.radius, ability.duration)

	_play_sound("inferno_tornado")
	_screen_shake("medium")

# ============================================
# LEAP TREE IMPLEMENTATIONS
# ============================================

func _execute_leap_tremor(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Stun on landing"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_value)
	var target_pos = target.global_position if target else player.global_position + _get_attack_direction(player) * ability.range_value

	# Leap
	_dash_player(player, (target_pos - player.global_position).normalized(),
		player.global_position.distance_to(target_pos), 0.4)

	# Impact with stun
	var enemies = _get_enemies_in_radius(target_pos, ability.radius)
	for enemy in enemies:
		_deal_damage_to_enemy(enemy, damage)
		_apply_stun(enemy, ability.stun_duration)

	_spawn_effect("tremor_leap", target_pos)
	_play_sound("savage_leap")
	_screen_shake("medium")

func _execute_leap_extinction(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Meteors on landing"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_value)
	var target_pos = target.global_position if target else player.global_position + _get_attack_direction(player) * ability.range_value

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

	_spawn_effect("extinction_event", target_pos)
	_play_sound("extinction_event")
	_screen_shake("large")
	_impact_pause(0.3)

func _execute_leap_predator(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 2: Gain attack speed after leap"""
	var damage = _get_damage(ability)
	var target = _get_nearest_enemy(player.global_position, ability.range_value)
	var target_pos = target.global_position if target else player.global_position + _get_attack_direction(player) * ability.range_value

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

	_spawn_effect("predator_leap", target_pos)
	_play_sound("savage_leap")

func _execute_leap_apex(ability: ActiveAbilityData, player: Node2D) -> void:
	"""Tier 3 SIGNATURE: Chain leaps with healing"""
	var damage = _get_damage(ability)
	var enemies = _get_enemies_in_radius(player.global_position, ability.range_value)
	enemies = enemies.slice(0, 3)  # Max 3 targets

	var kills = 0
	for enemy in enemies:
		if is_instance_valid(enemy):
			# Leap to each target
			_dash_player(player, (enemy.global_position - player.global_position).normalized(),
				player.global_position.distance_to(enemy.global_position), 0.2)

			_deal_damage_to_enemy(enemy, damage)
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
