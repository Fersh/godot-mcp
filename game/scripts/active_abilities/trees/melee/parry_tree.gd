extends RefCounted
class_name ParryTree

# Parry Ability Tree (Melee)
# Base: Parry incoming attack
# Branch A (Counter): Counter attack -> Perfect Riposte (massive counter damage)
# Branch B (Deflect): Deflect projectiles -> Mirror Guard (reflect all damage)

const BASE_NAME = "Parry"
const BASE_ID = "parry"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_counter(),
		_create_riposte()
	)

	tree.add_branch(
		_create_deflect(),
		_create_mirror()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"parry",
		"Parry",
		"Parry the next incoming attack.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		4.0
	).with_damage(0.0, 0.0) \
	 .with_duration(0.5) \
	 .with_effect("parry_pixel")

static func _create_counter() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"parry_counter",
		"Counter Strike",
		"Successful parry triggers a powerful counter attack.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		5.0
	).with_damage(60.0, 1.5) \
	 .with_duration(0.6) \
	 .with_range(100.0) \
	 .with_effect("counter_strike") \
	 .with_prerequisite("parry", 0)

static func _create_riposte() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"parry_riposte",
		"Perfect Riposte",
		"A perfectly timed parry deals devastating counter damage.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		6.0
	).with_damage(150.0, 3.0) \
	 .with_duration(0.8) \
	 .with_range(150.0) \
	 .with_stun(1.5) \
	 .with_effect("perfect_riposte") \
	 .with_prerequisite("parry_counter", 0) \
	 .with_signature("Parry window extended, counter crits guaranteed, stuns attacker")

static func _create_deflect() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"parry_deflect",
		"Deflection",
		"Parry can also deflect projectiles back at enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		5.0
	).with_damage(40.0, 1.0) \
	 .with_duration(0.7) \
	 .with_effect("deflection") \
	 .with_prerequisite("parry", 1)

static func _create_mirror() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"parry_mirror",
		"Mirror Guard",
		"Become invulnerable briefly, reflecting all damage back.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		12.0
	).with_damage(0.0, 0.0) \
	 .with_duration(1.5) \
	 .with_aoe(200.0) \
	 .with_effect("mirror_guard") \
	 .with_prerequisite("parry_deflect", 1) \
	 .with_signature("100% damage reflection, immunity during duration, AoE reflect burst")

static func get_all_ability_ids() -> Array[String]:
	return ["parry", "parry_counter", "parry_riposte", "parry_deflect", "parry_mirror"]

static func get_tree_name() -> String:
	return "Parry"
