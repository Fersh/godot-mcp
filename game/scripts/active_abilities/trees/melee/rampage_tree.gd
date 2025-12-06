extends RefCounted
class_name RampageTree

# Rampage Ability Tree (Melee)
# Base: Enter rampage mode for attack speed
# Branch A (Frenzy): Stack frenzy -> Bloodlust (faster with each kill)
# Branch B (Fury): Damage increase -> Unstoppable (immune + massive damage)
# Branch C (Energy): Monster Energy -> Gigantamax (size/power transformation)
# Branch D (Berserk): I See Red base -> I See Red (full berserk mode)

const BASE_NAME = "Rampage"
const BASE_ID = "rampage"

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

	# Branch C: Energy/Transform path
	tree.add_branch(
		_create_monster_energy(),
		_create_gigantamax()
	)

	# Branch D: Berserk path
	tree.add_branch(
		_create_seeing_red(),
		_create_i_see_red()
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
	 .with_effect("rampage_pixel")

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

static func _create_monster_energy() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"rampage_energy",
		"Monster Energy",
		"Enter an energized state with +150% attack speed.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		18.0
	).with_damage(0.0, 0.0) \
	 .with_duration(7.0) \
	 .with_effect("monster_energy") \
	 .with_prerequisite("rampage", 2)

static func _create_gigantamax() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"rampage_giant",
		"Gigantamax",
		"Grow HUGE! +300% damage, +75% range, but -90% movement speed.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		40.0
	).with_damage(0.0, 0.0) \
	 .with_duration(7.0) \
	 .with_effect("gigantamax") \
	 .with_prerequisite("rampage_energy", 2) \
	 .with_signature("Massive size, +300% damage, +75% attack range, but rooted/slowed")

static func _create_seeing_red() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"rampage_red",
		"Seeing Red",
		"Enter a rage state with +75% damage and +50% speed, but take more damage.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		18.0
	).with_damage(0.0, 0.0) \
	 .with_duration(8.0) \
	 .with_effect("seeing_red") \
	 .with_prerequisite("rampage", 3)

static func _create_i_see_red() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"rampage_berserk",
		"I See Red",
		"Go full berserk! +150% damage, +75% speed, but take +50% more damage.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		35.0
	).with_damage(0.0, 0.0) \
	 .with_duration(10.0) \
	 .with_effect("i_see_red") \
	 .with_prerequisite("rampage_red", 3) \
	 .with_signature("+150% damage, +75% move speed, +50% incoming damage, unstoppable rage")

static func get_all_ability_ids() -> Array[String]:
	return ["rampage", "rampage_frenzy", "rampage_bloodlust", "rampage_fury", "rampage_unstoppable", "rampage_energy", "rampage_giant", "rampage_red", "rampage_berserk"]

static func get_tree_name() -> String:
	return "Rampage"
