extends Node
class_name CombatPassives

# Combat-focused passive abilities
# On-hit triggers, momentum mechanics, and conditional damage boosts

static func get_abilities() -> Array[AbilityData]:
	return [
		# Berserker's Fury
		AbilityData.new(
			"berserker_fury",
			"Berserker's Fury",
			"+5% damage when hit (stacks to 25%)",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.BERSERKER_FURY, value = 0.05}]
		),

		# Combat Momentum
		AbilityData.new(
			"combat_momentum",
			"Combat Momentum",
			"+5% damage per hit on same target (max 25%)",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.COMBAT_MOMENTUM, value = 0.05}]
		),

		# Executioner
		AbilityData.new(
			"executioner",
			"Executioner",
			"+50% damage to enemies below 30% HP",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.EXECUTIONER, value = 0.5}]
		),

		# Vengeance
		AbilityData.new(
			"vengeance",
			"Vengeance",
			"After taking damage, next attack deals +100%",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.VENGEANCE, value = 1.0}]
		),

		# Last Resort
		AbilityData.new(
			"last_resort",
			"Last Resort",
			"+50% damage when at critical HP",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.LAST_RESORT, value = 0.5}]
		),

		# Horde Breaker
		AbilityData.new(
			"horde_breaker",
			"Horde Breaker",
			"+1% damage per nearby enemy (max 20%)",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.HORDE_BREAKER, value = 0.01}]
		),

		# Arcane Absorption
		AbilityData.new(
			"arcane_absorption",
			"Arcane Absorption",
			"Kills reduce ability cooldowns by 0.5s",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.ARCANE_ABSORPTION, value = 0.5}]
		),

		# Adrenaline Rush (Melee)
		AbilityData.new(
			"adrenaline_rush",
			"Adrenaline Rush",
			"35% chance to dash on hit",
			AbilityData.Rarity.RARE,
			AbilityData.Type.MELEE_ONLY,
			[{effect_type = AbilityData.EffectType.ADRENALINE_RUSH, value = 0.35}]
		),

		# Phalanx (Melee)
		AbilityData.new(
			"phalanx",
			"Phalanx",
			"15% chance to block frontal projectiles",
			AbilityData.Rarity.RARE,
			AbilityData.Type.MELEE_ONLY,
			[{effect_type = AbilityData.EffectType.PHALANX, value = 0.15}]
		),

		# Homing Instinct (Ranged)
		AbilityData.new(
			"homing_instinct",
			"Homing Instinct",
			"Projectiles curve toward enemies",
			AbilityData.Rarity.RARE,
			AbilityData.Type.RANGED_ONLY,
			[{effect_type = AbilityData.EffectType.HOMING, value = 1.0}]
		),

		# Kill Streak Passives
		AbilityData.new(
			"rampage",
			"Rampage",
			"+3% damage per kill, resets after 4s",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.RAMPAGE, value = 0.03}]
		),

		AbilityData.new(
			"killing_frenzy",
			"Killing Frenzy",
			"+5% attack speed per kill, resets after 4s",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.KILLING_FRENZY, value = 0.05}]
		),

		AbilityData.new(
			"massacre",
			"Massacre",
			"+2% damage and speed per kill, resets after 3s",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.MASSACRE, value = 0.02}]
		),

		AbilityData.new(
			"cooldown_killer",
			"Cooldown Killer",
			"Kills reduce active ability cooldowns by 1s",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.COOLDOWN_KILLER, value = 1.0}]
		),
	]
