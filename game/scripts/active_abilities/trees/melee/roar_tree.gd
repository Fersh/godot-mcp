extends RefCounted
class_name RoarTree

# Roar/Fear Ability Tree (Melee)
# Base: Terrifying roar that fears enemies
# Branch A (Intimidate): Reduce enemy damage -> Crushing Presence (permanent debuff)
# Branch B (Enrage): Self buff after roar -> Blood Rage (damage on hit fuels power)

const BASE_NAME = "Terrifying Roar"
const BASE_ID = "roar"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_intimidate(),
		_create_crushing_presence()
	)

	tree.add_branch(
		_create_enrage(),
		_create_blood_rage()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"roar",
		"Terrifying Roar",
		"Let out a roar that causes enemies to flee briefly.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		10.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(200.0) \
	 .with_duration(2.0) \
	 .with_effect("roar")

static func _create_intimidate() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"roar_intimidate",
		"Intimidating Roar",
		"Feared enemies deal 30% less damage for 5 seconds.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		12.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(250.0) \
	 .with_duration(5.0) \
	 .with_effect("intimidate") \
	 .with_prerequisite("roar", 0) \
	 .with_prefix("Intimidating", BASE_NAME, BASE_ID)

static func _create_crushing_presence() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"roar_crushing",
		"Crushing Presence",
		"Your presence permanently weakens nearby enemies.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		30.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(300.0) \
	 .with_duration(15.0) \
	 .with_effect("crushing_presence") \
	 .with_prerequisite("roar_intimidate", 0) \
	 .with_signature("Aura: -40% enemy damage, -30% enemy speed, fear on first contact") \
	 .with_suffix("of Domination", BASE_NAME, "Intimidating", BASE_ID)

static func _create_enrage() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"roar_enrage",
		"Enraging Roar",
		"Roar buffs your damage by 40% for 6 seconds.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		14.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(200.0) \
	 .with_duration(6.0) \
	 .with_effect("enrage") \
	 .with_prerequisite("roar", 1) \
	 .with_prefix("Enraging", BASE_NAME, BASE_ID)

static func _create_blood_rage() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"roar_blood_rage",
		"Blood Rage",
		"Enter blood rage. Each hit increases your power.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		25.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(200.0) \
	 .with_duration(10.0) \
	 .with_effect("blood_rage") \
	 .with_prerequisite("roar_enrage", 1) \
	 .with_signature("+10% damage per hit (max 100%), lifesteal, attack speed boost") \
	 .with_suffix("of Blood Rage", BASE_NAME, "Enraging", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["roar", "roar_intimidate", "roar_crushing", "roar_enrage", "roar_blood_rage"]

static func get_tree_name() -> String:
	return "Roar"
