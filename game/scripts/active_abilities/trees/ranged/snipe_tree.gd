extends RefCounted
class_name SnipeTree

# Snipe Ability Tree (Ranged)
# Base: Charged shot with bonus damage
# Branch A (Crit): Guaranteed crit on weak spot -> Assassinate (instant kill low HP)
# Branch B (Penetrate): Ignore armor -> Obliterate (massive single target)

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_headshot(),
		_create_assassinate()
	)

	tree.add_branch(
		_create_armor_pierce(),
		_create_obliterate()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"snipe",
		"Snipe",
		"Charge a powerful shot. Longer charge = more damage.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		8.0
	).with_damage(80.0, 1.6) \
	 .with_range(600.0) \
	 .with_cast_time(1.0) \
	 .with_effect("snipe")

static func _create_headshot() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"snipe_headshot",
		"Headshot",
		"Aim for weak points. Guaranteed critical hit.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		10.0
	).with_damage(70.0, 1.5) \
	 .with_range(700.0) \
	 .with_cast_time(1.2) \
	 .with_effect("headshot") \
	 .with_prerequisite("snipe", 0)

static func _create_assassinate() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"snipe_assassinate",
		"Assassinate",
		"Execute enemies below 30% HP instantly.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		18.0
	).with_damage(100.0, 2.0) \
	 .with_range(800.0) \
	 .with_cast_time(0.8) \
	 .with_effect("assassinate") \
	 .with_prerequisite("snipe_headshot", 0) \
	 .with_signature("Instant kill below 30%, refund CD on kill, invisible briefly after")

static func _create_armor_pierce() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"snipe_pierce",
		"Armor Piercing",
		"Shot ignores all armor and defensive buffs.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		10.0
	).with_damage(90.0, 1.7) \
	 .with_range(650.0) \
	 .with_cast_time(1.0) \
	 .with_effect("armor_pierce") \
	 .with_prerequisite("snipe", 1)

static func _create_obliterate() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"snipe_obliterate",
		"Obliterate",
		"Channel ultimate shot that deals devastating damage.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		25.0
	).with_damage(300.0, 3.5) \
	 .with_range(1000.0) \
	 .with_cast_time(2.0) \
	 .with_effect("obliterate") \
	 .with_prerequisite("snipe_pierce", 1) \
	 .with_signature("Massive damage, pierces all, leaves destruction trail, knockback self")

static func get_all_ability_ids() -> Array[String]:
	return ["snipe", "snipe_headshot", "snipe_assassinate", "snipe_pierce", "snipe_obliterate"]

static func get_tree_name() -> String:
	return "Snipe"
