extends RefCounted
class_name ShoutTree

const BASE_NAME = "Battle Cry"
const BASE_ID = "battle_cry"

# Battle Cry Ability Tree (Melee) - DEFENSIVE BUFF
# Base: Reduce incoming damage (defensive stance)
# Branch A (Rallying): Team damage reduction -> Fortress (massive team defense)
# Branch B (Iron): CC immunity + damage reduction -> Unbreakable (invulnerability)

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_rallying_cry(),
		_create_fortress()
	)

	tree.add_branch(
		_create_iron_will(),
		_create_unbreakable()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		BASE_ID,
		BASE_NAME,
		"Let out a battle cry, reducing incoming damage by 40% for 5 seconds.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		12.0
	).with_damage(0.0, 0.0) \
	 .with_duration(5.0) \
	 .with_effect("battle_cry_pixel")

static func _create_rallying_cry() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"shout_rallying",
		"Rallying Battle Cry",
		"Your cry inspires nearby allies, granting 30% damage reduction to all.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		15.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(250.0) \
	 .with_duration(6.0) \
	 .with_effect("rallying_cry") \
	 .with_prerequisite("battle_cry", 0) \
	 .with_prefix("Rallying", BASE_NAME, BASE_ID)

static func _create_fortress() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"shout_fortress",
		"Rallying Battle Cry of the Fortress",
		"Create an aura of protection. Allies take 50% less damage and reflect attacks.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		25.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(350.0) \
	 .with_duration(8.0) \
	 .with_effect("fortress_aura") \
	 .with_prerequisite("shout_rallying", 0) \
	 .with_signature("50% damage reduction aura, 25% damage reflection, enemies slowed") \
	 .with_suffix("of the Fortress", BASE_NAME, "Rallying", BASE_ID)

static func _create_iron_will() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"shout_iron",
		"Iron Battle Cry",
		"Steel yourself. Become immune to crowd control and take 50% less damage.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		14.0
	).with_damage(0.0, 0.0) \
	 .with_duration(4.0) \
	 .with_effect("iron_will") \
	 .with_prerequisite("battle_cry", 1) \
	 .with_prefix("Iron", BASE_NAME, BASE_ID)

static func _create_unbreakable() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"shout_unbreakable",
		"Iron Battle Cry of the Unbreakable",
		"Become truly unbreakable. Immune to all damage and effects.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		30.0
	).with_damage(0.0, 0.0) \
	 .with_duration(3.0) \
	 .with_invulnerability(3.0) \
	 .with_effect("unbreakable") \
	 .with_prerequisite("shout_iron", 1) \
	 .with_signature("3 seconds of total invulnerability, immune to all CC") \
	 .with_suffix("of the Unbreakable", BASE_NAME, "Iron", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["battle_cry", "shout_rallying", "shout_fortress", "shout_iron", "shout_unbreakable"]

static func get_tree_name() -> String:
	return "Battle Cry"
