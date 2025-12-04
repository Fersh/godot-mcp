extends RefCounted
class_name ExecuteTree

# Execute Ability Tree (Melee)
# Base: Deal bonus damage to low HP enemies
# Branch A (Reaper): Instant kill threshold -> Soul Harvest (heal per execute)
# Branch B (Brutal): Massive single hit -> Decapitate (guaranteed crit on low HP)

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_reaper(),
		_create_soul_harvest()
	)

	tree.add_branch(
		_create_brutal_strike(),
		_create_decapitate()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"execute",
		"Execute",
		"Strike a wounded enemy for bonus damage. +100% damage below 30% HP.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		8.0
	).with_damage(60.0, 1.4) \
	 .with_range(150.0) \
	 .with_effect("execute")

static func _create_reaper() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"execute_reaper",
		"Reaper's Touch",
		"Enemies below 20% HP are instantly killed.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		10.0
	).with_damage(50.0, 1.2) \
	 .with_range(150.0) \
	 .with_effect("reaper_touch") \
	 .with_prerequisite("execute", 0)

static func _create_soul_harvest() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"execute_harvest",
		"Soul Harvest",
		"Executions restore health and extend the kill threshold.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		12.0
	).with_damage(55.0, 1.3) \
	 .with_range(180.0) \
	 .with_effect("soul_harvest") \
	 .with_prerequisite("execute_reaper", 0) \
	 .with_signature("Kill below 25% HP, heal 20% max HP per kill, resets cooldown on kill")

static func _create_brutal_strike() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"execute_brutal",
		"Brutal Strike",
		"Massive overhead strike. Ignores armor on low HP targets.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		10.0
	).with_damage(100.0, 1.8) \
	 .with_range(120.0) \
	 .with_effect("brutal_strike") \
	 .with_prerequisite("execute", 1)

static func _create_decapitate() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"execute_decapitate",
		"Decapitate",
		"Guaranteed critical hit. Targets below 40% HP take triple damage.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		15.0
	).with_damage(120.0, 2.0) \
	 .with_range(150.0) \
	 .with_effect("decapitate") \
	 .with_prerequisite("execute_brutal", 1) \
	 .with_signature("Always crits, 3x damage below 40% HP, brief slow-mo on kill")

static func get_all_ability_ids() -> Array[String]:
	return ["execute", "execute_reaper", "execute_harvest", "execute_brutal", "execute_decapitate"]

static func get_tree_name() -> String:
	return "Execute"
