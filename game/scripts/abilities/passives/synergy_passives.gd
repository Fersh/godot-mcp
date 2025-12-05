extends Node
class_name SynergyPassives

# Synergy passive abilities
# Enhance existing mechanics and create combo potential

static func get_abilities() -> Array[AbilityData]:
	return [
		# ============================================
		# KILL STREAK ENHANCEMENTS
		# ============================================

		# Momentum Master - Kill streaks last longer (requires any kill streak ability)
		AbilityData.new(
			"momentum_master",
			"Momentum Master",
			"Kill streak timers last 30% longer",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.MOMENTUM_MASTER, value = 0.3}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.MOMENTUM_MASTER, value = 0.3}],
			[{effect_type = AbilityData.EffectType.MOMENTUM_MASTER, value = 0.5}],
			[{effect_type = AbilityData.EffectType.MOMENTUM_MASTER, value = 0.75}]
		).with_rank_descriptions(
			"Kill streak timers last 30% longer",
			"Kill streak timers last 50% longer",
			"Kill streak timers last 75% longer"
		).with_prerequisites(["rampage", "killing_frenzy", "massacre"] as Array[String]),

		# ============================================
		# ACTIVE ABILITY SYNERGIES
		# ============================================

		# Ability Cascade - Chance to reset another ability
		AbilityData.new(
			"ability_cascade",
			"Ability Cascade",
			"Using an ability has 12% chance to reset another",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.ABILITY_CASCADE, value = 0.12}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.ABILITY_CASCADE, value = 0.12}],
			[{effect_type = AbilityData.EffectType.ABILITY_CASCADE, value = 0.20}],
			[{effect_type = AbilityData.EffectType.ABILITY_CASCADE, value = 0.30}]
		).with_rank_descriptions(
			"Using an ability has 12% chance to reset another",
			"Using an ability has 20% chance to reset another",
			"Using an ability has 30% chance to reset another"
		),

		# ============================================
		# ELEMENTAL ENHANCEMENTS
		# ============================================

		# Conductor - Lightning chains further (requires lightning ability)
		AbilityData.new(
			"conductor",
			"Conductor",
			"Lightning effects chain to +1 additional enemy",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.CONDUCTOR, value = 1.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.CONDUCTOR, value = 1.0}],
			[{effect_type = AbilityData.EffectType.CONDUCTOR, value = 2.0}],
			[{effect_type = AbilityData.EffectType.CONDUCTOR, value = 3.0}]
		).with_rank_descriptions(
			"Lightning effects chain to +1 additional enemy",
			"Lightning effects chain to +2 additional enemies",
			"Lightning effects chain to +3 additional enemies"
		).with_prerequisites(["lightning_strike_proc", "static_charge"] as Array[String]),

		# ============================================
		# KILL EFFECTS
		# ============================================

		# Blood Trail - Kills leave damaging pools
		AbilityData.new(
			"blood_trail",
			"Blood Trail",
			"Kills leave damaging blood pools for 1.5s",
			AbilityData.Rarity.RARE,
			AbilityData.Type.ON_KILL,
			[{effect_type = AbilityData.EffectType.BLOOD_TRAIL, value = 1.5}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.BLOOD_TRAIL, value = 1.5}],
			[{effect_type = AbilityData.EffectType.BLOOD_TRAIL, value = 2.0}],
			[{effect_type = AbilityData.EffectType.BLOOD_TRAIL, value = 3.0}]
		).with_rank_descriptions(
			"Kills leave damaging blood pools for 1.5s",
			"Kills leave damaging blood pools for 2s",
			"Kills leave damaging blood pools for 3s"
		),
	]
