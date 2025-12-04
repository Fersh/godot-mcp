extends RefCounted
class_name EvasionTree

# Quick Roll Ability Tree (Ranged)
# Base: Evasive roll with i-frames
# Branch A (Shadow): Leave decoy -> Shadow Dance (chain rolls with clones)
# Branch B (Counter): Counter-attack after roll -> Perfect Dodge (massive counter)

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_shadow_roll(),
		_create_shadow_dance()
	)

	tree.add_branch(
		_create_counter_roll(),
		_create_perfect_dodge()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"quick_roll",
		"Quick Roll",
		"Roll to evade attacks with brief invulnerability.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		3.0
	).with_damage(0.0, 0.0) \
	 .with_range(150.0) \
	 .with_movement() \
	 .with_invulnerability(0.3) \
	 .with_effect("quick_roll")

static func _create_shadow_roll() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"roll_shadow",
		"Shadow Roll",
		"Leave a decoy that explodes after 1 second.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		4.0
	).with_damage(40.0, 1.0) \
	 .with_range(150.0) \
	 .with_aoe(100.0) \
	 .with_movement() \
	 .with_invulnerability(0.3) \
	 .with_effect("shadow_roll") \
	 .with_prerequisite("quick_roll", 0)

static func _create_shadow_dance() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"roll_dance",
		"Shadow Dance",
		"Perform 3 rapid rolls, each leaving an attacking clone.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		12.0
	).with_damage(35.0, 1.2) \
	 .with_range(150.0) \
	 .with_aoe(80.0) \
	 .with_projectiles(3, 0) \
	 .with_movement() \
	 .with_invulnerability(1.0) \
	 .with_duration(2.0) \
	 .with_effect("shadow_dance") \
	 .with_prerequisite("roll_shadow", 0) \
	 .with_signature("3 chain rolls, each clone attacks 3 times before vanishing")

static func _create_counter_roll() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"roll_counter",
		"Counter Roll",
		"Roll and strike back at the nearest enemy.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		4.0
	).with_damage(50.0, 1.2) \
	 .with_range(150.0) \
	 .with_movement() \
	 .with_invulnerability(0.3) \
	 .with_effect("counter_roll") \
	 .with_prerequisite("quick_roll", 1)

static func _create_perfect_dodge() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"roll_perfect",
		"Perfect Dodge",
		"Time slows during roll. Counter with devastating strike.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		10.0
	).with_damage(150.0, 2.0) \
	 .with_range(200.0) \
	 .with_movement() \
	 .with_invulnerability(0.8) \
	 .with_stun(1.0) \
	 .with_effect("perfect_dodge") \
	 .with_prerequisite("roll_counter", 1) \
	 .with_signature("Slow-mo for 0.5s, guaranteed crit counter, stuns target")

static func get_all_ability_ids() -> Array[String]:
	return ["quick_roll", "roll_shadow", "roll_dance", "roll_counter", "roll_perfect"]

static func get_tree_name() -> String:
	return "Quick Roll"
