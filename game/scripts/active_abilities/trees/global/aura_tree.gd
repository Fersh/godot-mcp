extends RefCounted
class_name AuraTree

# Aura/Buff Ability Tree (Global)
# Base: Temporary damage buff
# Branch A (Might): Attack buff -> Avatar (massive transformation)
# Branch B (Speed): Speed buff -> Haste (attack and move speed)

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_might(),
		_create_avatar()
	)

	tree.add_branch(
		_create_speed(),
		_create_haste()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"empower",
		"Empower",
		"Temporarily increase your damage by 30%.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		15.0
	).with_damage(0.0, 0.0) \
	 .with_duration(6.0) \
	 .with_effect("empower")

static func _create_might() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"empower_might",
		"Might",
		"Increase damage by 50% and gain 20% lifesteal.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		20.0
	).with_damage(0.0, 0.0) \
	 .with_duration(8.0) \
	 .with_effect("might") \
	 .with_prerequisite("empower", 0)

static func _create_avatar() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"empower_avatar",
		"Avatar of War",
		"Transform into a war god. Massive size, damage, and AoE.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		45.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(100.0) \
	 .with_duration(12.0) \
	 .with_effect("avatar_of_war") \
	 .with_prerequisite("empower_might", 0) \
	 .with_signature("2x size, 100% damage, all attacks are AoE, 25% damage reduction")

static func _create_speed() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"empower_speed",
		"Quicken",
		"Increase movement and attack speed by 40%.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		18.0
	).with_damage(0.0, 0.0) \
	 .with_duration(7.0) \
	 .with_effect("quicken") \
	 .with_prerequisite("empower", 1)

static func _create_haste() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"empower_haste",
		"Haste",
		"Blazing speed. Double attack rate and leave afterimages.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		35.0
	).with_damage(20.0, 0.5) \
	 .with_duration(10.0) \
	 .with_effect("haste") \
	 .with_prerequisite("empower_speed", 1) \
	 .with_signature("100% attack speed, 50% move speed, afterimages deal 25% damage")

static func get_all_ability_ids() -> Array[String]:
	return ["empower", "empower_might", "empower_avatar", "empower_speed", "empower_haste"]

static func get_tree_name() -> String:
	return "Empower"
