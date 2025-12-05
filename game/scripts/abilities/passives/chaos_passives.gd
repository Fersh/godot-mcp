extends Node
class_name ChaosPassives

# Chaos, Zone, Trail, and Fun passive abilities
# These are the wacky, game-changing, and entertaining passives

static func get_abilities() -> Array[AbilityData]:
	var abilities: Array[AbilityData] = [
		# ============================================
		# ZONE & TRAIL PASSIVES
		# ============================================

		# Blazing Trail - Leave fire behind you
		AbilityData.new(
			"blazing_trail",
			"Blazing Trail",
			"Leave a trail of fire behind you (3 damage per tick)",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.BLAZING_TRAIL, value = 3.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.BLAZING_TRAIL, value = 3.0}],
			[{effect_type = AbilityData.EffectType.BLAZING_TRAIL, value = 5.0}],
			[{effect_type = AbilityData.EffectType.BLAZING_TRAIL, value = 8.0}]
		).with_rank_descriptions(
			"Leave a trail of fire behind you (3 damage per tick)",
			"Leave a trail of fire behind you (5 damage per tick)",
			"Leave a trail of fire behind you (8 damage per tick)"
		),

		# Toxic Traits - Leave poison pools
		AbilityData.new(
			"toxic_traits",
			"Toxic Traits",
			"Leave pools of poison where you walk (2 damage per tick)",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.TOXIC_TRAITS, value = 2.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.TOXIC_TRAITS, value = 2.0}],
			[{effect_type = AbilityData.EffectType.TOXIC_TRAITS, value = 3.0}],
			[{effect_type = AbilityData.EffectType.TOXIC_TRAITS, value = 5.0}]
		).with_rank_descriptions(
			"Leave pools of poison where you walk (2 damage per tick)",
			"Leave pools of poison where you walk (3 damage per tick)",
			"Leave pools of poison where you walk (5 damage per tick)"
		),

		# Surprise Mechanics - Drop mines when hit
		AbilityData.new(
			"surprise_mechanics",
			"Surprise Mechanics",
			"10% chance when hit to drop a proximity mine.",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.SURPRISE_MECHANICS, value = 0.10}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.SURPRISE_MECHANICS, value = 0.10}],
			[{effect_type = AbilityData.EffectType.SURPRISE_MECHANICS, value = 0.15}],
			[{effect_type = AbilityData.EffectType.SURPRISE_MECHANICS, value = 0.25}]
		).with_rank_descriptions(
			"10% chance when hit to drop a proximity mine.",
			"15% chance when hit to drop a proximity mine.",
			"25% chance when hit to drop a proximity mine."
		),

		# Sore Loser - Enemies drop traps on death
		AbilityData.new(
			"sore_loser",
			"Sore Loser",
			"Enemies have 15% chance to drop a damaging trap on death.",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.ON_KILL,
			[{effect_type = AbilityData.EffectType.SORE_LOSER, value = 0.15}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.SORE_LOSER, value = 0.15}],
			[{effect_type = AbilityData.EffectType.SORE_LOSER, value = 0.25}],
			[{effect_type = AbilityData.EffectType.SORE_LOSER, value = 0.35}]
		).with_rank_descriptions(
			"Enemies have 15% chance to drop a damaging trap on death.",
			"Enemies have 25% chance to drop a damaging trap on death.",
			"Enemies have 35% chance to drop a damaging trap on death."
		),

		# ============================================
		# STEALTH PASSIVES
		# ============================================

		# Wallflower - Invisible while still
		AbilityData.new(
			"wallflower",
			"Wallflower",
			"Standing still for 3 seconds makes you invisible.",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.WALLFLOWER, value = 3.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.WALLFLOWER, value = 3.0}],
			[{effect_type = AbilityData.EffectType.WALLFLOWER, value = 2.0}],
			[{effect_type = AbilityData.EffectType.WALLFLOWER, value = 1.0}]
		).with_rank_descriptions(
			"Standing still for 3 seconds makes you invisible.",
			"Standing still for 2 seconds makes you invisible.",
			"Standing still for 1 second makes you invisible."
		),

		# ============================================
		# CHAOS PASSIVES
		# ============================================

		# Friendly Fire - Enemy damage hurts enemies
		AbilityData.new(
			"friendly_fire",
			"Friendly Fire",
			"5% of damage enemies deal hurts other enemies too.",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.FRIENDLY_FIRE, value = 0.05}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.FRIENDLY_FIRE, value = 0.05}],
			[{effect_type = AbilityData.EffectType.FRIENDLY_FIRE, value = 0.10}],
			[{effect_type = AbilityData.EffectType.FRIENDLY_FIRE, value = 0.15}]
		).with_rank_descriptions(
			"5% of damage enemies deal hurts other enemies too.",
			"10% of damage enemies deal hurts other enemies too.",
			"15% of damage enemies deal hurts other enemies too."
		),

		# Built Different - Random stat boost
		AbilityData.new(
			"built_different",
			"Built Different",
			"Gain a random stat boost every 45 seconds.",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.BUILT_DIFFERENT, value = 45.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.BUILT_DIFFERENT, value = 45.0}],
			[{effect_type = AbilityData.EffectType.BUILT_DIFFERENT, value = 30.0}],
			[{effect_type = AbilityData.EffectType.BUILT_DIFFERENT, value = 20.0}]
		).with_rank_descriptions(
			"Gain a random stat boost every 45 seconds.",
			"Gain a random stat boost every 30 seconds.",
			"Gain a random stat boost every 20 seconds."
		),

		# Wombo Combo - Multi-source explosion
		AbilityData.new(
			"wombo_combo",
			"Wombo Combo",
			"Hitting with 3 damage sources in 1s triggers 15 damage explosion.",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.WOMBO_COMBO, value = 15.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.WOMBO_COMBO, value = 15.0}],
			[{effect_type = AbilityData.EffectType.WOMBO_COMBO, value = 25.0}],
			[{effect_type = AbilityData.EffectType.WOMBO_COMBO, value = 40.0}]
		).with_rank_descriptions(
			"Hitting with 3 damage sources in 1s triggers 15 damage explosion.",
			"Hitting with 3 damage sources in 1s triggers 25 damage explosion.",
			"Hitting with 3 damage sources in 1s triggers 40 damage explosion."
		),

		# 99 Stacks - Stackable status effects
		AbilityData.new(
			"ninety_nine_stacks",
			"99 Stacks",
			"Your status effects can stack up to 2x.",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.NINETY_NINE_STACKS, value = 2.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.NINETY_NINE_STACKS, value = 2.0}],
			[{effect_type = AbilityData.EffectType.NINETY_NINE_STACKS, value = 3.0}],
			[{effect_type = AbilityData.EffectType.NINETY_NINE_STACKS, value = 5.0}]
		).with_rank_descriptions(
			"Your status effects can stack up to 2x.",
			"Your status effects can stack up to 3x.",
			"Your status effects can stack up to 5x."
		),

		# Glass Soul - Damage = missing HP %
		AbilityData.new(
			"glass_soul",
			"Glass Soul",
			"Deal bonus damage equal to 50% of missing HP percentage.",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.GLASS_SOUL, value = 0.5}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.GLASS_SOUL, value = 0.5}],
			[{effect_type = AbilityData.EffectType.GLASS_SOUL, value = 1.0}],
			[{effect_type = AbilityData.EffectType.GLASS_SOUL, value = 1.5}]
		).with_rank_descriptions(
			"Deal bonus damage equal to 50% of missing HP percentage.",
			"Deal bonus damage equal to 100% of missing HP percentage.",
			"Deal bonus damage equal to 150% of missing HP percentage."
		),

		# ============================================
		# GAMBLING PASSIVES
		# ============================================

		# Lucky Number 7 - Every 7th hit crits
		AbilityData.new(
			"lucky_number_7",
			"Lucky Number 7",
			"Every 9th hit is automatically a critical hit.",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.LUCKY_NUMBER_7, value = 9.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.LUCKY_NUMBER_7, value = 9.0}],
			[{effect_type = AbilityData.EffectType.LUCKY_NUMBER_7, value = 7.0}],
			[{effect_type = AbilityData.EffectType.LUCKY_NUMBER_7, value = 5.0}]
		).with_rank_descriptions(
			"Every 9th hit is automatically a critical hit.",
			"Every 7th hit is automatically a critical hit.",
			"Every 5th hit is automatically a critical hit."
		),

		# Risk/Reward - Permanent damage on low HP
		AbilityData.new(
			"risk_reward",
			"Risk/Reward",
			"+3% permanent damage each time you drop below 10% HP.",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.RISK_REWARD, value = 0.03}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.RISK_REWARD, value = 0.03}],
			[{effect_type = AbilityData.EffectType.RISK_REWARD, value = 0.05}],
			[{effect_type = AbilityData.EffectType.RISK_REWARD, value = 0.08}]
		).with_rank_descriptions(
			"+3% permanent damage each time you drop below 10% HP.",
			"+5% permanent damage each time you drop below 10% HP.",
			"+8% permanent damage each time you drop below 10% HP."
		),

		# ============================================
		# SUMMON/COMPANION PASSIVES
		# ============================================

		# Emotional Support Animal - Auto-pickup companion
		AbilityData.new(
			"emotional_support",
			"Emotional Support Animal",
			"1 small creature follows you, picking up XP gems.",
			AbilityData.Rarity.RARE,
			AbilityData.Type.SUMMON,
			[{effect_type = AbilityData.EffectType.EMOTIONAL_SUPPORT, value = 1.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.EMOTIONAL_SUPPORT, value = 1.0}],
			[{effect_type = AbilityData.EffectType.EMOTIONAL_SUPPORT, value = 2.0}],
			[{effect_type = AbilityData.EffectType.EMOTIONAL_SUPPORT, value = 3.0}]
		).with_rank_descriptions(
			"1 small creature follows you, picking up XP gems.",
			"2 small creatures follow you, picking up XP gems.",
			"3 small creatures follow you, picking up XP gems."
		),

		# Haunted - Ghost on kills
		AbilityData.new(
			"haunted",
			"Haunted",
			"Every 12th kill spawns a ghost that fights for 5 seconds.",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.ON_KILL,
			[{effect_type = AbilityData.EffectType.HAUNTED, value = 12.0}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.HAUNTED, value = 12.0}],
			[{effect_type = AbilityData.EffectType.HAUNTED, value = 8.0}],
			[{effect_type = AbilityData.EffectType.HAUNTED, value = 5.0}]
		).with_rank_descriptions(
			"Every 12th kill spawns a ghost that fights for 5 seconds.",
			"Every 8th kill spawns a ghost that fights for 5 seconds.",
			"Every 5th kill spawns a ghost that fights for 5 seconds."
		),

		# Survivor's Guilt - Buff when summons die (requires a summon)
		AbilityData.new(
			"survivors_guilt",
			"Survivor's Guilt",
			"When a summon dies, gain +15% damage for 10 seconds.",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.SURVIVORS_GUILT, value = 0.15}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.SURVIVORS_GUILT, value = 0.15}],
			[{effect_type = AbilityData.EffectType.SURVIVORS_GUILT, value = 0.25}],
			[{effect_type = AbilityData.EffectType.SURVIVORS_GUILT, value = 0.40}]
		).with_rank_descriptions(
			"When a summon dies, gain +15% damage for 10 seconds.",
			"When a summon dies, gain +25% damage for 10 seconds.",
			"When a summon dies, gain +40% damage for 10 seconds."
		).with_prerequisites(["chicken_companion", "summoner_aid", "drone_support", "blade_orbit", "flame_orbit", "frost_orbit"] as Array[String]),

		# ============================================
		# SCALING PASSIVES
		# ============================================

		# Getting Warmed Up - Scaling attack speed
		AbilityData.new(
			"getting_warmed_up",
			"Getting Warmed Up",
			"Gain +3% attack speed every 30 seconds, stacking infinitely.",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.GETTING_WARMED_UP, value = 0.03}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.GETTING_WARMED_UP, value = 0.03}],
			[{effect_type = AbilityData.EffectType.GETTING_WARMED_UP, value = 0.05}],
			[{effect_type = AbilityData.EffectType.GETTING_WARMED_UP, value = 0.08}]
		).with_rank_descriptions(
			"Gain +3% attack speed every 30 seconds, stacking infinitely.",
			"Gain +5% attack speed every 30 seconds, stacking infinitely.",
			"Gain +8% attack speed every 30 seconds, stacking infinitely."
		),

		# Intimidating Presence - Fear on sight
		AbilityData.new(
			"intimidating_presence",
			"Intimidating Presence",
			"Enemies in close range have 7% chance to flee.",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.INTIMIDATING_PRESENCE, value = 0.07}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.INTIMIDATING_PRESENCE, value = 0.07}],
			[{effect_type = AbilityData.EffectType.INTIMIDATING_PRESENCE, value = 0.12}],
			[{effect_type = AbilityData.EffectType.INTIMIDATING_PRESENCE, value = 0.18}]
		).with_rank_descriptions(
			"Enemies in close range have 7% chance to flee.",
			"Enemies in close range have 12% chance to flee.",
			"Enemies in close range have 18% chance to flee."
		),
	]

	# Set icon paths for all abilities
	var icon_map = {
		"blazing_trail": "res://assets/icons/abilities/blazing_trail.png",
		"toxic_traits": "res://assets/icons/abilities/toxic_traits.png",
		"surprise_mechanics": "res://assets/icons/abilities/surprise_mechanics.png",
		"sore_loser": "res://assets/icons/abilities/sore_loser.png",
		"wallflower": "res://assets/icons/abilities/wallflower.png",  # thiefskills/icon9
		"friendly_fire": "res://assets/icons/abilities/friendly_fire.png",
		"built_different": "res://assets/icons/abilities/built_different.png",
		"wombo_combo": "res://assets/icons/abilities/wombo_combo.png",
		"ninety_nine_stacks": "res://assets/icons/abilities/ninety_nine_stacks.png",
		"glass_soul": "res://assets/icons/abilities/glass_soul.png",
		"lucky_number_7": "res://assets/icons/abilities/lucky_number_7.png",
		"risk_reward": "res://assets/icons/abilities/risk_reward.png",
		"emotional_support": "res://assets/icons/abilities/emotional_support.png",
		"haunted": "res://assets/icons/abilities/haunted.png",
		"survivors_guilt": "res://assets/icons/abilities/survivors_guilt.png",
		"getting_warmed_up": "res://assets/icons/abilities/getting_warmed_up.png",
		"intimidating_presence": "res://assets/icons/abilities/intimidating_presence.png",
	}

	for ability in abilities:
		if icon_map.has(ability.id):
			ability.icon_path = icon_map[ability.id]

	return abilities
