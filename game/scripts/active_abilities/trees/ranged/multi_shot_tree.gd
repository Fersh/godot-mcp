extends RefCounted
class_name MultiShotTree

# Multi Shot Ability Tree
# Base: Fire 3 arrows in a spread
# Branch A (Fan): More projectiles, wider spread -> Blade Tornado (360 degree, 12 projectiles)
# Branch B (Focus): All arrows hit same target -> Triple Threat (each arrow spawns 3 more)

const BASE_NAME = "Multi Shot"
const BASE_ID = "multi_shot"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_fan_of_knives(),
		_create_blade_tornado()
	)

	tree.add_branch(
		_create_focused_volley(),
		_create_triple_threat()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"multi_shot",
		"Multi Shot",
		"Fire 3 arrows in a spread pattern.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		6.0
	).with_damage(45.0, 1.2) \
	 .with_projectiles(3, 500.0) \
	 .with_effect("multi_shot")

static func _create_fan_of_knives() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"multi_fan",
		"Fan of Knives",
		"Throw 5 knives in a wide arc, covering more area.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		6.0
	).with_damage(25.0, 0.9) \
	 .with_projectiles(5, 550.0) \
	 .with_effect("fan_of_knives") \
	 .with_prerequisite("multi_shot", 0) \
	 .with_prefix("Fanning", BASE_NAME, BASE_ID)

static func _create_blade_tornado() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"multi_tornado",
		"Blade Tornado",
		"Release a storm of 12 blades in all directions. Nothing escapes.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		10.0
	).with_damage(35.0, 1.2) \
	 .with_projectiles(12, 600.0) \
	 .with_aoe(360.0) \
	 .with_effect("blade_tornado") \
	 .with_prerequisite("multi_fan", 0) \
	 .with_signature("360-degree blade storm, 12 projectiles") \
	 .with_suffix("of Blades", BASE_NAME, "Fanning", BASE_ID)

static func _create_focused_volley() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"multi_focused",
		"Focused Volley",
		"All 3 arrows converge on a single target for concentrated damage.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		5.0
	).with_damage(40.0, 1.5) \
	 .with_projectiles(3, 600.0) \
	 .with_effect("focused_volley") \
	 .with_prerequisite("multi_shot", 1) \
	 .with_prefix("Focused", BASE_NAME, BASE_ID)

static func _create_triple_threat() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"multi_triple",
		"Triple Threat",
		"Each arrow splits into 3 more on impact. 9 total projectiles devastate your target.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		8.0
	).with_damage(35.0, 1.3) \
	 .with_projectiles(3, 650.0) \
	 .with_effect("triple_threat") \
	 .with_prerequisite("multi_focused", 1) \
	 .with_signature("Each arrow spawns 3 more on hit (9 total)") \
	 .with_suffix("of Splitting", BASE_NAME, "Focused", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["multi_shot", "multi_fan", "multi_tornado", "multi_focused", "multi_triple"]

static func get_tree_name() -> String:
	return "Multi Shot"
