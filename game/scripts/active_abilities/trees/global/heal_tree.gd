extends RefCounted
class_name HealTree

# Healing Light Ability Tree (Global - available to all classes)
# Base: Heal yourself
# Branch A (Regen): AoE heal zone -> Sanctuary (heal + damage reduction zone)
# Branch B (Emergency): Big heal at low HP -> Martyrdom (full heal + vulnerability)

const BASE_NAME = "Healing Light"
const BASE_ID = "healing_light"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_regen_aura(),
		_create_sanctuary()
	)

	tree.add_branch(
		_create_emergency_heal(),
		_create_martyrdom()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"healing_light",
		"Healing Light",
		"Channel holy light to restore your health.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		10.0
	).with_damage(40.0, 1.0) \
	 .with_effect("healing_light")

static func _create_regen_aura() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"heal_regen",
		"Regeneration Aura",
		"Create a zone that heals over time.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		15.0
	).with_damage(10.0, 0.5) \
	 .with_aoe(150.0) \
	 .with_duration(6.0) \
	 .with_effect("healing_light") \
	 .with_prerequisite("healing_light", 0)

static func _create_sanctuary() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"heal_sanctuary",
		"Sanctuary",
		"Create a holy zone that heals and reduces damage taken.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		25.0
	).with_damage(15.0, 0.6) \
	 .with_aoe(200.0) \
	 .with_duration(8.0) \
	 .with_effect("healing_light") \
	 .with_prerequisite("heal_regen", 0) \
	 .with_signature("Heal zone + 30% damage reduction while inside")

static func _create_emergency_heal() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"heal_emergency",
		"Emergency Heal",
		"Desperate healing. More effective at low health.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		12.0
	).with_damage(50.0, 1.2) \
	 .with_effect("healing_light") \
	 .with_prerequisite("healing_light", 1)

static func _create_martyrdom() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"heal_martyr",
		"Martyrdom",
		"Fully restore health, but take increased damage temporarily.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		45.0
	).with_damage(0.0, 0.0) \
	 .with_duration(10.0) \
	 .with_effect("healing_light") \
	 .with_prerequisite("heal_emergency", 1) \
	 .with_signature("Full heal, but +50% damage taken for 10 seconds")

static func get_all_ability_ids() -> Array[String]:
	return ["healing_light", "heal_regen", "heal_sanctuary", "heal_emergency", "heal_martyr"]

static func get_tree_name() -> String:
	return "Healing Light"
