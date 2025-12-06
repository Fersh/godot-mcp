extends RefCounted
class_name BarrageTree

# Barrage Ability Tree (Ranged)
# Base: Rapid fire barrage
# Branch A (Focused): Concentrated fire -> Bullet Storm (single target devastation)
# Branch B (Spread): Wide spread -> Lead Rain (area suppression)

const BASE_NAME = "Barrage"
const BASE_ID = "barrage"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	tree.add_branch(
		_create_focused(),
		_create_bullet_storm()
	)

	tree.add_branch(
		_create_spread(),
		_create_lead_rain()
	)

	return tree

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"barrage",
		"Barrage",
		"Fire a rapid barrage of projectiles.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		8.0
	).with_damage(10.0, 0.4) \
	 .with_range(350.0) \
	 .with_duration(1.5) \
	 .with_effect("barrage") \
	 .with_icon("res://assets/sprites/icons/archerskills/PNG/Icon46_Barrage.png")

static func _create_focused() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"barrage_focused",
		"Focused Fire",
		"All projectiles target a single enemy for concentrated damage.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		9.0
	).with_damage(15.0, 0.5) \
	 .with_range(400.0) \
	 .with_duration(2.0) \
	 .with_effect("focused_fire") \
	 .with_prerequisite("barrage", 0)

static func _create_bullet_storm() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"barrage_bullet_storm",
		"Bullet Storm",
		"Unleash an overwhelming storm of projectiles at your target.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		15.0
	).with_damage(12.0, 0.4) \
	 .with_range(450.0) \
	 .with_duration(3.0) \
	 .with_effect("bullet_storm") \
	 .with_prerequisite("barrage_focused", 0) \
	 .with_signature("50+ projectiles over duration, armor shred stacks, execute low HP enemies")

static func _create_spread() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"barrage_spread",
		"Spread Fire",
		"Projectiles spread out to hit multiple enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.CLUSTER,
		9.0
	).with_damage(8.0, 0.35) \
	 .with_range(350.0) \
	 .with_aoe(200.0) \
	 .with_duration(1.5) \
	 .with_effect("spread_fire") \
	 .with_prerequisite("barrage", 1)

static func _create_lead_rain() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"barrage_lead_rain",
		"Lead Rain",
		"Create a zone of suppressive fire that damages all enemies.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.CLUSTER,
		18.0
	).with_damage(8.0, 0.3) \
	 .with_range(400.0) \
	 .with_aoe(300.0) \
	 .with_duration(4.0) \
	 .with_slow(0.5, 4.0) \
	 .with_effect("lead_rain") \
	 .with_prerequisite("barrage_spread", 1) \
	 .with_signature("Suppression zone, enemies slowed inside, continuous damage ticks")

static func get_all_ability_ids() -> Array[String]:
	return ["barrage", "barrage_focused", "barrage_bullet_storm", "barrage_spread", "barrage_lead_rain"]

static func get_tree_name() -> String:
	return "Barrage"
