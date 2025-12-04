extends RefCounted
class_name CombatEffects

# Handles combat-specific ability effects (berserker, executioner, momentum, etc.)
# Extracted from ability_manager.gd for modularity

# Reference to ability manager for state access
var _manager: Node = null

func _init(manager: Node) -> void:
	_manager = manager

# ============================================
# BERSERKER FURY
# ============================================

func trigger_berserker_fury() -> void:
	"""Add a stack of Berserker Fury"""
	if _manager.has_berserker_fury:
		_manager.berserker_fury_stacks = mini(_manager.berserker_fury_stacks + 1, 5)  # Max 5 stacks
		_manager.berserker_fury_timer = 5.0

func get_berserker_fury_bonus() -> float:
	"""Get current damage bonus from Berserker Fury"""
	if not _manager.has_berserker_fury:
		return 0.0
	return _manager.berserker_fury_bonus * _manager.berserker_fury_stacks

# ============================================
# COMBAT MOMENTUM
# ============================================

func update_combat_momentum(target: Node2D) -> void:
	"""Update momentum stacks when attacking the same target"""
	if not _manager.has_combat_momentum:
		return
	if _manager.combat_momentum_target == target:
		_manager.combat_momentum_stacks = mini(_manager.combat_momentum_stacks + 1, 5)
	else:
		_manager.combat_momentum_target = target
		_manager.combat_momentum_stacks = 1

func get_combat_momentum_bonus() -> float:
	"""Get current damage bonus from Combat Momentum"""
	if not _manager.has_combat_momentum:
		return 0.0
	return _manager.combat_momentum_bonus * _manager.combat_momentum_stacks

# ============================================
# EXECUTIONER
# ============================================

func get_executioner_bonus(enemy_hp_percent: float) -> float:
	"""Get damage bonus when enemy is below 30% HP"""
	if not _manager.has_executioner or enemy_hp_percent > 0.3:
		return 0.0
	return _manager.executioner_bonus

# ============================================
# VENGEANCE
# ============================================

func trigger_vengeance() -> void:
	"""Activate vengeance buff after taking damage"""
	if _manager.has_vengeance:
		_manager.vengeance_active = true
		_manager.vengeance_timer = 3.0

func consume_vengeance() -> float:
	"""Consume and return vengeance damage bonus"""
	if _manager.vengeance_active:
		_manager.vengeance_active = false
		return _manager.vengeance_bonus
	return 0.0

# ============================================
# LAST RESORT
# ============================================

func get_last_resort_bonus(hp_percent: float) -> float:
	"""Get damage bonus based on how low HP is"""
	if not _manager.has_last_resort:
		return 0.0
	# More bonus the lower HP (inverse of HP percent)
	return _manager.last_resort_bonus * (1.0 - hp_percent)

# ============================================
# HORDE BREAKER
# ============================================

func get_horde_breaker_bonus(player_pos: Vector2) -> float:
	"""Get damage bonus based on nearby enemy count"""
	if not _manager.has_horde_breaker:
		return 0.0

	var enemies = _manager.get_tree().get_nodes_in_group("enemies")
	var nearby_count = 0
	var range_sq = 200.0 * 200.0  # 200 unit range

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist_sq = player_pos.distance_squared_to(enemy.global_position)
			if dist_sq <= range_sq:
				nearby_count += 1

	# 5% damage per nearby enemy, cap at 50%
	return minf(_manager.horde_breaker_bonus * nearby_count, 0.5)

# ============================================
# GIANT SLAYER
# ============================================

func get_giant_slayer_bonus(enemy_hp_percent: float) -> float:
	"""Get damage bonus against enemies with high HP"""
	if not _manager.has_giant_slayer:
		return 0.0
	# Bonus scales with enemy max HP - higher HP enemies take more damage
	# This checks current HP percent, but the bonus should be based on max HP
	# For now, give full bonus (actual max HP check would need enemy reference)
	return _manager.giant_slayer_bonus

# ============================================
# BACKSTAB
# ============================================

func get_backstab_crit_bonus() -> float:
	"""Get crit chance bonus for backstab (checked elsewhere for position)"""
	if not _manager.has_backstab:
		return 0.0
	return _manager.backstab_crit_bonus

# ============================================
# PARRY
# ============================================

func check_parry() -> bool:
	"""Roll for parry chance"""
	return _manager.has_parry and randf() < _manager.parry_chance

# ============================================
# SEISMIC SLAM
# ============================================

func check_seismic_stun() -> bool:
	"""Roll for seismic stun chance"""
	return _manager.has_seismic_slam and randf() < _manager.seismic_stun_chance

# ============================================
# DOUBLE TAP
# ============================================

func check_double_tap() -> bool:
	"""Roll for double tap (extra attack) chance"""
	return _manager.has_double_tap and randf() < _manager.double_tap_chance

# ============================================
# POINT BLANK
# ============================================

func get_point_blank_bonus(distance: float) -> float:
	"""Get damage bonus for close-range attacks"""
	if not _manager.has_point_blank:
		return 0.0
	# Full bonus at 0 distance, no bonus at 150+ distance
	var falloff = 1.0 - clampf(distance / 150.0, 0.0, 1.0)
	return _manager.point_blank_bonus * falloff

# ============================================
# BLADE BEAM
# ============================================

func should_fire_blade_beam() -> bool:
	"""Check if blade beam should be fired with melee attacks"""
	return _manager.has_blade_beam

# ============================================
# DOUBLE STRIKE
# ============================================

func should_double_strike() -> bool:
	"""Check if attack should hit twice"""
	return _manager.has_double_strike

func get_extra_melee_swings() -> int:
	"""Get number of extra melee swings"""
	if _manager.has_double_strike:
		return 1
	return 0

# ============================================
# PHALANX
# ============================================

func check_phalanx(projectile_direction: Vector2, player_facing: Vector2) -> bool:
	"""Check if projectile should be blocked by phalanx (facing check)"""
	if not _manager.has_phalanx:
		return false
	# Block if projectile is coming from the direction player is facing
	var dot = projectile_direction.dot(player_facing)
	# Negative dot means projectile is coming from front
	return dot < -0.5 and randf() < _manager.phalanx_chance

# ============================================
# BLOODTHIRST
# ============================================

func apply_bloodthirst_boost(player: Node2D) -> void:
	"""Apply temporary attack speed boost"""
	if not _manager.has_bloodthirst:
		return
	# Delegate to player for buff application
	if player.has_method("apply_bloodthirst"):
		player.apply_bloodthirst(_manager.bloodthirst_boost)

# ============================================
# ADRENALINE
# ============================================

func apply_adrenaline_buff(player: Node2D) -> void:
	"""Apply adrenaline movement speed buff"""
	if not _manager.has_adrenaline:
		return
	if player.has_method("apply_adrenaline"):
		player.apply_adrenaline(_manager.adrenaline_boost)

# ============================================
# AGGREGATE DAMAGE MULTIPLIER
# ============================================

func get_combat_damage_multiplier(enemy: Node2D = null, player: Node2D = null) -> float:
	"""Get combined damage multiplier from all combat effects"""
	var multiplier = 1.0

	# Berserker Fury
	multiplier += get_berserker_fury_bonus()

	# Combat Momentum
	multiplier += get_combat_momentum_bonus()

	# Vengeance (consumed on use)
	# Note: This is handled separately as it's a one-time bonus

	# Last Resort (based on player HP)
	if player and player.has_method("get_health_percent"):
		multiplier += get_last_resort_bonus(player.get_health_percent())

	# Horde Breaker
	if player:
		multiplier += get_horde_breaker_bonus(player.global_position)

	# Executioner (based on enemy HP)
	if enemy and enemy.has_method("get_health_percent"):
		multiplier += get_executioner_bonus(enemy.get_health_percent())

	# Giant Slayer
	if enemy and enemy.has_method("get_health_percent"):
		multiplier += get_giant_slayer_bonus(enemy.get_health_percent())

	return multiplier
