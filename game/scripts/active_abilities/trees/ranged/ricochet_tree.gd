extends RefCounted
class_name RicochetTree

# Ricochet Ability Tree (Ranged)
# Base: Fire bouncing projectile
# Branch A (Chain): More bounces -> Infinite Ricochet (bounces until no targets)
# Branch B (Splitting): Split on bounce -> Cascade (exponential splitting)

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_chain(),
		_create_infinite()
	)

	tree.add_branch(
		_create_split(),
		_create_cascade()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"ricochet",
		"Ricochet Shot",
		"Fire a projectile that bounces between enemies.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		5.0
	).with_damage(25.0, 0.8) \
	 .with_range(400.0) \
	 .with_effect("ricochet")

static func _create_chain() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"ricochet_chain",
		"Chain Bounce",
		"Projectile bounces to more targets.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		6.0
	).with_damage(30.0, 0.9) \
	 .with_range(450.0) \
	 .with_effect("chain_bounce") \
	 .with_prerequisite("ricochet", 0)

static func _create_infinite() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"ricochet_infinite",
		"Endless Ricochet",
		"Projectile bounces infinitely until no valid targets remain.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		12.0
	).with_damage(35.0, 1.0) \
	 .with_range(500.0) \
	 .with_duration(5.0) \
	 .with_effect("endless_ricochet") \
	 .with_prerequisite("ricochet_chain", 0) \
	 .with_signature("Unlimited bounces, +5% damage per bounce, pierces on final hit")

static func _create_split() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"ricochet_split",
		"Splitting Shot",
		"Projectile splits into two on each bounce.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		7.0
	).with_damage(20.0, 0.7) \
	 .with_range(400.0) \
	 .with_effect("splitting_shot") \
	 .with_prerequisite("ricochet", 1)

static func _create_cascade() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"ricochet_cascade",
		"Cascade",
		"Each projectile spawns more, creating an exponential cascade.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		15.0
	).with_damage(18.0, 0.6) \
	 .with_range(450.0) \
	 .with_duration(3.0) \
	 .with_effect("cascade") \
	 .with_prerequisite("ricochet_split", 1) \
	 .with_signature("Exponential splitting, up to 32 projectiles, screen-filling chaos")

static func get_all_ability_ids() -> Array[String]:
	return ["ricochet", "ricochet_chain", "ricochet_infinite", "ricochet_split", "ricochet_cascade"]

static func get_tree_name() -> String:
	return "Ricochet"
