extends RefCounted
class_name SmokeTree

# Smoke Bomb Ability Tree (Ranged)
# Base: Create smoke cloud for cover
# Branch A (Blind): Blind enemies -> Total Darkness (massive blind zone)
# Branch B (Poison): Poison smoke -> Plague Cloud (spreading poison)

const BASE_NAME = "Smoke Bomb"
const BASE_ID = "smoke_bomb"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_blind(),
		_create_darkness()
	)

	tree.add_branch(
		_create_poison(),
		_create_plague()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"smoke_bomb",
		"Smoke Bomb",
		"Drop a smoke bomb, obscuring vision.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		8.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(150.0) \
	 .with_duration(4.0) \
	 .with_effect("smoke_bomb")

static func _create_blind() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"smoke_blind",
		"Blinding Smoke",
		"Smoke blinds enemies, reducing their accuracy.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		10.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(180.0) \
	 .with_duration(5.0) \
	 .with_effect("blinding_smoke") \
	 .with_prerequisite("smoke_bomb", 0) \
	 .with_prefix("Blinding", BASE_NAME, BASE_ID)

static func _create_darkness() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"smoke_darkness",
		"Total Darkness",
		"Create impenetrable darkness. You can see, enemies can't.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		20.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(250.0) \
	 .with_duration(6.0) \
	 .with_effect("total_darkness") \
	 .with_prerequisite("smoke_blind", 0) \
	 .with_signature("Enemies completely blind, you gain 50% crit chance in darkness") \
	 .with_suffix("of Darkness", BASE_NAME, "Blinding", BASE_ID)

static func _create_poison() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"smoke_poison",
		"Poison Cloud",
		"Smoke is toxic, damaging enemies inside.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		10.0
	).with_damage(15.0, 0.6) \
	 .with_aoe(160.0) \
	 .with_duration(5.0) \
	 .with_effect("poison_cloud") \
	 .with_prerequisite("smoke_bomb", 1) \
	 .with_prefix("Poison", BASE_NAME, BASE_ID)

static func _create_plague() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"smoke_plague",
		"Plague Cloud",
		"Toxic cloud that spreads and grows over time.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		25.0
	).with_damage(20.0, 0.8) \
	 .with_aoe(300.0) \
	 .with_duration(8.0) \
	 .with_effect("plague_cloud") \
	 .with_prerequisite("smoke_poison", 1) \
	 .with_signature("Cloud grows over time, poison stacks, spreads to new areas") \
	 .with_suffix("of Plague", BASE_NAME, "Poison", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["smoke_bomb", "smoke_blind", "smoke_darkness", "smoke_poison", "smoke_plague"]

static func get_tree_name() -> String:
	return "Smoke Bomb"
