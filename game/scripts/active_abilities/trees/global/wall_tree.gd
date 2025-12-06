extends RefCounted
class_name WallTree

# Wall Ability Tree (Global - available to all classes)
# Base: Create a wall of fire that damages enemies
# Branch A (Fire): Infernal Wall -> Floor is Lava (massive ground fire zone)
# Branch B (Ice): Ice Barricade -> Frozen Fortress (ice dome that freezes all)

const BASE_NAME = "Flame Wall"
const BASE_ID = "flame_wall"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	# Branch A: Fire path (spreading fire)
	tree.add_branch(
		_create_infernal_wall(),
		_create_floor_is_lava()
	)

	# Branch B: Ice path (defensive barriers)
	tree.add_branch(
		_create_ice_barricade(),
		_create_frozen_fortress()
	)

	return tree

# ============================================
# BASE ABILITY (TIER 1)
# ============================================

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"flame_wall",
		"Flame Wall",
		"Summon a wall of fire that burns enemies walking through.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.DIRECTION,
		14.0
	).with_damage(35.0, 1.5) \
	 .with_aoe(350.0) \
	 .with_duration(6.0) \
	 .with_effect("flame_wall")

# ============================================
# TIER 2 - BRANCH A: FIRE PATH
# ============================================

static func _create_infernal_wall() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"wall_infernal",
		"Infernal Flame Wall",
		"A wider, hotter wall of fire that burns more intensely.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.DIRECTION,
		14.0
	).with_damage(50.0, 1.8) \
	 .with_aoe(450.0) \
	 .with_duration(7.0) \
	 .with_effect("flame_wall") \
	 .with_prerequisite("flame_wall", 0) \
	 .with_prefix("Infernal", BASE_NAME, BASE_ID)

# ============================================
# TIER 3 - BRANCH A: FLOOR IS LAVA (SIGNATURE)
# ============================================

static func _create_floor_is_lava() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"wall_lava",
		"Infernal Flame Wall of Magma",
		"Convert the ground around you to magma, burning all who stand on it.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		25.0
	).with_damage(15.0, 2.0) \
	 .with_aoe(400.0) \
	 .with_duration(8.0) \
	 .with_effect("floor_is_lava") \
	 .with_prerequisite("wall_infernal", 0) \
	 .with_signature("Massive lava zone around you, constant burn damage, enemies slowed") \
	 .with_suffix("of Magma", BASE_NAME, "Infernal", BASE_ID)

# ============================================
# TIER 2 - BRANCH B: ICE PATH
# ============================================

static func _create_ice_barricade() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"wall_ice",
		"Frozen Flame Wall",
		"Create an ice wall that blocks enemies and explodes, freezing nearby foes.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.DIRECTION,
		16.0
	).with_damage(28.0, 1.5) \
	 .with_aoe(150.0) \
	 .with_duration(3.0) \
	 .with_stun(2.5) \
	 .with_effect("ice_barricade") \
	 .with_prerequisite("flame_wall", 1) \
	 .with_prefix("Frozen", BASE_NAME, BASE_ID)

# ============================================
# TIER 3 - BRANCH B: FROZEN FORTRESS (SIGNATURE)
# ============================================

static func _create_frozen_fortress() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"wall_fortress",
		"Frozen Flame Wall of the Fortress",
		"Create an impenetrable ice dome that freezes all enemies inside.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		25.0
	).with_damage(40.0, 1.8) \
	 .with_aoe(250.0) \
	 .with_duration(5.0) \
	 .with_stun(4.0) \
	 .with_effect("frozen_fortress") \
	 .with_prerequisite("wall_ice", 1) \
	 .with_signature("Ice dome blocks projectiles, freezes all inside for 4s, explodes on end") \
	 .with_suffix("of the Fortress", BASE_NAME, "Frozen", BASE_ID)

# ============================================
# UTILITY FUNCTIONS
# ============================================

static func get_all_ability_ids() -> Array[String]:
	return ["flame_wall", "wall_infernal", "wall_lava", "wall_ice", "wall_fortress"]

static func get_tree_name() -> String:
	return "Wall"
