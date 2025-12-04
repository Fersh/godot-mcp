extends RefCounted
class_name ImpaleTree

# Impale Ability Tree (Melee)
# Base: Thrust attack that impales enemies
# Branch A (Skewer): Pierce multiple enemies -> Shish Kebab (carry enemies on weapon)
# Branch B (Pin): Pin enemy in place -> Crucify (pin to nearest wall)

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_skewer(),
		_create_shish_kebab()
	)

	tree.add_branch(
		_create_pin(),
		_create_crucify()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"impale",
		"Impale",
		"Thrust forward, impaling an enemy for bonus damage.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		5.0
	).with_damage(55.0, 1.4) \
	 .with_range(180.0) \
	 .with_effect("impale")

static func _create_skewer() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"impale_skewer",
		"Skewer",
		"Pierce through up to 3 enemies in a line.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		6.0
	).with_damage(45.0, 1.2) \
	 .with_range(250.0) \
	 .with_effect("skewer") \
	 .with_prerequisite("impale", 0)

static func _create_shish_kebab() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"impale_kebab",
		"Shish Kebab",
		"Skewer enemies and carry them, then slam them down.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		12.0
	).with_damage(40.0, 1.1) \
	 .with_range(300.0) \
	 .with_aoe(120.0) \
	 .with_stun(1.5) \
	 .with_movement() \
	 .with_effect("shish_kebab") \
	 .with_prerequisite("impale_skewer", 0) \
	 .with_signature("Carry up to 5 enemies, slam deals AoE + stuns, move while carrying")

static func _create_pin() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"impale_pin",
		"Pinning Strike",
		"Pin an enemy in place for 2 seconds.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		7.0
	).with_damage(50.0, 1.3) \
	 .with_range(150.0) \
	 .with_stun(2.0) \
	 .with_effect("pinning_strike") \
	 .with_prerequisite("impale", 1)

static func _create_crucify() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"impale_crucify",
		"Crucify",
		"Thrust enemy into nearest wall, dealing massive bonus damage.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		14.0
	).with_damage(100.0, 2.0) \
	 .with_range(200.0) \
	 .with_stun(3.0) \
	 .with_effect("crucify") \
	 .with_prerequisite("impale_pin", 1) \
	 .with_signature("Push to wall for 3x damage, pinned for 3 seconds, bleed effect")

static func get_all_ability_ids() -> Array[String]:
	return ["impale", "impale_skewer", "impale_kebab", "impale_pin", "impale_crucify"]

static func get_tree_name() -> String:
	return "Impale"
