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
			"Auto attacks call lightning",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.LIGHTNING_PROC, value = 1.0}]
		),

		# Ignite (On-Hit)
		AbilityData.new(
			"ignite",
			"Ignite",
			"Auto attacks burn for 5% max HP",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.IGNITE, value = 1.0}]
		),

		# Frostbite (On-Hit) - Changed to Chill
		AbilityData.new(
			"frostbite",
			"Frostbite",
			"Auto attacks chill, slowing enemies",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.FROSTBITE, value = 1.0}]
		),

		# Toxic Tip (On-Hit)
		AbilityData.new(
			"toxic_tip",
			"Toxic Tip",
			"Auto attacks poison for 50 damage over 5s",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.TOXIC_TIP, value = 1.0}]
		),

		# Chaotic Strikes
		AbilityData.new(
			"chaotic_strikes",
			"Chaotic Strikes",
			"Auto attacks deal random elemental damage",
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
