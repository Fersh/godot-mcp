extends RefCounted
class_name SummonTree

# Summon Ability Tree (Global)
# Base: Summon a temporary minion
# Branch A (Golem): Tank minion -> Titan (massive golem)
# Branch B (Swarm): Multiple weak minions -> Army (endless horde)
# Branch C (Wolves): Wolf companion -> Release the Hounds (wolf pack)
# Branch D (Healer): Healing spirit -> Pocket Healer (healing fairy)

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

	# Branch C: Wolf pack path
	tree.add_branch(
		_create_wolf(),
		_create_release_the_hounds()
	)

	# Branch D: Healing spirit path
	tree.add_branch(
		_create_spirit(),
		_create_pocket_healer()
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
	 .with_prerequisite("summon", 0)

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
	 .with_signature("Massive AoE attacks, taunts all enemies, earthquakes on stomp")

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
	 .with_prerequisite("summon", 1)

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
	 .with_signature("8 minions, respawn after 3s when killed, explode on death")

static func _create_wolf() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"summon_wolf",
		"Wolf Minion",
		"Summon a ghostly wolf that hunts down enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		18.0
	).with_damage(30.0, 1.2) \
	 .with_duration(15.0) \
	 .with_effect("summon_wolf") \
	 .with_prerequisite("summon", 2)

static func _create_release_the_hounds() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"summon_hounds",
		"Release the Hounds",
		"Release a pack of 5 ghostly wolves that chase down enemies.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		30.0
	).with_damage(28.0, 1.5) \
	 .with_duration(12.0) \
	 .with_projectiles(5, 0) \
	 .with_effect("release_the_hounds") \
	 .with_prerequisite("summon_wolf", 2) \
	 .with_signature("5 wolves, high speed, hunt nearest enemies, howl on spawn stuns nearby")

static func _create_spirit() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"summon_spirit",
		"Spirit Minion",
		"Summon a healing spirit that heals you over time.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		25.0
	).with_damage(0.0, 0.0) \
	 .with_duration(10.0) \
	 .with_effect("summon_spirit") \
	 .with_prerequisite("summon", 3)

static func _create_pocket_healer() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"summon_healer",
		"Pocket Healer",
		"Summon a healing fairy that follows you and heals 3% HP per second.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		35.0
	).with_damage(0.0, 0.0) \
	 .with_duration(15.0) \
	 .with_effect("pocket_healer") \
	 .with_prerequisite("summon_spirit", 3) \
	 .with_signature("3% max HP heal per second, removes debuffs, revives on death once")

static func get_all_ability_ids() -> Array[String]:
	return ["summon", "summon_golem", "summon_titan", "summon_swarm", "summon_army", "summon_wolf", "summon_hounds", "summon_spirit", "summon_healer"]

static func get_tree_name() -> String:
	return "Summon"
