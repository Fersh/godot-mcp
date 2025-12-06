extends RefCounted
class_name SpinTree

# Whirlwind Ability Tree (formerly Spinning Attack)
# Base: Spin rapidly damaging all nearby enemies
# Branch A (Vortex): Sustained spinning with pull -> of Storms
# Branch B (Deflecting): Reflects projectiles -> of Mirrors
# Branch C (Fiery): Fire trails while spinning -> of Inferno

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

	tree.add_branch(
		_create_fiery_whirlwind(),
		_create_inferno_tornado()
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
		"Blade Vortex",
		"Creates a vortex that pulls enemies toward you while dealing damage.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		25.0
	).with_damage(60.0, 1.2) \
	 .with_aoe(150.0) \
	 .with_duration(3.0) \
	 .with_effect("vortex") \
	 .with_prerequisite("whirlwind", 0)

static func _create_bladestorm() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"spin_bladestorm",
		"Bladestorm",
		"Become a whirlwind of death. Move freely while constantly damaging enemies.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		30.0
	).with_damage(80.0, 1.5) \
	 .with_aoe(180.0) \
	 .with_duration(5.0) \
	 .with_movement() \
	 .with_effect("bladestorm") \
	 .with_prerequisite("spin_vortex", 0) \
	 .with_signature("Move freely while spinning, pulls enemies in")

static func _create_deflecting_spin() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"spin_deflect",
		"Deflecting Spin",
		"Deflects incoming projectiles back at enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		6.0
	).with_damage(30.0, 1.1) \
	 .with_aoe(130.0) \
	 .with_duration(1.5) \
	 .with_effect("deflect_spin") \
	 .with_prerequisite("whirlwind", 1)

static func _create_mirror_dance() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"spin_mirror",
		"Mirror Dance",
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
	 .with_signature("Reflected projectiles become homing missiles")

static func _create_fiery_whirlwind() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"spin_fiery",
		"Flame Spin",
		"Leaves trails of fire while spinning. Burns enemies caught in the flames.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		9.0
	).with_damage(30.0, 1.2) \
	 .with_aoe(130.0) \
	 .with_duration(2.5) \
	 .with_effect("flame_whirlwind") \
	 .with_prerequisite("whirlwind", 2)

static func _create_inferno_tornado() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"spin_inferno",
		"Inferno Tornado",
		"Transform into a massive fire tornado that scorches everything.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		22.0
	).with_damage(50.0, 1.8) \
	 .with_aoe(200.0) \
	 .with_duration(5.0) \
	 .with_effect("inferno_tornado") \
	 .with_prerequisite("spin_fiery", 2) \
	 .with_signature("Leave burning ground, enemies take 50% more fire damage")

static func get_all_ability_ids() -> Array[String]:
	return ["whirlwind", "spin_vortex", "spin_bladestorm", "spin_deflect", "spin_mirror", "spin_fiery", "spin_inferno"]

static func get_tree_name() -> String:
	return "Whirlwind"
