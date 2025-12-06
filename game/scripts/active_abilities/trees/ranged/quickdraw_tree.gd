extends RefCounted
class_name QuickdrawTree

# Quickdraw Ability Tree (Ranged)
# Base: Instant shot with brief invulnerability
# Branch A (Reflex): Chain quickdraws -> Gunslinger (multiple instant shots)
# Branch B (Execute): High damage finish -> Dead Eye (guaranteed crit execute)

const BASE_NAME = "Quickdraw"
const BASE_ID = "quickdraw"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_reflex(),
		_create_gunslinger()
	)

	tree.add_branch(
		_create_execute(),
		_create_deadeye()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"quickdraw",
		"Quickdraw",
		"Instantly fire a shot with brief invulnerability.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		6.0
	).with_damage(50.0, 1.2) \
	 .with_range(400.0) \
	 .with_effect("quickdraw")

static func _create_reflex() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"quickdraw_reflex",
		"Reflex Shot",
		"Can fire a second quickdraw immediately after the first.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		7.0
	).with_damage(45.0, 1.1) \
	 .with_range(400.0) \
	 .with_effect("reflex_shot") \
	 .with_prerequisite("quickdraw", 0)

static func _create_gunslinger() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"quickdraw_gunslinger",
		"Gunslinger",
		"Fire a rapid sequence of precision shots.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.CLUSTER,
		12.0
	).with_damage(40.0, 1.0) \
	 .with_range(450.0) \
	 .with_aoe(250.0) \
	 .with_effect("gunslinger") \
	 .with_prerequisite("quickdraw_reflex", 0) \
	 .with_signature("6 instant shots at different targets, each kill resets cooldown by 2s")

static func _create_execute() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"quickdraw_execute",
		"Execution Shot",
		"Deals massive damage to low health targets.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		8.0
	).with_damage(80.0, 1.8) \
	 .with_range(450.0) \
	 .with_effect("execution_shot") \
	 .with_prerequisite("quickdraw", 1)

static func _create_deadeye() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"quickdraw_deadeye",
		"Dead Eye",
		"Time slows as you line up the perfect shot.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		15.0
	).with_damage(200.0, 3.0) \
	 .with_range(500.0) \
	 .with_effect("deadeye") \
	 .with_prerequisite("quickdraw_execute", 1) \
	 .with_signature("Guaranteed critical hit, ignores armor, kills below 30% HP instantly")

static func get_all_ability_ids() -> Array[String]:
	return ["quickdraw", "quickdraw_reflex", "quickdraw_gunslinger", "quickdraw_execute", "quickdraw_deadeye"]

static func get_tree_name() -> String:
	return "Quickdraw"
