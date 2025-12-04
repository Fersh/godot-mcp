extends RefCounted
class_name BashTree

# Bash (Shield Bash) Ability Tree
# Base: Single target stun with knockback
# Branch A (Shockwave): AoE stun, shorter duration -> Earthquake Slam (massive AoE, enemies airborne)
# Branch B (Lockdown): Long single-target stun -> Petrifying Strike (stun + damage amp)

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	# Branch A: Shockwave path (AoE control)
	tree.add_branch(
		_create_shockwave_bash(),
		_create_earthquake_slam()
	)

	# Branch B: Lockdown path (single target lockdown)
	tree.add_branch(
		_create_lockdown_bash(),
		_create_petrifying_strike()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"shield_bash",
		"Shield Bash",
		"Bash an enemy with your shield, stunning them briefly and knocking them back.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		6.0
	).with_damage(40.0, 1.2) \
	 .with_stun(1.0) \
	 .with_knockback(150.0) \
	 .with_effect("shield_bash")

static func _create_shockwave_bash() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"bash_shockwave",
		"Shockwave Bash",
		"Your bash creates a shockwave that stuns all nearby enemies for a short duration.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		7.0
	).with_damage(45.0, 1.3) \
	 .with_aoe(150.0) \
	 .with_stun(0.8) \
	 .with_knockback(100.0) \
	 .with_effect("shockwave_bash") \
	 .with_prerequisite("shield_bash", 0)

static func _create_earthquake_slam() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"bash_earthquake",
		"Earthquake Slam",
		"Slam the ground with devastating force. Enemies are launched airborne and stunned on landing.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		10.0
	).with_damage(70.0, 2.0) \
	 .with_aoe(250.0) \
	 .with_stun(2.0) \
	 .with_knockback(300.0) \
	 .with_effect("earthquake") \
	 .with_prerequisite("bash_shockwave", 0) \
	 .with_signature("Launches enemies airborne with massive AoE stun")

static func _create_lockdown_bash() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"bash_lockdown",
		"Lockdown Bash",
		"A focused bash that stuns a single enemy for an extended duration.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		6.0
	).with_damage(50.0, 1.5) \
	 .with_stun(3.0) \
	 .with_knockback(50.0) \
	 .with_effect("lockdown_bash") \
	 .with_prerequisite("shield_bash", 1)

static func _create_petrifying_strike() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"bash_petrify",
		"Petrifying Strike",
		"Turn your enemy to stone. Petrified enemies take double damage and can be chain-stunned.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		8.0
	).with_damage(60.0, 1.8) \
	 .with_stun(4.0) \
	 .with_effect("petrify") \
	 .with_prerequisite("bash_lockdown", 1) \
	 .with_signature("Petrified enemies take 2x damage")

static func get_all_ability_ids() -> Array[String]:
	return ["shield_bash", "bash_shockwave", "bash_earthquake", "bash_lockdown", "bash_petrify"]

static func get_tree_name() -> String:
	return "Shield Bash"
