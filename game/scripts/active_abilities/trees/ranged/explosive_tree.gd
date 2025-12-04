extends RefCounted
class_name ExplosiveTree

# Explosive Arrow Ability Tree (Ranged)
# Base: Arrow that explodes on impact
# Branch A (Cluster): Spawns smaller bombs -> Carpet Bomb (massive area denial)
# Branch B (Sticky): Attaches to enemy -> Walking Bomb (infects and spreads)

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_cluster(),
		_create_carpet_bomb()
	)

	tree.add_branch(
		_create_sticky(),
		_create_walking_bomb()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"explosive_arrow",
		"Explosive Arrow",
		"Fire an arrow that explodes on impact.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		6.0
	).with_damage(40.0, 1.2) \
	 .with_projectiles(1, 500.0) \
	 .with_aoe(100.0) \
	 .with_effect("explosive_arrow")

static func _create_cluster() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"explosive_cluster",
		"Cluster Bomb",
		"Explosion spawns 4 smaller bombs.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		8.0
	).with_damage(35.0, 1.0) \
	 .with_projectiles(1, 500.0) \
	 .with_aoe(80.0) \
	 .with_effect("cluster_bomb") \
	 .with_prerequisite("explosive_arrow", 0)

static func _create_carpet_bomb() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"explosive_carpet",
		"Carpet Bomb",
		"Launch a volley that blankets an area with explosions.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.CLUSTER,
		18.0
	).with_damage(30.0, 0.9) \
	 .with_aoe(250.0) \
	 .with_duration(3.0) \
	 .with_effect("carpet_bomb") \
	 .with_prerequisite("explosive_cluster", 0) \
	 .with_signature("12 explosions over 3 seconds, leaves burning ground")

static func _create_sticky() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"explosive_sticky",
		"Sticky Bomb",
		"Arrow attaches to enemy and explodes after 2 seconds.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		7.0
	).with_damage(60.0, 1.4) \
	 .with_range(400.0) \
	 .with_aoe(120.0) \
	 .with_effect("sticky_bomb") \
	 .with_prerequisite("explosive_arrow", 1)

static func _create_walking_bomb() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"explosive_walking",
		"Walking Bomb",
		"Infect an enemy. They explode on death, spreading the infection.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		15.0
	).with_damage(50.0, 1.3) \
	 .with_range(450.0) \
	 .with_aoe(150.0) \
	 .with_duration(10.0) \
	 .with_effect("walking_bomb") \
	 .with_prerequisite("explosive_sticky", 1) \
	 .with_signature("Infection chains to 3 nearby enemies on death")

static func get_all_ability_ids() -> Array[String]:
	return ["explosive_arrow", "explosive_cluster", "explosive_carpet", "explosive_sticky", "explosive_walking"]

static func get_tree_name() -> String:
	return "Explosive Arrow"
