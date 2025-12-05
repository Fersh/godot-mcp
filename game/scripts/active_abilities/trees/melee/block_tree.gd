extends RefCounted
class_name BlockTree

# Block Ability Tree
# Base: Block incoming attacks
# Branch A (Reflecting): Reflect projectiles -> of Retribution
# Branch B (Parrying): Perfect timing counter -> of Vengeance

const BASE_NAME = "Block"
const BASE_ID = "block"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_reflect(),
		_create_mirror_shield()
	)

	tree.add_branch(
		_create_parry(),
		_create_riposte()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		BASE_ID,
		BASE_NAME,
		"Raise your guard, reducing incoming damage by 50%.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		6.0
	).with_damage(0.0, 0.0) \
	 .with_duration(1.5) \
	 .with_effect("block_pixel")

static func _create_reflect() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"block_reflect",
		"Reflecting Block",
		"Also reflects projectiles back at enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		8.0
	).with_damage(0.0, 0.0) \
	 .with_duration(2.0) \
	 .with_effect("reflect_shield") \
	 .with_prerequisite("block", 0) \
	 .with_prefix("Reflecting", BASE_NAME, BASE_ID)

static func _create_mirror_shield() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"block_mirror",
		"Reflecting Block of Retribution",
		"All blocked damage is reflected back to attackers.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		15.0
	).with_damage(0.0, 0.0) \
	 .with_duration(3.0) \
	 .with_effect("mirror_shield") \
	 .with_prerequisite("block_reflect", 0) \
	 .with_signature("100% damage reflection, projectiles return at 2x speed") \
	 .with_suffix("of Retribution", BASE_NAME, "Reflecting", BASE_ID)

static func _create_parry() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"block_parry",
		"Parrying Block",
		"Brief window to negate damage and stun attacker.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		6.0
	).with_damage(0.0, 0.0) \
	 .with_duration(0.4) \
	 .with_stun(1.0) \
	 .with_effect("parry") \
	 .with_prerequisite("block", 1) \
	 .with_prefix("Parrying", BASE_NAME, BASE_ID)

static func _create_riposte() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"block_riposte",
		"Parrying Block of Vengeance",
		"Perfect parry triggers devastating counter-attack.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		8.0
	).with_damage(150.0, 2.5) \
	 .with_duration(0.3) \
	 .with_stun(2.0) \
	 .with_effect("riposte") \
	 .with_prerequisite("block_parry", 1) \
	 .with_signature("Tiny parry window, success deals 250% damage + 2s stun") \
	 .with_suffix("of Vengeance", BASE_NAME, "Parrying", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["block", "block_reflect", "block_mirror", "block_parry", "block_riposte"]

static func get_tree_name() -> String:
	return "Block"
