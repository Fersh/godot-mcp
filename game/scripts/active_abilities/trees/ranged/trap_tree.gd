extends RefCounted
class_name TrapTree

# Trap Ability Tree
# Base: Place floor trap that triggers when enemy steps on it
# Branch A (Bear Trap): Root + damage -> Chain Trap (trapped enemy pulls others in)
# Branch B (Explosive): AoE explosion -> Cluster Mine (spawns more traps)

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_bear_trap(),
		_create_chain_trap()
	)

	tree.add_branch(
		_create_explosive_trap(),
		_create_cluster_mine()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"trap",
		"Trap",
		"Place a trap on the ground that damages and slows enemies.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		8.0
	).with_damage(50.0, 1.0) \
	 .with_slow(0.5, 2.0) \
	 .with_effect("trap")

static func _create_bear_trap() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"trap_bear",
		"Bear Trap",
		"A vicious trap that roots enemies in place and deals heavy damage.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		10.0
	).with_damage(70.0, 1.3) \
	 .with_stun(3.0) \
	 .with_effect("bear_trap") \
	 .with_prerequisite("trap", 0)

static func _create_chain_trap() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"trap_chain",
		"Chain Trap",
		"When triggered, chains shoot out and pull nearby enemies into the trap.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		12.0
	).with_damage(80.0, 1.5) \
	 .with_stun(4.0) \
	 .with_aoe(200.0) \
	 .with_effect("chain_trap") \
	 .with_prerequisite("trap_bear", 0) \
	 .with_signature("Pulls all nearby enemies into the trap")

static func _create_explosive_trap() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"trap_explosive",
		"Explosive Trap",
		"A trap that explodes when triggered, dealing AoE damage.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		8.0
	).with_damage(60.0, 1.2) \
	 .with_aoe(150.0) \
	 .with_effect("explosive_trap") \
	 .with_prerequisite("trap", 1)

static func _create_cluster_mine() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"trap_cluster",
		"Cluster Mine",
		"When triggered, spawns 4 additional explosive traps in a circle.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		15.0
	).with_damage(50.0, 1.0) \
	 .with_aoe(120.0) \
	 .with_effect("cluster_mine") \
	 .with_prerequisite("trap_explosive", 1) \
	 .with_signature("Creates 4 additional explosive traps on detonation")

static func get_all_ability_ids() -> Array[String]:
	return ["trap", "trap_bear", "trap_chain", "trap_explosive", "trap_cluster"]

static func get_tree_name() -> String:
	return "Trap"
