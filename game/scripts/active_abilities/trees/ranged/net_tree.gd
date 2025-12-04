extends RefCounted
class_name NetTree

# Net/Entangle Ability Tree (Ranged)
# Base: Throw net to slow enemies
# Branch A (Electric): Electrified net -> Tesla Net (chains lightning)
# Branch B (Barbed): Damaging net -> Razor Net (shreds trapped enemies)

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_electric(),
		_create_tesla()
	)

	tree.add_branch(
		_create_barbed(),
		_create_razor()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"net",
		"Throwing Net",
		"Throw a net that slows enemies caught in it.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.CLUSTER,
		7.0
	).with_damage(0.0, 0.0) \
	 .with_range(300.0) \
	 .with_aoe(100.0) \
	 .with_slow(0.5, 3.0) \
	 .with_effect("net")

static func _create_electric() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"net_electric",
		"Electric Net",
		"Net is electrified, damaging and stunning briefly.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.CLUSTER,
		9.0
	).with_damage(25.0, 0.8) \
	 .with_range(350.0) \
	 .with_aoe(120.0) \
	 .with_slow(0.6, 4.0) \
	 .with_stun(0.5) \
	 .with_effect("electric_net") \
	 .with_prerequisite("net", 0)

static func _create_tesla() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"net_tesla",
		"Tesla Net",
		"Net chains lightning between all trapped enemies.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.CLUSTER,
		15.0
	).with_damage(35.0, 1.2) \
	 .with_range(400.0) \
	 .with_aoe(180.0) \
	 .with_slow(0.7, 5.0) \
	 .with_stun(1.0) \
	 .with_duration(5.0) \
	 .with_effect("tesla_net") \
	 .with_prerequisite("net_electric", 0) \
	 .with_signature("Continuous lightning between trapped enemies, longer duration")

static func _create_barbed() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"net_barbed",
		"Barbed Net",
		"Net has barbs that damage enemies when they move.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.CLUSTER,
		8.0
	).with_damage(15.0, 0.6) \
	 .with_range(350.0) \
	 .with_aoe(110.0) \
	 .with_slow(0.5, 4.0) \
	 .with_duration(4.0) \
	 .with_effect("barbed_net") \
	 .with_prerequisite("net", 1)

static func _create_razor() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"net_razor",
		"Razor Net",
		"Constricting net that shreds enemies over time.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.CLUSTER,
		14.0
	).with_damage(25.0, 1.0) \
	 .with_range(400.0) \
	 .with_aoe(150.0) \
	 .with_slow(0.8, 5.0) \
	 .with_duration(5.0) \
	 .with_effect("razor_net") \
	 .with_prerequisite("net_barbed", 1) \
	 .with_signature("Constricts over time dealing increasing damage, bleed effect")

static func get_all_ability_ids() -> Array[String]:
	return ["net", "net_electric", "net_tesla", "net_barbed", "net_razor"]

static func get_tree_name() -> String:
	return "Net"
