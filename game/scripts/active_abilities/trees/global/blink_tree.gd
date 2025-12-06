extends RefCounted
class_name BlinkTree

# Blink Ability Tree (Global)
# Base: Short range instant teleport
# Branch A (Phase): Phase through enemies -> Phantom Step (invulnerable dash)
# Branch B (Flash): Damage on blink -> Thunder Step (chain blinks with lightning)

const BASE_NAME = "Blink"
const BASE_ID = "blink"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_phase(),
		_create_phantom()
	)

	tree.add_branch(
		_create_flash(),
		_create_thunder()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"blink",
		"Blink",
		"Instantly teleport a short distance.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		3.0
	).with_damage(0.0, 0.0) \
	 .with_range(200.0) \
	 .with_movement() \
	 .with_effect("blink")

static func _create_phase() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"blink_phase",
		"Phase Shift",
		"Blink makes you briefly invulnerable.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		4.0
	).with_damage(0.0, 0.0) \
	 .with_range(250.0) \
	 .with_duration(0.5) \
	 .with_movement() \
	 .with_effect("blink") \
	 .with_prerequisite("blink", 0)

static func _create_phantom() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"blink_phantom",
		"Phantom Step",
		"Become a phantom, dashing through enemies dealing damage.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		8.0
	).with_damage(40.0, 1.0) \
	 .with_range(400.0) \
	 .with_duration(1.0) \
	 .with_movement() \
	 .with_effect("blink") \
	 .with_prerequisite("blink_phase", 0) \
	 .with_signature("Invulnerable dash, damage all enemies passed through, reset on kill")

static func _create_flash() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"blink_flash",
		"Flash Strike",
		"Deal damage at both start and end points of blink.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		4.0
	).with_damage(30.0, 0.8) \
	 .with_range(200.0) \
	 .with_aoe(80.0) \
	 .with_movement() \
	 .with_effect("blink") \
	 .with_prerequisite("blink", 1)

static func _create_thunder() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"blink_thunder",
		"Thunder Step",
		"Chain multiple blinks, each leaving a lightning strike.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		10.0
	).with_damage(50.0, 1.2) \
	 .with_range(300.0) \
	 .with_aoe(120.0) \
	 .with_movement() \
	 .with_stun(0.5) \
	 .with_effect("blink") \
	 .with_prerequisite("blink_flash", 1) \
	 .with_signature("3 rapid blinks, each creates lightning AoE, enemies stunned")

static func get_all_ability_ids() -> Array[String]:
	return ["blink", "blink_phase", "blink_phantom", "blink_flash", "blink_thunder"]

static func get_tree_name() -> String:
	return "Blink"
