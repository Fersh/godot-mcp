extends Node
class_name ConditionalPassives

# Conditional and trade-off passive abilities
# Time-based, position-based, and situational effects

static func get_abilities() -> Array[AbilityData]:
	return [
		# Warmup
		AbilityData.new(
			"warmup",
			"Warmup",
			"+30% Attack Speed for first 2 minutes",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.WARMUP, value = 0.3}]
		),

		# Practiced Stance
		AbilityData.new(
			"practiced_stance",
			"Practiced Stance",
			"+15% damage when standing still",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.PRACTICED_STANCE, value = 0.15}]
		),

		# Early Bird
		AbilityData.new(
			"early_bird",
			"Early Bird",
			"+50% XP first half of run, -50% second half",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.EARLY_BIRD, value = 0.5}]
		),
	]
