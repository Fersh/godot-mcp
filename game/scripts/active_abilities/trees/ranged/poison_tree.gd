extends RefCounted
class_name PoisonTree

# Poison Arrow Ability Tree (Ranged)
# Base: Arrow that poisons enemies
# Branch A (Plague): Spreads on death -> Pandemic (massive spread radius)
# Branch B (Toxic): Stacking poison -> Venom (instant stacks = instant death)

const BASE_NAME = "Poison Arrow"
const BASE_ID = "poison_arrow"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_plague(),
		_create_pandemic()
	)

	tree.add_branch(
		_create_toxic(),
		_create_venom()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"poison_arrow",
		"Poison Arrow",
		"Fire a poisoned arrow that deals damage over time.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		5.0
	).with_damage(20.0, 0.8) \
	 .with_projectiles(1, 550.0) \
	 .with_duration(5.0) \
	 .with_effect("poison_arrow")

static func _create_plague() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"poison_plague",
		"Plague Arrow",
		"Poison spreads to nearby enemies when host dies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		6.0
	).with_damage(18.0, 0.7) \
	 .with_projectiles(1, 550.0) \
	 .with_aoe(100.0) \
	 .with_duration(6.0) \
	 .with_effect("plague_arrow") \
	 .with_prerequisite("poison_arrow", 0)

static func _create_pandemic() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"poison_pandemic",
		"Pandemic",
		"Poison spreads infinitely. Each spread increases damage.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		15.0
	).with_damage(15.0, 0.6) \
	 .with_projectiles(1, 550.0) \
	 .with_aoe(150.0) \
	 .with_duration(8.0) \
	 .with_effect("pandemic") \
	 .with_prerequisite("poison_plague", 0) \
	 .with_signature("Infinite spread, +10% damage per spread, slows 20%")

static func _create_toxic() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"poison_toxic",
		"Toxic Shot",
		"Poison stacks up to 5 times, increasing damage per stack.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		4.0
	).with_damage(15.0, 0.6) \
	 .with_projectiles(1, 600.0) \
	 .with_duration(4.0) \
	 .with_effect("toxic_shot") \
	 .with_prerequisite("poison_arrow", 1)

static func _create_venom() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"poison_venom",
		"Lethal Venom",
		"At 10 poison stacks, enemy takes massive burst damage.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		5.0
	).with_damage(12.0, 0.5) \
	 .with_projectiles(1, 650.0) \
	 .with_duration(5.0) \
	 .with_effect("lethal_venom") \
	 .with_prerequisite("poison_toxic", 1) \
	 .with_signature("10 stacks = 500% instant damage burst, stacks build faster")

static func get_all_ability_ids() -> Array[String]:
	return ["poison_arrow", "poison_plague", "poison_pandemic", "poison_toxic", "poison_venom"]

static func get_tree_name() -> String:
	return "Poison Arrow"
