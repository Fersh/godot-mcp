extends RefCounted
class_name FireballTree

# Fireball Ability Tree (Global - available to all classes)
# Base: Fire projectile that burns enemies
# Branch A (Meteor): Delayed massive AoE -> Meteor Shower (multiple meteors)
# Branch B (Phoenix): Healing fire -> Phoenix Dive (dash through enemies, heal on hit)

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_meteor_strike(),
		_create_meteor_shower()
	)

	tree.add_branch(
		_create_phoenix_flame(),
		_create_phoenix_dive()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"fireball",
		"Fireball",
		"Hurl a ball of fire that explodes on impact, burning enemies.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.DIRECTION,
		5.0
	).with_damage(45.0, 1.3) \
	 .with_projectiles(1, 450.0) \
	 .with_aoe(80.0) \
	 .with_effect("fireball")

static func _create_meteor_strike() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"fireball_meteor",
		"Meteor Strike",
		"Call down a meteor at target location after a short delay.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		8.0
	).with_damage(100.0, 2.0) \
	 .with_aoe(150.0) \
	 .with_cast_time(1.0) \
	 .with_stun(1.0) \
	 .with_effect("meteor") \
	 .with_prerequisite("fireball", 0)

static func _create_meteor_shower() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"fireball_shower",
		"Meteor Shower",
		"Rain destruction from the sky. Multiple meteors strike the battlefield.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		15.0
	).with_damage(80.0, 1.8) \
	 .with_aoe(300.0) \
	 .with_cast_time(0.5) \
	 .with_duration(3.0) \
	 .with_stun(0.5) \
	 .with_effect("meteor_shower") \
	 .with_prerequisite("fireball_meteor", 0) \
	 .with_signature("5 meteors rain down over 3 seconds")

static func _create_phoenix_flame() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"fireball_phoenix",
		"Phoenix Flame",
		"Sacred fire that damages enemies and heals you for a portion of damage dealt.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.DIRECTION,
		7.0
	).with_damage(55.0, 1.4) \
	 .with_projectiles(1, 400.0) \
	 .with_aoe(100.0) \
	 .with_effect("phoenix_flame") \
	 .with_prerequisite("fireball", 1)

static func _create_phoenix_dive() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"fireball_dive",
		"Phoenix Dive",
		"Transform into a phoenix and dive through enemies. Heal for each enemy hit.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.DIRECTION,
		12.0
	).with_damage(70.0, 1.6) \
	 .with_range(300.0) \
	 .with_aoe(80.0) \
	 .with_movement() \
	 .with_invulnerability(1.0) \
	 .with_effect("phoenix_dive") \
	 .with_prerequisite("fireball_phoenix", 1) \
	 .with_signature("Invulnerable dash, heal 10% max HP per enemy hit")

static func get_all_ability_ids() -> Array[String]:
	return ["fireball", "fireball_meteor", "fireball_shower", "fireball_phoenix", "fireball_dive"]

static func get_tree_name() -> String:
	return "Fireball"
