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
			"+20% Attack Speed for first 2 minutes",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.WARMUP, value = 0.2}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.WARMUP, value = 0.2}],
			[{effect_type = AbilityData.EffectType.WARMUP, value = 0.3}],
			[{effect_type = AbilityData.EffectType.WARMUP, value = 0.45}]
		).with_rank_descriptions(
			"+20% Attack Speed for first 2 minutes",
			"+30% Attack Speed for first 2 minutes",
			"+45% Attack Speed for first 2 minutes"
		),

		# Practiced Stance
		AbilityData.new(
			"practiced_stance",
			"Practiced Stance",
			"+10% damage when standing still",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.PRACTICED_STANCE, value = 0.10}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.PRACTICED_STANCE, value = 0.10}],
			[{effect_type = AbilityData.EffectType.PRACTICED_STANCE, value = 0.15}],
			[{effect_type = AbilityData.EffectType.PRACTICED_STANCE, value = 0.25}]
		).with_rank_descriptions(
			"+10% damage when standing still",
			"+15% damage when standing still",
			"+25% damage when standing still"
		),

		# Early Bird
		AbilityData.new(
			"early_bird",
			"Early Bird",
			"+30% XP first half of run, -30% second half",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.EARLY_BIRD, value = 0.3}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.EARLY_BIRD, value = 0.3}],
			[{effect_type = AbilityData.EffectType.EARLY_BIRD, value = 0.5}],
			[{effect_type = AbilityData.EffectType.EARLY_BIRD, value = 0.75}]
		).with_rank_descriptions(
			"+30% XP first half of run, -30% second half",
			"+50% XP first half of run, -50% second half",
			"+75% XP first half of run, -75% second half"
		),
	]
