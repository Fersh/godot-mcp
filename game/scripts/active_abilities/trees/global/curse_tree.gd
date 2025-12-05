extends RefCounted
class_name CurseTree

# Curse Ability Tree (Global)
# Base: Apply curse debuff to enemies
# Branch A (Weakness): Weaken enemies -> Doom (massive damage after delay)
# Branch B (Spread): Spreading curse -> Plague (jumps on death)

const BASE_NAME = "Curse"
const BASE_ID = "curse"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_weakness(),
		_create_doom()
	)

	tree.add_branch(
		_create_spread(),
		_create_plague()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"curse",
		"Curse",
		"Place a curse on an enemy, reducing their damage.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		6.0
	).with_damage(0.0, 0.0) \
	 .with_range(300.0) \
	 .with_duration(5.0) \
	 .with_effect("curse")

static func _create_weakness() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"curse_weakness",
		"Weakness Curse",
		"Cursed enemies take increased damage from all sources.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		7.0
	).with_damage(0.0, 0.0) \
	 .with_range(350.0) \
	 .with_duration(6.0) \
	 .with_effect("curse") \
	 .with_prerequisite("curse", 0) \
	 .with_prefix("Weakness", BASE_NAME, BASE_ID)

static func _create_doom() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"curse_doom",
		"Mark of Doom",
		"After a delay, cursed enemy takes massive damage.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		15.0
	).with_damage(300.0, 4.0) \
	 .with_range(400.0) \
	 .with_duration(3.0) \
	 .with_effect("curse") \
	 .with_prerequisite("curse_weakness", 0) \
	 .with_signature("3s delay, then massive damage, damage increased by hits during countdown") \
	 .with_suffix("of Doom", BASE_NAME, "Weakness", BASE_ID)

static func _create_spread() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"curse_spread",
		"Spreading Curse",
		"Curse spreads to nearby enemies on application.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		8.0
	).with_damage(10.0, 0.3) \
	 .with_range(300.0) \
	 .with_aoe(150.0) \
	 .with_duration(5.0) \
	 .with_effect("curse") \
	 .with_prerequisite("curse", 1) \
	 .with_prefix("Spreading", BASE_NAME, BASE_ID)

static func _create_plague() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"curse_plague",
		"Plague Curse",
		"Curse jumps to new targets when the host dies.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		12.0
	).with_damage(20.0, 0.5) \
	 .with_range(350.0) \
	 .with_aoe(200.0) \
	 .with_duration(8.0) \
	 .with_effect("curse") \
	 .with_prerequisite("curse_spread", 1) \
	 .with_signature("Jumps to 3 enemies on death, curse stacks increase damage, chain reaction potential") \
	 .with_suffix("of the Plague", BASE_NAME, "Spreading", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["curse", "curse_weakness", "curse_doom", "curse_spread", "curse_plague"]

static func get_tree_name() -> String:
	return "Curse"
