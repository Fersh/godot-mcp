extends Node
class_name ActiveAbilityDatabase

# All active abilities organized by category
# Initial implementation: 3-5 per rarity/class combination

static var _abilities: Dictionary = {}
static var _initialized: bool = false

static func get_all_abilities() -> Array[ActiveAbilityData]:
	_ensure_initialized()
	var result: Array[ActiveAbilityData] = []
	for ability in _abilities.values():
		result.append(ability)
	return result

static func get_ability(id: String) -> ActiveAbilityData:
	_ensure_initialized()
	return _abilities.get(id, null)

static func get_abilities_for_class(is_melee: bool) -> Array[ActiveAbilityData]:
	_ensure_initialized()
	var result: Array[ActiveAbilityData] = []
	var allowed_class = ActiveAbilityData.ClassType.MELEE if is_melee else ActiveAbilityData.ClassType.RANGED

	for ability in _abilities.values():
		if ability.class_type == ActiveAbilityData.ClassType.GLOBAL or ability.class_type == allowed_class:
			result.append(ability)

	return result

static func get_abilities_by_rarity(rarity: ActiveAbilityData.Rarity, is_melee: bool) -> Array[ActiveAbilityData]:
	var class_abilities = get_abilities_for_class(is_melee)
	var result: Array[ActiveAbilityData] = []

	for ability in class_abilities:
		if ability.rarity == rarity:
			result.append(ability)

	return result

static func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	_register_all_abilities()

static func _register_all_abilities() -> void:
	# ============================================
	# MELEE - COMMON
	# ============================================
	_register(_create_cleave())
	_register(_create_shield_bash())
	_register(_create_ground_slam())
	_register(_create_spinning_attack())
	_register(_create_dash_strike())

	# ============================================
	# MELEE - RARE
	# ============================================
	_register(_create_whirlwind())
	_register(_create_seismic_slam())
	_register(_create_savage_leap())
	_register(_create_blade_rush())
	_register(_create_battle_cry())

	# ============================================
	# MELEE - LEGENDARY
	# ============================================
	_register(_create_earthquake())
	_register(_create_bladestorm())
	_register(_create_omnislash())
	_register(_create_avatar_of_war())
	_register(_create_divine_shield())

	# ============================================
	# RANGED - COMMON
	# ============================================
	_register(_create_power_shot())
	_register(_create_explosive_arrow())
	_register(_create_multi_shot())
	_register(_create_quick_roll())
	_register(_create_throw_net())

	# ============================================
	# RANGED - RARE
	# ============================================
	_register(_create_rain_of_arrows())
	_register(_create_piercing_volley())
	_register(_create_cluster_bomb())
	_register(_create_fan_of_knives())
	_register(_create_sentry_turret())

	# ============================================
	# RANGED - LEGENDARY
	# ============================================
	_register(_create_arrow_storm())
	_register(_create_ballista_strike())
	_register(_create_sentry_network())
	_register(_create_rain_of_vengeance())
	_register(_create_explosive_decoy())

	# ============================================
	# GLOBAL - COMMON
	# ============================================
	_register(_create_fireball())
	_register(_create_frost_nova())
	_register(_create_healing_light())
	_register(_create_throwing_bomb())
	_register(_create_blinding_flash())

	# ============================================
	# GLOBAL - RARE
	# ============================================
	_register(_create_chain_lightning())
	_register(_create_meteor_strike())
	_register(_create_totem_of_frost())
	_register(_create_shadowstep())
	_register(_create_time_slow())

	# ============================================
	# GLOBAL - LEGENDARY
	# ============================================
	_register(_create_black_hole())
	_register(_create_time_stop())
	_register(_create_thunderstorm())
	_register(_create_summon_golem())
	_register(_create_army_of_the_dead())

static func _register(ability: ActiveAbilityData) -> void:
	_abilities[ability.id] = ability

# ============================================
# MELEE ABILITY CREATORS - COMMON
# ============================================

static func _create_cleave() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"cleave",
		"Cleave",
		"A broad swing hitting multiple enemies in front for moderate damage.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		8.0  # 8 second cooldown
	).with_damage(15.0, 1.2).with_aoe(80.0)

static func _create_shield_bash() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"shield_bash",
		"Bash",
		"Slam forward, dealing damage and stunning nearby enemies for 1 second.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		10.0
	).with_damage(10.0, 1.0).with_stun(1.0).with_range(60.0).with_knockback(150.0)

static func _create_ground_slam() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"ground_slam",
		"Ground Slam",
		"Smash the ground, sending a shockwave that damages and slows enemies.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		12.0
	).with_damage(12.0, 1.0).with_aoe(100.0).with_slow(0.5, 2.0)

static func _create_spinning_attack() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"spinning_attack",
		"Spinning Attack",
		"Perform a quick 360 spin, hitting all foes around you for light damage.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		6.0
	).with_damage(8.0, 0.8).with_aoe(70.0)

static func _create_dash_strike() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"dash_strike",
		"Dash Strike",
		"A short-range charge attack through enemies, dealing damage and knockback.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		8.0
	).with_damage(12.0, 1.0).with_range(120.0).with_knockback(100.0).with_movement()

# ============================================
# MELEE ABILITY CREATORS - RARE
# ============================================

static func _create_whirlwind() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"whirlwind",
		"Whirlwind",
		"Spin continuously for 3 seconds, damaging all surrounding enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		18.0
	).with_damage(5.0, 1.0).with_aoe(90.0).with_duration(3.0)

static func _create_seismic_slam() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"seismic_slam",
		"Seismic Slam",
		"Slam the ground with tremendous force, sending a stunning shockwave forward.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		15.0
	).with_damage(25.0, 1.5).with_range(150.0).with_stun(1.5).with_aoe(60.0)

static func _create_savage_leap() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"savage_leap",
		"Savage Leap",
		"Leap to target location, dealing AoE damage on landing.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.CLUSTER,
		14.0
	).with_damage(20.0, 1.3).with_aoe(80.0).with_range(200.0).with_movement()

static func _create_blade_rush() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"blade_rush",
		"Blade Rush",
		"Dash through enemies in a line, slashing each for damage.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		12.0
	).with_damage(18.0, 1.2).with_range(180.0).with_movement()

static func _create_battle_cry() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"battle_cry",
		"Battle Cry",
		"Release a warcry boosting damage +30% for 5s. Frightens weak enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		20.0
	).with_duration(5.0).with_aoe(150.0)

# ============================================
# MELEE ABILITY CREATORS - LEGENDARY
# ============================================

static func _create_earthquake() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"earthquake",
		"Earthquake",
		"Quake the entire screen! All enemies take heavy damage and are stunned.",
		ActiveAbilityData.Rarity.LEGENDARY,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		35.0
	).with_damage(40.0, 2.0).with_aoe(400.0).with_stun(2.0).with_duration(2.0)

static func _create_bladestorm() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"bladestorm",
		"Bladestorm",
		"Spin at high speed for 3 seconds, dragging enemies in a vortex of blades.",
		ActiveAbilityData.Rarity.LEGENDARY,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		30.0
	).with_damage(8.0, 1.5).with_aoe(100.0).with_duration(3.0).with_movement()

static func _create_omnislash() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"omnislash",
		"Omnislash",
		"Dash between nearby enemies, striking rapid hits distributed among them.",
		ActiveAbilityData.Rarity.LEGENDARY,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.CLUSTER,
		28.0
	).with_damage(50.0, 2.5).with_range(250.0).with_invulnerability(1.5)

static func _create_avatar_of_war() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"avatar_of_war",
		"Avatar of War",
		"Transform into a powerful form for 8s. +50% damage, -30% damage taken.",
		ActiveAbilityData.Rarity.LEGENDARY,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		40.0
	).with_duration(8.0)

static func _create_divine_shield() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"divine_shield",
		"Divine Shield",
		"Become invulnerable for 3 seconds and reflect damage back to attackers.",
		ActiveAbilityData.Rarity.LEGENDARY,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		45.0
	).with_invulnerability(3.0)

# ============================================
# RANGED ABILITY CREATORS - COMMON
# ============================================

static func _create_power_shot() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"power_shot",
		"Power Shot",
		"A carefully aimed shot dealing high single-target damage.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		8.0
	).with_damage(25.0, 1.5).with_projectiles(1, 600.0).with_range(500.0)

static func _create_explosive_arrow() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"explosive_arrow",
		"Explosive Arrow",
		"Fire an arrow that explodes on impact, dealing splash damage.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		10.0
	).with_damage(12.0, 1.0).with_aoe(60.0).with_projectiles(1, 450.0)

static func _create_multi_shot() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"multi_shot",
		"Multi-Shot",
		"Release a spread of arrows hitting multiple enemies in a cone.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		9.0
	).with_damage(8.0, 0.7).with_projectiles(5, 480.0).with_range(400.0)

static func _create_quick_roll() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"quick_roll",
		"Quick Roll",
		"A faster, shorter cooldown dodge-roll for repositioning.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		4.0
	).with_movement().with_invulnerability(0.3).with_range(100.0)

static func _create_throw_net() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"throw_net",
		"Throw Net",
		"Toss a net that ensnares enemies, rooting them in place for 2 seconds.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		10.0
	).with_slow(1.0, 2.0).with_range(300.0).with_aoe(80.0)

# ============================================
# RANGED ABILITY CREATORS - RARE
# ============================================

static func _create_rain_of_arrows() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"rain_of_arrows",
		"Rain of Arrows",
		"Mark an area where arrows rain down, dealing heavy damage.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.CLUSTER,
		16.0
	).with_damage(30.0, 1.5).with_aoe(120.0).with_duration(2.0).with_cast_time(0.5)

static func _create_piercing_volley() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"piercing_volley",
		"Piercing Volley",
		"Fire projectiles that pierce through all enemies in a line.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		14.0
	).with_damage(15.0, 1.2).with_projectiles(3, 550.0).with_range(500.0)

static func _create_cluster_bomb() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"cluster_bomb",
		"Cluster Bomb",
		"Throw a bomb that splits into smaller grenades on impact.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.CLUSTER,
		15.0
	).with_damage(10.0, 1.0).with_aoe(100.0).with_projectiles(5, 300.0)

static func _create_fan_of_knives() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"fan_of_knives",
		"Fan of Knives",
		"Unleash a spray of knives in all directions around you.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		12.0
	).with_damage(12.0, 1.0).with_projectiles(12, 400.0).with_aoe(150.0)

static func _create_sentry_turret() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"sentry_turret",
		"Sentry Turret",
		"Deploy a turret that auto-fires at enemies for 8 seconds.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		18.0
	).with_damage(5.0, 0.6).with_duration(8.0).with_aoe(180.0)

# ============================================
# RANGED ABILITY CREATORS - LEGENDARY
# ============================================

static func _create_arrow_storm() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"arrow_storm",
		"Arrow Storm",
		"Call upon a massive volley blanketing the screen in arrows.",
		ActiveAbilityData.Rarity.LEGENDARY,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		35.0
	).with_damage(5.0, 1.0).with_aoe(500.0).with_duration(3.0)

static func _create_ballista_strike() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"ballista_strike",
		"Ballista Strike",
		"Fire an immense bolt for huge single-target damage that pierces.",
		ActiveAbilityData.Rarity.LEGENDARY,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		25.0
	).with_damage(80.0, 3.0).with_projectiles(1, 800.0).with_range(600.0)

static func _create_sentry_network() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"sentry_network",
		"Sentry Network",
		"Deploy three turrets that auto-fire at enemies for 10 seconds.",
		ActiveAbilityData.Rarity.LEGENDARY,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		30.0
	).with_damage(8.0, 0.8).with_duration(10.0).with_aoe(200.0)

static func _create_rain_of_vengeance() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"rain_of_vengeance",
		"Rain of Vengeance",
		"Dark arrows rain down in waves across the screen, slowing and damaging all.",
		ActiveAbilityData.Rarity.LEGENDARY,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		38.0
	).with_damage(8.0, 1.2).with_aoe(600.0).with_duration(5.0).with_slow(0.4, 2.0)

static func _create_explosive_decoy() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"explosive_decoy",
		"Explosive Decoy",
		"Throw a decoy that taunts enemies, then explodes after 2 seconds.",
		ActiveAbilityData.Rarity.LEGENDARY,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.CLUSTER,
		28.0
	).with_damage(60.0, 2.0).with_aoe(120.0).with_duration(2.0)

# ============================================
# GLOBAL ABILITY CREATORS - COMMON
# ============================================

static func _create_fireball() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"fireball",
		"Fireball",
		"Cast a fireball that explodes on hit, dealing moderate fire damage.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		8.0
	).with_damage(18.0, 1.2).with_aoe(50.0).with_projectiles(1, 400.0)

static func _create_frost_nova() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"frost_nova",
		"Frost Nova",
		"Emit a burst of frost, freezing nearby enemies for 1.5 seconds.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		12.0
	).with_damage(5.0, 0.5).with_aoe(100.0).with_stun(1.5)

static func _create_healing_light() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"healing_light",
		"Healing Light",
		"Restore 10% of your max HP over 5 seconds.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		20.0
	).with_duration(5.0)

static func _create_throwing_bomb() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"throwing_bomb",
		"Throwing Bomb",
		"Lob a grenade that explodes after a short delay.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		10.0
	).with_damage(15.0, 1.0).with_aoe(70.0).with_projectiles(1, 350.0)

static func _create_blinding_flash() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"blinding_flash",
		"Blinding Flash",
		"Emanate a flash that blinds enemies, reducing their accuracy.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		15.0
	).with_aoe(120.0).with_slow(0.3, 3.0)

# ============================================
# GLOBAL ABILITY CREATORS - RARE
# ============================================

static func _create_chain_lightning() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"chain_lightning",
		"Chain Lightning",
		"Unleash lightning that jumps to several enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		14.0
	).with_damage(12.0, 1.0).with_range(200.0)  # Jump range

static func _create_meteor_strike() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"meteor_strike",
		"Meteor Strike",
		"Call down a meteor at a target location for massive damage.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		18.0
	).with_damage(35.0, 2.0).with_aoe(100.0).with_cast_time(1.0)

static func _create_totem_of_frost() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"totem_of_frost",
		"Totem of Frost",
		"Place a totem that slows and damages nearby enemies for 6 seconds.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		20.0
	).with_damage(15.0, 0.5).with_aoe(100.0).with_slow(0.5, 1.0).with_duration(6.0)

static func _create_shadowstep() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"shadowstep",
		"Shadowstep",
		"Instantly teleport to the nearest enemy with a damage boost.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		10.0
	).with_range(350.0).with_movement().with_invulnerability(0.1)

static func _create_time_slow() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"time_slow",
		"Time Slow",
		"Create a bubble where enemies are 50% slower for 4 seconds.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		22.0
	).with_aoe(200.0).with_slow(0.5, 4.0).with_duration(4.0)

# ============================================
# GLOBAL ABILITY CREATORS - LEGENDARY
# ============================================

static func _create_black_hole() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"black_hole",
		"Black Hole",
		"Open a void that pulls in enemies and explodes after 3 seconds.",
		ActiveAbilityData.Rarity.LEGENDARY,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		30.0
	).with_damage(50.0, 2.0).with_aoe(150.0).with_duration(3.0)

static func _create_time_stop() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"time_stop",
		"Time Stop",
		"Freeze time for enemies for 3 seconds while you move freely.",
		ActiveAbilityData.Rarity.LEGENDARY,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		35.0
	).with_aoe(600.0).with_stun(3.0)

static func _create_thunderstorm() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"thunderstorm",
		"Thunderstorm",
		"Channel the heavens - lightning strikes all enemies repeatedly.",
		ActiveAbilityData.Rarity.LEGENDARY,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		32.0
	).with_damage(15.0, 1.5).with_aoe(500.0).with_duration(3.0).with_stun(0.3)

static func _create_summon_golem() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"summon_golem",
		"Summon Golem",
		"Summon a giant golem that taunts enemies and deals damage for 15 seconds.",
		ActiveAbilityData.Rarity.LEGENDARY,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		45.0
	).with_damage(10.0, 1.0).with_duration(15.0).with_aoe(100.0)

static func _create_army_of_the_dead() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"army_of_the_dead",
		"Army of the Dead",
		"Summon 5 skeleton warriors that fight alongside you for 10 seconds.",
		ActiveAbilityData.Rarity.LEGENDARY,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		40.0
	).with_damage(40.0, 2.0).with_aoe(200.0).with_duration(10.0)
