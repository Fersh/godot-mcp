extends RefCounted
class_name ComboTree

# Combo Strike Ability Tree (Melee)
# Base: Quick combo attack
# Branch A (Chain): Longer combo -> Infinite Combo (never-ending attacks)
# Branch B (Finisher): Big finisher -> Ultimate Finisher (massive final hit)

const BASE_NAME = "Combo Strike"
const BASE_ID = "combo_strike"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_chain_combo(),
		_create_infinite_combo()
	)

	tree.add_branch(
		_create_finisher(),
		_create_ultimate_finisher()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"combo_strike",
		"Combo Strike",
		"Execute a 3-hit combo attack.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		4.0
	).with_damage(25.0, 0.9) \
	 .with_range(100.0) \
	 .with_projectiles(3, 0) \
	 .with_effect("combo_strike_pixel")

static func _create_chain_combo() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"combo_chain",
		"Chain Combo",
		"5-hit combo. Each hit builds attack speed.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		5.0
	).with_damage(22.0, 0.8) \
	 .with_range(100.0) \
	 .with_projectiles(5, 0) \
	 .with_effect("chain_combo") \
	 .with_prerequisite("combo_strike", 0) \
	 .with_prefix("Chain", BASE_NAME, BASE_ID)

static func _create_infinite_combo() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"combo_infinite",
		"Infinite Combo",
		"Rapid attacks until you run out of stamina or miss.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		12.0
	).with_damage(18.0, 0.7) \
	 .with_range(120.0) \
	 .with_duration(5.0) \
	 .with_effect("infinite_combo") \
	 .with_prerequisite("combo_chain", 0) \
	 .with_signature("Attack until interrupted, +5% damage per hit, lifesteal on hit") \
	 .with_suffix("of Infinity", BASE_NAME, "Chain", BASE_ID)

static func _create_finisher() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"combo_finisher",
		"Combo Finisher",
		"3-hit combo with powerful final strike.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		5.0
	).with_damage(30.0, 1.0) \
	 .with_range(100.0) \
	 .with_projectiles(3, 0) \
	 .with_effect("combo_finisher") \
	 .with_prerequisite("combo_strike", 1) \
	 .with_prefix("Finishing", BASE_NAME, BASE_ID)

static func _create_ultimate_finisher() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"combo_ultimate",
		"Ultimate Finisher",
		"5-hit combo building to devastating final attack.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		10.0
	).with_damage(25.0, 0.9) \
	 .with_range(120.0) \
	 .with_aoe(100.0) \
	 .with_projectiles(5, 0) \
	 .with_stun(1.0) \
	 .with_effect("ultimate_finisher") \
	 .with_prerequisite("combo_finisher", 1) \
	 .with_signature("5th hit deals 400% damage, AoE shockwave, brief slow-mo") \
	 .with_suffix("of Devastation", BASE_NAME, "Finishing", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["combo_strike", "combo_chain", "combo_infinite", "combo_finisher", "combo_ultimate"]

static func get_tree_name() -> String:
	return "Combo Strike"
