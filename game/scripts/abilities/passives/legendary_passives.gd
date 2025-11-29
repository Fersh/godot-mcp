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
			"Kills fire 2 homing daggers at enemies",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.ON_KILL,
			[{effect_type = AbilityData.EffectType.CEREMONIAL_DAGGER, value = 2.0}]
		),

		# Missile Barrage
		AbilityData.new(
			"missile_barrage",
			"Missile Barrage",
			"25% chance to fire homing missiles",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.MISSILE_BARRAGE, value = 0.25}]
		),

		# Soul Reaper
		AbilityData.new(
			"soul_reaper",
			"Soul Reaper",
			"Kills heal 5% HP and grant stacking damage",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.ON_KILL,
			[{effect_type = AbilityData.EffectType.SOUL_REAPER, value = 0.05}]
		),

		# Summoner's Aid
		AbilityData.new(
			"summoner_aid",
			"Summoner's Aid",
			"Summon a skeleton every 10 seconds",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.SUMMON,
			[{effect_type = AbilityData.EffectType.SUMMONER, value = 10.0}]
		),

		# Mind Control
		AbilityData.new(
			"mind_control",
			"Mind Control",
			"5% chance to charm enemies on hit",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.MIND_CONTROL, value = 0.05}]
		),

		# Blood Debt
		AbilityData.new(
			"blood_debt",
			"Blood Debt",
			"+50% damage, take 10% of damage dealt",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.BLOOD_DEBT, value = 0.5}]
		),

		# Chrono Trigger
		AbilityData.new(
			"chrono_trigger",
			"Chrono Trigger",
			"Freeze all enemies for 1s every 10s",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PERIODIC,
			[{effect_type = AbilityData.EffectType.CHRONO_TRIGGER, value = 10.0}]
		),

		# Unlimited Power
		AbilityData.new(
			"unlimited_power",
			"Unlimited Power",
			"+2% permanent damage per kill (max 40%)",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.ON_KILL,
			[{effect_type = AbilityData.EffectType.UNLIMITED_POWER, value = 0.02}]
		),

		# One With The Wind
		AbilityData.new(
			"wind_dancer",
			"One With The Wind",
			"50% reduced dodge cooldown, invisibility on dodge",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.WIND_DANCER, value = 0.5}]
		),

		# Empathic Bond
		AbilityData.new(
			"empathic_bond",
			"Empathic Bond",
			"Auras and orbitals have double effect",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.EMPATHIC_BOND, value = 2.0}]
		),

		# Fortune's Favor
		AbilityData.new(
			"fortune_favor",
			"Fortune's Favor",
			"Chance to get better loot (+25%)",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.FORTUNE_FAVOR, value = 0.25}]
		),
	]
