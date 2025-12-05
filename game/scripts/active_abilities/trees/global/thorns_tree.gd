extends RefCounted
class_name ThornsTree

# Thorns Ability Tree (Global)
# Base: Reflect damage back to attackers
# Branch A (Flame): Fire thorns -> Inferno Aura (burn all nearby enemies)
# Branch B (Lightning): Lightning thorns -> Storm Aura (chain lightning on hit)

const BASE_NAME = "Thorns"
const BASE_ID = "thorns"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_flame(),
		_create_inferno()
	)

	tree.add_branch(
		_create_lightning(),
		_create_storm()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"thorns",
		"Thorns",
		"Create a thorns aura that reflects damage.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		10.0
	).with_damage(20.0, 0.5) \
	 .with_aoe(100.0) \
	 .with_duration(5.0) \
	 .with_effect("thorns")

static func _create_flame() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"thorns_flame",
		"Flame Thorns",
		"Thorns burn attackers with fire damage.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		12.0
	).with_damage(30.0, 0.7) \
	 .with_aoe(120.0) \
	 .with_duration(6.0) \
	 .with_effect("thorns") \
	 .with_prerequisite("thorns", 0) \
	 .with_prefix("Flame", BASE_NAME, BASE_ID)

static func _create_inferno() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"thorns_inferno",
		"Inferno Aura",
		"Emit an inferno that burns all nearby enemies continuously.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		18.0
	).with_damage(25.0, 0.6) \
	 .with_aoe(180.0) \
	 .with_duration(8.0) \
	 .with_effect("thorns") \
	 .with_prerequisite("thorns_flame", 0) \
	 .with_signature("Constant fire damage to all nearby, stacking burn, explodes on expire") \
	 .with_suffix("of the Inferno", BASE_NAME, "Flame", BASE_ID)

static func _create_lightning() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"thorns_lightning",
		"Lightning Thorns",
		"Thorns shock attackers and chain to nearby enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		12.0
	).with_damage(25.0, 0.6) \
	 .with_aoe(150.0) \
	 .with_duration(6.0) \
	 .with_effect("thorns") \
	 .with_prerequisite("thorns", 1) \
	 .with_prefix("Lightning", BASE_NAME, BASE_ID)

static func _create_storm() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"thorns_storm",
		"Storm Aura",
		"Become the eye of a lightning storm.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		20.0
	).with_damage(35.0, 0.8) \
	 .with_aoe(200.0) \
	 .with_duration(8.0) \
	 .with_stun(0.3) \
	 .with_effect("thorns") \
	 .with_prerequisite("thorns_lightning", 1) \
	 .with_signature("Constant lightning strikes, chains between enemies, brief stuns") \
	 .with_suffix("of the Storm", BASE_NAME, "Lightning", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["thorns", "thorns_flame", "thorns_inferno", "thorns_lightning", "thorns_storm"]

static func get_tree_name() -> String:
	return "Thorns"
