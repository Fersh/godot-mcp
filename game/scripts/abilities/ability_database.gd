extends Node
class_name AbilityDatabase

# All abilities organized by category
# Effects use: {effect_type: AbilityData.EffectType, value: float}
#
# Modular ability files are loaded from:
# - passives/elemental_passives.gd (on-hit elemental effects)
# - passives/combat_passives.gd (combat mechanics & procs)
# - passives/defensive_passives.gd (shields, healing, mitigation)
# - passives/conditional_passives.gd (trade-offs & situational)
# - passives/legendary_passives.gd (game-changing effects)
# - passives/mythic_passives.gd (ultra-rare abilities)

static func get_all_abilities() -> Array[AbilityData]:
	var abilities: Array[AbilityData] = []
	# Core abilities
	abilities.append_array(get_common_abilities())
	abilities.append_array(get_rare_abilities())
	abilities.append_array(get_legendary_abilities())
	abilities.append_array(get_mythic_abilities())
	abilities.append_array(get_ranged_abilities())
	abilities.append_array(get_melee_abilities())
	# Extended modular abilities
	abilities.append_array(get_extended_abilities())
	return abilities

static func get_extended_abilities() -> Array[AbilityData]:
	var abilities: Array[AbilityData] = []
	abilities.append_array(ElementalPassives.get_abilities())
	abilities.append_array(CombatPassives.get_abilities())
	abilities.append_array(DefensivePassives.get_abilities())
	abilities.append_array(ConditionalPassives.get_abilities())
	abilities.append_array(LegendaryPassives.get_abilities())
	abilities.append_array(MythicPassives.get_abilities())
	abilities.append_array(OrbitalPassives.get_abilities())
	abilities.append_array(SummonPassives.get_abilities())
	abilities.append_array(SynergyPassives.get_abilities())
	abilities.append_array(ChaosPassives.get_abilities())
	abilities.append_array(get_active_synergy_abilities())
	return abilities

# ============================================
# ACTIVE ABILITY SYNERGY PASSIVES
# ============================================
static func get_active_synergy_abilities() -> Array[AbilityData]:
	return [
		# Common - Basic active ability enhancements
		AbilityData.new(
			"quick_reflexes",
			"Quick Reflexes",
			"Active ability cooldowns reduced by 10%",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.QUICK_REFLEXES, value = 0.10}]
		),
		AbilityData.new(
			"swift_dodge",
			"Swift Dodge",
			"Dodging grants +30% move speed for 2s",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.SWIFT_DODGE, value = 0.30}]
		),
		# Rare - More impactful synergies
		AbilityData.new(
			"adrenaline_surge",
			"Adrenaline Surge",
			"Taking damage reduces active cooldowns by 0.5s",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.ADRENALINE_SURGE, value = 0.5}]
		),
		AbilityData.new(
			"empowered_abilities",
			"Empowered Abilities",
			"Active abilities deal 20% more damage",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.EMPOWERED_ABILITIES, value = 0.20}]
		),
		AbilityData.new(
			"combo_master",
			"Combo Master",
			"Using an active grants +15% damage for 3s",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.COMBO_MASTER, value = 0.15}]
		),
		AbilityData.new(
			"kill_accelerant",
			"Kill Accelerant",
			"Kills reduce ultimate cooldown by 0.5s",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.KILL_ACCELERANT, value = 0.5}]
		),
		# Legendary - Powerful active synergies
		AbilityData.new(
			"double_charge",
			"Double Charge",
			"Dodge gains a second charge",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.DOUBLE_CHARGE, value = 1.0}]
		),
		AbilityData.new(
			"elemental_infusion",
			"Elemental Infusion",
			"Active abilities apply your elemental effects",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.ELEMENTAL_INFUSION, value = 1.0}]
		),
		AbilityData.new(
			"phantom_strike",
			"Phantom Strike",
			"Dodging through enemies deals area damage",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.PHANTOM_STRIKE, value = 25.0}]  # base damage
		),
		AbilityData.new(
			"ability_echo",
			"Ability Echo",
			"10% chance for active abilities to trigger twice",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.ABILITY_ECHO, value = 0.10}]
		),
		# Passive Ability Enhancement
		AbilityData.new(
			"passive_amplifier",
			"Passive Amplifier",
			"Passive abilities deal 20% more damage",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.PASSIVE_AMPLIFIER, value = 0.20}]
		),
	]

# ============================================
# COMMON ABILITIES (Stat Boosts)
# ============================================
static func get_common_abilities() -> Array[AbilityData]:
	return [
		AbilityData.new(
			"overclock",
			"Overclock",
			"+20% Attack Speed",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.STAT_BOOST,
			[{effect_type = AbilityData.EffectType.ATTACK_SPEED, value = 0.2}]
		),
		AbilityData.new(
			"high_voltage",
			"High Voltage",
			"+20% Damage, +Size",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.STAT_BOOST,
			[
				{effect_type = AbilityData.EffectType.DAMAGE, value = 0.2},
				{effect_type = AbilityData.EffectType.SIZE, value = 0.15}
			]
		),
		AbilityData.new(
			"vitality",
			"Vitality",
			"+20% Max HP",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.STAT_BOOST,
			[{effect_type = AbilityData.EffectType.MAX_HP_PERCENT, value = 0.2}]
		),
		AbilityData.new(
			"fast_learner",
			"Fast Learner",
			"+20% XP Gain",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.STAT_BOOST,
			[{effect_type = AbilityData.EffectType.XP_GAIN, value = 0.2}]
		),
		AbilityData.new(
			"regeneration",
			"Regeneration",
			"Heal 1% HP every 5 seconds",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.REGEN, value = 0.2}]  # HP per second
		),
		AbilityData.new(
			"tank",
			"Tank",
			"+50 HP, +Size, -10% Speed",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.STAT_BOOST,
			[
				{effect_type = AbilityData.EffectType.MAX_HP, value = 50.0},
				{effect_type = AbilityData.EffectType.SIZE, value = 0.2},
				{effect_type = AbilityData.EffectType.MOVE_SPEED, value = -0.1}
			]
		),
		AbilityData.new(
			"scavenger",
			"Scavenger",
			"20% Chance for Double XP gems",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.DOUBLE_XP_CHANCE, value = 0.2}]
		),
		AbilityData.new(
			"greed",
			"Greed",
			"+50% Coin Gain, -20% Max HP",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.STAT_BOOST,
			[
				{effect_type = AbilityData.EffectType.COIN_GAIN, value = 0.5},
				{effect_type = AbilityData.EffectType.MAX_HP, value = -20.0}
			]
		),
		AbilityData.new(
			"focus",
			"Focus",
			"Regenerate HP while standing still",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.FOCUS_REGEN, value = 2.0}]  # HP per second while still
		),
		AbilityData.new(
			"momentum",
			"Momentum",
			"Moving increases next hit damage",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.MOMENTUM, value = 0.25}]  # +25% max bonus
		),
	]

# ============================================
# RARE ABILITIES (Passives & Utility)
# ============================================
static func get_rare_abilities() -> Array[AbilityData]:
	return [
		AbilityData.new(
			"adrenaline",
			"Adrenaline",
			"Gain Speed boost on kill",
			AbilityData.Rarity.RARE,
			AbilityData.Type.ON_KILL,
			[{effect_type = AbilityData.EffectType.ADRENALINE, value = 0.3}]  # 30% speed for 2s
		),
		AbilityData.new(
			"frenzy",
			"Frenzy",
			"Attack faster when low HP",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.FRENZY, value = 0.5}]  # +50% attack speed below 30% HP
		),
		AbilityData.new(
			"lucky_clover",
			"Lucky Clover",
			"+High Luck (crit & drops)",
			AbilityData.Rarity.RARE,
			AbilityData.Type.STAT_BOOST,
			[{effect_type = AbilityData.EffectType.LUCK, value = 0.25}]
		),
		AbilityData.new(
			"thorns",
			"Thorns",
			"Enemies take 5 damage on touch",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.THORNS, value = 5.0}]
		),
		# Moved from Legendary
		AbilityData.new(
			"attractor_field",
			"Attractor Field",
			"+50% Pickup Range",
			AbilityData.Rarity.RARE,
			AbilityData.Type.STAT_BOOST,
			[{effect_type = AbilityData.EffectType.PICKUP_RANGE, value = 0.5}]
		),
		AbilityData.new(
			"afterburner",
			"Afterburner",
			"+20% Move Speed",
			AbilityData.Rarity.RARE,
			AbilityData.Type.STAT_BOOST,
			[{effect_type = AbilityData.EffectType.MOVE_SPEED, value = 0.2}]
		),
		AbilityData.new(
			"vampirism",
			"Vampirism",
			"5% Chance to heal 5% HP on kill",
			AbilityData.Rarity.RARE,
			AbilityData.Type.ON_KILL,
			[{effect_type = AbilityData.EffectType.VAMPIRISM, value = 0.05}]
		),
		AbilityData.new(
			"critical_eye",
			"Critical Eye",
			"+20% Crit Chance (Double Damage)",
			AbilityData.Rarity.RARE,
			AbilityData.Type.STAT_BOOST,
			[{effect_type = AbilityData.EffectType.CRIT_CHANCE, value = 0.2}]
		),
		AbilityData.new(
			"concussive_hit",
			"Concussive Hit",
			"Attacks push enemies back",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.KNOCKBACK, value = 150.0}]
		),
		AbilityData.new(
			"retribution",
			"Retribution",
			"You explode when taking damage",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.RETRIBUTION, value = 15.0}]  # explosion damage
		),
		AbilityData.new(
			"time_dilation",
			"Time Dilation",
			"Enemies move 20% slower permanently",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.TIME_DILATION, value = 0.2}]  # 20% slow
		),
		AbilityData.new(
			"giant_slayer",
			"Giant Slayer",
			"+100% Damage to enemies with >80% HP",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.GIANT_SLAYER, value = 1.0}]  # +100% damage
		),
		AbilityData.new(
			"backstab",
			"Backstab",
			"+25% Critical Hit chance",
			AbilityData.Rarity.RARE,
			AbilityData.Type.STAT_BOOST,
			[{effect_type = AbilityData.EffectType.BACKSTAB, value = 0.25}]
		),
	]

# ============================================
# LEGENDARY ABILITIES (Game Changers & Summons)
# ============================================
static func get_legendary_abilities() -> Array[AbilityData]:
	return [
		AbilityData.new(
			"orbital_defense",
			"Orbital Defense",
			"A projectile orbits around you",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.SUMMON,
			[{effect_type = AbilityData.EffectType.ORBITAL, value = 1.0}]
		),
		AbilityData.new(
			"tesla_coil",
			"Tesla Coil",
			"Lightning arcs to nearby enemies",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PERIODIC,
			[{effect_type = AbilityData.EffectType.TESLA_COIL, value = 10.0}]  # damage
		),
		AbilityData.new(
			"cull_the_weak",
			"Cull the Weak",
			"Instantly kill enemies under 20% HP",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.CULL_WEAK, value = 0.2}]
		),
		AbilityData.new(
			"ring_of_fire",
			"Ring of Fire",
			"Periodically fires 360-degree spread",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PERIODIC,
			[{effect_type = AbilityData.EffectType.RING_OF_FIRE, value = 8.0}]  # projectile count
		),
		AbilityData.new(
			"toxic_cloud",
			"Toxic Cloud",
			"Damages nearby enemies over time",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.TOXIC_CLOUD, value = 3.0}]  # DPS
		),
		AbilityData.new(
			"glass_cannon",
			"Glass Cannon",
			"+80% Damage, -30 Max HP",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.STAT_BOOST,
			[
				{effect_type = AbilityData.EffectType.DAMAGE, value = 0.8},
				{effect_type = AbilityData.EffectType.MAX_HP, value = -30.0}
			]
		),
		AbilityData.new(
			"death_detonation",
			"Death Detonation",
			"Enemies explode on death",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.ON_KILL,
			[{effect_type = AbilityData.EffectType.DEATH_EXPLOSION, value = 8.0}]  # explosion damage (toned down)
		),
		AbilityData.new(
			"thundercaller",
			"Thundercaller",
			"Strikes random enemies with lightning",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PERIODIC,
			[{effect_type = AbilityData.EffectType.LIGHTNING_STRIKE, value = 6.0}]  # damage (halved)
		),
		AbilityData.new(
			"drone_support",
			"Drone Support",
			"Summons a drone that shoots enemies",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.SUMMON,
			[{effect_type = AbilityData.EffectType.DRONE, value = 1.0}]
		),
		AbilityData.new(
			"blood_money",
			"Blood Money",
			"Picking up coins heals you for 1% HP",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.BLOOD_MONEY, value = 1.0}]  # HP per coin
		),
		AbilityData.new(
			"divine_shield",
			"Divine Shield",
			"Invulnerable for 2 seconds after taking damage",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.DIVINE_SHIELD, value = 2.0}]  # duration in seconds
		),
	]

# ============================================
# MYTHIC ABILITIES (Game Changers)
# ============================================
static func get_mythic_abilities() -> Array[AbilityData]:
	return [
		AbilityData.new(
			"phoenix",
			"Phoenix",
			"Revive once per run with full HP and explosion",
			AbilityData.Rarity.MYTHIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.PHOENIX, value = 1.0}]  # revive with full HP
		),
		AbilityData.new(
			"boomerang",
			"Boomerang",
			"Projectiles fly out and return, hitting twice",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.RANGED_ONLY,
			[{effect_type = AbilityData.EffectType.BOOMERANG, value = 1.0}]
		),
	]

# ============================================
# RANGED-ONLY ABILITIES
# ============================================
static func get_ranged_abilities() -> Array[AbilityData]:
	return [
		# Common
		AbilityData.new(
			"accelerator",
			"Accelerator",
			"+30% Projectile Speed",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.RANGED_ONLY,
			[{effect_type = AbilityData.EffectType.PROJECTILE_SPEED, value = 0.3}]
		),
		AbilityData.new(
			"heavy_draw",
			"Heavy Draw",
			"+50% Damage, +20% Speed, -20% Fire Rate",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.RANGED_ONLY,
			[
				{effect_type = AbilityData.EffectType.DAMAGE, value = 0.5},
				{effect_type = AbilityData.EffectType.PROJECTILE_SPEED, value = 0.2},
				{effect_type = AbilityData.EffectType.ATTACK_SPEED, value = -0.2}
			]
		),
		AbilityData.new(
			"rapid_fire",
			"Rapid Fire",
			"+15% Fire Rate, -5% Damage",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.RANGED_ONLY,
			[
				{effect_type = AbilityData.EffectType.ATTACK_SPEED, value = 0.15},
				{effect_type = AbilityData.EffectType.DAMAGE, value = -0.05}
			]
		),
		# Rare
		AbilityData.new(
			"split_shot",
			"Split Shot",
			"+1 Projectile per volley",
			AbilityData.Rarity.RARE,
			AbilityData.Type.RANGED_ONLY,
			[{effect_type = AbilityData.EffectType.PROJECTILE_COUNT, value = 1.0}]
		),
		AbilityData.new(
			"laser_drill",
			"Laser Drill",
			"Shots pierce +1 enemy",
			AbilityData.Rarity.RARE,
			AbilityData.Type.RANGED_ONLY,
			[{effect_type = AbilityData.EffectType.PROJECTILE_PIERCE, value = 1.0}]
		),
		AbilityData.new(
			"rear_guard",
			"Rear Guard",
			"Shoot an extra arrow backwards",
			AbilityData.Rarity.RARE,
			AbilityData.Type.RANGED_ONLY,
			[{effect_type = AbilityData.EffectType.REAR_SHOT, value = 1.0}]
		),
		AbilityData.new(
			"sniper_barrel",
			"Sniper Barrel",
			"Deal more damage to distant enemies",
			AbilityData.Rarity.RARE,
			AbilityData.Type.RANGED_ONLY,
			[{effect_type = AbilityData.EffectType.SNIPER_DAMAGE, value = 0.5}]  # +50% at max range
		),
		AbilityData.new(
			"double_tap",
			"Double Tap",
			"20% chance to fire twice per shot",
			AbilityData.Rarity.RARE,
			AbilityData.Type.RANGED_ONLY,
			[{effect_type = AbilityData.EffectType.DOUBLE_TAP, value = 0.2}]
		),
		AbilityData.new(
			"barrage",
			"Barrage",
			"+3 Projectiles, +Spread, -20% Damage",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.RANGED_ONLY,
			[
				{effect_type = AbilityData.EffectType.PROJECTILE_COUNT, value = 3.0},
				{effect_type = AbilityData.EffectType.PROJECTILE_SPREAD, value = 0.4},
				{effect_type = AbilityData.EffectType.DAMAGE, value = -0.2}
			]
		),
		AbilityData.new(
			"point_blank",
			"Point Blank",
			"+50% Damage to enemies within close range",
			AbilityData.Rarity.RARE,
			AbilityData.Type.RANGED_ONLY,
			[{effect_type = AbilityData.EffectType.POINT_BLANK, value = 0.5}]  # +50% damage within close range
		),
		AbilityData.new(
			"scattergun",
			"Scattergun",
			"+2 Projectiles, increased spread",
			AbilityData.Rarity.EPIC,  # Very powerful, made legendary
			AbilityData.Type.RANGED_ONLY,
			[
				{effect_type = AbilityData.EffectType.PROJECTILE_COUNT, value = 2.0},
				{effect_type = AbilityData.EffectType.PROJECTILE_SPREAD, value = 0.3}  # radians
			]
		),
		AbilityData.new(
			"ricochet",
			"Ricochet",
			"Arrows bounce to a nearby enemy on hit",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.RANGED_ONLY,
			[{effect_type = AbilityData.EffectType.RICOCHET, value = 1.0}]  # number of bounces
		),
	]

# ============================================
# MELEE-ONLY ABILITIES
# ============================================
static func get_melee_abilities() -> Array[AbilityData]:
	return [
		# Common
		AbilityData.new(
			"heavy_blade",
			"Heavy Blade",
			"+25% swing size",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.MELEE_ONLY,
			[{effect_type = AbilityData.EffectType.MELEE_AREA, value = 0.25}]
		),
		AbilityData.new(
			"quick_slash",
			"Quick Slash",
			"+20% Attack Speed",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.MELEE_ONLY,
			[{effect_type = AbilityData.EffectType.ATTACK_SPEED, value = 0.2}]
		),
		AbilityData.new(
			"iron_skin",
			"Iron Skin",
			"+2 Armor (Flat damage reduction)",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.MELEE_ONLY,
			[{effect_type = AbilityData.EffectType.ARMOR, value = 2.0}]
		),
		AbilityData.new(
			"knockout",
			"Knockout",
			"+10 Knockback force",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.MELEE_ONLY,
			[{effect_type = AbilityData.EffectType.MELEE_KNOCKBACK, value = 10.0}]
		),
		AbilityData.new(
			"sword_mastery",
			"Sword Mastery",
			"+10% Damage and +10% Attack Speed",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.MELEE_ONLY,
			[
				{effect_type = AbilityData.EffectType.DAMAGE, value = 0.1},
				{effect_type = AbilityData.EffectType.ATTACK_SPEED, value = 0.1}
			]
		),
		# Rare
		AbilityData.new(
			"long_reach",
			"Long Reach",
			"+50% Melee Range",
			AbilityData.Rarity.RARE,
			AbilityData.Type.MELEE_ONLY,
			[{effect_type = AbilityData.EffectType.MELEE_RANGE, value = 0.5}]
		),
		AbilityData.new(
			"crimson_edge",
			"Crimson Edge",
			"Attacks cause Bleeding (DOT)",
			AbilityData.Rarity.RARE,
			AbilityData.Type.MELEE_ONLY,
			[{effect_type = AbilityData.EffectType.BLEEDING, value = 3.0}]
		),
		AbilityData.new(
			"deflection",
			"Deflection",
			"Destroy enemy projectiles on hit",
			AbilityData.Rarity.RARE,
			AbilityData.Type.MELEE_ONLY,
			[{effect_type = AbilityData.EffectType.DEFLECT, value = 1.0}]
		),
		AbilityData.new(
			"wide_swing",
			"Wide Swing",
			"+40% Melee Area, hits more enemies",
			AbilityData.Rarity.RARE,
			AbilityData.Type.MELEE_ONLY,
			[{effect_type = AbilityData.EffectType.MELEE_AREA, value = 0.4}]
		),
		AbilityData.new(
			"parry",
			"Parry",
			"20% chance to block damage entirely",
			AbilityData.Rarity.RARE,
			AbilityData.Type.MELEE_ONLY,
			[{effect_type = AbilityData.EffectType.PARRY, value = 0.2}]
		),
		AbilityData.new(
			"seismic_slam",
			"Seismic Slam",
			"Attacks have a chance to Stun enemies",
			AbilityData.Rarity.RARE,
			AbilityData.Type.MELEE_ONLY,
			[{effect_type = AbilityData.EffectType.SEISMIC_SLAM, value = 0.15}]  # 15% stun chance
		),
		AbilityData.new(
			"bloodthirst",
			"Bloodthirst",
			"Kills grant temporary Attack Speed boost",
			AbilityData.Rarity.RARE,
			AbilityData.Type.MELEE_ONLY,
			[{effect_type = AbilityData.EffectType.BLOODTHIRST, value = 0.3}]  # +30% attack speed for 3s
		),
		# Legendary
		AbilityData.new(
			"whirlwind",
			"Whirlwind",
			"Spin attack every 3 seconds",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.MELEE_ONLY,
			[{effect_type = AbilityData.EffectType.WHIRLWIND, value = 3.0}]
		),
		AbilityData.new(
			"titans_grip",
			"Titan's Grip",
			"+100% Damage, -50% Move Speed",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.MELEE_ONLY,
			[
				{effect_type = AbilityData.EffectType.DAMAGE, value = 1.0},
				{effect_type = AbilityData.EffectType.MOVE_SPEED, value = -0.5}
			]
		),
		AbilityData.new(
			"berserker_rage",
			"Berserker Rage",
			"+50% Damage & Attack Speed when below 30% HP",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.MELEE_ONLY,
			[{effect_type = AbilityData.EffectType.FRENZY, value = 0.5}]
		),
		AbilityData.new(
			"blade_beam",
			"Blade Beam",
			"Auto attacking fires an extra projectile",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.MELEE_ONLY,
			[{effect_type = AbilityData.EffectType.BLADE_BEAM, value = 1.0}]
		),
		AbilityData.new(
			"extra_strike",
			"Extra Strike",
			"Auto attacks hit twice",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.MELEE_ONLY,
			[{effect_type = AbilityData.EffectType.DOUBLE_STRIKE, value = 1.0}]
		),
	]
