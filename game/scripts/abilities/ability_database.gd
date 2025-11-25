extends Node
class_name AbilityDatabase

# All abilities organized by category
# Effects use: {effect_type: AbilityData.EffectType, value: float}

static func get_all_abilities() -> Array[AbilityData]:
	var abilities: Array[AbilityData] = []
	abilities.append_array(get_common_abilities())
	abilities.append_array(get_rare_abilities())
	abilities.append_array(get_legendary_abilities())
	abilities.append_array(get_ranged_abilities())
	# abilities.append_array(get_melee_abilities())  # Uncomment for melee character
	return abilities

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
			"+40% Damage, +Size",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.STAT_BOOST,
			[
				{effect_type = AbilityData.EffectType.DAMAGE, value = 0.4},
				{effect_type = AbilityData.EffectType.SIZE, value = 0.15}
			]
		),
		AbilityData.new(
			"vitality",
			"Vitality",
			"+50 Max HP",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.STAT_BOOST,
			[{effect_type = AbilityData.EffectType.MAX_HP, value = 50.0}]
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
			"Heal 1 HP every 5 seconds",
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
			"5% Chance to heal 1HP on kill",
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
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.SUMMON,
			[{effect_type = AbilityData.EffectType.ORBITAL, value = 1.0}]
		),
		AbilityData.new(
			"tesla_coil",
			"Tesla Coil",
			"Lightning arcs to nearby enemies",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PERIODIC,
			[{effect_type = AbilityData.EffectType.TESLA_COIL, value = 10.0}]  # damage
		),
		AbilityData.new(
			"cull_the_weak",
			"Cull the Weak",
			"Instantly kill enemies under 20% HP",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.CULL_WEAK, value = 0.2}]
		),
		AbilityData.new(
			"ring_of_fire",
			"Ring of Fire",
			"Periodically fires 360-degree spread",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PERIODIC,
			[{effect_type = AbilityData.EffectType.RING_OF_FIRE, value = 8.0}]  # projectile count
		),
		AbilityData.new(
			"toxic_cloud",
			"Toxic Cloud",
			"Damages nearby enemies over time",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.TOXIC_CLOUD, value = 3.0}]  # DPS
		),
		AbilityData.new(
			"glass_cannon",
			"Glass Cannon",
			"+80% Damage, -30 Max HP",
			AbilityData.Rarity.LEGENDARY,
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
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.ON_KILL,
			[{effect_type = AbilityData.EffectType.DEATH_EXPLOSION, value = 15.0}]  # explosion damage
		),
		AbilityData.new(
			"thundercaller",
			"Thundercaller",
			"Strikes random enemies with lightning",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PERIODIC,
			[{effect_type = AbilityData.EffectType.LIGHTNING_STRIKE, value = 25.0}]  # damage
		),
		AbilityData.new(
			"drone_support",
			"Drone Support",
			"Summons a drone that shoots enemies",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.SUMMON,
			[{effect_type = AbilityData.EffectType.DRONE, value = 1.0}]
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
			"rubber_walls",
			"Rubber Walls",
			"Arrows bounce off walls",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.RANGED_ONLY,
			[{effect_type = AbilityData.EffectType.RUBBER_WALLS, value = 1.0}]
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
			"scattergun",
			"Scattergun",
			"+2 Projectiles, increased spread",
			AbilityData.Rarity.RARE,
			AbilityData.Type.RANGED_ONLY,
			[
				{effect_type = AbilityData.EffectType.PROJECTILE_COUNT, value = 2.0},
				{effect_type = AbilityData.EffectType.PROJECTILE_SPREAD, value = 0.3}  # radians
			]
		),
	]

# ============================================
# MELEE-ONLY ABILITIES (Commented out for future)
# ============================================
#static func get_melee_abilities() -> Array[AbilityData]:
#	return [
#		# Common
#		AbilityData.new(
#			"heavy_blade",
#			"Heavy Blade",
#			"+50% Area (Swing Size), +20% Damage",
#			AbilityData.Rarity.COMMON,
#			AbilityData.Type.MELEE_ONLY,
#			[
#				{effect_type = AbilityData.EffectType.MELEE_AREA, value = 0.5},
#				{effect_type = AbilityData.EffectType.DAMAGE, value = 0.2}
#			]
#		),
#		AbilityData.new(
#			"quick_slash",
#			"Quick Slash",
#			"+30% Attack Speed",
#			AbilityData.Rarity.COMMON,
#			AbilityData.Type.MELEE_ONLY,
#			[{effect_type = AbilityData.EffectType.ATTACK_SPEED, value = 0.3}]
#		),
#		# Rare
#		AbilityData.new(
#			"long_reach",
#			"Long Reach",
#			"+100% Melee Range",
#			AbilityData.Rarity.RARE,
#			AbilityData.Type.MELEE_ONLY,
#			[{effect_type = AbilityData.EffectType.MELEE_RANGE, value = 1.0}]
#		),
#		AbilityData.new(
#			"crimson_edge",
#			"Crimson Edge",
#			"Attacks cause Bleeding (DOT)",
#			AbilityData.Rarity.RARE,
#			AbilityData.Type.MELEE_ONLY,
#			[{effect_type = AbilityData.EffectType.BLEEDING, value = 3.0}]  # DPS
#		),
#		AbilityData.new(
#			"deflection",
#			"Deflection",
#			"Destroy enemy projectiles on hit",
#			AbilityData.Rarity.RARE,
#			AbilityData.Type.MELEE_ONLY,
#			[{effect_type = AbilityData.EffectType.DEFLECT, value = 1.0}]
#		),
#		# Legendary
#		AbilityData.new(
#			"whirlwind",
#			"Whirlwind",
#			"Spin attack every 3 seconds",
#			AbilityData.Rarity.LEGENDARY,
#			AbilityData.Type.MELEE_ONLY,
#			[{effect_type = AbilityData.EffectType.WHIRLWIND, value = 3.0}]  # cooldown
#		),
#		AbilityData.new(
#			"titans_grip",
#			"Titan's Grip",
#			"+100% Damage, -20% Move Speed",
#			AbilityData.Rarity.LEGENDARY,
#			AbilityData.Type.MELEE_ONLY,
#			[
#				{effect_type = AbilityData.EffectType.DAMAGE, value = 1.0},
#				{effect_type = AbilityData.EffectType.MOVE_SPEED, value = -0.2}
#			]
#		),
#	]
