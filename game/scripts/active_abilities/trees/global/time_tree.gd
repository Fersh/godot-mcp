extends RefCounted
class_name TimeTree

# Time Manipulation Ability Tree (Global)
# Base: Slow time briefly
# Branch A (Stop): Full time stop -> Temporal Prison (freeze specific enemies)
# Branch B (Rewind): Restore HP/position -> Chronoshift (full reset)

const BASE_NAME = "Time Slow"
const BASE_ID = "time_slow"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_time_stop(),
		_create_temporal_prison()
	)

	tree.add_branch(
		_create_rewind(),
		_create_chronoshift()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"time_slow",
		"Time Slow",
		"Slow time around you for 2 seconds.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		15.0
	).with_damage(0.0, 0.0) \
	 .with_duration(2.0) \
	 .with_effect("time_slow")

static func _create_time_stop() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"time_stop",
		"Time Stop",
		"Completely freeze time for 1.5 seconds.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		25.0
	).with_damage(0.0, 0.0) \
	 .with_duration(1.5) \
	 .with_effect("time_slow") \
	 .with_prerequisite("time_slow", 0) \
	 .with_prefix("Stop", BASE_NAME, BASE_ID)

static func _create_temporal_prison() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"time_prison",
		"Temporal Prison",
		"Trap enemies in frozen time. They take accumulated damage when released.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		35.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(250.0) \
	 .with_duration(3.0) \
	 .with_stun(3.0) \
	 .with_effect("time_slow") \
	 .with_prerequisite("time_stop", 0) \
	 .with_signature("Enemies frozen, all damage stored and dealt at once when released") \
	 .with_suffix("of Temporal Prison", BASE_NAME, "Stop", BASE_ID)

static func _create_rewind() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"time_rewind",
		"Rewind",
		"Restore yourself to your state 3 seconds ago.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		20.0
	).with_damage(0.0, 0.0) \
	 .with_effect("time_slow") \
	 .with_prerequisite("time_slow", 1) \
	 .with_prefix("Rewind", BASE_NAME, BASE_ID)

static func _create_chronoshift() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"time_chronoshift",
		"Chronoshift",
		"Mark a point in time. Reactivate to fully reset to that state.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		45.0
	).with_damage(0.0, 0.0) \
	 .with_duration(10.0) \
	 .with_effect("time_slow") \
	 .with_prerequisite("time_rewind", 1) \
	 .with_signature("Full HP/position restore, enemies damaged during period take it again") \
	 .with_suffix("of Chronoshift", BASE_NAME, "Rewind", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["time_slow", "time_stop", "time_prison", "time_rewind", "time_chronoshift"]

static func get_tree_name() -> String:
	return "Time Slow"
