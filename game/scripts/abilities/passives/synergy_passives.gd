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
			"Kill streak timers last 50% longer",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.MOMENTUM_MASTER, value = 0.5}]
		).with_prerequisites(["rampage", "killing_frenzy", "massacre"] as Array[String]),

		# ============================================
		# ACTIVE ABILITY SYNERGIES
		# ============================================

		# Ability Cascade - Chance to reset another ability
		AbilityData.new(
			"ability_cascade",
			"Ability Cascade",
			"Using an ability has 20% chance to reset another",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.ABILITY_CASCADE, value = 0.20}]
		),

		# ============================================
		# ELEMENTAL ENHANCEMENTS
		# ============================================

		# Conductor - Lightning chains further (requires lightning ability)
		AbilityData.new(
			"conductor",
			"Conductor",
			"Lightning effects chain to +2 additional enemies",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.CONDUCTOR, value = 2.0}]
		).with_prerequisites(["lightning_strike_proc", "static_charge"] as Array[String]),

		# ============================================
		# KILL EFFECTS
		# ============================================

		# Blood Trail - Kills leave damaging pools
		AbilityData.new(
			"blood_trail",
			"Blood Trail",
			"Kills leave damaging blood pools for 2s",
			AbilityData.Rarity.RARE,
			AbilityData.Type.ON_KILL,
			[{effect_type = AbilityData.EffectType.BLOOD_TRAIL, value = 2.0}]
		),
	]
