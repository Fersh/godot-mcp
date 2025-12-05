extends RefCounted
class_name DecoyTree

# Decoy Ability Tree (Ranged)
# Base: Deploy a decoy that draws aggro
# Branch A (Explosive): Decoy explodes -> Chain Reaction (multiple decoys)
# Branch B (Mirror): Decoy copies attacks -> Army of Me (permanent clones)

const BASE_NAME = "Decoy"
const BASE_ID = "decoy"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_explosive_decoy(),
		_create_chain_reaction()
	)

	tree.add_branch(
		_create_mirror_image(),
		_create_army_of_me()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"decoy",
		"Decoy",
		"Deploy a decoy that draws enemy attention.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		10.0
	).with_damage(0.0, 0.0) \
	 .with_duration(6.0) \
	 .with_effect("decoy")

static func _create_explosive_decoy() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"decoy_explosive",
		"Explosive Decoy",
		"Decoy explodes when destroyed or expires.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		12.0
	).with_damage(60.0, 1.3) \
	 .with_aoe(120.0) \
	 .with_duration(5.0) \
	 .with_effect("explosive_decoy") \
	 .with_prerequisite("decoy", 0) \
	 .with_prefix("Explosive", BASE_NAME, BASE_ID)

static func _create_chain_reaction() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"decoy_chain",
		"Chain Reaction",
		"Deploy 3 decoys that explode in sequence.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		20.0
	).with_damage(50.0, 1.2) \
	 .with_aoe(100.0) \
	 .with_duration(6.0) \
	 .with_projectiles(3, 0) \
	 .with_effect("chain_reaction") \
	 .with_prerequisite("decoy_explosive", 0) \
	 .with_signature("3 decoys in triangle, chain explosions, final blast is 2x") \
	 .with_suffix("of Chain Reaction", BASE_NAME, "Explosive", BASE_ID)

static func _create_mirror_image() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"decoy_mirror",
		"Mirror Image",
		"Decoy copies your basic attacks at 50% damage.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		14.0
	).with_damage(0.0, 0.0) \
	 .with_duration(8.0) \
	 .with_effect("mirror_image") \
	 .with_prerequisite("decoy", 1) \
	 .with_prefix("Mirror", BASE_NAME, BASE_ID)

static func _create_army_of_me() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"decoy_army",
		"Army of Me",
		"Create 3 permanent mirror images that fight alongside you.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		45.0
	).with_damage(0.0, 0.0) \
	 .with_duration(0.0) \
	 .with_projectiles(3, 0) \
	 .with_effect("army_of_me") \
	 .with_prerequisite("decoy_mirror", 1) \
	 .with_signature("3 permanent clones at 35% damage, respawn after 10s if killed") \
	 .with_suffix("of the Legion", BASE_NAME, "Mirror", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["decoy", "decoy_explosive", "decoy_chain", "decoy_mirror", "decoy_army"]

static func get_tree_name() -> String:
	return "Decoy"
