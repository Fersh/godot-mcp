extends RefCounted
class_name CleaveTree

# Cleave Ability Tree
# Base: Wide arc attack hitting multiple enemies
# Branch A (Executioner): Bonus damage to low HP enemies -> of Judgment (execute mechanic)
# Branch B (Sweeping): Slow enemies -> of Thunder (knockback + stun)
#
# Naming: Base "Cleave" -> "Executioner's Cleave" -> "Executioner's Cleave of Judgment"
#                       -> "Sweeping Cleave" -> "Sweeping Cleave of Thunder"

const BASE_NAME = "Cleave"
const BASE_ID = "cleave"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	# Branch A: Executioner path (high damage to wounded)
	tree.add_branch(
		_create_executioner_swing(),
		_create_guillotine()
	)

	# Branch B: Crowd Control path (slow and control)
	tree.add_branch(
		_create_crowd_control_cleave(),
		_create_shockwave_cleave()
	)

	return tree

# ============================================
# BASE ABILITY (TIER 1)
# ============================================

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		BASE_ID,
		BASE_NAME,
		"Swing your weapon in a wide arc, damaging all enemies in front of you.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		8.0  # 8 second cooldown
	).with_damage(55.0, 1.5) \
	 .with_aoe(180.0) \
	 .with_effect("cleave_pixel")

# ============================================
# TIER 2 - BRANCH A: EXECUTIONER PATH
# ============================================

static func _create_executioner_swing() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"cleave_executioner",
		"Executioner's Cleave",  # Will be overwritten by with_prefix
		"Deals 2x damage to enemies below 50% HP.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		8.0
	).with_damage(60.0, 1.8) \
	 .with_aoe(180.0) \
	 .with_effect("cleave_executioner") \
	 .with_prerequisite("cleave", 0) \
	 .with_prefix("Executioner's", BASE_NAME, BASE_ID)

# ============================================
# TIER 3 - BRANCH A: GUILLOTINE (SIGNATURE)
# ============================================

static func _create_guillotine() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"cleave_guillotine",
		"Executioner's Cleave of Judgment",  # Will be overwritten by with_suffix
		"Execute enemies below 20% HP instantly. Deals massive damage to others.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		10.0  # Slightly longer cooldown for power
	).with_damage(80.0, 2.5) \
	 .with_aoe(200.0) \
	 .with_effect("guillotine") \
	 .with_prerequisite("cleave_executioner", 0) \
	 .with_signature("Instant execute enemies below 20% HP") \
	 .with_suffix("of Judgment", BASE_NAME, "Executioner's", BASE_ID)

# ============================================
# TIER 2 - BRANCH B: CROWD CONTROL PATH
# ============================================

static func _create_crowd_control_cleave() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"cleave_crowd",
		"Sweeping Cleave",  # Will be overwritten by with_prefix
		"Slows enemies by 60% for 2 seconds.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		8.0
	).with_damage(50.0, 1.5) \
	 .with_aoe(200.0) \
	 .with_slow(0.6, 2.0) \
	 .with_effect("cleave_frost") \
	 .with_prerequisite("cleave", 1) \
	 .with_prefix("Sweeping", BASE_NAME, BASE_ID)

# ============================================
# TIER 3 - BRANCH B: SHOCKWAVE CLEAVE (SIGNATURE)
# ============================================

static func _create_shockwave_cleave() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"cleave_shockwave",
		"Sweeping Cleave of Thunder",  # Will be overwritten by with_suffix
		"Unleash a devastating shockwave that knocks enemies back and stuns them.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		10.0
	).with_damage(65.0, 2.0) \
	 .with_aoe(250.0) \
	 .with_knockback(300.0) \
	 .with_stun(1.5) \
	 .with_slow(0.5, 3.0) \
	 .with_effect("shockwave") \
	 .with_prerequisite("cleave_crowd", 1) \
	 .with_signature("Massive knockback wave that stuns enemies") \
	 .with_suffix("of Thunder", BASE_NAME, "Sweeping", BASE_ID)

# ============================================
# UTILITY FUNCTIONS
# ============================================

static func get_all_ability_ids() -> Array[String]:
	"""Get all ability IDs in this tree"""
	return [
		"cleave",
		"cleave_executioner",
		"cleave_guillotine",
		"cleave_crowd",
		"cleave_shockwave"
	]

static func get_tree_name() -> String:
	return "Cleave"

static func get_tree_description() -> String:
	return "Wide arc melee attacks. Choose between executing wounded enemies or controlling crowds."
