extends RefCounted
class_name ShieldTree

# Shield/Barrier Ability Tree (Global)
# Base: Create a damage-absorbing shield
# Branch A (Absorb): Convert damage to healing -> Retaliation (damage back)
# Branch B (Bubble): Team shield -> Fortress (massive area shield)

const BASE_NAME = "Barrier"
const BASE_ID = "barrier"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_absorb(),
		_create_retaliation()
	)

	tree.add_branch(
		_create_bubble(),
		_create_fortress()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"barrier",
		"Barrier",
		"Create a shield that absorbs damage.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		12.0
	).with_damage(0.0, 0.0) \
	 .with_duration(5.0) \
	 .with_effect("barrier")

static func _create_absorb() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"barrier_absorb",
		"Absorption Shield",
		"Shield converts 25% of absorbed damage to healing.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		15.0
	).with_damage(0.0, 0.0) \
	 .with_duration(6.0) \
	 .with_effect("barrier") \
	 .with_prerequisite("barrier", 0) \
	 .with_prefix("Absorb", BASE_NAME, BASE_ID)

static func _create_retaliation() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"barrier_retaliation",
		"Retaliation Shield",
		"When shield breaks, explode and reflect all absorbed damage.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		25.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(200.0) \
	 .with_duration(8.0) \
	 .with_effect("barrier") \
	 .with_prerequisite("barrier_absorb", 0) \
	 .with_signature("200% reflected damage, heal 50% of absorbed, stuns nearby") \
	 .with_suffix("of Retaliation", BASE_NAME, "Absorb", BASE_ID)

static func _create_bubble() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"barrier_bubble",
		"Protective Bubble",
		"Create a shield that protects an area.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		18.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(150.0) \
	 .with_duration(5.0) \
	 .with_effect("barrier") \
	 .with_prerequisite("barrier", 1) \
	 .with_prefix("Bubble", BASE_NAME, BASE_ID)

static func _create_fortress() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"barrier_fortress",
		"Fortress",
		"Create an impenetrable fortress. Nothing gets in or out.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		35.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(250.0) \
	 .with_duration(6.0) \
	 .with_effect("barrier") \
	 .with_prerequisite("barrier_bubble", 1) \
	 .with_signature("Complete immunity inside, enemies pushed out, heal over time") \
	 .with_suffix("of the Fortress", BASE_NAME, "Bubble", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["barrier", "barrier_absorb", "barrier_retaliation", "barrier_bubble", "barrier_fortress"]

static func get_tree_name() -> String:
	return "Barrier"
