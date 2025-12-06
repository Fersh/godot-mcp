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

static func get_ability_by_id(id: String) -> ActiveAbilityData:
	"""Alias for get_ability for consistent API naming."""
	return get_ability(id)

static func get_abilities_for_class(is_melee: bool) -> Array[ActiveAbilityData]:
	_ensure_initialized()
	var result: Array[ActiveAbilityData] = []
	var allowed_class = ActiveAbilityData.ClassType.MELEE if is_melee else ActiveAbilityData.ClassType.RANGED

	# Get UnlocksManager singleton
	var unlocks_manager = Engine.get_singleton("UnlocksManager") if Engine.has_singleton("UnlocksManager") else null
	if unlocks_manager == null:
		# Try to get from scene tree (autoload)
		var tree = Engine.get_main_loop()
		if tree and tree.root:
			unlocks_manager = tree.root.get_node_or_null("UnlocksManager")

	for ability in _abilities.values():
		# Skip locked abilities
		if unlocks_manager and not unlocks_manager.is_active_unlocked(ability.id):
			continue

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
	# MELEE - COMMON (from trees)
	# ============================================
	_register(_create_cleave())
	# _register(_create_shield_bash())  # Commented out - non-tree ability, consolidating into tree system
	_register(_create_ground_slam())
	_register(_create_dash_strike())
	# Additional melee trees - load base abilities from tree registry
	_register_from_tree("whirlwind")      # Whirlwind (Spin Tree)
	# _register_from_tree("impale")       # Commented out - consolidating melee roster
	# _register_from_tree("uppercut")     # Commented out - consolidating melee roster
	_register_from_tree("combo_strike")   # Combo Strike Tree
	_register_from_tree("parry")          # Parry Tree
	_register_from_tree("block")          # Block Tree
	_register_from_tree("throw_weapon")   # Throw Weapon Tree
	_register_from_tree("roar")           # Terrifying Roar Tree
	_register_from_tree("stomp")          # Stomp Tree
	_register_from_tree("charge")         # Charge Tree
	# _register_from_tree("taunt")        # Commented out - redundant with defensive Battle Cry
	_register_from_tree("battle_cry")     # Battle Cry Tree (now defensive)

	# ============================================
	# MELEE - RARE (from trees)
	# ============================================
	_register(_create_savage_leap())
	_register_from_tree("execute")        # Execute Tree
	_register_from_tree("rampage")        # Rampage Tree

	# ============================================
	# RANGED - COMMON
	# ============================================
	_register(_create_power_shot())
	_register(_create_explosive_arrow())
	_register(_create_multi_shot())
	_register(_create_quick_roll())
	# Throw Net merged into Frost Nova

	# ============================================
	# RANGED - RARE
	# ============================================
	_register(_create_rain_of_arrows())
	_register(_create_piercing_volley())
	# _register(_create_cluster_bomb())  # Removed - now Explosive Arrow Tree T2
	# _register(_create_fan_of_knives())  # Removed - now Multi Shot Tree T2
	_register(_create_sentry_turret())

	# ============================================
	# RANGED - LEGENDARY
	# ============================================
	# _register(_create_arrow_storm())  # Removed - now Rain of Arrows Tree T2
	# _register(_create_ballista_strike())  # Removed - now Power Shot Tree T3 (power_shot_ballista)
	# _register(_create_sentry_network())  # Removed - now Turret Tree T3 (Gatling Network)
	# _register(_create_rain_of_vengeance())  # Removed - now Rain of Arrows Tree T3 (Arrow Apocalypse)
	# _register(_create_explosive_decoy())  # Removed - now Decoy Tree T2

	# ============================================
	# GLOBAL - COMMON
	# ============================================
	# _register(_create_fireball())  # Disabled - Fireball tree temporarily removed
	_register(_create_healing_light())
	_register(_create_throwing_bomb())
	# Blinding Flash merged into Pocket Sand

	# ============================================
	# GLOBAL - RARE
	# ============================================
	_register(_create_frost_nova())  # Upgraded - merged with Throw Net
	_register(_create_chain_lightning())
	# _register(_create_meteor_strike())  # Removed - now Fireball Tree T2 (fireball_meteor)
	# _register(_create_totem_of_frost())  # Removed - now Frost Nova Tree T2 (frost_nova_totem)
	# _register(_create_shadowstep())  # Removed - now Teleport Tree T2 B (teleport_shadow)
	_register(_create_time_slow())

	# ============================================
	# GLOBAL - LEGENDARY
	# ============================================
	# _register(_create_black_hole())  # Removed - now Gravity Tree T3 A (gravity_singularity)
	# _register(_create_time_stop())  # Removed - now Time Tree T2 A (time_stop)
	# _register(_create_thunderstorm())  # Removed - now Lightning Tree T2 A (chain_lightning_storm)
	# _register(_create_summon_golem())  # Removed - now Summon Tree T2 A (summon_golem)
	# _register(_create_army_of_the_dead())  # Removed - now Summon Tree T3 B (summon_army)

	# ============================================
	# NEW ABILITIES - ZONE & WALL
	# ============================================
	# _register(_create_flame_wall())  # Removed - now Wall Tree BASE
	# _register(_create_ice_barricade())  # Removed - now Wall Tree T2 (wall_ice)
	# _register(_create_floor_is_lava())  # Removed - now Wall Tree T3 (wall_lava)
	_register_from_tree("flame_wall")  # Wall Tree

	# ============================================
	# NEW ABILITIES - TRAPS
	# ============================================
	# _register(_create_bear_trap())  # Removed - now Trap Tree T2 (ranged)
	# _register(_create_glue_bomb())  # Removed - now Snare Tree BASE
	# _register(_create_pressure_mine())  # Removed - now Snare Tree T2 (snare_mine)
	_register_from_tree("glue_bomb")  # Snare Tree

	# ============================================
	# NEW ABILITIES - STEALTH & DECEPTION
	# ============================================
	# _register(_create_smoke_bomb())  # Removed - now Smoke Tree BASE (ranged)
	# _register(_create_now_you_see_me())  # Disabled - needs rework
	# _register(_create_pocket_sand())  # Commented out - redundant with frost_nova (AoE CC)

	# ============================================
	# NEW ABILITIES - SHOUTS
	# ============================================
	# _register(_create_terrifying_shout())  # Removed - now Roar Tree base (Terrifying Roar)
	# _register(_create_demoralizing_shout())  # Removed - now Roar Tree T2 (Intimidating Roar)

	# ============================================
	# NEW ABILITIES - CHAOS & UTILITY
	# ============================================
	# _register(_create_mirror_clone())  # Commented out for now
	# _register(_create_uno_reverse())  # Removed - now Shield Tree T3 (barrier_reverse)
	# _register(_create_orbital_strike())  # Removed - now Rain of Arrows Tree T3 Branch B (ranged)
	# _register(_create_summon_party())  # Commented out - too niche
	# _register(_create_panic_button())  # Removed - now Shield Tree T2 (barrier_panic)
	# _register(_create_pocket_healer())  # Removed - now Summon Tree T3 (summon_healer)
	# _register(_create_safe_space())  # Commented out - redundant with barrier_bubble
	# _register(_create_double_or_nothing())  # Commented out for now

	# ============================================
	# NEW ABILITIES - SUMMONS & TRANSFORMS
	# ============================================
	# _register(_create_release_the_hounds())  # Removed - now Summon Tree T3 (summon_hounds)
	# _register(_create_gigantamax())  # Removed - now Rampage Tree T3 (rampage_giant)
	# _register(_create_monster_energy())  # Removed - now Rampage Tree T2 (rampage_energy)
	# _register(_create_i_see_red())  # Removed - now Rampage Tree T3 (rampage_berserk)

	# ============================================
	# NEW ABILITIES - CROWD CONTROL
	# ============================================
	# vortex removed - now part of spin_tree as spin_vortex (T2)
	# _register(_create_repulsive())  # Removed - now Gravity Tree T2 B (gravity_repulse)
	# _register(_create_dj_drop())  # Commented out - redundant with frost_nova (AoE stun)

static func _register(ability: ActiveAbilityData) -> void:
	_abilities[ability.id] = ability

static func _register_from_tree(base_id: String) -> void:
	"""Register a base ability by loading it from the AbilityTreeRegistry."""
	var tree = AbilityTreeRegistry.get_tree(base_id)
	if tree and tree.base_ability:
		_abilities[tree.base_ability.id] = tree.base_ability
	else:
		push_warning("ActiveAbilityDatabase: Could not find tree for base_id: " + base_id)

# ============================================
# MELEE ABILITY CREATORS - COMMON
# ============================================

static func _create_cleave() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"cleave",
		"Cleave",
		"A broad swing hitting multiple enemies in front for heavy damage.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		8.0
	).with_damage(55.0, 1.5).with_aoe(200.0).with_icon("res://assets/sprites/icons/barbarianskills/PNG/Icon5_Cleave.png")

static func _create_shield_bash() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"shield_bash",
		"Bash",
		"Slam forward, dealing damage and stunning nearby enemies for 1.5 seconds.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		10.0
	).with_damage(35.0, 1.2).with_stun(1.5).with_range(90.0).with_knockback(200.0).with_icon("res://assets/icons/abilities/shield_bash.png")

static func _create_ground_slam() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"ground_slam",
		"Ground Slam",
		"Smash the ground, sending a shockwave that damages and slows enemies.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		12.0
	).with_damage(45.0, 1.2).with_aoe(150.0).with_slow(0.6, 3.0).with_icon("res://assets/icons/abilities/ground_slam.png")

static func _create_spinning_attack() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"spinning_attack",
		"Spinning Attack",
		"Perform a quick 360 spin, dealing damage to all nearby enemies.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		6.0
	).with_damage(40.0, 1.2).with_aoe(150.0).with_icon("res://assets/icons/abilities/spinning_attack.png")

static func _create_dash_strike() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"dash_strike",
		"Dash Strike",
		"A charge attack through enemies, dealing damage and knockback.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		8.0
	).with_damage(40.0, 1.2).with_range(280.0).with_knockback(180.0).with_movement().with_icon("res://assets/sprites/icons/swordsmanskills/PNG/Icon40_DashStrike.png")

# ============================================
# MELEE ABILITY CREATORS - RARE
# ============================================

static func _create_whirlwind() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"whirlwind",
		"Whirlwind",
		"Spin continuously for 4 seconds, damaging all surrounding enemies.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		18.0
	).with_damage(14.0, 1.5).with_aoe(160.0).with_duration(4.0).with_icon("res://assets/sprites/icons/barbarianskills/PNG/Icon20_Whirlwind.png")

static func _create_seismic_slam() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"seismic_slam",
		"Seismic Slam",
		"Slam the ground with tremendous force, sending a stunning shockwave forward.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		15.0
	).with_damage(45.0, 1.8).with_range(220.0).with_stun(2.0).with_aoe(100.0).with_icon("res://assets/icons/abilities/seismic_slam.png")

static func _create_savage_leap() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"savage_leap",
		"Savage Leap",
		"Leap to target location, dealing AoE damage on landing.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.CLUSTER,
		14.0
	).with_damage(35.0, 1.5).with_aoe(130.0).with_range(280.0).with_movement().with_icon("res://assets/icons/abilities/savage_leap.png")

static func _create_blade_rush() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"blade_rush",
		"Blade Rush",
		"Dash through enemies in a line, slashing each for damage.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.DIRECTION,
		12.0
	).with_damage(32.0, 1.5).with_range(280.0).with_movement().with_icon("res://assets/sprites/icons/barbarianskills/PNG/Icon22_BladeRush.png")

static func _create_battle_cry() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"battle_cry",
		"Battle Cry",
		"Release a warcry boosting damage +50% for 6s.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		20.0
	).with_duration(6.0).with_aoe(200.0).with_icon("res://assets/sprites/icons/barbarianskills/PNG/Icon18_BattleCry.png")

# ============================================
# MELEE ABILITY CREATORS - LEGENDARY
# ============================================

static func _create_earthquake() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"earthquake",
		"Earthquake",
		"Shake the ground violently, damaging and stunning nearby enemies.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		38.0
	).with_damage(50.0, 2.0).with_aoe(350.0).with_stun(1.8).with_duration(2.0).with_icon("res://assets/icons/abilities/earthquake.png")

# _create_bladestorm removed - now part of spin_tree as spin_bladestorm (T3)

static func _create_omnislash() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"omnislash",
		"Omnislash",
		"Dash between nearby enemies, striking rapid hits distributed among them.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.CLUSTER,
		28.0
	).with_damage(80.0, 3.0).with_range(350.0).with_invulnerability(2.0).with_icon("res://assets/sprites/icons/swordsmanskills/PNG/Icon20_Omnislash.png")

static func _create_avatar_of_war() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"avatar_of_war",
		"Avatar of War",
		"Transform into a powerful form for 10s. +75% damage, -40% damage taken.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		40.0
	).with_duration(10.0).with_icon("res://assets/sprites/icons/demonskills/PNG/Group20_AvatarOfWar.png")

static func _create_divine_shield() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"divine_shield",
		"Divine Shield",
		"Become invulnerable for 4 seconds and reflect damage back to attackers.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.SELF,
		45.0
	).with_invulnerability(4.0).with_icon("res://assets/sprites/icons/swordsmanskills/PNG/Icon10_DivineShield.png")

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
	).with_damage(50.0, 1.5).with_projectiles(1, 600.0).with_range(500.0).with_icon("res://assets/icons/abilities/power_shot.png")  # Buffed 2x

static func _create_explosive_arrow() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"explosive_arrow",
		"Explosive Arrow",
		"Fire an arrow that explodes on impact, dealing splash damage.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		10.0
	).with_damage(40.0, 1.2).with_aoe(60.0).with_projectiles(1, 450.0).with_icon("res://assets/icons/abilities/explosive_arrow.png")  # Buffed 2x

static func _create_multi_shot() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"multi_shot",
		"Multi-Shot",
		"Release a spread of arrows dealing damage to multiple enemies.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		9.0
	).with_damage(16.0, 0.7).with_projectiles(5, 480.0).with_range(400.0).with_icon("res://assets/icons/abilities/multi_shot.png")  # Buffed 2x

static func _create_quick_roll() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"quick_roll",
		"Quick Roll",
		"A quick dodge-roll with brief invulnerability.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		3.0
	).with_movement().with_invulnerability(0.5).with_range(150.0).with_icon("res://assets/icons/abilities/quick_roll.png")

static func _create_throw_net() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"throw_net",
		"Throw Net",
		"Toss a net that ensnares enemies, rooting them in place for 2 seconds.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		10.0
	).with_slow(1.0, 2.0).with_range(300.0).with_aoe(80.0).with_icon("res://assets/icons/abilities/throw_net.png")

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
	).with_damage(50.0, 1.8).with_aoe(180.0).with_duration(3.0).with_cast_time(0.5).with_icon("res://assets/icons/abilities/rain_of_arrows.png")

static func _create_piercing_volley() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"piercing_volley",
		"Piercing Volley",
		"Fire piercing projectiles that damage all enemies in a line.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.DIRECTION,
		14.0
	).with_damage(28.0, 1.5).with_projectiles(5, 600.0).with_range(600.0).with_icon("res://assets/sprites/icons/archerskills/PNG/Icon8_PiercingVolley.png")

static func _create_cluster_bomb() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"cluster_bomb",
		"Cluster Bomb",
		"Throw a bomb that explodes into smaller grenades on impact.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.CLUSTER,
		15.0
	).with_damage(18.0, 1.3).with_aoe(150.0).with_projectiles(7, 350.0).with_icon("res://assets/icons/abilities/cluster_bomb.png")

static func _create_fan_of_knives() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"fan_of_knives",
		"Fan of Knives",
		"Unleash damaging knives in all directions around you.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		12.0
	).with_damage(22.0, 1.3).with_projectiles(16, 450.0).with_aoe(200.0).with_icon("res://assets/icons/abilities/fan_of_knives.png")

static func _create_sentry_turret() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"sentry_turret",
		"Sentry Totem",
		"Deploy a turret that auto-fires at enemies for 12 seconds.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		18.0
	).with_damage(4.0, 1.0).with_duration(12.0).with_aoe(250.0).with_icon("res://assets/icons/abilities/sentry_turret.png")  # 4 dmg per shot, 24 shots = 96 total

# ============================================
# RANGED ABILITY CREATORS - LEGENDARY
# ============================================

static func _create_arrow_storm() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"arrow_storm",
		"Arrow Storm",
		"Rain down a massive volley of arrows, damaging the entire screen.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		35.0
	).with_damage(40.0, 1.8).with_aoe(600.0).with_duration(4.0).with_icon("res://assets/sprites/icons/archerskills/PNG/Icon1_ArrowStorm.png")

static func _create_ballista_strike() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"ballista_strike",
		"Ballista Strike",
		"Fire an immense bolt for huge single-target damage that pierces.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		25.0
	).with_damage(130.0, 3.5).with_projectiles(1, 900.0).with_range(700.0).with_icon("res://assets/icons/abilities/ballista_strike.png")

static func _create_sentry_network() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"sentry_network",
		"Sentry Network",
		"Deploy three turrets that auto-fire at enemies for 15 seconds.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.SELF,
		30.0
	).with_damage(14.0, 1.2).with_duration(15.0).with_aoe(280.0).with_icon("res://assets/icons/abilities/sentry_network.png")

static func _create_rain_of_vengeance() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"rain_of_vengeance",
		"Rain of Vengeance",
		"Dark arrows rain down in waves across the screen, slowing and damaging all.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		38.0
	).with_damage(25.0, 2.0).with_aoe(700.0).with_duration(6.0).with_slow(0.5, 3.0).with_icon("res://assets/sprites/icons/demonskills/PNG/Group35_RainOfVengeance.png")

static func _create_explosive_decoy() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"explosive_decoy",
		"Explosive Decoy",
		"Throw a decoy that taunts enemies, then explodes after 2 seconds.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.RANGED,
		ActiveAbilityData.TargetType.CLUSTER,
		28.0
	).with_damage(100.0, 2.5).with_aoe(180.0).with_duration(2.0).with_icon("res://assets/sprites/icons/demonskills/PNG/Group18_ExplosiveDecoy.png")

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
	).with_damage(36.0, 1.2).with_aoe(50.0).with_projectiles(1, 400.0).with_icon("res://assets/icons/abilities/fireball.png")  # Buffed 2x

static func _create_frost_nova() -> ActiveAbilityData:
	# Upgraded to Rare - merged with Throw Net for definitive AOE CC
	return ActiveAbilityData.new(
		"frost_nova",
		"Frost Nova",
		"Emit a powerful burst of frost, freezing enemies for 2.5 seconds then slowing them.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		14.0
	).with_damage(22.0, 1.2).with_aoe(350.0).with_stun(2.5).with_slow(0.6, 2.5).with_icon("res://assets/icons/abilities/frost_nova.png")

static func _create_healing_light() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"healing_light",
		"Healing Light",
		"Restore 35% of your max HP over 5 seconds.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		18.0
	).with_duration(5.0).with_icon("res://assets/sprites/icons/mageskills/PNG/Icon14_HealingLight.png")

static func _create_throwing_bomb() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"throwing_bomb",
		"Throwing Bomb",
		"Lob a grenade that explodes after a short delay.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		10.0
	).with_damage(30.0, 1.0).with_aoe(70.0).with_projectiles(1, 350.0).with_icon("res://assets/icons/abilities/throwing_bomb.png")  # Buffed 2x

static func _create_blinding_flash() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"blinding_flash",
		"Blinding Flash",
		"Emanate a flash that blinds and slows enemies.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		15.0
	).with_aoe(120.0).with_slow(0.3, 3.0).with_icon("res://assets/sprites/icons/mageskills/PNG/Icon8_BlindingFlash.png")

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
	).with_damage(30.0, 1.5).with_range(300.0).with_icon("res://assets/sprites/icons/mageskills/PNG/Icon1_ChainLightning.png")

static func _create_meteor_strike() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"meteor_strike",
		"Meteor Strike",
		"Call down a meteor at a target location for massive damage.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		18.0
	).with_damage(60.0, 2.5).with_aoe(160.0).with_cast_time(0.8).with_icon("res://assets/sprites/icons/mageskills/PNG/Icon10_MeteorStrike.png")

static func _create_totem_of_frost() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"totem_of_frost",
		"Frost Totem",
		"Place a totem that slows and damages nearby enemies for 10 seconds.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		20.0
	).with_damage(28.0, 1.0).with_aoe(144.0).with_slow(0.45, 2.0).with_duration(10.0).with_icon("res://assets/icons/abilities/totem_of_frost.png")

static func _create_shadowstep() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"shadowstep",
		"Shadowstep",
		"Instantly teleport to the nearest enemy with a damage boost.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		8.0
	).with_range(450.0).with_movement().with_invulnerability(0.3).with_icon("res://assets/sprites/icons/demonskills/PNG/Group5_Shadowstep.png")

static func _create_time_slow() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"time_slow",
		"Time Slow",
		"Create a bubble where enemies are 70% slower for 5 seconds.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		22.0
	).with_aoe(280.0).with_slow(0.7, 5.0).with_duration(5.0).with_icon("res://assets/sprites/icons/demonskills/PNG/Group25_TimeSlow.png")

# ============================================
# GLOBAL ABILITY CREATORS - LEGENDARY
# ============================================

static func _create_black_hole() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"black_hole",
		"Black Hole",
		"Open a void that pulls in enemies and explodes after 3 seconds.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		30.0
	).with_damage(80.0, 2.5).with_aoe(220.0).with_duration(3.5).with_icon("res://assets/sprites/icons/demonskills/PNG/Group2_BlackHole.png")

static func _create_time_stop() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"time_stop",
		"Time Stop",
		"Freeze time for enemies for 4 seconds while you move freely.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		35.0
	).with_aoe(800.0).with_stun(4.0).with_icon("res://assets/sprites/icons/demonskills/PNG/Group28_TimeStop.png")

static func _create_thunderstorm() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"thunderstorm",
		"Thunderstorm",
		"Channel the heavens - lightning strikes all enemies repeatedly.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		32.0
	).with_damage(150.0, 2.5).with_aoe(600.0).with_duration(5.0).with_stun(0.8).with_icon("res://assets/icons/abilities/thunderstorm.png")

static func _create_summon_golem() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"summon_golem",
		"Summon Golem",
		"Summon a giant golem that taunts enemies and deals damage for 20 seconds.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		45.0
	).with_damage(18.0, 1.5).with_duration(20.0).with_aoe(150.0).with_icon("res://assets/sprites/icons/mageskills/PNG/Icon40_SummonGolem.png")

static func _create_army_of_the_dead() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"army_of_the_dead",
		"Army of the Dead",
		"Summon 5 skeleton warriors that fight alongside you for 15 seconds.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		40.0
	).with_damage(65.0, 2.5).with_aoe(250.0).with_duration(15.0).with_icon("res://assets/sprites/icons/undeadskills/PNG/Icon45_ArmyOfTheDead.png")

# ============================================
# NEW ABILITY CREATORS - ZONE & WALL
# ============================================

static func _create_flame_wall() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"flame_wall",
		"Flame Wall",
		"Summon a wide wall of fire that burns enemies walking through for 6 seconds.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.DIRECTION,
		14.0
	).with_damage(35.0, 1.5).with_aoe(350.0).with_duration(6.0).with_icon("res://assets/icons/abilities/flame_wall.png")

static func _create_ice_barricade() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"ice_barricade",
		"Ice Barricade",
		"Create an ice wall that blocks enemies and explodes after 3s, freezing nearby foes.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.DIRECTION,
		16.0
	).with_damage(28.0, 1.5).with_aoe(150.0).with_duration(3.0).with_stun(2.5).with_icon("res://assets/icons/abilities/ice_barricade.png")

static func _create_floor_is_lava() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"floor_is_lava",
		"The Floor is Lava",
		"Convert the ground to magma for 7 seconds.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		30.0
	).with_damage(12.0, 2.0).with_aoe(350.0).with_duration(7.0).with_icon("res://assets/icons/abilities/floor_is_lava.png")

# ============================================
# NEW ABILITY CREATORS - TRAPS
# ============================================

static func _create_bear_trap() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"bear_trap",
		"Bear Trap",
		"Place a hidden trap that immobilizes the first enemy for 2 seconds and deals damage.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		8.0
	).with_damage(40.0, 1.0).with_stun(2.0).with_icon("res://assets/icons/abilities/bear_trap.png")  # Buffed 2x

static func _create_glue_bomb() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"glue_bomb",
		"Glue Bomb",
		"Throw a sticky bomb creating a slowing tar zone for 6 seconds.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.CLUSTER,
		12.0
	).with_aoe(160.0).with_slow(0.85, 6.0).with_duration(6.0).with_icon("res://assets/icons/abilities/glue_bomb.png")

static func _create_pressure_mine() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"pressure_mine",
		"Pressure Mine",
		"Plant an invisible mine that explodes when 3+ enemies are nearby for massive damage.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		20.0
	).with_damage(100.0, 3.0).with_aoe(220.0).with_icon("res://assets/icons/abilities/pressure_mine.png")

# ============================================
# NEW ABILITY CREATORS - STEALTH & DECEPTION
# ============================================

static func _create_smoke_bomb() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"smoke_bomb",
		"Smoke Bomb",
		"Become invisible for 3 seconds with 3x damage on next attack.",
		ActiveAbilityData.Rarity.COMMON,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		10.0
	).with_duration(3.0).with_invulnerability(0.8).with_icon("res://assets/icons/abilities/smoke_bomb.png")

static func _create_now_you_see_me() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"now_you_see_me",
		"Now You See Me",
		"Swap places with nearest enemy, confusing all enemies to attack each other for 2.5s.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		15.0
	).with_range(300.0).with_stun(2.5).with_aoe(220.0).with_icon("res://assets/icons/abilities/now_you_see_me.png")

static func _create_pocket_sand() -> ActiveAbilityData:
	# Now includes Blinding Flash effect - upgraded to Rare
	return ActiveAbilityData.new(
		"pocket_sand",
		"Pocket Sand",
		"Throw sand and flash a blinding light! Enemies are slowed and briefly stunned.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		8.0
	).with_damage(12.0, 0.8).with_aoe(200.0).with_slow(0.7, 4.0).with_stun(1.2).with_duration(4.0).with_icon("res://assets/icons/abilities/pocket_sand.png")

# ============================================
# NEW ABILITY CREATORS - SHOUTS
# ============================================

static func _create_terrifying_shout() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"terrifying_shout",
		"Terrifying Shout",
		"Release a barbaric scream that causes nearby enemies to flee in terror for 4 seconds.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		18.0
	).with_aoe(280.0).with_duration(4.0).with_knockback(450.0).with_slow(0.5, 4.0).with_icon("res://assets/icons/abilities/terrifying_shout.png")

static func _create_demoralizing_shout() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"demoralizing_shout",
		"Demoralizing Shout",
		"A powerful warcry that weakens nearby enemies, reducing their damage by 50% for 7s.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.MELEE,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		20.0
	).with_aoe(300.0).with_duration(7.0).with_icon("res://assets/icons/abilities/demoralizing_shout.png")

# ============================================
# NEW ABILITY CREATORS - CHAOS & UTILITY
# ============================================

static func _create_mirror_clone() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"mirror_clone",
		"Mirror Clone",
		"Spawn a clone that fights with your abilities at 75% damage for half the cooldown time.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		35.0
	).with_damage(0.75, 0.75).with_duration(17.5).with_icon("res://assets/icons/abilities/mirror_clone.png")

static func _create_uno_reverse() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"uno_reverse",
		"Uno Reverse",
		"For 4 seconds, all damage you would take is instead dealt to enemies.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		30.0
	).with_duration(4.0).with_aoe(280.0).with_icon("res://assets/icons/abilities/uno_reverse.png")

static func _create_orbital_strike() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"orbital_strike",
		"Orbital Strike",
		"Fire ALL your orbitals at the nearest enemy for massive damage.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.NEAREST_ENEMY,
		25.0
	).with_damage(50.0, 2.5).with_range(400.0).with_aoe(160.0).with_cast_time(0.8).with_icon("res://assets/icons/abilities/orbital_strike.png")

static func _create_summon_party() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"summon_party",
		"Summon Party",
		"All your summons gain +150% damage and attack speed for 8 seconds.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		35.0
	).with_duration(8.0).with_icon("res://assets/icons/abilities/summon_party.png")

static func _create_panic_button() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"panic_button",
		"Panic Button",
		"Push all enemies away and gain 4 seconds of invulnerability.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		30.0
	).with_aoe(300.0).with_knockback(600.0).with_invulnerability(4.0).with_icon("res://assets/icons/abilities/panic_button.png")

static func _create_pocket_healer() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"pocket_healer",
		"Pocket Healer",
		"Summon a healing fairy for 15 seconds that follows you and heals 3% HP per second.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		40.0
	).with_duration(15.0).with_icon("res://assets/icons/abilities/pocket_healer.png")

static func _create_safe_space() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"safe_space",
		"Safe Space",
		"Create a shield bubble for 4 seconds.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		18.0
	).with_invulnerability(4.0).with_aoe(120.0).with_icon("res://assets/icons/abilities/safe_space.png")

static func _create_double_or_nothing() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"double_or_nothing",
		"Double or Nothing",
		"For 8 seconds, your attacks either deal 4x damage or 0 damage. 50/50 each hit.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		25.0
	).with_duration(8.0).with_icon("res://assets/icons/abilities/double_or_nothing.png")

# ============================================
# NEW ABILITY CREATORS - SUMMONS & TRANSFORMS
# ============================================

static func _create_release_the_hounds() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"release_the_hounds",
		"Release the Hounds",
		"Summon 5 ghostly wolves that chase down enemies for 12 seconds.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		35.0
	).with_damage(28.0, 1.5).with_duration(12.0).with_icon("res://assets/icons/abilities/release_the_hounds.png")

static func _create_gigantamax() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"gigantamax",
		"Gigantamax",
		"Grow HUGE for 7 seconds. +300% damage, +75% range, but 90% reduced movement speed.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		45.0
	).with_duration(7.0).with_icon("res://assets/icons/abilities/gigantamax.png")

static func _create_monster_energy() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"monster_energy",
		"Monster Energy",
		"+150% attack speed for 7 seconds.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		20.0
	).with_duration(7.0).with_icon("res://assets/icons/abilities/monster_energy.png")

static func _create_i_see_red() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"i_see_red",
		"I See Red",
		"Go berserk. +150% damage, +75% speed, but take 50% more damage for 10 seconds.",
		ActiveAbilityData.Rarity.EPIC,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.SELF,
		40.0
	).with_duration(10.0).with_icon("res://assets/icons/abilities/i_see_red.png")

# ============================================
# NEW ABILITY CREATORS - CROWD CONTROL
# ============================================

# _create_vortex removed - now part of spin_tree as spin_vortex (T2)

static func _create_repulsive() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"repulsive",
		"Repulsive",
		"Constantly knockback and damage enemies around you for 5 seconds.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		14.0
	).with_aoe(260.0).with_knockback(350.0).with_damage(28.0, 1.3).with_icon("res://assets/icons/abilities/repulsive.png")

static func _create_dj_drop() -> ActiveAbilityData:
	return ActiveAbilityData.new(
		"dj_drop",
		"DJ Drop",
		"Drop a sick beat stunning enemies for 2.5 seconds.",
		ActiveAbilityData.Rarity.RARE,
		ActiveAbilityData.ClassType.GLOBAL,
		ActiveAbilityData.TargetType.AREA_AROUND_SELF,
		18.0
	).with_aoe(280.0).with_stun(2.5).with_icon("res://assets/icons/abilities/dj_drop.png")
