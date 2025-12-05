extends RefCounted
class_name FrostNovaTree

# Frost Nova Ability Tree (Global - available to all classes)
# Base: Freeze enemies around you
# Branch A (Blizzard): Persistent AoE -> Absolute Zero (massive freeze + shatter)
# Branch B (Prison): Single target freeze -> Shatter (chain ice explosions)

const BASE_NAME = "Frost Nova"
const BASE_ID = "frost_nova"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_blizzard(),
		_create_absolute_zero()
	)

	tree.add_branch(
		_create_ice_prison(),
		_create_shatter()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"frost_nova",
		"Frost Nova",
		"Release a wave of frost, damaging and slowing nearby enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		8.0
	).with_damage(35.0, 1.1) \
	 .with_aoe(120.0) \
	 .with_slow(0.4, 3.0) \
	 .with_effect("frost_nova")

static func _create_blizzard() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"frost_nova_blizzard",
		"Blizzard",
		"Create a persistent ice storm that damages and slows.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		12.0
	).with_damage(20.0, 0.8) \
	 .with_aoe(180.0) \
	 .with_duration(5.0) \
	 .with_slow(0.5, 1.0) \
	 .with_effect("frost_nova") \
	 .with_prerequisite("frost_nova", 0) \
	 .with_prefix("Blizzard", BASE_NAME, BASE_ID)

static func _create_absolute_zero() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"frost_nova_absolute",
		"Absolute Zero",
		"Flash freeze all enemies. Frozen enemies shatter on death.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		20.0
	).with_damage(60.0, 1.5) \
	 .with_aoe(300.0) \
	 .with_stun(3.0) \
	 .with_effect("frost_nova") \
	 .with_prerequisite("frost_nova_blizzard", 0) \
	 .with_signature("All enemies frozen 3s, shatter for 50% bonus damage on death") \
	 .with_suffix("of Absolute Zero", BASE_NAME, "Blizzard", BASE_ID)

static func _create_ice_prison() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"frost_nova_prison",
		"Ice Prison",
		"Trap an enemy in ice, damaging when it breaks.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		10.0
	).with_damage(50.0, 1.3) \
	 .with_range(300.0) \
	 .with_stun(2.0) \
	 .with_effect("frost_nova") \
	 .with_prerequisite("frost_nova", 1) \
	 .with_prefix("Prison", BASE_NAME, BASE_ID)

static func _create_shatter() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"frost_nova_shatter",
		"Shatter",
		"Freeze multiple enemies. Each one explodes when broken.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		18.0
	).with_damage(45.0, 1.4) \
	 .with_range(350.0) \
	 .with_aoe(100.0) \
	 .with_stun(2.5) \
	 .with_effect("frost_nova") \
	 .with_prerequisite("frost_nova_prison", 1) \
	 .with_signature("Up to 5 targets frozen, each shatters dealing AoE damage") \
	 .with_suffix("of Shattering", BASE_NAME, "Prison", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["frost_nova", "frost_nova_blizzard", "frost_nova_absolute", "frost_nova_prison", "frost_nova_shatter"]

static func get_tree_name() -> String:
	return "Frost Nova"
