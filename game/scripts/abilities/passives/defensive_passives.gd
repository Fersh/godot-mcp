extends Node
class_name DefensivePassives

# Defensive and survival passive abilities
# Shields, healing boosts, damage mitigation

static func get_abilities() -> Array[AbilityData]:
	return [
		# Fleet Footed (trade-off)
		AbilityData.new(
			"fleet_footed",
			"Fleet Footed",
			"+20% Move Speed, -2 Armor",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.STAT_BOOST,
			[
				{effect_type = AbilityData.EffectType.MOVE_SPEED, value = 0.2},
				{effect_type = AbilityData.EffectType.ARMOR, value = -2.0}
			]
		),

		# Guardian's Heart
		AbilityData.new(
			"guardian_heart",
			"Guardian's Heart",
			"+50% healing received",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.GUARDIAN_HEART, value = 0.5}]
		),

		# Overheal Shield
		AbilityData.new(
			"overheal_shield",
			"Overheal Shield",
			"Excess healing becomes shield (max 20% HP)",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.OVERHEAL_SHIELD, value = 0.2}]
		),

		# Mirror Image
		AbilityData.new(
			"mirror_image",
			"Mirror Image",
			"5% chance to spawn a decoy when hit",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.MIRROR_IMAGE, value = 0.05}]
		),

		# Battle Medic
		AbilityData.new(
			"battle_medic",
			"Battle Medic",
			"Health pickups trigger a heal nova",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.BATTLE_MEDIC, value = 5.0}]
		),

		# Mirror Shield (Legendary)
		AbilityData.new(
			"mirror_shield",
			"Mirror Shield",
			"Reflect a projectile every 5 seconds",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.MIRROR_SHIELD, value = 5.0}]
		),

		# Thundershock (Legendary)
		AbilityData.new(
			"thundershock",
			"Thundershock",
			"Taking damage strikes nearby enemies",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.THUNDERSHOCK, value = 25.0}]
		),
	]
