extends RefCounted
class_name WhirlwindTree

# Whirlwind Ability Tree
# Base: Spin rapidly dealing damage around you
# Branch A (Vacuum): Pull enemies in -> of Singularity
# Branch B (Fiery): Add fire damage -> of Inferno

const BASE_NAME = "Whirlwind"
const BASE_ID = "whirlwind"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_vacuum_spin(),
		_create_singularity()
	)

	tree.add_branch(
		_create_flame_spin(),
		_create_inferno_tornado()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		BASE_ID,
		BASE_NAME,
		"Spin rapidly, damaging all enemies around you.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		8.0
	).with_damage(25.0, 1.0) \
	 .with_aoe(120.0) \
	 .with_duration(2.0) \
	 .with_movement() \
	 .with_effect("whirlwind")

static func _create_vacuum_spin() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"whirlwind_vacuum",
		"Vacuum Whirlwind",
		"Pull nearby enemies toward you while spinning.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		9.0
	).with_damage(30.0, 1.1) \
	 .with_aoe(180.0) \
	 .with_duration(2.5) \
	 .with_knockback(-150.0) \
	 .with_movement() \
	 .with_effect("vacuum_spin") \
	 .with_prerequisite("whirlwind", 0) \
	 .with_prefix("Vacuum", BASE_NAME, BASE_ID)

static func _create_singularity() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"whirlwind_singularity",
		"Vacuum Whirlwind of Singularity",
		"Become a gravitational anomaly, shredding all who approach.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		20.0
	).with_damage(40.0, 1.5) \
	 .with_aoe(250.0) \
	 .with_duration(4.0) \
	 .with_knockback(-300.0) \
	 .with_movement() \
	 .with_effect("singularity") \
	 .with_prerequisite("whirlwind_vacuum", 0) \
	 .with_signature("Massive pull radius, damage scales with proximity") \
	 .with_suffix("of Singularity", BASE_NAME, "Vacuum", BASE_ID)

static func _create_flame_spin() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"whirlwind_flame",
		"Fiery Whirlwind",
		"Leaves trails of fire while spinning.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		9.0
	).with_damage(30.0, 1.2) \
	 .with_aoe(130.0) \
	 .with_duration(2.5) \
	 .with_movement() \
	 .with_effect("flame_whirlwind") \
	 .with_prerequisite("whirlwind", 1) \
	 .with_prefix("Fiery", BASE_NAME, BASE_ID)

static func _create_inferno_tornado() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"whirlwind_inferno",
		"Fiery Whirlwind of Inferno",
		"Transform into a massive fire tornado that scorches everything.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		22.0
	).with_damage(50.0, 1.8) \
	 .with_aoe(200.0) \
	 .with_duration(5.0) \
	 .with_movement() \
	 .with_effect("inferno_tornado") \
	 .with_prerequisite("whirlwind_flame", 1) \
	 .with_signature("Leave burning ground, enemies take 50% more fire damage") \
	 .with_suffix("of Inferno", BASE_NAME, "Fiery", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["whirlwind", "whirlwind_vacuum", "whirlwind_singularity", "whirlwind_flame", "whirlwind_inferno"]

static func get_tree_name() -> String:
	return "Whirlwind"
