extends Node
class_name ElementalPassives

# Elemental on-hit passive abilities
# These add status effects and elemental damage to attacks

static func get_abilities() -> Array[AbilityData]:
	return [
		# Lightning Strike (On-Hit)
		AbilityData.new(
			"lightning_strike_proc",
			"Lightning Strike",
			"20% chance to call lightning on hit",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.LIGHTNING_PROC, value = 0.2}]
		),

		# Ignite (On-Hit)
		AbilityData.new(
			"ignite",
			"Ignite",
			"30% chance to burn enemies for 5% max HP",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.IGNITE, value = 0.3}]
		),

		# Frostbite (On-Hit)
		AbilityData.new(
			"frostbite",
			"Frostbite",
			"20% chance to freeze enemies briefly",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.FROSTBITE, value = 0.2}]
		),

		# Toxic Tip (On-Hit)
		AbilityData.new(
			"toxic_tip",
			"Toxic Tip",
			"30% chance to poison for 50 damage over 5s",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.TOXIC_TIP, value = 0.3}]
		),

		# Chaotic Strikes
		AbilityData.new(
			"chaotic_strikes",
			"Chaotic Strikes",
			"Attacks deal random elemental damage",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.CHAOTIC_STRIKES, value = 0.1}]
		),

		# Static Charge
		AbilityData.new(
			"static_charge",
			"Static Charge",
			"Every 5 seconds, stun next enemy hit",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.STATIC_CHARGE, value = 5.0}]
		),

		# Chain Reaction (Legendary)
		AbilityData.new(
			"chain_reaction",
			"Chain Reaction",
			"Status effects spread to 2 nearby enemies on kill",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.CHAIN_REACTION, value = 2.0}]
		),
	]
