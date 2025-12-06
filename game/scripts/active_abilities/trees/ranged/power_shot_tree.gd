extends RefCounted
class_name PowerShotTree

# Power Shot Ability Tree
# Base: Charged high-damage single arrow
# Branch A (Piercing): Arrow pierces through enemies -> of Annihilation (infinite pierce)
# Branch B (Explosive): Arrow explodes on impact -> of Devastation (massive AoE)
# Branch C (Ballista): Heavy siege shot -> Ballista Strike (massive single-target pierce)
#
# Naming: "Power Shot" -> "Piercing Power Shot" -> "Piercing Power Shot of Annihilation"
#                      -> "Explosive Power Shot" -> "Explosive Power Shot of Devastation"
#                      -> "Heavy Power Shot" -> "Heavy Power Shot of the Ballista"

const BASE_NAME = "Power Shot"
const BASE_ID = "power_shot"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	# Branch A: Piercing path (penetration and line damage)
	tree.add_branch(
		_create_piercing_shot(),
		_create_rail_gun()
	)

	# Branch B: Explosive path (AoE destruction)
	tree.add_branch(
		_create_explosive_shot(),
		_create_nuke_arrow()
	)

	# Branch C: Ballista path (heavy single-target)
	tree.add_branch(
		_create_heavy_shot(),
		_create_ballista_strike()
	)

	return tree

# ============================================
# BASE ABILITY (TIER 1)
# ============================================

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		BASE_ID,
		BASE_NAME,
		"Charge and release a powerful arrow that deals heavy damage to a single target.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		7.0  # 7 second cooldown
	).with_damage(80.0, 2.0) \
	 .with_projectiles(1, 600.0) \
	 .with_cast_time(0.3) \
	 .with_effect("power_shot")

# ============================================
# TIER 2 - BRANCH A: PIERCING PATH
# ============================================

static func _create_piercing_shot() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"power_shot_pierce",
		"Piercing Shot",
		"Pierces through up to 5 enemies, dealing full damage to each.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		7.0
	).with_damage(85.0, 2.2) \
	 .with_projectiles(1, 700.0) \
	 .with_cast_time(0.3) \
	 .with_effect("piercing_shot") \
	 .with_prerequisite("power_shot", 0)

# ============================================
# TIER 3 - BRANCH A: RAIL GUN (SIGNATURE)
# ============================================

static func _create_rail_gun() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"power_shot_railgun",
		"Rail Gun",
		"Fire a devastating beam that pierces infinitely across the entire screen.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		10.0  # Longer cooldown for screen-wide damage
	).with_damage(120.0, 3.0) \
	 .with_projectiles(1, 2000.0) \
	 .with_cast_time(0.5) \
	 .with_effect("railgun") \
	 .with_prerequisite("power_shot_pierce", 0) \
	 .with_signature("Infinite pierce beam across the entire screen")

# ============================================
# TIER 2 - BRANCH B: EXPLOSIVE PATH
# ============================================

static func _create_explosive_shot() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"power_shot_explosive",
		"Explosive Shot",
		"Explodes on impact, dealing AoE damage in a radius.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		8.0
	).with_damage(70.0, 1.8) \
	 .with_projectiles(1, 550.0) \
	 .with_aoe(120.0) \
	 .with_cast_time(0.3) \
	 .with_effect("explosive_arrow") \
	 .with_prerequisite("power_shot", 1)

# ============================================
# TIER 3 - BRANCH B: NUKE ARROW (SIGNATURE)
# ============================================

static func _create_nuke_arrow() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"power_shot_nuke",
		"Nuke Arrow",
		"Launch a devastating payload that creates a massive explosion. Enemies are obliterated.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		12.0  # Long cooldown for massive power
	).with_damage(150.0, 2.5) \
	 .with_projectiles(1, 400.0) \
	 .with_aoe(300.0) \
	 .with_cast_time(0.5) \
	 .with_stun(1.0) \
	 .with_knockback(400.0) \
	 .with_effect("nuke_explosion") \
	 .with_prerequisite("power_shot_explosive", 1) \
	 .with_signature("Massive 300-unit radius explosion with stun and knockback")

# ============================================
# TIER 2 - BRANCH C: BALLISTA PATH
# ============================================

static func _create_heavy_shot() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"power_shot_heavy",
		"Heavy Shot",
		"Fire a heavy bolt with extended range and armor penetration.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		10.0
	).with_damage(100.0, 2.5) \
	 .with_projectiles(1, 700.0) \
	 .with_range(600.0) \
	 .with_cast_time(0.5) \
	 .with_effect("heavy_shot") \
	 .with_prerequisite("power_shot", 2)

# ============================================
# TIER 3 - BRANCH C: BALLISTA STRIKE (SIGNATURE)
# ============================================

static func _create_ballista_strike() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"power_shot_ballista",
		"Ballista Strike",
		"Fire an immense siege bolt that pierces all enemies for devastating damage.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		18.0
	).with_damage(200.0, 4.0) \
	 .with_projectiles(1, 900.0) \
	 .with_range(800.0) \
	 .with_cast_time(0.8) \
	 .with_effect("ballista_strike") \
	 .with_prerequisite("power_shot_heavy", 2) \
	 .with_signature("Massive piercing bolt, ignores armor, 800 range, devastates single target")

# ============================================
# UTILITY FUNCTIONS
# ============================================

static func get_all_ability_ids() -> Array[String]:
	"""Get all ability IDs in this tree"""
	return [
		"power_shot",
		"power_shot_pierce",
		"power_shot_railgun",
		"power_shot_explosive",
		"power_shot_nuke",
		"power_shot_heavy",
		"power_shot_ballista"
	]

static func get_tree_name() -> String:
	return "Power Shot"

static func get_tree_description() -> String:
	return "High-damage single shots. Choose between piercing everything or explosive destruction."
