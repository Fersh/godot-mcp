extends RefCounted
class_name RainTree

# Rain of Arrows Ability Tree (Ranged)
# Base: Area denial with falling projectiles
# Branch A (Storm): More arrows, longer duration -> Arrow Apocalypse (screen-wide)
# Branch B (Precision): Targeted, higher damage -> Orbital Strike (massive single strike)

const BASE_NAME = "Rain of Arrows"
const BASE_ID = "rain_of_arrows"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_arrow_storm(),
		_create_arrow_apocalypse()
	)

	tree.add_branch(
		_create_focused_barrage(),
		_create_orbital_strike()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"rain_of_arrows",
		"Rain of Arrows",
		"Call down a rain of arrows on target area.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.CLUSTER,
		10.0
	).with_damage(30.0, 1.0) \
	 .with_aoe(150.0) \
	 .with_duration(2.0) \
	 .with_effect("rain_of_arrows")

static func _create_arrow_storm() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"rain_storm",
		"Arrow Storm",
		"Intensify the rain with more arrows over a larger area.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.CLUSTER,
		12.0
	).with_damage(35.0, 1.2) \
	 .with_aoe(200.0) \
	 .with_duration(3.0) \
	 .with_effect("arrow_storm") \
	 .with_prerequisite("rain_of_arrows", 0) \
	 .with_prefix("Storming", BASE_NAME, BASE_ID)

static func _create_arrow_apocalypse() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"rain_apocalypse",
		"Arrow Apocalypse",
		"Blot out the sun. The entire battlefield becomes a death zone.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		25.0
	).with_damage(50.0, 1.8) \
	 .with_aoe(500.0) \
	 .with_duration(5.0) \
	 .with_effect("arrow_apocalypse") \
	 .with_prerequisite("rain_storm", 0) \
	 .with_signature("Screen-wide arrow rain for 5 seconds, slows enemies 30%") \
	 .with_suffix("of Apocalypse", BASE_NAME, "Storming", BASE_ID)

static func _create_focused_barrage() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"rain_focused",
		"Focused Barrage",
		"Concentrate arrows on a smaller area for more damage.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.CLUSTER,
		8.0
	).with_damage(50.0, 1.5) \
	 .with_aoe(100.0) \
	 .with_duration(1.5) \
	 .with_effect("focused_barrage") \
	 .with_prerequisite("rain_of_arrows", 1) \
	 .with_prefix("Focused", BASE_NAME, BASE_ID)

static func _create_orbital_strike() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"rain_orbital",
		"Orbital Strike",
		"Call down a devastating beam from the heavens.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.CLUSTER,
		20.0
	).with_damage(200.0, 3.0) \
	 .with_aoe(120.0) \
	 .with_cast_time(1.5) \
	 .with_stun(2.0) \
	 .with_effect("orbital_strike") \
	 .with_prerequisite("rain_focused", 1) \
	 .with_signature("Massive single strike, 2s charge, stuns survivors") \
	 .with_suffix("of Annihilation", BASE_NAME, "Focused", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["rain_of_arrows", "rain_storm", "rain_apocalypse", "rain_focused", "rain_orbital"]

static func get_tree_name() -> String:
	return "Rain of Arrows"
