extends RefCounted
class_name StatEffects

# Handles stat calculation logic extracted from ability_manager.gd
# Provides methods for getting final stat values with all modifiers applied

# Reference to ability manager for state access
var _manager: Node = null

func _init(manager: Node) -> void:
	_manager = manager

# ============================================
# DAMAGE MULTIPLIER
# ============================================

func get_damage_multiplier() -> float:
	var base = 1.0 + _manager.stat_modifiers["damage"]

	# Add level-up bonus (5% per level after level 1)
	base += _manager.level_bonus_damage

	# Add permanent upgrade bonus
	if PermanentUpgrades:
		base += PermanentUpgrades.get_all_bonuses().get("damage", 0.0)

	# Add character passive bonus (Mage's Arcane Intellect)
	if CharacterManager:
		base += CharacterManager.get_passive_bonuses().get("damage", 0.0)

	# Add equipment bonus
	base += _get_equipment_stat("damage")

	# Kill streak bonuses
	if _manager.has_rampage and _manager.rampage_stacks > 0:
		base += _manager.rampage_bonus * _manager.rampage_stacks

	if _manager.has_massacre and _manager.massacre_stacks > 0:
		base += _manager.massacre_bonus * _manager.massacre_stacks

	# Combo Master bonus (from using active abilities)
	base *= _manager.get_combo_master_damage_multiplier()

	return base

# ============================================
# ATTACK SPEED MULTIPLIER
# ============================================

func get_attack_speed_multiplier() -> float:
	var base = 1.0 + _manager.stat_modifiers["attack_speed"]

	# Frenzy bonus when low HP
	if _manager.has_frenzy:
		var player = _manager.get_tree().get_first_node_in_group("player")
		if player and player.current_health / player.max_health < 0.3:
			base += _manager.frenzy_boost

	# Add equipment bonus
	base += _get_equipment_stat("attack_speed")

	# Kill streak bonuses
	if _manager.has_killing_frenzy and _manager.killing_frenzy_stacks > 0:
		base += _manager.killing_frenzy_bonus * _manager.killing_frenzy_stacks

	if _manager.has_massacre and _manager.massacre_stacks > 0:
		base += _manager.massacre_bonus * _manager.massacre_stacks

	return base

# ============================================
# XP MULTIPLIER
# ============================================

func get_xp_multiplier() -> float:
	var base = 1.0 + _manager.stat_modifiers["xp_gain"]

	# Add permanent upgrade bonus
	if PermanentUpgrades:
		base += PermanentUpgrades.get_all_bonuses().get("xp_gain", 0.0)

	# Add equipment bonus
	base += _get_equipment_stat("xp_gain")

	return base

# ============================================
# MOVE SPEED MULTIPLIER
# ============================================

func get_move_speed_multiplier() -> float:
	var base = 1.0 + _manager.stat_modifiers["move_speed"]

	# Add equipment bonus
	base += _get_equipment_stat("move_speed")

	return base

# ============================================
# PROJECTILE STATS
# ============================================

func get_total_projectile_count() -> int:
	var count = _manager.stat_modifiers.get("projectile_count", 0)

	if PermanentUpgrades:
		count += PermanentUpgrades.get_all_bonuses().get("projectile_count", 0)

	return count

func get_projectile_speed_multiplier() -> float:
	var base = 1.0 + _manager.stat_modifiers.get("projectile_speed", 0.0)

	if PermanentUpgrades:
		base += PermanentUpgrades.get_all_bonuses().get("projectile_speed", 0.0)

	# Add character passive bonus (Archer's Eagle Eye)
	if CharacterManager:
		base += CharacterManager.get_passive_bonuses().get("projectile_speed", 0.0)

	return base

# ============================================
# CRIT STATS
# ============================================

func get_crit_chance() -> float:
	var base = _manager.stat_modifiers.get("crit_chance", 0.0)

	# Add character base crit rate
	if CharacterManager:
		base += CharacterManager.get_base_combat_stats().get("crit_rate", 0.0)

	# Add permanent upgrade crit chance
	if PermanentUpgrades:
		base += PermanentUpgrades.get_all_bonuses().get("crit_chance", 0.0)
		base += PermanentUpgrades.get_all_bonuses().get("luck", 0.0)

	# Add character passive bonus (Archer's Eagle Eye)
	if CharacterManager:
		base += CharacterManager.get_passive_bonuses().get("crit_chance", 0.0)

	# Add equipment bonus
	base += _get_equipment_stat("crit_chance")

	return base

func get_crit_damage_multiplier() -> float:
	var base = 2.0  # Default crit is 2x damage

	if PermanentUpgrades:
		base += PermanentUpgrades.get_all_bonuses().get("crit_damage", 0.0)

	# Add character passive bonus (Mage's Arcane Intellect)
	if CharacterManager:
		base += CharacterManager.get_passive_bonuses().get("crit_damage", 0.0)

	return base

# ============================================
# DEFENSIVE STATS
# ============================================

func get_block_chance() -> float:
	var base = 0.0

	# Add character base block rate
	if CharacterManager:
		base += CharacterManager.get_base_combat_stats().get("block_rate", 0.0)

	# Add permanent upgrade block chance
	if PermanentUpgrades:
		base += PermanentUpgrades.get_all_bonuses().get("block_chance", 0.0)

	# Add equipment bonus
	base += _get_equipment_stat("block_chance")

	return base

func get_dodge_chance() -> float:
	var base = 0.0

	# Add character base dodge rate
	if CharacterManager:
		base += CharacterManager.get_base_combat_stats().get("dodge_rate", 0.0)

	# Add permanent upgrade dodge chance
	if PermanentUpgrades:
		base += PermanentUpgrades.get_all_bonuses().get("dodge_chance", 0.0)

	# Add equipment bonus
	base += _get_equipment_stat("dodge_chance")

	return base

func get_armor() -> float:
	return _manager.armor

func get_equipment_damage_reduction() -> float:
	return _get_equipment_stat("damage_reduction")

# ============================================
# LUCK & MISC STATS
# ============================================

func get_luck_multiplier() -> float:
	var base = 1.0 + _manager.stat_modifiers.get("luck", 0.0)

	if PermanentUpgrades:
		base += PermanentUpgrades.get_all_bonuses().get("luck", 0.0)

	# Apply Jinxed curse (reduced luck)
	if CurseEffects:
		base *= CurseEffects.get_luck_multiplier()

	return base

func get_coin_gain_multiplier() -> float:
	return 1.0 + _manager.coin_gain_bonus

func get_regen_rate() -> float:
	var base = _manager.regen_rate

	if PermanentUpgrades:
		base += PermanentUpgrades.get_all_bonuses().get("hp_regen", 0.0)

	return base

func has_permanent_regen() -> bool:
	if PermanentUpgrades:
		return PermanentUpgrades.get_all_bonuses().get("hp_regen", 0.0) > 0
	return false

# ============================================
# MELEE STATS
# ============================================

func get_melee_area_multiplier() -> float:
	return 1.0 + _manager.stat_modifiers.get("melee_area", 0.0) + _get_equipment_stat("melee_area")

func get_melee_range_multiplier() -> float:
	return 1.0 + _manager.stat_modifiers.get("melee_range", 0.0) + _get_equipment_stat("melee_range")

func get_attack_range_multiplier() -> float:
	var perm_bonus = 0.0
	if PermanentUpgrades:
		perm_bonus = PermanentUpgrades.get_all_bonuses().get("attack_range", 0.0)
	return 1.0 + _manager.stat_modifiers.get("attack_range", 0.0) + _get_equipment_stat("attack_range") + perm_bonus

func get_melee_knockback() -> float:
	return _manager.melee_knockback

# ============================================
# MOMENTUM
# ============================================

func get_momentum_damage_bonus(player_velocity: Vector2) -> float:
	if not _manager.has_momentum:
		return 0.0
	var speed_ratio = clampf(player_velocity.length() / 300.0, 0.0, 1.0)  # Normalized to 300 speed
	return _manager.momentum_bonus * speed_ratio

# ============================================
# SUMMON STATS
# ============================================

func get_summon_damage_multiplier() -> float:
	var mult = 1.0
	if _manager.has_summon_damage:
		mult += _manager.summon_damage_bonus
	# Add permanent upgrade bonus
	if PermanentUpgrades:
		mult += PermanentUpgrades.get_all_bonuses().get("summon_damage", 0.0)
	if _manager.has_empathic_bond:
		mult *= _manager.empathic_bond_multiplier
	return mult

# ============================================
# EQUIPMENT STAT HELPER
# ============================================

func _get_equipment_stat(stat: String) -> float:
	if not EquipmentManager:
		return 0.0
	if not CharacterManager:
		return 0.0

	var character_id = CharacterManager.selected_character_id
	var equipment_stats = EquipmentManager.get_equipment_stats(character_id)
	var base_value = equipment_stats.get(stat, 0.0)

	# Apply Brittle Armor curse (reduced equipment effectiveness)
	if CurseEffects:
		base_value *= CurseEffects.get_equipment_bonus_multiplier()

	return base_value

func get_equipment_max_hp_bonus() -> float:
	return _get_equipment_stat("max_hp")

# ============================================
# APPLY STATS TO PLAYER
# ============================================

func apply_stats_to_player() -> void:
	var player = _manager.get_tree().get_first_node_in_group("player")
	if player == null:
		return

	# Combine ability stat modifiers with equipment stats
	var combined_modifiers = _manager.stat_modifiers.duplicate()

	# Add equipment stats
	combined_modifiers["max_hp"] = _manager.stat_modifiers.get("max_hp", 0.0) + _get_equipment_stat("max_hp")
	combined_modifiers["move_speed"] = _manager.stat_modifiers.get("move_speed", 0.0) + _get_equipment_stat("move_speed")
	combined_modifiers["attack_speed"] = _manager.stat_modifiers.get("attack_speed", 0.0) + _get_equipment_stat("attack_speed")
	combined_modifiers["pickup_range"] = _manager.stat_modifiers.get("pickup_range", 0.0) + _get_equipment_stat("pickup_range")
	combined_modifiers["size"] = _manager.stat_modifiers.get("size", 0.0) + _get_equipment_stat("size")

	# Update player stats based on combined modifiers
	if player.has_method("update_ability_stats"):
		player.update_ability_stats(combined_modifiers)
