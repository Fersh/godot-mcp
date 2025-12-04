extends RefCounted
class_name RampageTree

# Rampage Ability Tree (Melee)
# Base: Enter rampage mode for attack speed
# Branch A (Frenzy): Stack frenzy -> Bloodlust (faster with each kill)
# Branch B (Fury): Damage increase -> Unstoppable (immune + massive damage)

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_frenzy(),
		_create_bloodlust()
	)

	tree.add_branch(
		_create_fury(),
		_create_unstoppable()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"rampage",
		"Rampage",
		"Enter a rampage, increasing attack speed.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		15.0
	).with_damage(0.0, 0.0) \
	 .with_duration(5.0) \
	 .with_effect("rampage")

static func _create_frenzy() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"rampage_frenzy",
		"Frenzy",
		"Attacks build frenzy stacks, each increasing speed further.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		15.0
	).with_damage(0.0, 0.0) \
	 .with_duration(6.0) \
	 .with_effect("frenzy") \
	 .with_prerequisite("rampage", 0)

static func _create_bloodlust() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"rampage_bloodlust",
		"Bloodlust",
		"Each kill during rampage extends duration and increases power.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		18.0
	).with_damage(0.0, 0.0) \
	 .with_duration(8.0) \
	 .with_effect("bloodlust") \
	 .with_prerequisite("rampage_frenzy", 0) \
	 .with_signature("Kills extend duration by 2s, +10% damage per kill, lifesteal during rampage")

static func _create_fury() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"rampage_fury",
		"Fury",
		"Rampage now also increases damage dealt.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		16.0
	).with_damage(0.0, 0.0) \
	 .with_duration(5.0) \
	 .with_effect("fury") \
	 .with_prerequisite("rampage", 1)

static func _create_unstoppable() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"rampage_unstoppable",
		"Unstoppable Force",
		"Become an unstoppable force of destruction.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		25.0
	).with_damage(0.0, 0.0) \
	 .with_duration(6.0) \
	 .with_movement() \
	 .with_effect("unstoppable_force") \
	 .with_prerequisite("rampage_fury", 1) \
	 .with_signature("Immune to CC, +100% damage, move through enemies dealing damage, can't be stopped")

static func get_all_ability_ids() -> Array[String]:
	return ["rampage", "rampage_frenzy", "rampage_bloodlust", "rampage_fury", "rampage_unstoppable"]

static func get_tree_name() -> String:
	return "Rampage"
