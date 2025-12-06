extends RefCounted
class_name GrappleTree

# Grappling Hook Ability Tree (Ranged)
# Base: Pull yourself to a location
# Branch A (Pull): Pull enemies to you -> Scorpion (GET OVER HERE!)
# Branch B (Swing): Swing through enemies -> Spider (web swing combo)

const BASE_NAME = "Grappling Hook"
const BASE_ID = "grapple"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_pull(),
		_create_scorpion()
	)

	tree.add_branch(
		_create_swing(),
		_create_spider()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"grapple",
		"Grappling Hook",
		"Fire a hook to pull yourself to a location.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		5.0
	).with_damage(0.0, 0.0) \
	 .with_range(400.0) \
	 .with_movement() \
	 .with_effect("grapple")

static func _create_pull() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"grapple_pull",
		"Hook Pull",
		"Hook an enemy and pull them to you.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		6.0
	).with_damage(30.0, 1.0) \
	 .with_range(450.0) \
	 .with_stun(0.5) \
	 .with_effect("hook_pull") \
	 .with_prerequisite("grapple", 0)

static func _create_scorpion() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"grapple_scorpion",
		"GET OVER HERE!",
		"Chain multiple enemies and pull them all to you.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.CLUSTER,
		12.0
	).with_damage(40.0, 1.2) \
	 .with_range(500.0) \
	 .with_aoe(150.0) \
	 .with_stun(1.0) \
	 .with_effect("scorpion") \
	 .with_prerequisite("grapple_pull", 0) \
	 .with_signature("Pull up to 5 enemies, impale on arrival, follow-up strike")

static func _create_swing() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"grapple_swing",
		"Swing Kick",
		"Swing to location and kick enemies on arrival.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		5.0
	).with_damage(45.0, 1.1) \
	 .with_range(400.0) \
	 .with_aoe(100.0) \
	 .with_movement() \
	 .with_knockback(200.0) \
	 .with_effect("swing_kick") \
	 .with_prerequisite("grapple", 1)

static func _create_spider() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"grapple_spider",
		"Web Slinger",
		"Chain swings between enemies, kicking each one.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.CLUSTER,
		15.0
	).with_damage(35.0, 1.0) \
	 .with_range(500.0) \
	 .with_movement() \
	 .with_knockback(150.0) \
	 .with_invulnerability(2.0) \
	 .with_effect("web_slinger") \
	 .with_prerequisite("grapple_swing", 1) \
	 .with_signature("Swing through up to 6 enemies, invulnerable, webs slow 50%")

static func get_all_ability_ids() -> Array[String]:
	return ["grapple", "grapple_pull", "grapple_scorpion", "grapple_swing", "grapple_spider"]

static func get_tree_name() -> String:
	return "Grapple"
