extends RefCounted
class_name ShoutTree

# Battle Cry Ability Tree (Melee)
# Base: Buff self with attack speed
# Branch A (War): Team buff -> Warlord's Command (massive team buff + fear)
# Branch B (Berserk): Self damage boost + take more -> Rage Incarnate (transform)

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_rallying_cry(),
		_create_warlords_command()
	)

	tree.add_branch(
		_create_berserker_rage(),
		_create_rage_incarnate()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"battle_cry",
		"Battle Cry",
		"Let out a fearsome cry, boosting your attack speed.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		12.0
	).with_damage(0.0, 0.0) \
	 .with_duration(5.0) \
	 .with_effect("battle_cry")

static func _create_rallying_cry() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"shout_rallying",
		"Rallying Cry",
		"Inspire nearby allies, granting damage and speed.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		15.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(200.0) \
	 .with_duration(6.0) \
	 .with_effect("rallying_cry") \
	 .with_prerequisite("battle_cry", 0)

static func _create_warlords_command() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"shout_warlord",
		"Warlord's Command",
		"Your presence commands the battlefield. Allies empowered, enemies flee.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		25.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(350.0) \
	 .with_duration(8.0) \
	 .with_effect("warlords_command") \
	 .with_prerequisite("shout_rallying", 0) \
	 .with_signature("50% damage boost to allies, enemies feared for 2s")

static func _create_berserker_rage() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"shout_berserk",
		"Berserker Rage",
		"Enter a frenzy. Deal 50% more damage but take 25% more.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		10.0
	).with_damage(0.0, 0.0) \
	 .with_duration(6.0) \
	 .with_effect("berserker_rage") \
	 .with_prerequisite("battle_cry", 1)

static func _create_rage_incarnate() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"shout_rage_incarnate",
		"Rage Incarnate",
		"Transform into pure rage. Unstoppable, but burns your life force.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		30.0
	).with_damage(0.0, 0.0) \
	 .with_duration(10.0) \
	 .with_effect("rage_incarnate") \
	 .with_prerequisite("shout_berserk", 1) \
	 .with_signature("100% damage, immune to CC, but lose 3% HP/sec")

static func get_all_ability_ids() -> Array[String]:
	return ["battle_cry", "shout_rallying", "shout_warlord", "shout_berserk", "shout_rage_incarnate"]

static func get_tree_name() -> String:
	return "Battle Cry"
