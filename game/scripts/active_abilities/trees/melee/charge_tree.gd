extends RefCounted
class_name ChargeTree

# Charge Ability Tree
# Base: Rush forward, damage first enemy hit
# Branch A (Trampling): Damage ALL enemies in path -> Stampede (fire trail, 3x distance)
# Branch B (Shield): Immune during charge -> Unstoppable Force (stun all, destroy projectiles)

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_trampling_charge(),
		_create_stampede()
	)

	tree.add_branch(
		_create_shield_charge(),
		_create_unstoppable_force()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"charge",
		"Charge",
		"Rush forward and slam into the first enemy, dealing damage.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		8.0
	).with_damage(60.0, 1.5) \
	 .with_range(200.0) \
	 .with_movement() \
	 .with_effect("charge")

static func _create_trampling_charge() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"charge_trample",
		"Trampling Charge",
		"Charge through enemies, damaging everyone in your path.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		8.0
	).with_damage(50.0, 1.3) \
	 .with_range(250.0) \
	 .with_movement() \
	 .with_effect("trample") \
	 .with_prerequisite("charge", 0)

static func _create_stampede() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"charge_stampede",
		"Stampede",
		"An unstoppable charge that covers triple distance and leaves a trail of fire.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		10.0
	).with_damage(70.0, 1.8) \
	 .with_range(600.0) \
	 .with_movement() \
	 .with_effect("stampede") \
	 .with_prerequisite("charge_trample", 0) \
	 .with_signature("3x charge distance with fire trail")

static func _create_shield_charge() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"charge_shield",
		"Shield Charge",
		"Raise your shield while charging, becoming immune to damage.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		9.0
	).with_damage(55.0, 1.4) \
	 .with_range(200.0) \
	 .with_movement() \
	 .with_invulnerability(0.5) \
	 .with_knockback(200.0) \
	 .with_effect("shield_charge") \
	 .with_prerequisite("charge", 1)

static func _create_unstoppable_force() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"charge_unstoppable",
		"Unstoppable Force",
		"Nothing can stop you. Stun all enemies in path and destroy incoming projectiles.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		12.0
	).with_damage(80.0, 2.0) \
	 .with_range(300.0) \
	 .with_movement() \
	 .with_invulnerability(1.0) \
	 .with_stun(2.0) \
	 .with_knockback(300.0) \
	 .with_effect("unstoppable") \
	 .with_prerequisite("charge_shield", 1) \
	 .with_signature("Destroys projectiles and stuns all in path")

static func get_all_ability_ids() -> Array[String]:
	return ["charge", "charge_trample", "charge_stampede", "charge_shield", "charge_unstoppable"]

static func get_tree_name() -> String:
	return "Charge"
