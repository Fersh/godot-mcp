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
			"+15% Move Speed, -1 Armor",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.STAT_BOOST,
			[
				{effect_type = AbilityData.EffectType.MOVE_SPEED, value = 0.15},
				{effect_type = AbilityData.EffectType.ARMOR, value = -1.0}
			]
		).with_rank_effects(
			[
				{effect_type = AbilityData.EffectType.MOVE_SPEED, value = 0.15},
				{effect_type = AbilityData.EffectType.ARMOR, value = -1.0}
			],
			[
				{effect_type = AbilityData.EffectType.MOVE_SPEED, value = 0.20},
				{effect_type = AbilityData.EffectType.ARMOR, value = -1.5}
			],
			[
				{effect_type = AbilityData.EffectType.MOVE_SPEED, value = 0.30},
				{effect_type = AbilityData.EffectType.ARMOR, value = -2.0}
			]
		).with_rank_descriptions(
			"+15% Move Speed, -1 Armor",
			"+20% Move Speed, -1.5 Armor",
			"+30% Move Speed, -2 Armor"
		),

		# Guardian's Heart
		AbilityData.new(
			"guardian_heart",
			"Guardian's Heart",
			"+15% healing received",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.GUARDIAN_HEART, value = 0.15}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.GUARDIAN_HEART, value = 0.15}],
			[{effect_type = AbilityData.EffectType.GUARDIAN_HEART, value = 0.25}],
			[{effect_type = AbilityData.EffectType.GUARDIAN_HEART, value = 0.40}]
		).with_rank_descriptions(
			"+15% healing received",
			"+25% healing received",
			"+40% healing received"
		),

		# Overheal Shield
		AbilityData.new(
			"overheal_shield",
			"Overheal Shield",
			"Excess healing becomes shield (max 15% HP)",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.OVERHEAL_SHIELD, value = 0.15}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.OVERHEAL_SHIELD, value = 0.15}],
			[{effect_type = AbilityData.EffectType.OVERHEAL_SHIELD, value = 0.20}],
			[{effect_type = AbilityData.EffectType.OVERHEAL_SHIELD, value = 0.30}]
		).with_rank_descriptions(
			"Excess healing becomes shield (max 15% HP)",
			"Excess healing becomes shield (max 20% HP)",
			"Excess healing becomes shield (max 30% HP)"
		),

		# Mirror Image
		AbilityData.new(
			"mirror_image",
			"Mirror Image",
			"3% chance to spawn a decoy when hit",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.MIRROR_IMAGE, value = 0.03}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.MIRROR_IMAGE, value = 0.03}],
			[{effect_type = AbilityData.EffectType.MIRROR_IMAGE, value = 0.05}],
			[{effect_type = AbilityData.EffectType.MIRROR_IMAGE, value = 0.08}]
		).with_rank_descriptions(
			"3% chance to spawn a decoy when hit",
			"5% chance to spawn a decoy when hit",
			"8% chance to spawn a decoy when hit"
		),

		# Battle Medic
		AbilityData.new(
			"battle_medic",
			"Battle Medic",
			"Health pickups trigger a heal nova (3 healing)",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.BATTLE_MEDIC, value = 3.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.BATTLE_MEDIC, value = 3.0}],
			[{effect_type = AbilityData.EffectType.BATTLE_MEDIC, value = 5.0}],
			[{effect_type = AbilityData.EffectType.BATTLE_MEDIC, value = 8.0}]
		).with_rank_descriptions(
			"Health pickups trigger a heal nova (3 healing)",
			"Health pickups trigger a heal nova (5 healing)",
			"Health pickups trigger a heal nova (8 healing)"
		),

		# Mirror Shield (Legendary)
		AbilityData.new(
			"mirror_shield",
			"Mirror Shield",
			"Reflect a projectile every 7 seconds",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.MIRROR_SHIELD, value = 7.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.MIRROR_SHIELD, value = 7.0}],
			[{effect_type = AbilityData.EffectType.MIRROR_SHIELD, value = 5.0}],
			[{effect_type = AbilityData.EffectType.MIRROR_SHIELD, value = 3.0}]
		).with_rank_descriptions(
			"Reflect a projectile every 7 seconds",
			"Reflect a projectile every 5 seconds",
			"Reflect a projectile every 3 seconds"
		),

		# Thundershock (Legendary)
		AbilityData.new(
			"thundershock",
			"Thundershock",
			"Taking damage strikes nearby enemies (15 damage)",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.THUNDERSHOCK, value = 15.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.THUNDERSHOCK, value = 15.0}],
			[{effect_type = AbilityData.EffectType.THUNDERSHOCK, value = 25.0}],
			[{effect_type = AbilityData.EffectType.THUNDERSHOCK, value = 40.0}]
		).with_rank_descriptions(
			"Taking damage strikes nearby enemies (15 damage)",
			"Taking damage strikes nearby enemies (25 damage)",
			"Taking damage strikes nearby enemies (40 damage)"
		),
	]
