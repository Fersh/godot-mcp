extends RefCounted
class_name StompTree

# Stomp Ability Tree (Melee)
# Base: Stomp creating shockwave
# Branch A (Quake): Larger waves -> Tectonic Shift (reshape terrain)
# Branch B (Stun): Stun focused -> Thunderous Stomp (massive stun)

const BASE_NAME = "Stomp"
const BASE_ID = "stomp"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_quake(),
		_create_tectonic()
	)

	tree.add_branch(
		_create_thunder(),
		_create_thunderous()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"stomp",
		"Stomp",
		"Stomp the ground, creating a damaging shockwave.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		5.0
	).with_damage(40.0, 1.1) \
	 .with_aoe(120.0) \
	 .with_effect("stomp_pixel")

static func _create_quake() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"stomp_quake",
		"Quake Stomp",
		"Shockwaves travel further and hit harder.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		6.0
	).with_damage(50.0, 1.3) \
	 .with_aoe(180.0) \
	 .with_slow(0.3, 2.0) \
	 .with_effect("quake_stomp") \
	 .with_prerequisite("stomp", 0) \
	 .with_prefix("Quaking", BASE_NAME, BASE_ID)

static func _create_tectonic() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"stomp_tectonic",
		"Tectonic Shift",
		"Reshape the ground itself, creating fissures that damage over time.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		18.0
	).with_damage(60.0, 1.5) \
	 .with_aoe(300.0) \
	 .with_duration(5.0) \
	 .with_effect("tectonic_shift") \
	 .with_prerequisite("stomp_quake", 0) \
	 .with_signature("Creates ground fissures, DoT zone, knockback, terrain hazard") \
	 .with_suffix("of Tectonics", BASE_NAME, "Quaking", BASE_ID)

static func _create_thunder() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"stomp_thunder",
		"Thunder Stomp",
		"Stomp with enough force to stun enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		7.0
	).with_damage(45.0, 1.2) \
	 .with_aoe(140.0) \
	 .with_stun(1.0) \
	 .with_effect("thunder_stomp") \
	 .with_prerequisite("stomp", 1) \
	 .with_prefix("Thundering", BASE_NAME, BASE_ID)

static func _create_thunderous() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"stomp_thunderous",
		"Thunderous Impact",
		"Leap and stomp with earth-shattering force.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.CLUSTER,
		15.0
	).with_damage(100.0, 2.0) \
	 .with_range(300.0) \
	 .with_aoe(200.0) \
	 .with_stun(2.5) \
	 .with_movement() \
	 .with_effect("thunderous_impact") \
	 .with_prerequisite("stomp_thunder", 1) \
	 .with_signature("Leap to target, massive stun, screen shake, knockback") \
	 .with_suffix("of Thunder", BASE_NAME, "Thundering", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["stomp", "stomp_quake", "stomp_tectonic", "stomp_thunder", "stomp_thunderous"]

static func get_tree_name() -> String:
	return "Stomp"
