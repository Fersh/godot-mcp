extends RefCounted
class_name OnHitEffects

# Handles on-hit ability effects (elemental procs, vampirism, chains, etc.)
# Extracted from ability_manager.gd for modularity

# Reference to ability manager for state access
var _manager: Node = null

func _init(manager: Node) -> void:
	_manager = manager

# ============================================
# ELEMENTAL ON-HIT PROCS
# ============================================

func check_ignite() -> bool:
	"""Roll for ignite (fire DoT) proc"""
	return _manager.has_ignite and randf() < _manager.ignite_chance

func check_frostbite() -> bool:
	"""Roll for frostbite (slow) proc"""
	return _manager.has_frostbite and randf() < _manager.frostbite_chance

func check_toxic_tip() -> bool:
	"""Roll for toxic tip (poison) proc"""
	return _manager.has_toxic_tip and randf() < _manager.toxic_tip_chance

func check_lightning_proc() -> bool:
	"""Roll for lightning proc"""
	return _manager.has_lightning_proc and randf() < _manager.lightning_proc_chance

# ============================================
# CHAOTIC STRIKES
# ============================================

func get_chaotic_element() -> String:
	"""Get a random element for chaotic strikes"""
	if not _manager.has_chaotic_strikes:
		return ""
	var elements = ["fire", "ice", "lightning"]
	return elements[randi() % elements.size()]

func get_chaotic_bonus() -> float:
	"""Get damage bonus from chaotic strikes"""
	if not _manager.has_chaotic_strikes:
		return 0.0
	return _manager.chaotic_bonus

# ============================================
# STATIC CHARGE
# ============================================

func consume_static_charge() -> bool:
	"""Consume static charge if ready, returns true if consumed"""
	if _manager.has_static_charge and _manager.static_charge_ready:
		_manager.static_charge_ready = false
		return true
	return false

func is_static_charge_ready() -> bool:
	"""Check if static charge is ready without consuming"""
	return _manager.has_static_charge and _manager.static_charge_ready

# ============================================
# CHAIN REACTION
# ============================================

func has_chain_reaction() -> bool:
	"""Check if chain reaction is enabled"""
	return _manager.has_chain_reaction

func get_chain_reaction_count() -> int:
	"""Get number of targets for chain reaction"""
	if not _manager.has_chain_reaction:
		return 0
	return _manager.chain_reaction_count

func spread_status_effects(from_enemy: Node2D) -> void:
	"""Spread status effects from killed enemy to nearby enemies"""
	if not _manager.has_chain_reaction:
		return

	var enemies = _manager.get_tree().get_nodes_in_group("enemies")
	var spread_count = 0

	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy == from_enemy:
			continue
		if from_enemy.global_position.distance_to(enemy.global_position) > 150.0:
			continue

		spread_count += 1
		if spread_count > _manager.chain_reaction_count:
			break

		# Apply random status effect
		if enemy.has_method("apply_status"):
			var statuses = ["burn", "freeze", "poison"]
			enemy.apply_status(statuses[randi() % statuses.size()])

# ============================================
# VAMPIRISM / LIFESTEAL
# ============================================

func check_vampirism() -> bool:
	"""Roll for vampirism lifesteal on hit"""
	return _manager.has_vampirism and randf() < _manager.vampirism_chance

func get_vampirism_heal_percent() -> float:
	"""Get vampirism heal percent (of max HP)"""
	return 0.05  # 5% of max HP

# ============================================
# RICOCHET
# ============================================

func has_ricochet() -> bool:
	"""Check if ricochet is enabled"""
	return _manager.has_ricochet

func get_ricochet_bounces() -> int:
	"""Get number of ricochet bounces"""
	if not _manager.has_ricochet:
		return 0
	return _manager.ricochet_bounces

# ============================================
# DOUBLE TAP
# ============================================

func check_double_tap() -> bool:
	"""Roll for double tap (extra attack)"""
	return _manager.has_double_tap and randf() < _manager.double_tap_chance

# ============================================
# REAR SHOT
# ============================================

func should_fire_rear_shot() -> bool:
	"""Check if rear shot is enabled"""
	return _manager.has_rear_shot

# ============================================
# BOOMERANG
# ============================================

func has_boomerang() -> bool:
	"""Check if boomerang return is enabled"""
	return _manager.has_boomerang

# ============================================
# RUBBER WALLS (BOUNCE)
# ============================================

func has_rubber_walls() -> bool:
	"""Check if projectiles bounce off walls"""
	return _manager.has_rubber_walls

# ============================================
# SNIPER DAMAGE
# ============================================

func get_sniper_damage_bonus(distance: float) -> float:
	"""Get sniper damage bonus based on distance"""
	if not _manager.has_sniper_damage:
		return 0.0
	# Full bonus at long range
	var range_ratio = clampf(distance / 400.0, 0.0, 1.0)
	return _manager.sniper_bonus * range_ratio

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
# BLEEDING (MELEE)
# ============================================

func has_bleeding() -> bool:
	"""Check if bleeding is enabled"""
	return _manager.has_bleeding

func get_bleeding_dps() -> float:
	"""Get bleeding damage per second"""
	return _manager.bleeding_dps

# ============================================
# KNOCKBACK
# ============================================

func has_knockback() -> bool:
	"""Check if knockback is enabled"""
	return _manager.has_knockback

func get_knockback_force() -> float:
	"""Get knockback force amount"""
	return _manager.knockback_force

# ============================================
# HOMING PROJECTILES
# ============================================

func has_homing() -> bool:
	"""Check if projectiles should home in on targets"""
	return _manager.has_homing

# ============================================
# AGGREGATE ON-HIT CHECK
# ============================================

func process_on_hit_effects(enemy: Node2D, damage: float, distance: float) -> Dictionary:
	"""Process all on-hit effects and return results"""
	var results = {
		"bonus_damage": 0.0,
		"apply_ignite": false,
		"apply_frostbite": false,
		"apply_poison": false,
		"trigger_lightning": false,
		"lifesteal": 0.0,
		"chaotic_element": "",
		"trigger_static_charge": false
	}

	# Distance-based bonuses
	results["bonus_damage"] += get_sniper_damage_bonus(distance)
	results["bonus_damage"] += get_point_blank_bonus(distance)

	# Elemental procs
	if check_ignite():
		results["apply_ignite"] = true

	if check_frostbite():
		results["apply_frostbite"] = true

	if check_toxic_tip():
		results["apply_poison"] = true

	if check_lightning_proc():
		results["trigger_lightning"] = true

	# Chaotic strikes
	if _manager.has_chaotic_strikes:
		results["chaotic_element"] = get_chaotic_element()
		results["bonus_damage"] += get_chaotic_bonus()

	# Static charge
	if consume_static_charge():
		results["trigger_static_charge"] = true

	# Vampirism lifesteal
	if check_vampirism():
		results["lifesteal"] = get_vampirism_heal_percent()

	return results
