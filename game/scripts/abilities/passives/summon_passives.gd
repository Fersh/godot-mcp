extends Node
class_name SummonPassives

# Summon passive abilities
# Different summon types and enhancements for summoner builds

static func get_abilities() -> Array[AbilityData]:
	return [
		# ============================================
		# SUMMON TYPES
		# ============================================

		# Chicken Companion - A chicken that pecks enemies
		AbilityData.new(
			"chicken_companion",
			"Chicken Companion",
			"Summon 1 angry chicken that pecks enemies",
			AbilityData.Rarity.RARE,
			AbilityData.Type.SUMMON,
			[{effect_type = AbilityData.EffectType.CHICKEN_SUMMON, value = 1.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.CHICKEN_SUMMON, value = 1.0}],
			[{effect_type = AbilityData.EffectType.CHICKEN_SUMMON, value = 2.0}],
			[{effect_type = AbilityData.EffectType.CHICKEN_SUMMON, value = 3.0}]
		).with_rank_descriptions(
			"Summon 1 angry chicken that pecks enemies",
			"Summon 2 angry chickens that peck enemies",
			"Summon 3 angry chickens that peck enemies"
		),

		# ============================================
		# SUMMON ENHANCEMENTS
		# ============================================

		# Pack Leader - Summons deal more damage (requires any summon)
		AbilityData.new(
			"pack_leader",
			"Pack Leader",
			"All summons deal +15% damage",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.SUMMON_DAMAGE, value = 0.15}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.SUMMON_DAMAGE, value = 0.15}],
			[{effect_type = AbilityData.EffectType.SUMMON_DAMAGE, value = 0.25}],
			[{effect_type = AbilityData.EffectType.SUMMON_DAMAGE, value = 0.40}]
		).with_rank_descriptions(
			"All summons deal +15% damage",
			"All summons deal +25% damage",
			"All summons deal +40% damage"
		).with_prerequisites(["chicken_companion", "summoner_aid", "blade_orbit", "flame_orbit", "frost_orbit"] as Array[String]),
	]
