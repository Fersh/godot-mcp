extends RefCounted
class_name TeleportTree

# Shadowstep/Teleport Ability Tree (Global)
# Base: Short range teleport
# Branch A (Blink): Longer range -> Dimension Shift (invulnerable blink)
# Branch B (Shadow): Leave clone -> Shadow Swap (swap with clone)

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_blink(),
		_create_dimension_shift()
	)

	tree.add_branch(
		_create_shadow_step(),
		_create_shadow_swap()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"teleport",
		"Teleport",
		"Instantly teleport a short distance.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.DIRECTION,
		5.0
	).with_damage(0.0, 0.0) \
	 .with_range(200.0) \
	 .with_movement() \
	 .with_effect("teleport")

static func _create_blink() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"teleport_blink",
		"Blink",
		"Extended range teleport with brief invulnerability.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.DIRECTION,
		6.0
	).with_damage(0.0, 0.0) \
	 .with_range(350.0) \
	 .with_movement() \
	 .with_invulnerability(0.3) \
	 .with_effect("blink") \
	 .with_prerequisite("teleport", 0)

static func _create_dimension_shift() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"teleport_dimension",
		"Dimension Shift",
		"Phase through reality. Long invulnerable teleport that damages enemies in path.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.DIRECTION,
		12.0
	).with_damage(60.0, 1.2) \
	 .with_range(500.0) \
	 .with_movement() \
	 .with_invulnerability(0.8) \
	 .with_effect("dimension_shift") \
	 .with_prerequisite("teleport_blink", 0) \
	 .with_signature("Damage all enemies in path, leave afterimage that explodes")

static func _create_shadow_step() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"teleport_shadow",
		"Shadow Step",
		"Teleport and leave a shadow clone at start position.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.DIRECTION,
		7.0
	).with_damage(30.0, 0.8) \
	 .with_range(250.0) \
	 .with_duration(4.0) \
	 .with_movement() \
	 .with_effect("shadow_step") \
	 .with_prerequisite("teleport", 1)

static func _create_shadow_swap() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"teleport_swap",
		"Shadow Swap",
		"Create a shadow. Can reactivate to swap positions. Clone explodes on swap.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.DIRECTION,
		10.0
	).with_damage(80.0, 1.5) \
	 .with_range(300.0) \
	 .with_aoe(120.0) \
	 .with_duration(6.0) \
	 .with_movement() \
	 .with_effect("shadow_swap") \
	 .with_prerequisite("teleport_shadow", 1) \
	 .with_signature("Clone attacks enemies, swap causes explosion, reset CD on kill")

static func get_all_ability_ids() -> Array[String]:
	return ["teleport", "teleport_blink", "teleport_dimension", "teleport_shadow", "teleport_swap"]

static func get_tree_name() -> String:
	return "Teleport"
