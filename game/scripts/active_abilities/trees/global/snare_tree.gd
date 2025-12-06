extends RefCounted
class_name SnareTree

# Snare/Trap Ability Tree (Global - available to all classes)
# Base: Glue Bomb - slow zone
# Branch A (Damage): Pressure Mine -> Minefield (multiple mines)
# Branch B (Control): Tar Pit -> Web of Sloth (massive slow zone)

const BASE_NAME = "Glue Bomb"
const BASE_ID = "glue_bomb"

static func create() -> AbilityTreeNode:
	var tree = AbilityTreeNode.new(_create_base())

	# Branch A: Explosive trap path
	tree.add_branch(
		_create_pressure_mine(),
		_create_minefield()
	)

	# Branch B: Slow zone path
	tree.add_branch(
		_create_tar_pit(),
		_create_web_of_sloth()
	)

	return tree

# ============================================
# BASE ABILITY (TIER 1)
# ============================================

static func _create_base() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"glue_bomb",
		"Glue Bomb",
		"Throw a sticky bomb creating a tar zone that slows enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		12.0
	).with_damage(0.0, 0.0) \
	 .with_aoe(160.0) \
	 .with_slow(0.85, 6.0) \
	 .with_duration(6.0) \
	 .with_effect("glue_bomb")

# ============================================
# TIER 2 - BRANCH A: EXPLOSIVE TRAP PATH
# ============================================

static func _create_pressure_mine() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"snare_mine",
		"Explosive Glue Bomb",
		"Plant an invisible mine that explodes when 3+ enemies are nearby.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		18.0
	).with_damage(100.0, 3.0) \
	 .with_aoe(220.0) \
	 .with_effect("pressure_mine") \
	 .with_prerequisite("glue_bomb", 0)

# ============================================
# TIER 3 - BRANCH A: MINEFIELD (SIGNATURE)
# ============================================

static func _create_minefield() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"snare_minefield",
		"Minefield",
		"Deploy 5 pressure mines in an area. Massive chain explosion potential.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		30.0
	).with_damage(80.0, 2.5) \
	 .with_aoe(180.0) \
	 .with_projectiles(5, 0) \
	 .with_effect("minefield") \
	 .with_prerequisite("snare_mine", 0) \
	 .with_signature("5 mines, chain reaction when one explodes, massive AoE damage")

# ============================================
# TIER 2 - BRANCH B: SLOW ZONE PATH
# ============================================

static func _create_tar_pit() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"snare_tar",
		"Sticky Glue Bomb",
		"Create a larger tar zone that roots enemies briefly on entry.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		14.0
	).with_damage(15.0, 1.0) \
	 .with_aoe(200.0) \
	 .with_slow(0.9, 8.0) \
	 .with_stun(1.0) \
	 .with_duration(8.0) \
	 .with_effect("tar_pit") \
	 .with_prerequisite("glue_bomb", 1)

# ============================================
# TIER 3 - BRANCH B: WEB OF SLOTH (SIGNATURE)
# ============================================

static func _create_web_of_sloth() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"snare_web",
		"Web of Sloth",
		"Create a massive web zone that spreads and roots enemies.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		25.0
	).with_damage(25.0, 1.5) \
	 .with_aoe(350.0) \
	 .with_slow(0.95, 10.0) \
	 .with_stun(2.0) \
	 .with_duration(10.0) \
	 .with_effect("web_of_sloth") \
	 .with_prerequisite("snare_tar", 1) \
	 .with_signature("Massive 350 radius, 95% slow, periodic root, 10s duration")

# ============================================
# UTILITY FUNCTIONS
# ============================================

static func get_all_ability_ids() -> Array[String]:
	return ["glue_bomb", "snare_mine", "snare_minefield", "snare_tar", "snare_web"]

static func get_tree_name() -> String:
	return "Snare"
