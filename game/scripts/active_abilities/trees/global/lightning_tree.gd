extends RefCounted
class_name LightningTree

# Chain Lightning Ability Tree (Global - available to all classes)
# Base: Lightning that chains between enemies
# Branch A (Storm): AoE storm -> Overload (massive strike with chain stun)
# Branch B (Static): Aura that shocks -> Power Surge (buff that electrifies attacks)

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_thunderstorm(),
		_create_overload()
	)

	tree.add_branch(
		_create_static_field(),
		_create_power_surge()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"chain_lightning",
		"Chain Lightning",
		"Lightning bolt that jumps between nearby enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		6.0
	).with_damage(40.0, 1.2) \
	 .with_range(400.0) \
	 .with_projectiles(3, 0) \
	 .with_effect("chain_lightning")

static func _create_thunderstorm() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"chain_lightning_storm",
		"Thunderstorm",
		"Call down a persistent storm that strikes random enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		15.0
	).with_damage(30.0, 1.0) \
	 .with_aoe(250.0) \
	 .with_duration(5.0) \
	 .with_effect("thunderstorm") \
	 .with_prerequisite("chain_lightning", 0)

static func _create_overload() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"chain_lightning_overload",
		"Overload",
		"Massive lightning strike. Stunned enemies chain to all nearby.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		22.0
	).with_damage(100.0, 2.0) \
	 .with_range(500.0) \
	 .with_aoe(200.0) \
	 .with_stun(1.5) \
	 .with_effect("overload") \
	 .with_prerequisite("chain_lightning_storm", 0) \
	 .with_signature("Initial target stunned, chains at double damage to nearby")

static func _create_static_field() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"chain_lightning_static",
		"Static Field",
		"Create an aura that periodically shocks nearby enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		14.0
	).with_damage(15.0, 0.6) \
	 .with_aoe(150.0) \
	 .with_duration(8.0) \
	 .with_effect("static_field") \
	 .with_prerequisite("chain_lightning", 1)

static func _create_power_surge() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"chain_lightning_surge",
		"Power Surge",
		"Electrify yourself. All attacks chain lightning to nearby enemies.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		25.0
	).with_damage(20.0, 0.8) \
	 .with_aoe(120.0) \
	 .with_duration(10.0) \
	 .with_effect("power_surge") \
	 .with_prerequisite("chain_lightning_static", 1) \
	 .with_signature("All attacks chain lightning, +20% attack speed")

static func get_all_ability_ids() -> Array[String]:
	return ["chain_lightning", "chain_lightning_storm", "chain_lightning_overload", "chain_lightning_static", "chain_lightning_surge"]

static func get_tree_name() -> String:
	return "Chain Lightning"
