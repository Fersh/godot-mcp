extends RefCounted
class_name BoomerangTree

# Boomerang Ability Tree (Ranged)
# Base: Throw returning projectile
# Branch A (Multi): Throw multiple -> Blade Storm (orbiting blades return)
# Branch B (Track): Homing boomerang -> Predator (hunts down targets)

const BASE_NAME = "Boomerang"
const BASE_ID = "boomerang"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_multi_rang(),
		_create_blade_storm()
	)

	tree.add_branch(
		_create_tracking(),
		_create_predator()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"boomerang",
		"Boomerang",
		"Throw a boomerang that returns to you.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		4.0
	).with_damage(35.0, 1.0) \
	 .with_range(350.0) \
	 .with_projectiles(1, 500.0) \
	 .with_effect("boomerang")

static func _create_multi_rang() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"boomerang_multi",
		"Multi-Rang",
		"Throw 3 boomerangs in a spread pattern.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		5.0
	).with_damage(28.0, 0.9) \
	 .with_range(350.0) \
	 .with_projectiles(3, 500.0) \
	 .with_effect("multi_rang") \
	 .with_prerequisite("boomerang", 0)

static func _create_blade_storm() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"boomerang_storm",
		"Blade Storm",
		"Launch 6 blades that orbit outward and return.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		12.0
	).with_damage(25.0, 0.8) \
	 .with_aoe(300.0) \
	 .with_projectiles(6, 400.0) \
	 .with_effect("blade_storm") \
	 .with_prerequisite("boomerang_multi", 0) \
	 .with_signature("6 blades expand then contract, hit twice, spin for 3 seconds")

static func _create_tracking() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"boomerang_track",
		"Tracking Rang",
		"Boomerang homes in on nearest enemy.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		5.0
	).with_damage(40.0, 1.1) \
	 .with_range(400.0) \
	 .with_projectiles(1, 550.0) \
	 .with_effect("tracking_rang") \
	 .with_prerequisite("boomerang", 1)

static func _create_predator() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"boomerang_predator",
		"Predator Disc",
		"Intelligent disc that hunts enemies until it kills 5.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		18.0
	).with_damage(50.0, 1.3) \
	 .with_range(600.0) \
	 .with_duration(8.0) \
	 .with_effect("predator_disc") \
	 .with_prerequisite("boomerang_track", 1) \
	 .with_signature("Hunts until 5 kills or 8 seconds, +20% damage per kill")

static func get_all_ability_ids() -> Array[String]:
	return ["boomerang", "boomerang_multi", "boomerang_storm", "boomerang_track", "boomerang_predator"]

static func get_tree_name() -> String:
	return "Boomerang"
