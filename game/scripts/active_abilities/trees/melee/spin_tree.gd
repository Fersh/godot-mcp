extends RefCounted
class_name SpinTree

# Whirlwind Ability Tree (formerly Spinning Attack)
# Base: Spin rapidly damaging all nearby enemies
# Branch A (Vortex): Sustained spinning with pull -> of Storms
# Branch B (Deflecting): Reflects projectiles -> of Mirrors

const BASE_NAME = "Whirlwind"
const BASE_ID = "whirlwind"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_blade_vortex(),
		_create_bladestorm()
	)

	tree.add_branch(
		_create_deflecting_spin(),
		_create_mirror_dance()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		BASE_ID,
		BASE_NAME,
		"Spin rapidly, damaging all enemies around you.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		6.0
	).with_damage(30.0, 1.0) \
	 .with_aoe(120.0) \
	 .with_duration(1.5) \
	 .with_effect("whirlwind_pixel")

static func _create_blade_vortex() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"spin_vortex",
		"Vortex Whirlwind",
		"Creates a vortex that pulls enemies toward you while dealing damage.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		25.0
	).with_damage(10.0, 0.5) \
	 .with_aoe(150.0) \
	 .with_duration(3.0) \
	 .with_effect("vortex") \
	 .with_prerequisite("whirlwind", 0) \
	 .with_prefix("Vortex", BASE_NAME, BASE_ID)

static func _create_bladestorm() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"spin_bladestorm",
		"Vortex Whirlwind of Storms",
		"Become a whirlwind of death. Move freely while constantly damaging enemies.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		30.0
	).with_damage(15.0, 0.8) \
	 .with_aoe(180.0) \
	 .with_duration(5.0) \
	 .with_movement() \
	 .with_effect("bladestorm") \
	 .with_prerequisite("spin_vortex", 0) \
	 .with_signature("Move freely while spinning, pulls enemies in") \
	 .with_suffix("of Storms", BASE_NAME, "Vortex", BASE_ID)

static func _create_deflecting_spin() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"spin_deflect",
		"Deflecting Whirlwind",
		"Deflects incoming projectiles back at enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		6.0
	).with_damage(30.0, 1.1) \
	 .with_aoe(130.0) \
	 .with_duration(1.5) \
	 .with_effect("deflect_spin") \
	 .with_prerequisite("whirlwind", 1) \
	 .with_prefix("Deflecting", BASE_NAME, BASE_ID)

static func _create_mirror_dance() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"spin_mirror",
		"Deflecting Whirlwind of Mirrors",
		"Reflects all projectiles. Reflected projectiles home in on enemies.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		10.0
	).with_damage(35.0, 1.3) \
	 .with_aoe(150.0) \
	 .with_duration(2.5) \
	 .with_invulnerability(2.5) \
	 .with_effect("mirror_dance") \
	 .with_prerequisite("spin_deflect", 1) \
	 .with_signature("Reflected projectiles become homing missiles") \
	 .with_suffix("of Mirrors", BASE_NAME, "Deflecting", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["whirlwind", "spin_vortex", "spin_bladestorm", "spin_deflect", "spin_mirror"]

static func get_tree_name() -> String:
	return "Whirlwind"
