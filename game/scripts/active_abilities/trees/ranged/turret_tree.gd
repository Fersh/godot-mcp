extends RefCounted
class_name TurretTree

# Sentry Turret Ability Tree (Ranged)
# Base: Deploy automated turret
# Branch A (Rapid): Fast-firing turret -> Gatling Network (multiple rapid turrets)
# Branch B (Heavy): Slow powerful shots -> Artillery Cannon (explosive shots)

const BASE_NAME = "Sentry Turret"
const BASE_ID = "sentry_turret"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_rapid_sentry(),
		_create_gatling_network()
	)

	tree.add_branch(
		_create_heavy_sentry(),
		_create_artillery_cannon()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"sentry_turret",
		"Sentry Turret",
		"Deploy an automated turret that attacks nearby enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		15.0
	).with_damage(20.0, 0.8) \
	 .with_range(250.0) \
	 .with_duration(10.0) \
	 .with_effect("sentry_turret")

static func _create_rapid_sentry() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"turret_rapid",
		"Rapid Sentry",
		"Deploy a fast-firing turret with increased attack speed.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		12.0
	).with_damage(15.0, 0.7) \
	 .with_range(250.0) \
	 .with_duration(12.0) \
	 .with_effect("rapid_sentry") \
	 .with_prerequisite("sentry_turret", 0) \
	 .with_prefix("Rapid", BASE_NAME, BASE_ID)

static func _create_gatling_network() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"turret_gatling",
		"Gatling Network",
		"Deploy 3 rapid-fire turrets that focus fire on the same target.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		25.0
	).with_damage(12.0, 0.6) \
	 .with_range(300.0) \
	 .with_duration(15.0) \
	 .with_projectiles(3, 0) \
	 .with_effect("gatling_network") \
	 .with_prerequisite("turret_rapid", 0) \
	 .with_signature("3 turrets that sync fire, each shot has 10% slow") \
	 .with_suffix("of the Swarm", BASE_NAME, "Rapid", BASE_ID)

static func _create_heavy_sentry() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"turret_heavy",
		"Heavy Sentry",
		"Deploy a powerful turret with slower but harder-hitting shots.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		18.0
	).with_damage(50.0, 1.2) \
	 .with_range(350.0) \
	 .with_duration(12.0) \
	 .with_effect("heavy_sentry") \
	 .with_prerequisite("sentry_turret", 1) \
	 .with_prefix("Heavy", BASE_NAME, BASE_ID)

static func _create_artillery_cannon() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"turret_artillery",
		"Artillery Cannon",
		"Deploy a massive cannon that fires explosive shells.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		30.0
	).with_damage(100.0, 2.0) \
	 .with_range(500.0) \
	 .with_aoe(120.0) \
	 .with_duration(15.0) \
	 .with_stun(0.5) \
	 .with_effect("artillery_cannon") \
	 .with_prerequisite("turret_heavy", 1) \
	 .with_signature("Explosive shells, each hit stuns 0.5s, 500 range") \
	 .with_suffix("of Artillery", BASE_NAME, "Heavy", BASE_ID)

static func get_all_ability_ids() -> Array[String]:
	return ["sentry_turret", "turret_rapid", "turret_gatling", "turret_heavy", "turret_artillery"]

static func get_tree_name() -> String:
	return "Sentry Turret"
