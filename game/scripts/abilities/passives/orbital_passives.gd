extends Node
class_name OrbitalPassives

# Orbital passive abilities
# Different orbital types and enhancements for orbital builds

static func get_abilities() -> Array[AbilityData]:
	return [
		# ============================================
		# NEW ORBITAL TYPES
		# ============================================

		# Blade Orbit - Melee damage orbital
		AbilityData.new(
			"blade_orbit",
			"Blade Orbit",
			"1 spectral sword orbits you, slashing enemies",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.SUMMON,
			[{effect_type = AbilityData.EffectType.BLADE_ORBIT, value = 1.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.BLADE_ORBIT, value = 1.0}],
			[{effect_type = AbilityData.EffectType.BLADE_ORBIT, value = 2.0}],
			[{effect_type = AbilityData.EffectType.BLADE_ORBIT, value = 3.0}]
		).with_rank_descriptions(
			"1 spectral sword orbits you, slashing enemies",
			"2 spectral swords orbit you, slashing enemies",
			"3 spectral swords orbit you, slashing enemies"
		),

		# Flame Orbit - Fire damage orbital with burn
		AbilityData.new(
			"flame_orbit",
			"Flame Orbit",
			"1 fireball orbits you, burning enemies on contact",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.SUMMON,
			[{effect_type = AbilityData.EffectType.FLAME_ORBIT, value = 1.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.FLAME_ORBIT, value = 1.0}],
			[{effect_type = AbilityData.EffectType.FLAME_ORBIT, value = 2.0}],
			[{effect_type = AbilityData.EffectType.FLAME_ORBIT, value = 3.0}]
		).with_rank_descriptions(
			"1 fireball orbits you, burning enemies on contact",
			"2 fireballs orbit you, burning enemies on contact",
			"3 fireballs orbit you, burning enemies on contact"
		),

		# Frost Orbit - Ice orbital with slow
		AbilityData.new(
			"frost_orbit",
			"Frost Orbit",
			"1 ice shard orbits you, chilling and slowing enemies",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.SUMMON,
			[{effect_type = AbilityData.EffectType.FROST_ORBIT, value = 1.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.FROST_ORBIT, value = 1.0}],
			[{effect_type = AbilityData.EffectType.FROST_ORBIT, value = 2.0}],
			[{effect_type = AbilityData.EffectType.FROST_ORBIT, value = 3.0}]
		).with_rank_descriptions(
			"1 ice shard orbits you, chilling and slowing enemies",
			"2 ice shards orbit you, chilling and slowing enemies",
			"3 ice shards orbit you, chilling and slowing enemies"
		),

		# ============================================
		# ORBITAL ENHANCEMENTS
		# ============================================

		# Orbital Amplifier - +1 to random orbital (requires any orbital)
		AbilityData.new(
			"orbital_amplifier",
			"Orbital Amplifier",
			"+1 to a random orbital type you have",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.ORBITAL_AMPLIFIER, value = 1.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.ORBITAL_AMPLIFIER, value = 1.0}],
			[{effect_type = AbilityData.EffectType.ORBITAL_AMPLIFIER, value = 2.0}],
			[{effect_type = AbilityData.EffectType.ORBITAL_AMPLIFIER, value = 3.0}]
		).with_rank_descriptions(
			"+1 to a random orbital type you have",
			"+2 to a random orbital type you have",
			"+3 to a random orbital type you have"
		).with_prerequisites(["blade_orbit", "flame_orbit", "frost_orbit"] as Array[String]),

		# Orbital Mastery - +1 to ALL orbitals (requires Orbital Amplifier)
		AbilityData.new(
			"orbital_mastery",
			"Orbital Mastery",
			"+1 to ALL orbital types",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.ORBITAL_MASTERY, value = 1.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.ORBITAL_MASTERY, value = 1.0}],
			[{effect_type = AbilityData.EffectType.ORBITAL_MASTERY, value = 2.0}],
			[{effect_type = AbilityData.EffectType.ORBITAL_MASTERY, value = 3.0}]
		).with_rank_descriptions(
			"+1 to ALL orbital types",
			"+2 to ALL orbital types",
			"+3 to ALL orbital types"
		).with_prerequisites(["orbital_amplifier"] as Array[String]),
	]
