extends RefCounted
class_name UppercutTree

# Uppercut Ability Tree (Melee)
# Base: Launch enemy into air
# Branch A (Juggle): Keep enemy airborne -> Air Combo (massive juggle damage)
# Branch B (Slam): Grab and slam -> Piledriver (suplex from air)

const BASE_NAME = "Uppercut"
const BASE_ID = "uppercut"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_juggle(),
		_create_air_combo()
	)

	tree.add_branch(
		_create_grab(),
		_create_piledriver()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"uppercut",
		"Uppercut",
		"Launch an enemy into the air with a powerful uppercut.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		6.0
	).with_damage(45.0, 1.2) \
	 .with_range(100.0) \
	 .with_knockback(200.0) \
	 .with_effect("uppercut")

static func _create_juggle() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"uppercut_juggle",
		"Juggle",
		"Keep airborne enemies in the air with follow-up attacks.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		7.0
	).with_damage(35.0, 1.0) \
	 .with_range(120.0) \
	 .with_duration(2.0) \
	 .with_knockback(150.0) \
	 .with_effect("juggle") \
	 .with_prerequisite("uppercut", 0) \
	 .with_prefix("Juggling", BASE_NAME, BASE_ID)

static func _create_air_combo() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"uppercut_air_combo",
		"Air Combo",
		"Launch into air and deliver a devastating combo.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		15.0
	).with_damage(30.0, 0.9) \
	 .with_range(150.0) \
	 .with_duration(3.0) \
	 .with_invulnerability(3.0) \
	 .with_movement() \
	 .with_effect("air_combo") \
	 .with_prerequisite("uppercut_juggle", 0) \
	 .with_signature("10-hit air combo, invulnerable during, finisher slams down") \
	 .with_suffix("of the Sky", BASE_NAME, "Juggling", BASE_ID)

static func _create_grab() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"uppercut_grab",
		"Grab",
		"Grab an airborne enemy and slam them down.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		8.0
	).with_damage(60.0, 1.4) \
	 .with_range(100.0) \
	 .with_aoe(80.0) \
	 .with_stun(1.0) \
	 .with_effect("grab_slam") \
	 .with_prerequisite("uppercut", 1) \
	 .with_prefix("Grappling", BASE_NAME, BASE_ID)

static func _create_piledriver() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"uppercut_piledriver",
		"Piledriver",
		"Leap up, grab enemy, and suplex them into the ground.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		16.0
	).with_damage(150.0, 2.2) \
	 .with_range(150.0) \
	 .with_aoe(150.0) \
	 .with_stun(2.0) \
	 .with_movement() \
	 .with_invulnerability(1.0) \
	 .with_effect("piledriver") \
	 .with_prerequisite("uppercut_grab", 1) \
	 .with_signature("Invulnerable grab, massive slam AoE, earthquake on impact") \
	 .with_suffix("of Destruction", BASE_NAME, "Grappling", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["uppercut", "uppercut_juggle", "uppercut_air_combo", "uppercut_grab", "uppercut_piledriver"]

static func get_tree_name() -> String:
	return "Uppercut"
