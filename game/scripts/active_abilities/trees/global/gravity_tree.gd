extends RefCounted
class_name GravityTree

# Gravity/Black Hole Ability Tree (Global)
# Base: Pull enemies together
# Branch A (Crush): Compress for damage -> Singularity (massive gravity crush)
# Branch B (Reverse): Push enemies away -> Supernova (massive explosion)

const BASE_NAME = "Gravity Well"
const BASE_ID = "gravity_well"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_crush(),
		_create_singularity()
	)

	tree.add_branch(
		_create_repulse(),
		_create_supernova()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"gravity_well",
		"Gravity Well",
		"Create a point that pulls enemies together.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		12.0
	).with_damage(20.0, 0.8) \
	 .with_aoe(180.0) \
	 .with_duration(3.0) \
	 .with_knockback(-200.0) \
	 .with_effect("gravity_well") \
	 .with_icon("res://assets/sprites/icons/demonskills/PNG/Group42_GravityWell.png")

static func _create_crush() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"gravity_crush",
		"Crushing Gravity",
		"Compress enemies together, dealing damage over time.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		15.0
	).with_damage(30.0, 1.0) \
	 .with_aoe(150.0) \
	 .with_duration(4.0) \
	 .with_knockback(-300.0) \
	 .with_slow(0.5, 4.0) \
	 .with_effect("gravity_well") \
	 .with_prerequisite("gravity_well", 0)

static func _create_singularity() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"gravity_singularity",
		"Singularity",
		"Create a black hole that consumes all nearby enemies.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		30.0
	).with_damage(50.0, 1.5) \
	 .with_aoe(250.0) \
	 .with_duration(5.0) \
	 .with_knockback(-500.0) \
	 .with_effect("gravity_well") \
	 .with_prerequisite("gravity_crush", 0) \
	 .with_signature("Inescapable pull, damage increases near center, collapse explosion")

static func _create_repulse() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"gravity_repulse",
		"Repulse",
		"Reverse gravity and push all enemies away.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		10.0
	).with_damage(35.0, 1.0) \
	 .with_aoe(200.0) \
	 .with_knockback(400.0) \
	 .with_effect("gravity_well") \
	 .with_prerequisite("gravity_well", 1)

static func _create_supernova() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"gravity_supernova",
		"Supernova",
		"Collapse inward then explode outward with massive force.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		35.0
	).with_damage(100.0, 2.0) \
	 .with_aoe(350.0) \
	 .with_stun(1.5) \
	 .with_knockback(600.0) \
	 .with_effect("gravity_well") \
	 .with_prerequisite("gravity_repulse", 1) \
	 .with_signature("Pull in for 1s, then massive explosion, leaves burning ground")

static func get_all_ability_ids() -> Array[String]:
	return ["gravity_well", "gravity_crush", "gravity_singularity", "gravity_repulse", "gravity_supernova"]

static func get_tree_name() -> String:
	return "Gravity Well"
