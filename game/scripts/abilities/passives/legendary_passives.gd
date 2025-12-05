extends Node
class_name LegendaryPassives

# Legendary passive abilities
# Game-changing effects that define builds

static func get_abilities() -> Array[AbilityData]:
	return [
		# Ceremonial Dagger
		AbilityData.new(
			"ceremonial_dagger",
			"Ceremonial Dagger",
			"Kills fire 1 homing dagger at enemies",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.ON_KILL,
			[{effect_type = AbilityData.EffectType.CEREMONIAL_DAGGER, value = 1.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.CEREMONIAL_DAGGER, value = 1.0}],
			[{effect_type = AbilityData.EffectType.CEREMONIAL_DAGGER, value = 2.0}],
			[{effect_type = AbilityData.EffectType.CEREMONIAL_DAGGER, value = 3.0}]
		).with_rank_descriptions(
			"Kills fire 1 homing dagger at enemies",
			"Kills fire 2 homing daggers at enemies",
			"Kills fire 3 homing daggers at enemies"
		),

		# Missile Barrage
		AbilityData.new(
			"missile_barrage",
			"Missile Barrage",
			"15% chance to fire homing missiles",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.MISSILE_BARRAGE, value = 0.15}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.MISSILE_BARRAGE, value = 0.15}],
			[{effect_type = AbilityData.EffectType.MISSILE_BARRAGE, value = 0.25}],
			[{effect_type = AbilityData.EffectType.MISSILE_BARRAGE, value = 0.35}]
		).with_rank_descriptions(
			"15% chance to fire homing missiles",
			"25% chance to fire homing missiles",
			"35% chance to fire homing missiles"
		),

		# Soul Reaper
		AbilityData.new(
			"soul_reaper",
			"Soul Reaper",
			"Kills heal 0.5% HP and grant stacking damage",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.ON_KILL,
			[{effect_type = AbilityData.EffectType.SOUL_REAPER, value = 0.005}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.SOUL_REAPER, value = 0.005}],
			[{effect_type = AbilityData.EffectType.SOUL_REAPER, value = 0.01}],
			[{effect_type = AbilityData.EffectType.SOUL_REAPER, value = 0.015}]
		).with_rank_descriptions(
			"Kills heal 0.5% HP and grant stacking damage",
			"Kills heal 1% HP and grant stacking damage",
			"Kills heal 1.5% HP and grant stacking damage"
		),

		# Summoner's Aid
		AbilityData.new(
			"summoner_aid",
			"Summoner's Aid",
			"Summon a skeleton every 12 seconds",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.SUMMON,
			[{effect_type = AbilityData.EffectType.SUMMONER, value = 12.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.SUMMONER, value = 12.0}],
			[{effect_type = AbilityData.EffectType.SUMMONER, value = 8.0}],
			[{effect_type = AbilityData.EffectType.SUMMONER, value = 5.0}]
		).with_rank_descriptions(
			"Summon a skeleton every 12 seconds",
			"Summon a skeleton every 8 seconds",
			"Summon a skeleton every 5 seconds"
		),

		# Mind Control
		AbilityData.new(
			"mind_control",
			"Mind Control",
			"3% chance to charm enemies on hit",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.MIND_CONTROL, value = 0.03}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.MIND_CONTROL, value = 0.03}],
			[{effect_type = AbilityData.EffectType.MIND_CONTROL, value = 0.05}],
			[{effect_type = AbilityData.EffectType.MIND_CONTROL, value = 0.08}]
		).with_rank_descriptions(
			"3% chance to charm enemies on hit",
			"5% chance to charm enemies on hit",
			"8% chance to charm enemies on hit"
		),

		# Blood Debt
		AbilityData.new(
			"blood_debt",
			"Blood Debt",
			"+30% damage, take 10% of damage dealt",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.BLOOD_DEBT, value = 0.3}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.BLOOD_DEBT, value = 0.3}],
			[{effect_type = AbilityData.EffectType.BLOOD_DEBT, value = 0.5}],
			[{effect_type = AbilityData.EffectType.BLOOD_DEBT, value = 0.75}]
		).with_rank_descriptions(
			"+30% damage, take 10% of damage dealt",
			"+50% damage, take 10% of damage dealt",
			"+75% damage, take 10% of damage dealt"
		),

		# Chrono Trigger
		AbilityData.new(
			"chrono_trigger",
			"Chrono Trigger",
			"Freeze all enemies for 0.75s every 12s",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PERIODIC,
			[{effect_type = AbilityData.EffectType.CHRONO_TRIGGER, value = 12.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.CHRONO_TRIGGER, value = 12.0}],
			[{effect_type = AbilityData.EffectType.CHRONO_TRIGGER, value = 10.0}],
			[{effect_type = AbilityData.EffectType.CHRONO_TRIGGER, value = 7.0}]
		).with_rank_descriptions(
			"Freeze all enemies for 0.75s every 12s",
			"Freeze all enemies for 1s every 10s",
			"Freeze all enemies for 1.5s every 7s"
		),

		# Unlimited Power
		AbilityData.new(
			"unlimited_power",
			"Unlimited Power",
			"+1% permanent damage per kill (max 25%)",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.ON_KILL,
			[{effect_type = AbilityData.EffectType.UNLIMITED_POWER, value = 0.01}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.UNLIMITED_POWER, value = 0.01}],
			[{effect_type = AbilityData.EffectType.UNLIMITED_POWER, value = 0.02}],
			[{effect_type = AbilityData.EffectType.UNLIMITED_POWER, value = 0.03}]
		).with_rank_descriptions(
			"+1% permanent damage per kill (max 25%)",
			"+2% permanent damage per kill (max 40%)",
			"+3% permanent damage per kill (max 60%)"
		),

		# One With The Wind
		AbilityData.new(
			"wind_dancer",
			"One With The Wind",
			"30% reduced dodge cooldown, invisibility on dodge",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.WIND_DANCER, value = 0.3}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.WIND_DANCER, value = 0.3}],
			[{effect_type = AbilityData.EffectType.WIND_DANCER, value = 0.5}],
			[{effect_type = AbilityData.EffectType.WIND_DANCER, value = 0.7}]
		).with_rank_descriptions(
			"30% reduced dodge cooldown, invisibility on dodge",
			"50% reduced dodge cooldown, invisibility on dodge",
			"70% reduced dodge cooldown, invisibility on dodge"
		),

		# Empathic Bond (requires orbital or aura ability)
		AbilityData.new(
			"empathic_bond",
			"Empathic Bond",
			"Auras and orbitals have +50% effect",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.EMPATHIC_BOND, value = 1.5}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.EMPATHIC_BOND, value = 1.5}],
			[{effect_type = AbilityData.EffectType.EMPATHIC_BOND, value = 2.0}],
			[{effect_type = AbilityData.EffectType.EMPATHIC_BOND, value = 2.5}]
		).with_rank_descriptions(
			"Auras and orbitals have +50% effect",
			"Auras and orbitals have double effect",
			"Auras and orbitals have +150% effect"
		).with_prerequisites(["blade_orbit", "flame_orbit", "frost_orbit", "ring_of_fire", "toxic_cloud", "tesla_coil"] as Array[String]),

		# Fortune's Favor
		AbilityData.new(
			"fortune_favor",
			"Fortune's Favor",
			"Chance to get better loot (+15%)",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.FORTUNE_FAVOR, value = 0.15}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.FORTUNE_FAVOR, value = 0.15}],
			[{effect_type = AbilityData.EffectType.FORTUNE_FAVOR, value = 0.25}],
			[{effect_type = AbilityData.EffectType.FORTUNE_FAVOR, value = 0.40}]
		).with_rank_descriptions(
			"Chance to get better loot (+15%)",
			"Chance to get better loot (+25%)",
			"Chance to get better loot (+40%)"
		),
	]
