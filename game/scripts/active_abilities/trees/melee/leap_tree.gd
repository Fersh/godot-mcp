extends RefCounted
class_name LeapTree

# Savage Leap Ability Tree
# Base: Leap to target, damage on landing
# Branch A (Tremor): Stun on landing -> of Extinction
# Branch B (Predator): Gain attack speed -> of the Apex

const BASE_NAME = "Savage Leap"
const BASE_ID = "savage_leap"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_tremor_leap(),
		_create_extinction_event()
	)

	tree.add_branch(
		_create_predator_leap(),
		_create_apex_predator()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		BASE_ID,
		BASE_NAME,
		"Leap to target location, damaging enemies on impact.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.CLUSTER,
		7.0
	).with_damage(50.0, 1.3) \
	 .with_range(300.0) \
	 .with_aoe(100.0) \
	 .with_movement() \
	 .with_effect("savage_leap")

static func _create_tremor_leap() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"leap_tremor",
		"Tremor Savage Leap",
		"Landing creates a shockwave that stuns enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.CLUSTER,
		8.0
	).with_damage(55.0, 1.4) \
	 .with_range(300.0) \
	 .with_aoe(150.0) \
	 .with_stun(1.0) \
	 .with_movement() \
	 .with_effect("tremor_leap") \
	 .with_prerequisite("savage_leap", 0) \
	 .with_prefix("Tremor", BASE_NAME, BASE_ID)

static func _create_extinction_event() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"leap_extinction",
		"Tremor Savage Leap of Extinction",
		"Leap so hard meteors rain from the sky on impact.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.CLUSTER,
		18.0
	).with_damage(80.0, 2.0) \
	 .with_range(350.0) \
	 .with_aoe(250.0) \
	 .with_stun(2.0) \
	 .with_duration(2.0) \
	 .with_movement() \
	 .with_invulnerability(0.5) \
	 .with_effect("extinction_event") \
	 .with_prerequisite("leap_tremor", 0) \
	 .with_signature("4 meteors rain down around landing zone") \
	 .with_suffix("of Extinction", BASE_NAME, "Tremor", BASE_ID)

static func _create_predator_leap() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"leap_predator",
		"Predator Savage Leap",
		"Gain 30% attack speed for 3 seconds after leaping.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.CLUSTER,
		6.0
	).with_damage(45.0, 1.2) \
	 .with_range(300.0) \
	 .with_aoe(100.0) \
	 .with_duration(3.0) \
	 .with_movement() \
	 .with_effect("predator_leap") \
	 .with_prerequisite("savage_leap", 1) \
	 .with_prefix("Predator", BASE_NAME, BASE_ID)

static func _create_apex_predator() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"leap_apex",
		"Predator Savage Leap of the Apex",
		"Chain leaps to 3 enemies, heal for each kill.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		16.0
	).with_damage(60.0, 1.6) \
	 .with_range(400.0) \
	 .with_aoe(80.0) \
	 .with_projectiles(3, 0) \
	 .with_movement() \
	 .with_effect("apex_predator") \
	 .with_prerequisite("leap_predator", 1) \
	 .with_signature("Chain to 3 enemies, heal 15% max HP per kill") \
	 .with_suffix("of the Apex", BASE_NAME, "Predator", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["savage_leap", "leap_tremor", "leap_extinction", "leap_predator", "leap_apex"]

static func get_tree_name() -> String:
	return "Savage Leap"
