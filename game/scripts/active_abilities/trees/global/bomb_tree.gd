extends RefCounted
class_name BombTree

# Throwing Bomb Ability Tree (Global)
# Base: Throw explosive bomb
# Branch A (Cluster): Splits into smaller bombs -> Carpet Bombing (area denial)
# Branch B (Sticky): Attaches to surfaces -> Remote Detonation (manual trigger)

const BASE_NAME = "Throwing Bomb"
const BASE_ID = "bomb"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_cluster(),
		_create_carpet()
	)

	tree.add_branch(
		_create_sticky(),
		_create_remote()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"bomb",
		"Throwing Bomb",
		"Throw a bomb that explodes on impact.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		6.0
	).with_damage(50.0, 1.2) \
	 .with_range(300.0) \
	 .with_aoe(100.0) \
	 .with_effect("bomb") \
	 .with_icon("res://assets/sprites/icons/thiefskills/PNG/Icon32_Bomb.png")

static func _create_cluster() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"bomb_cluster",
		"Cluster Bomb",
		"Bomb splits into 4 smaller bombs.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		8.0
	).with_damage(40.0, 1.0) \
	 .with_range(350.0) \
	 .with_aoe(80.0) \
	 .with_projectiles(4, 0) \
	 .with_effect("bomb") \
	 .with_prerequisite("bomb", 0)

static func _create_carpet() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"bomb_carpet",
		"Carpet Bombing",
		"Rain explosives over a large area.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		20.0
	).with_damage(35.0, 0.9) \
	 .with_range(400.0) \
	 .with_aoe(250.0) \
	 .with_duration(3.0) \
	 .with_effect("bomb") \
	 .with_prerequisite("bomb_cluster", 0) \
	 .with_signature("12 explosions over 3 seconds, burning ground, massive area")

static func _create_sticky() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"bomb_sticky",
		"Sticky Bomb",
		"Bomb attaches to enemies or surfaces.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		7.0
	).with_damage(65.0, 1.4) \
	 .with_range(350.0) \
	 .with_aoe(120.0) \
	 .with_effect("bomb") \
	 .with_prerequisite("bomb", 1)

static func _create_remote() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"bomb_remote",
		"Remote Detonation",
		"Place up to 5 bombs. Reactivate to detonate all.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		3.0
	).with_damage(80.0, 1.6) \
	 .with_aoe(150.0) \
	 .with_projectiles(5, 0) \
	 .with_duration(30.0) \
	 .with_effect("bomb") \
	 .with_prerequisite("bomb_sticky", 1) \
	 .with_signature("Place 5 bombs, detonate on command, chain reaction bonus damage")

static func get_all_ability_ids() -> Array[String]:
	return ["bomb", "bomb_cluster", "bomb_carpet", "bomb_sticky", "bomb_remote"]

static func get_tree_name() -> String:
	return "Bomb"
