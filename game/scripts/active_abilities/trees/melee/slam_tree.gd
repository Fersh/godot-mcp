extends RefCounted
class_name SlamTree

# Ground Slam Ability Tree (Melee)
# Base: Slam ground for AoE damage
# Branch A (Seismic): Delayed aftershock waves -> Earthquake (screen-wide)
# Branch B (Crater): Leave burning ground -> Meteor Slam (massive single crater)

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_seismic_slam(),
		_create_earthquake()
	)

	tree.add_branch(
		_create_crater_slam(),
		_create_meteor_slam()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"ground_slam",
		"Ground Slam",
		"Slam the ground, damaging all nearby enemies.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		6.0
	).with_damage(40.0, 1.2) \
	 .with_aoe(100.0) \
	 .with_stun(0.3) \
	 .with_effect("ground_slam")

static func _create_seismic_slam() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"slam_seismic",
		"Seismic Slam",
		"Slam creates aftershock waves that travel outward.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		7.0
	).with_damage(50.0, 1.4) \
	 .with_aoe(150.0) \
	 .with_stun(0.5) \
	 .with_duration(1.5) \
	 .with_effect("seismic_wave") \
	 .with_prerequisite("ground_slam", 0)

static func _create_earthquake() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"slam_earthquake",
		"Earthquake",
		"Devastate the entire battlefield with seismic fury.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		18.0
	).with_damage(80.0, 2.0) \
	 .with_aoe(400.0) \
	 .with_stun(1.5) \
	 .with_duration(3.0) \
	 .with_effect("earthquake") \
	 .with_prerequisite("slam_seismic", 0) \
	 .with_signature("Screen-wide damage over 3 seconds, stuns all enemies")

static func _create_crater_slam() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"slam_crater",
		"Crater Slam",
		"Leave burning ground where you slam.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		7.0
	).with_damage(55.0, 1.3) \
	 .with_aoe(120.0) \
	 .with_duration(4.0) \
	 .with_effect("burning_crater") \
	 .with_prerequisite("ground_slam", 1)

static func _create_meteor_slam() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"slam_meteor",
		"Meteor Slam",
		"Leap into the air and crash down like a meteor.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.CLUSTER,
		15.0
	).with_damage(120.0, 2.5) \
	 .with_aoe(180.0) \
	 .with_stun(2.0) \
	 .with_movement() \
	 .with_invulnerability(0.8) \
	 .with_effect("meteor_slam") \
	 .with_prerequisite("slam_crater", 1) \
	 .with_signature("Leap to target, invulnerable during, massive impact crater")

static func get_all_ability_ids() -> Array[String]:
	return ["ground_slam", "slam_seismic", "slam_earthquake", "slam_crater", "slam_meteor"]

static func get_tree_name() -> String:
	return "Ground Slam"
