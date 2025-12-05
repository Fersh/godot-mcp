extends RefCounted
class_name DrainTree

# Life Drain Ability Tree (Global)
# Base: Drain health from enemy
# Branch A (Siphon): AoE drain -> Soul Feast (massive AoE, heal to full)
# Branch B (Transfer): Give health to transfer damage -> Sacrifice (hurt self to mega damage)

const BASE_NAME = "Life Drain"
const BASE_ID = "drain"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_siphon(),
		_create_soul_feast()
	)

	tree.add_branch(
		_create_transfer(),
		_create_sacrifice()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"drain",
		"Life Drain",
		"Drain life from an enemy, healing yourself.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		8.0
	).with_damage(40.0, 1.0) \
	 .with_range(250.0) \
	 .with_effect("life_drain")

static func _create_siphon() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"drain_siphon",
		"Soul Siphon",
		"Drain life from all nearby enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		12.0
	).with_damage(30.0, 0.8) \
	 .with_aoe(200.0) \
	 .with_effect("life_drain") \
	 .with_prerequisite("drain", 0) \
	 .with_prefix("Siphon", BASE_NAME, BASE_ID)

static func _create_soul_feast() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"drain_feast",
		"Soul Feast",
		"Devour the life force of all nearby enemies.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		25.0
	).with_damage(50.0, 1.3) \
	 .with_aoe(300.0) \
	 .with_duration(3.0) \
	 .with_effect("life_drain") \
	 .with_prerequisite("drain_siphon", 0) \
	 .with_signature("Channel 3s, massive drain, heal to full, temporary max HP boost") \
	 .with_suffix("of the Soul Feast", BASE_NAME, "Siphon", BASE_ID)

static func _create_transfer() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"drain_transfer",
		"Life Transfer",
		"Convert your health into damage.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		6.0
	).with_damage(80.0, 1.5) \
	 .with_range(300.0) \
	 .with_effect("life_drain") \
	 .with_prerequisite("drain", 1) \
	 .with_prefix("Transfer", BASE_NAME, BASE_ID)

static func _create_sacrifice() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"drain_sacrifice",
		"Blood Sacrifice",
		"Sacrifice half your health for devastating damage.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		20.0
	).with_damage(200.0, 3.0) \
	 .with_range(350.0) \
	 .with_aoe(180.0) \
	 .with_effect("life_drain") \
	 .with_prerequisite("drain_transfer", 1) \
	 .with_signature("Costs 50% current HP, damage scales with HP sacrificed") \
	 .with_suffix("of Blood Sacrifice", BASE_NAME, "Transfer", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["drain", "drain_siphon", "drain_feast", "drain_transfer", "drain_sacrifice"]

static func get_tree_name() -> String:
	return "Drain"
