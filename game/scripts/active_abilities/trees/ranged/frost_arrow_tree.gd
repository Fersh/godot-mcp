extends RefCounted
class_name FrostArrowTree

# Frost Arrow Ability Tree (Ranged)
# Base: Arrow that slows enemies
# Branch A (Freeze): Can freeze enemies -> Ice Age (frozen enemies shatter nearby)
# Branch B (Chill): Stacking slow -> Frostbite (max stacks = damage burst)

const BASE_NAME = "Frost Arrow"
const BASE_ID = "frost_arrow"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_freezing(),
		_create_ice_age()
	)

	tree.add_branch(
		_create_chilling(),
		_create_frostbite()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"frost_arrow",
		"Frost Arrow",
		"Fire an icy arrow that slows enemies.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		5.0
	).with_damage(30.0, 1.0) \
	 .with_projectiles(1, 500.0) \
	 .with_slow(0.3, 3.0) \
	 .with_effect("frost_arrow")

static func _create_freezing() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"frost_freezing",
		"Freezing Arrow",
		"Chance to freeze enemies solid for 1.5 seconds.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		6.0
	).with_damage(35.0, 1.1) \
	 .with_projectiles(1, 500.0) \
	 .with_stun(1.5) \
	 .with_effect("freezing_arrow") \
	 .with_prerequisite("frost_arrow", 0) \
	 .with_prefix("Freezing", BASE_NAME, BASE_ID)

static func _create_ice_age() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"frost_ice_age",
		"Ice Age",
		"Frozen enemies explode into ice shards on death.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		12.0
	).with_damage(40.0, 1.3) \
	 .with_projectiles(1, 500.0) \
	 .with_aoe(120.0) \
	 .with_stun(2.0) \
	 .with_effect("ice_age") \
	 .with_prerequisite("frost_freezing", 0) \
	 .with_signature("Guaranteed freeze, death causes AoE that can chain freeze") \
	 .with_suffix("of the Ice Age", BASE_NAME, "Freezing", BASE_ID)

static func _create_chilling() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"frost_chilling",
		"Chilling Shot",
		"Slow stacks up to 80%. Attack speed also reduced.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		5.0
	).with_damage(28.0, 0.9) \
	 .with_projectiles(1, 550.0) \
	 .with_slow(0.2, 4.0) \
	 .with_effect("chilling_shot") \
	 .with_prerequisite("frost_arrow", 1) \
	 .with_prefix("Chilling", BASE_NAME, BASE_ID)

static func _create_frostbite() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"frost_frostbite",
		"Frostbite",
		"At max slow stacks, deal massive damage and reset stacks.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		6.0
	).with_damage(25.0, 0.8) \
	 .with_projectiles(1, 600.0) \
	 .with_slow(0.15, 5.0) \
	 .with_effect("frostbite") \
	 .with_prerequisite("frost_chilling", 1) \
	 .with_signature("Max stacks triggers 300% damage burst, brief freeze") \
	 .with_suffix("of Frostbite", BASE_NAME, "Chilling", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["frost_arrow", "frost_freezing", "frost_ice_age", "frost_chilling", "frost_frostbite"]

static func get_tree_name() -> String:
	return "Frost Arrow"
