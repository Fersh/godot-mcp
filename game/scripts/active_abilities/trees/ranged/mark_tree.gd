extends RefCounted
class_name MarkTree

# Mark Target Ability Tree (Ranged)
# Base: Mark enemy to take bonus damage
# Branch A (Hunt): Marked enemies revealed -> Death Mark (instant kill at low HP)
# Branch B (Focus): Team bonus damage -> Kill Order (massive team damage buff)

const BASE_NAME = "Mark Target"
const BASE_ID = "mark_target"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_hunters_mark(),
		_create_death_mark()
	)

	tree.add_branch(
		_create_focus_fire(),
		_create_kill_order()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"mark_target",
		"Mark Target",
		"Mark an enemy to take 25% bonus damage from all sources.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		8.0
	).with_damage(0.0, 0.0) \
	 .with_range(500.0) \
	 .with_duration(6.0) \
	 .with_effect("mark_target")

static func _create_hunters_mark() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"mark_hunter",
		"Hunter's Mark",
		"Marked enemies are revealed and take 35% bonus damage.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		10.0
	).with_damage(0.0, 0.0) \
	 .with_range(600.0) \
	 .with_duration(8.0) \
	 .with_effect("hunters_mark") \
	 .with_prerequisite("mark_target", 0)

static func _create_death_mark() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"mark_death",
		"Death Mark",
		"Marked enemies below 25% HP are executed instantly.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		15.0
	).with_damage(0.0, 0.0) \
	 .with_range(700.0) \
	 .with_duration(10.0) \
	 .with_effect("death_mark") \
	 .with_prerequisite("mark_hunter", 0) \
	 .with_signature("50% bonus damage, execute below 25%, mark spreads on kill")

static func _create_focus_fire() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"mark_focus",
		"Focus Fire",
		"Mark multiple enemies. Killing marked enemies extends duration.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.CLUSTER,
		12.0
	).with_damage(0.0, 0.0) \
	 .with_range(400.0) \
	 .with_aoe(200.0) \
	 .with_duration(6.0) \
	 .with_effect("focus_fire") \
	 .with_prerequisite("mark_target", 1)

static func _create_kill_order() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"mark_kill_order",
		"Kill Order",
		"Priority target. All damage to marked enemy is doubled.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		20.0
	).with_damage(0.0, 0.0) \
	 .with_range(600.0) \
	 .with_duration(8.0) \
	 .with_effect("kill_order") \
	 .with_prerequisite("mark_focus", 1) \
	 .with_signature("100% bonus damage, attacks can't miss, cooldown reset on kill")

static func get_all_ability_ids() -> Array[String]:
	return ["mark_target", "mark_hunter", "mark_death", "mark_focus", "mark_kill_order"]

static func get_tree_name() -> String:
	return "Mark Target"
