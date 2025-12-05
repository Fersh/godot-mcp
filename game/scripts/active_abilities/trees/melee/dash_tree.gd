extends RefCounted
class_name DashTree

# Dash Strike Ability Tree
# Base: Quick dash that damages enemies in path
# Branch A (Rushing): Chain dashes -> of Oblivion
# Branch B (Shadow): Leave damaging clone -> of Shadows

const BASE_NAME = "Dash Strike"
const BASE_ID = "dash_strike"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_blade_rush(),
		_create_omnislash()
	)

	tree.add_branch(
		_create_afterimage(),
		_create_shadow_legion()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		BASE_ID,
		BASE_NAME,
		"Dash forward, damaging enemies in your path.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		4.0
	).with_damage(35.0, 1.0) \
	 .with_range(200.0) \
	 .with_movement() \
	 .with_effect("dash_strike_pixel")

static func _create_blade_rush() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"dash_blade_rush",
		"Rushing Dash Strike",
		"Chain up to 3 dashes in quick succession.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		6.0
	).with_damage(30.0, 1.1) \
	 .with_range(150.0) \
	 .with_projectiles(3, 0) \
	 .with_movement() \
	 .with_effect("blade_rush") \
	 .with_prerequisite("dash_strike", 0) \
	 .with_prefix("Rushing", BASE_NAME, BASE_ID)

static func _create_omnislash() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"dash_omnislash",
		"Rushing Dash Strike of Oblivion",
		"Teleport between enemies, striking each one multiple times.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		20.0
	).with_damage(50.0, 1.8) \
	 .with_range(400.0) \
	 .with_duration(2.0) \
	 .with_movement() \
	 .with_invulnerability(2.0) \
	 .with_effect("omnislash") \
	 .with_prerequisite("dash_blade_rush", 0) \
	 .with_signature("Invulnerable, teleport to 8 enemies, hit each 3 times") \
	 .with_suffix("of Oblivion", BASE_NAME, "Rushing", BASE_ID)

static func _create_afterimage() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"dash_afterimage",
		"Shadow Dash Strike",
		"Leave a damaging clone at your start position.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		5.0
	).with_damage(40.0, 1.2) \
	 .with_range(200.0) \
	 .with_duration(2.0) \
	 .with_movement() \
	 .with_effect("afterimage") \
	 .with_prerequisite("dash_strike", 1) \
	 .with_prefix("Shadow", BASE_NAME, BASE_ID)

static func _create_shadow_legion() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"dash_shadow_legion",
		"Shadow Dash Strike of Shadows",
		"Create 4 shadow clones that mimic your attacks.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		18.0
	).with_damage(25.0, 1.0) \
	 .with_duration(8.0) \
	 .with_effect("shadow_legion") \
	 .with_prerequisite("dash_afterimage", 1) \
	 .with_signature("4 shadow clones follow you, each dealing 25% of your damage") \
	 .with_suffix("of Shadows", BASE_NAME, "Shadow", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["dash_strike", "dash_blade_rush", "dash_omnislash", "dash_afterimage", "dash_shadow_legion"]

static func get_tree_name() -> String:
	return "Dash Strike"
