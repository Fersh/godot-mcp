extends RefCounted
class_name ShieldTree

# Shield/Barrier Ability Tree (Global)
# Base: Create a damage-absorbing shield
# Branch A (Absorb): Convert damage to healing -> Retaliation (damage back)
# Branch B (Bubble): Team shield -> Fortress (massive area shield)
# Branch C (Panic): Emergency knockback + invuln -> Uno Reverse (reflect all damage)

const BASE_NAME = "Barrier"
const BASE_ID = "barrier"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_absorb(),
		_create_retaliation()
	)

	tree.add_branch(
		_create_bubble(),
		_create_fortress()
	)

	# Branch C: Emergency/Reflect path
	tree.add_branch(
		_create_panic_button(),
		_create_uno_reverse()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"barrier",
		"Barrier",
		"Create a shield that absorbs damage.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		12.0
	).with_damage(0.0, 0.0) \
	 .with_duration(5.0) \
	 .with_effect("barrier")

static func _create_absorb() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"barrier_absorb",
		"Absorption Shield",
		"Shield converts 25% of absorbed damage to healing.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		15.0
	).with_damage(0.0, 0.0) \
	 .with_duration(6.0) \
	 .with_effect("barrier") \
	 .with_prerequisite("barrier", 0) \
	 .with_prefix("Absorb", BASE_NAME, BASE_ID)

static func _create_retaliation() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"barrier_retaliation",
		"Retaliation Shield",
		"When shield breaks, explode and reflect all absorbed damage.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		25.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(200.0) \
	 .with_duration(8.0) \
	 .with_effect("barrier") \
	 .with_prerequisite("barrier_absorb", 0) \
	 .with_signature("200% reflected damage, heal 50% of absorbed, stuns nearby") \
	 .with_suffix("of Retaliation", BASE_NAME, "Absorb", BASE_ID)

static func _create_bubble() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"barrier_bubble",
		"Protective Bubble",
		"Create a shield that protects an area.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		18.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(150.0) \
	 .with_duration(5.0) \
	 .with_effect("barrier") \
	 .with_prerequisite("barrier", 1) \
	 .with_prefix("Bubble", BASE_NAME, BASE_ID)

static func _create_fortress() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"barrier_fortress",
		"Fortress",
		"Create an impenetrable fortress. Nothing gets in or out.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		35.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(250.0) \
	 .with_duration(6.0) \
	 .with_effect("barrier") \
	 .with_prerequisite("barrier_bubble", 1) \
	 .with_signature("Complete immunity inside, enemies pushed out, heal over time") \
	 .with_suffix("of the Fortress", BASE_NAME, "Bubble", BASE_ID)

static func _create_panic_button() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"barrier_panic",
		"Panic Barrier",
		"Push all enemies away and gain brief invulnerability.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		25.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(300.0) \
	 .with_knockback(600.0) \
	 .with_invulnerability(4.0) \
	 .with_effect("panic_button") \
	 .with_prerequisite("barrier", 2) \
	 .with_prefix("Panic", BASE_NAME, BASE_ID)

static func _create_uno_reverse() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"barrier_reverse",
		"Panic Barrier of Reversal",
		"For 4 seconds, all damage you would take is reflected back to enemies.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		35.0
	).with_damage(0.0, 0.0) \
	 .with_duration(4.0) \
	 .with_aoe(280.0) \
	 .with_effect("uno_reverse") \
	 .with_prerequisite("barrier_panic", 2) \
	 .with_signature("All incoming damage reflected 200%, gain invulnerability on activation") \
	 .with_suffix("of Reversal", BASE_NAME, "Panic", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["barrier", "barrier_absorb", "barrier_retaliation", "barrier_bubble", "barrier_fortress", "barrier_panic", "barrier_reverse"]

static func get_tree_name() -> String:
	return "Barrier"
