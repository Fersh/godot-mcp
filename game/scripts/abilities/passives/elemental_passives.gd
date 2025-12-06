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
			"Auto attacks call weak lightning",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.LIGHTNING_PROC, value = 0.5}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.LIGHTNING_PROC, value = 0.5}],
			[{effect_type = AbilityData.EffectType.LIGHTNING_PROC, value = 0.75}],
			[{effect_type = AbilityData.EffectType.LIGHTNING_PROC, value = 1.0}]
		).with_rank_descriptions(
			"Auto attacks call weak lightning",
			"Auto attacks call moderate lightning",
			"Auto attacks call powerful lightning"
		),

		# Ignite (On-Hit)
		AbilityData.new(
			"ignite",
			"Ignite",
			"Auto attacks burn for 3% max HP",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.IGNITE, value = 0.5}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.IGNITE, value = 0.5}],
			[{effect_type = AbilityData.EffectType.IGNITE, value = 0.75}],
			[{effect_type = AbilityData.EffectType.IGNITE, value = 1.0}]
		).with_rank_descriptions(
			"Auto attacks burn for 3% max HP",
			"Auto attacks burn for 5% max HP",
			"Auto attacks burn for 7% max HP"
		),

		# Frostbite (On-Hit) - Changed to Chill
		AbilityData.new(
			"frostbite",
			"Frostbite",
			"Auto attacks chill, slightly slowing enemies",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.FROSTBITE, value = 0.5}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.FROSTBITE, value = 0.5}],
			[{effect_type = AbilityData.EffectType.FROSTBITE, value = 0.75}],
			[{effect_type = AbilityData.EffectType.FROSTBITE, value = 1.0}]
		).with_rank_descriptions(
			"Auto attacks chill, slightly slowing enemies",
			"Auto attacks chill, moderately slowing enemies",
			"Auto attacks freeze, greatly slowing enemies"
		),

		# Toxic Tip (On-Hit)
		AbilityData.new(
			"toxic_tip",
			"Toxic Tip",
			"Auto attacks poison for 30 damage over 5s",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.TOXIC_TIP, value = 0.5}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.TOXIC_TIP, value = 0.5}],
			[{effect_type = AbilityData.EffectType.TOXIC_TIP, value = 0.75}],
			[{effect_type = AbilityData.EffectType.TOXIC_TIP, value = 1.0}]
		).with_rank_descriptions(
			"Auto attacks poison for 30 damage over 5s",
			"Auto attacks poison for 50 damage over 5s",
			"Auto attacks poison for 75 damage over 5s"
		),

		# Chaotic Strikes
		AbilityData.new(
			"chaotic_strikes",
			"Chaotic Strikes",
			"Auto attacks have 8% chance for random elemental damage",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.CHAOTIC_STRIKES, value = 0.08}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.CHAOTIC_STRIKES, value = 0.08}],
			[{effect_type = AbilityData.EffectType.CHAOTIC_STRIKES, value = 0.12}],
			[{effect_type = AbilityData.EffectType.CHAOTIC_STRIKES, value = 0.18}]
		).with_rank_descriptions(
			"Auto attacks have 8% chance for random elemental damage",
			"Auto attacks have 12% chance for random elemental damage",
			"Auto attacks have 18% chance for random elemental damage"
		),

		# Static Charge
		AbilityData.new(
			"static_charge",
			"Static Charge",
			"Every 7 seconds, stun next enemy hit",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.STATIC_CHARGE, value = 7.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.STATIC_CHARGE, value = 7.0}],
			[{effect_type = AbilityData.EffectType.STATIC_CHARGE, value = 5.0}],
			[{effect_type = AbilityData.EffectType.STATIC_CHARGE, value = 3.0}]
		).with_rank_descriptions(
			"Every 7 seconds, stun next enemy hit",
			"Every 5 seconds, stun next enemy hit",
			"Every 3 seconds, stun next enemy hit"
		),

		# Chain Reaction (requires any elemental effect)
		AbilityData.new(
			"chain_reaction",
			"Chain Reaction",
			"Burn, poison, and freeze spread to 1 nearby enemy on kill",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.CHAIN_REACTION, value = 1.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.CHAIN_REACTION, value = 1.0}],
			[{effect_type = AbilityData.EffectType.CHAIN_REACTION, value = 2.0}],
			[{effect_type = AbilityData.EffectType.CHAIN_REACTION, value = 3.0}]
		).with_rank_descriptions(
			"Burn, poison, and freeze spread to 1 nearby enemy on kill",
			"Burn, poison, and freeze spread to 2 nearby enemies on kill",
			"Burn, poison, and freeze spread to 3 nearby enemies on kill"
		).with_prerequisites(["ignite", "frostbite", "toxic_tip", "lightning_strike_proc", "static_charge", "chaotic_strikes"] as Array[String]),
	]
