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
			"Leave a trail of fire behind you as you move. Trail lasts 2s and burns enemies.",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.BLAZING_TRAIL, value = 5.0}]  # damage per tick
		),

		# Toxic Traits - Leave poison pools
		AbilityData.new(
			"toxic_traits",
			"Toxic Traits",
			"Leave pools of poison where you walk. Enemies take damage over time standing in them.",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.TOXIC_TRAITS, value = 3.0}]  # damage per tick
		),

		# Surprise Mechanics - Drop mines when hit
		AbilityData.new(
			"surprise_mechanics",
			"Surprise Mechanics",
			"15% chance when hit to drop a proximity mine at your location.",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.SURPRISE_MECHANICS, value = 0.15}]  # 15% chance
		),

		# Sore Loser - Enemies drop traps on death
		AbilityData.new(
			"sore_loser",
			"Sore Loser",
			"Enemies have a 25% chance to drop a trap on death that damages other enemies.",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.ON_KILL,
			[{effect_type = AbilityData.EffectType.SORE_LOSER, value = 0.25}]  # 25% chance
		),

		# ============================================
		# STEALTH PASSIVES
		# ============================================

		# Wallflower - Invisible while still
		AbilityData.new(
			"wallflower",
			"Wallflower",
			"Standing still for 2 seconds makes you invisible. First attack from invis crits.",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.WALLFLOWER, value = 2.0}]  # seconds to activate
		),

		# ============================================
		# CHAOS PASSIVES
		# ============================================

		# Friendly Fire - Enemy damage hurts enemies
		AbilityData.new(
			"friendly_fire",
			"Friendly Fire",
			"10% of damage enemies deal hurts other enemies too. Chaos reigns.",
			AbilityData.Rarity.MYTHIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.FRIENDLY_FIRE, value = 0.10}]  # 10% damage transfer
		),

		# Built Different - Random stat boost
		AbilityData.new(
			"built_different",
			"Built Different",
			"Gain a random stat boost every 30 seconds. Lose the previous one. You're just built different.",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.BUILT_DIFFERENT, value = 30.0}]  # seconds between changes
		),

		# Wombo Combo - Multi-source explosion
		AbilityData.new(
			"wombo_combo",
			"Wombo Combo",
			"Hitting an enemy with 3 different damage sources within 1 second triggers a bonus explosion.",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.WOMBO_COMBO, value = 25.0}]  # explosion damage
		),

		# 99 Stacks - Stackable status effects
		AbilityData.new(
			"ninety_nine_stacks",
			"99 Stacks",
			"Your status effects can stack up to 3x.",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.NINETY_NINE_STACKS, value = 3.0}]  # stack multiplier
		),

		# Glass Soul - Damage = missing HP %
		AbilityData.new(
			"glass_soul",
			"Glass Soul",
			"Deal bonus damage equal to your missing HP percentage. 90% missing = 90% more damage.",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.GLASS_SOUL, value = 1.0}]  # 1:1 ratio
		),

		# ============================================
		# GAMBLING PASSIVES
		# ============================================

		# Lucky Number 7 - Every 7th hit crits
		AbilityData.new(
			"lucky_number_7",
			"Lucky Number 7",
			"Every 7th hit is automatically a critical hit. Count carefully.",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.LUCKY_NUMBER_7, value = 7.0}]  # every 7th hit
		),

		# Risk/Reward - Permanent damage on low HP
		AbilityData.new(
			"risk_reward",
			"Risk/Reward",
			"+5% permanent damage (this run) each time you drop below 10% HP. High risk, high reward.",
			AbilityData.Rarity.MYTHIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.RISK_REWARD, value = 0.05}]  # 5% per trigger
		),

		# ============================================
		# SUMMON/COMPANION PASSIVES
		# ============================================

		# Emotional Support Animal - Auto-pickup companion
		AbilityData.new(
			"emotional_support",
			"Emotional Support Animal",
			"A small creature follows you, picking up XP gems automatically. Good boy.",
			AbilityData.Rarity.RARE,
			AbilityData.Type.SUMMON,
			[{effect_type = AbilityData.EffectType.EMOTIONAL_SUPPORT, value = 1.0}]
		),

		# Haunted - Ghost on kills
		AbilityData.new(
			"haunted",
			"Haunted",
			"Every 10th kill spawns a ghost that fights for you for 5 seconds. Spooky.",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.ON_KILL,
			[{effect_type = AbilityData.EffectType.HAUNTED, value = 10.0}]  # every 10 kills
		),

		# Survivor's Guilt - Buff when summons die
		AbilityData.new(
			"survivors_guilt",
			"Survivor's Guilt",
			"When a summon dies, gain +25% damage for 10 seconds. Avenge them.",
			AbilityData.Rarity.MYTHIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.SURVIVORS_GUILT, value = 0.25}]  # 25% damage boost
		),

		# ============================================
		# SCALING PASSIVES
		# ============================================

		# Getting Warmed Up - Scaling attack speed
		AbilityData.new(
			"getting_warmed_up",
			"Getting Warmed Up",
			"Gain +5% attack speed every 30 seconds, stacking infinitely. Patience pays off.",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.GETTING_WARMED_UP, value = 0.05}]  # 5% per stack
		),

		# Intimidating Presence - Fear on sight
		AbilityData.new(
			"intimidating_presence",
			"Intimidating Presence",
			"Enemies within close range have 10% chance to flee when they first see you. Terrifying.",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.INTIMIDATING_PRESENCE, value = 0.10}]  # 10% flee chance
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
