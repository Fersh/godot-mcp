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
			"A spectral sword orbits you, slashing enemies",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.SUMMON,
			[{effect_type = AbilityData.EffectType.BLADE_ORBIT, value = 1.0}]
		),

		# Flame Orbit - Fire damage orbital with burn
		AbilityData.new(
			"flame_orbit",
			"Flame Orbit",
			"A fireball orbits you, burning enemies on contact",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.SUMMON,
			[{effect_type = AbilityData.EffectType.FLAME_ORBIT, value = 1.0}]
		),

		# Frost Orbit - Ice orbital with slow
		AbilityData.new(
			"frost_orbit",
			"Frost Orbit",
			"An ice shard orbits you, chilling and slowing enemies",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.SUMMON,
			[{effect_type = AbilityData.EffectType.FROST_ORBIT, value = 1.0}]
		),

		# ============================================
		# ORBITAL ENHANCEMENTS
		# ============================================

		# Orbital Amplifier - +1 to random orbital
		AbilityData.new(
			"orbital_amplifier",
			"Orbital Amplifier",
			"+1 to a random orbital type you have",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.ORBITAL_AMPLIFIER, value = 1.0}]
		),

		# Orbital Mastery - +1 to ALL orbitals
		AbilityData.new(
			"orbital_mastery",
			"Orbital Mastery",
			"+1 to ALL orbital types",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.ORBITAL_MASTERY, value = 1.0}]
		),
	]
