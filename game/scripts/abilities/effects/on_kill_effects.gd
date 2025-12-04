extends RefCounted
class_name OnKillEffects

# Handles all on-kill ability effects
# Extracted from ability_manager.gd for modularity

# Reference to ability manager for state access
var _manager: Node = null

func _init(manager: Node) -> void:
	_manager = manager

func process_kill(enemy: Node2D, player: Node2D) -> void:
	"""Process all on-kill effects when an enemy dies"""
	# Don't trigger on-kill effects if player is dead
	if player == null or player.is_dead:
		return

	_process_permanent_upgrade_hp(player)
	_process_vampirism(player)
	_process_adrenaline(player)
	_process_death_explosion(enemy)
	_process_bloodthirst(player)
	_process_ceremonial_dagger(enemy, player)
	_process_soul_reaper(player)
	_process_unlimited_power()
	_process_arcane_absorption()
	_process_chain_reaction(enemy)
	_process_kill_streaks()
	_process_cooldown_killer()
	_process_kill_accelerant()
	_process_blood_trail(enemy)

# ============================================
# INDIVIDUAL EFFECTS
# ============================================

func _process_permanent_upgrade_hp(player: Node2D) -> void:
	"""Life Leech permanent upgrade"""
	if PermanentUpgrades:
		var bonuses = PermanentUpgrades.get_all_bonuses()
		if bonuses.get("hp_on_kill", 0.0) > 0:
			_heal_player(player, bonuses.get("hp_on_kill", 0.0))

func _process_vampirism(player: Node2D) -> void:
	"""Chance to heal on kill"""
	if _manager.has_vampirism and randf() < _manager.vampirism_chance:
		_heal_player(player, player.max_health * 0.05)

func _process_adrenaline(player: Node2D) -> void:
	"""Apply adrenaline buff on kill"""
	if _manager.has_adrenaline:
		_manager.apply_adrenaline_buff(player)

func _process_death_explosion(enemy: Node2D) -> void:
	"""Enemies explode on death"""
	if _manager.has_death_explosion:
		_manager.trigger_death_explosion(enemy)

func _process_bloodthirst(player: Node2D) -> void:
	"""Temporary attack speed boost on kill"""
	if _manager.has_bloodthirst:
		_manager.apply_bloodthirst_boost(player)

func _process_ceremonial_dagger(enemy: Node2D, player: Node2D) -> void:
	"""Fire homing daggers on kill (not from dagger kills)"""
	if _manager.has_ceremonial_dagger and not _manager._ceremonial_dagger_kill:
		_manager.fire_ceremonial_daggers(enemy.global_position, player)

func _process_soul_reaper(player: Node2D) -> void:
	"""Heal and stack damage on kill"""
	if _manager.has_soul_reaper:
		var heal_amount = player.max_health * _manager.soul_reaper_heal
		_heal_player(player, heal_amount)
		_manager.soul_reaper_stacks = mini(_manager.soul_reaper_stacks + 1, 50)  # Cap at 50 stacks
		_manager.soul_reaper_timer = 5.0

func _process_unlimited_power() -> void:
	"""Permanent stacking damage on kill"""
	if _manager.has_unlimited_power:
		_manager.unlimited_power_stacks += 1

func _process_arcane_absorption() -> void:
	"""Reduce cooldowns on kill"""
	if _manager.has_arcane_absorption:
		_manager.reduce_active_cooldowns(_manager.arcane_absorption_value)

func _process_chain_reaction(enemy: Node2D) -> void:
	"""Spread status effects to nearby enemies"""
	if _manager.has_chain_reaction:
		_manager.spread_status_effects(enemy)

func _process_kill_streaks() -> void:
	"""Update all kill streak counters"""
	if _manager.has_rampage:
		_manager.rampage_stacks = mini(_manager.rampage_stacks + 1, _manager.RAMPAGE_MAX_STACKS)
		_manager.rampage_timer = _manager.RAMPAGE_DECAY_TIME

	if _manager.has_killing_frenzy:
		_manager.killing_frenzy_stacks = mini(_manager.killing_frenzy_stacks + 1, _manager.KILLING_FRENZY_MAX_STACKS)
		_manager.killing_frenzy_timer = _manager.KILLING_FRENZY_DECAY_TIME

	if _manager.has_massacre:
		_manager.massacre_stacks = mini(_manager.massacre_stacks + 1, _manager.MASSACRE_MAX_STACKS)
		_manager.massacre_timer = _manager.MASSACRE_DECAY_TIME

func _process_cooldown_killer() -> void:
	"""Reduce cooldowns on kill"""
	if _manager.has_cooldown_killer:
		_manager.reduce_active_cooldowns(_manager.cooldown_killer_value)

func _process_kill_accelerant() -> void:
	"""Reduce ultimate cooldown on kill"""
	if _manager.has_kill_accelerant and UltimateAbilityManager:
		UltimateAbilityManager.reduce_cooldown(_manager.kill_accelerant_reduction)

func _process_blood_trail(enemy: Node2D) -> void:
	"""Spawn damaging blood pool at kill location"""
	if _manager.has_blood_trail:
		_manager.spawn_blood_pool(enemy.global_position)

# ============================================
# HELPER FUNCTIONS
# ============================================

func _heal_player(player: Node2D, amount: float) -> void:
	if player.has_method("heal"):
		player.heal(amount, false)

# ============================================
# KILL STREAK GETTERS
# ============================================

func get_rampage_damage_bonus() -> float:
	"""Get damage bonus from Rampage stacks"""
	if not _manager.has_rampage:
		return 0.0
	return _manager.rampage_bonus * _manager.rampage_stacks

func get_killing_frenzy_attack_speed_bonus() -> float:
	"""Get attack speed bonus from Killing Frenzy stacks"""
	if not _manager.has_killing_frenzy:
		return 0.0
	return _manager.killing_frenzy_bonus * _manager.killing_frenzy_stacks

func get_massacre_bonus() -> float:
	"""Get combined bonus from Massacre stacks (damage + attack speed)"""
	if not _manager.has_massacre:
		return 0.0
	return _manager.massacre_bonus * _manager.massacre_stacks

func get_soul_reaper_damage_bonus() -> float:
	"""Get damage bonus from Soul Reaper stacks"""
	if not _manager.has_soul_reaper:
		return 0.0
	# 1% damage per stack, max 50 stacks = 50% max damage
	return 0.01 * _manager.soul_reaper_stacks

func get_unlimited_power_bonus() -> float:
	"""Get damage bonus from Unlimited Power stacks"""
	if not _manager.has_unlimited_power:
		return 0.0
	return _manager.unlimited_power_bonus * _manager.unlimited_power_stacks
