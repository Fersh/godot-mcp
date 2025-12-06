extends RefCounted
class_name VolleyTree

# Piercing Volley Ability Tree (Ranged)
# Base: Fire arrows that pierce through enemies
# Branch A (Ricochet): Arrows bounce -> Chaos Bolts (random bouncing mayhem)
# Branch B (Sniper): Single powerful pierce -> Rail Shot (instant hitscan)

const BASE_NAME = "Piercing Volley"
const BASE_ID = "piercing_volley"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_ricochet(),
		_create_chaos_bolts()
	)

	tree.add_branch(
		_create_sniper_shot(),
		_create_rail_shot()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"piercing_volley",
		"Piercing Volley",
		"Fire 3 arrows that pierce through enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		6.0
	).with_damage(35.0, 1.0) \
	 .with_projectiles(3, 600.0) \
	 .with_effect("piercing_volley")

static func _create_ricochet() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"volley_ricochet",
		"Ricochet",
		"Arrows bounce between enemies up to 3 times each.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		7.0
	).with_damage(30.0, 0.9) \
	 .with_projectiles(3, 550.0) \
	 .with_effect("ricochet_volley") \
	 .with_prerequisite("piercing_volley", 0)

static func _create_chaos_bolts() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"volley_chaos",
		"Chaos Bolts",
		"Fire 8 bolts that bounce infinitely for 3 seconds.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		15.0
	).with_damage(25.0, 0.8) \
	 .with_projectiles(8, 700.0) \
	 .with_duration(3.0) \
	 .with_effect("chaos_bolts") \
	 .with_prerequisite("volley_ricochet", 0) \
	 .with_signature("8 projectiles bounce forever for 3s, +5% damage per bounce")

static func _create_sniper_shot() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"volley_sniper",
		"Sniper Shot",
		"Single powerful shot that pierces infinite enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		8.0
	).with_damage(80.0, 1.5) \
	 .with_projectiles(1, 1000.0) \
	 .with_effect("sniper_shot") \
	 .with_prerequisite("piercing_volley", 1)

static func _create_rail_shot() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"volley_rail",
		"Rail Shot",
		"Instant hitscan beam that vaporizes everything in a line.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		12.0
	).with_damage(150.0, 2.5) \
	 .with_range(2000.0) \
	 .with_effect("rail_shot") \
	 .with_prerequisite("volley_sniper", 1) \
	 .with_signature("Instant beam, screen-wide, +25% crit chance")

static func get_all_ability_ids() -> Array[String]:
	return ["piercing_volley", "volley_ricochet", "volley_chaos", "volley_sniper", "volley_rail"]

static func get_tree_name() -> String:
	return "Piercing Volley"
