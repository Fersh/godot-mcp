extends RefCounted
class_name ThrowTree

const BASE_NAME = "Throw Weapon"
const BASE_ID = "throw_weapon"

# Throw Weapon Ability Tree (Melee)
# Base: Throw your weapon at enemies
# Branch A (Ricochet): Bounces between enemies -> Blade Storm (orbiting blades)
# Branch B (Grapple): Pull yourself to weapon -> Impaler (pin enemies to walls)

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_ricochet(),
		_create_blade_storm()
	)

	tree.add_branch(
		_create_grapple(),
		_create_impaler()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		BASE_ID,
		BASE_NAME,
		"Hurl your weapon at an enemy, dealing heavy damage.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		5.0
	).with_damage(50.0, 1.3) \
	 .with_range(350.0) \
	 .with_projectiles(1, 600.0) \
	 .with_effect("throw_weapon_pixel")

static func _create_ricochet() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"throw_ricochet",
		"Bouncing Throw Weapon",
		"Weapon bounces between up to 4 enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		6.0
	).with_damage(40.0, 1.1) \
	 .with_range(400.0) \
	 .with_projectiles(1, 650.0) \
	 .with_effect("ricochet_blade") \
	 .with_prerequisite("throw_weapon", 0) \
	 .with_prefix("Bouncing", BASE_NAME, BASE_ID)

static func _create_blade_storm() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"throw_bladestorm",
		"Bouncing Throw Weapon of Storms",
		"Summon 6 blades that orbit you, shredding nearby enemies.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		18.0
	).with_damage(60.0, 1.2) \
	 .with_aoe(120.0) \
	 .with_duration(8.0) \
	 .with_effect("orbital_blades") \
	 .with_prerequisite("throw_ricochet", 0) \
	 .with_signature("6 orbiting blades for 8 seconds, can throw them at will") \
	 .with_suffix("of Storms", BASE_NAME, "Bouncing", BASE_ID)

static func _create_grapple() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"throw_grapple",
		"Grappling Throw Weapon",
		"Throw weapon then pull yourself to its location.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		7.0
	).with_damage(45.0, 1.2) \
	 .with_range(400.0) \
	 .with_movement() \
	 .with_effect("grapple_throw") \
	 .with_prerequisite("throw_weapon", 1) \
	 .with_prefix("Grappling", BASE_NAME, BASE_ID)

static func _create_impaler() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"throw_impaler",
		"Grappling Throw Weapon of Impalement",
		"Throw a massive spear that pins enemies and pierces infinitely.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		15.0
	).with_damage(80.0, 1.8) \
	 .with_range(600.0) \
	 .with_stun(2.0) \
	 .with_effect("impaler") \
	 .with_prerequisite("throw_grapple", 1) \
	 .with_signature("Infinite pierce, enemies pinned for 2s, pull yourself to end point") \
	 .with_suffix("of Impalement", BASE_NAME, "Grappling", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["throw_weapon", "throw_ricochet", "throw_bladestorm", "throw_grapple", "throw_impaler"]

static func get_tree_name() -> String:
	return "Throw Weapon"
