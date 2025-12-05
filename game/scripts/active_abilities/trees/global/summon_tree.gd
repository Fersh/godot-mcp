extends RefCounted
class_name SummonTree

# Summon Ability Tree (Global)
# Base: Summon a temporary minion
# Branch A (Golem): Tank minion -> Titan (massive golem)
# Branch B (Swarm): Multiple weak minions -> Army (endless horde)

const BASE_NAME = "Summon Minion"
const BASE_ID = "summon"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_golem(),
		_create_titan()
	)

	tree.add_branch(
		_create_swarm(),
		_create_army()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"summon",
		"Summon Minion",
		"Summon a minion to fight for you.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		15.0
	).with_damage(25.0, 0.8) \
	 .with_duration(15.0) \
	 .with_effect("summon_minion")

static func _create_golem() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"summon_golem",
		"Summon Golem",
		"Summon a sturdy golem that taunts enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		20.0
	).with_damage(35.0, 1.0) \
	 .with_duration(20.0) \
	 .with_effect("summon_minion") \
	 .with_prerequisite("summon", 0) \
	 .with_prefix("Golem", BASE_NAME, BASE_ID)

static func _create_titan() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"summon_titan",
		"Summon Titan",
		"Summon a massive titan that devastates the battlefield.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		45.0
	).with_damage(80.0, 1.5) \
	 .with_aoe(150.0) \
	 .with_duration(25.0) \
	 .with_effect("summon_minion") \
	 .with_prerequisite("summon_golem", 0) \
	 .with_signature("Massive AoE attacks, taunts all enemies, earthquakes on stomp") \
	 .with_suffix("of the Titan", BASE_NAME, "Golem", BASE_ID)

static func _create_swarm() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"summon_swarm",
		"Summon Swarm",
		"Summon 4 small minions that overwhelm enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		18.0
	).with_damage(15.0, 0.5) \
	 .with_duration(12.0) \
	 .with_projectiles(4, 0) \
	 .with_effect("summon_minion") \
	 .with_prerequisite("summon", 1) \
	 .with_prefix("Swarm", BASE_NAME, BASE_ID)

static func _create_army() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"summon_army",
		"Army of the Dead",
		"Raise an undead army. Minions respawn when killed.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		60.0
	).with_damage(20.0, 0.6) \
	 .with_duration(30.0) \
	 .with_projectiles(8, 0) \
	 .with_effect("summon_minion") \
	 .with_prerequisite("summon_swarm", 1) \
	 .with_signature("8 minions, respawn after 3s when killed, explode on death") \
	 .with_suffix("of the Army", BASE_NAME, "Swarm", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["summon", "summon_golem", "summon_titan", "summon_swarm", "summon_army"]

static func get_tree_name() -> String:
	return "Summon"
