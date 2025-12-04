extends RefCounted
class_name TauntTree

# Taunt Ability Tree (Melee)
# Base: Force enemies to attack you
# Branch A (Fortify): Gain armor while taunted -> Unstoppable (immune to damage briefly)
# Branch B (Counter): Counter when hit -> Vengeance (explode on taking damage)

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_fortify(),
		_create_unstoppable()
	)

	tree.add_branch(
		_create_counter_stance(),
		_create_vengeance()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"taunt",
		"Taunt",
		"Force nearby enemies to attack you for 3 seconds.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		12.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(200.0) \
	 .with_duration(3.0) \
	 .with_effect("taunt")

static func _create_fortify() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"taunt_fortify",
		"Fortifying Taunt",
		"Gain 40% damage reduction while enemies are taunted.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		14.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(250.0) \
	 .with_duration(4.0) \
	 .with_effect("fortify_taunt") \
	 .with_prerequisite("taunt", 0)

static func _create_unstoppable() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"taunt_unstoppable",
		"Unstoppable",
		"Become immune to damage and CC. Enemies forced to attack you.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		30.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(300.0) \
	 .with_duration(3.0) \
	 .with_invulnerability(3.0) \
	 .with_effect("unstoppable") \
	 .with_prerequisite("taunt_fortify", 0) \
	 .with_signature("3 seconds of invulnerability, all enemies attack you")

static func _create_counter_stance() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"taunt_counter",
		"Counter Stance",
		"When hit during taunt, automatically counter-attack.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		12.0
	).with_damage(30.0, 1.0) \
	 .with_aoe(200.0) \
	 .with_duration(4.0) \
	 .with_effect("counter_stance") \
	 .with_prerequisite("taunt", 1)

static func _create_vengeance() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"taunt_vengeance",
		"Vengeance",
		"Every hit you take causes an explosion damaging nearby enemies.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		25.0
	).with_damage(50.0, 1.5) \
	 .with_aoe(150.0) \
	 .with_duration(5.0) \
	 .with_effect("vengeance") \
	 .with_prerequisite("taunt_counter", 1) \
	 .with_signature("Each hit triggers AoE explosion, gain 10% lifesteal")

static func get_all_ability_ids() -> Array[String]:
	return ["taunt", "taunt_fortify", "taunt_unstoppable", "taunt_counter", "taunt_vengeance"]

static func get_tree_name() -> String:
	return "Taunt"
