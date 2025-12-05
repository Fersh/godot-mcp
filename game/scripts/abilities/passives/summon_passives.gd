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
			"Summon an angry chicken that pecks enemies",
			AbilityData.Rarity.RARE,
			AbilityData.Type.SUMMON,
			[{effect_type = AbilityData.EffectType.CHICKEN_SUMMON, value = 1.0}]
		),

		# ============================================
		# SUMMON ENHANCEMENTS
		# ============================================

		# Pack Leader - Summons deal more damage (requires any summon)
		AbilityData.new(
			"pack_leader",
			"Pack Leader",
			"All summons deal +25% damage",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.SUMMON_DAMAGE, value = 0.25}]
		).with_prerequisites(["chicken_companion", "summoner_aid", "blade_orbit", "flame_orbit", "frost_orbit"] as Array[String]),
	]
