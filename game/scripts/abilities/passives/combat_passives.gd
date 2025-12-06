extends Node
class_name CombatPassives

# Combat-focused passive abilities
# On-hit triggers, momentum mechanics, and conditional damage boosts

static func get_abilities() -> Array[AbilityData]:
	return [
		# Berserker's Fury
		AbilityData.new(
			"berserker_fury",
			"Berserker's Fury",
			"+3% damage when hit (stacks to 15%)",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.BERSERKER_FURY, value = 0.03}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.BERSERKER_FURY, value = 0.03}],
			[{effect_type = AbilityData.EffectType.BERSERKER_FURY, value = 0.05}],
			[{effect_type = AbilityData.EffectType.BERSERKER_FURY, value = 0.07}]
		).with_rank_descriptions(
			"+3% damage when hit (stacks to 15%)",
			"+5% damage when hit (stacks to 25%)",
			"+7% damage when hit (stacks to 35%)"
		),

		# Combat Momentum
		AbilityData.new(
			"combat_momentum",
			"Combat Momentum",
			"+3% damage per hit on same target (max 15%)",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.COMBAT_MOMENTUM, value = 0.03}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.COMBAT_MOMENTUM, value = 0.03}],
			[{effect_type = AbilityData.EffectType.COMBAT_MOMENTUM, value = 0.05}],
			[{effect_type = AbilityData.EffectType.COMBAT_MOMENTUM, value = 0.07}]
		).with_rank_descriptions(
			"+3% damage per hit on same target (max 15%)",
			"+5% damage per hit on same target (max 25%)",
			"+7% damage per hit on same target (max 35%)"
		),

		# ============================================
		# EXECUTIONER UPGRADE CHAIN
		# Executioner → Cull the Weak → Soul Reaper
		# ============================================

		# Executioner (Base of chain)
		AbilityData.new(
			"executioner",
			"Executioner",
			"+30% damage to enemies below 30% HP",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.EXECUTIONER, value = 0.3}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.EXECUTIONER, value = 0.3}],
			[{effect_type = AbilityData.EffectType.EXECUTIONER, value = 0.5}],
			[{effect_type = AbilityData.EffectType.EXECUTIONER, value = 0.75}]
		).with_rank_descriptions(
			"+30% damage to enemies below 30% HP",
			"+50% damage to enemies below 30% HP",
			"+75% damage to enemies below 30% HP"
		),

		# Cull the Weak (Tier 2 - requires Executioner)
		AbilityData.new(
			"cull_the_weak",
			"Cull the Weak",
			"Instantly kill enemies under 20% HP",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.CULL_WEAK, value = 0.2}]
		).with_prerequisites(["executioner"] as Array[String]).as_upgrade(),

		# Soul Reaper (Tier 3 - requires Cull the Weak)
		AbilityData.new(
			"soul_reaper",
			"Soul Reaper",
			"Executing low HP enemies heals 2.5% max HP",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.SOUL_REAPER, value = 0.025}]
		).with_prerequisites(["cull_the_weak"] as Array[String]).as_upgrade(),

		# ============================================
		# FINISHER PASSIVES (Standalone)
		# ============================================

		# Armor Breaker (Melee only)
		AbilityData.new(
			"armor_breaker",
			"Armor Breaker",
			"Attacks ignore armor on enemies below 20% HP",
			AbilityData.Rarity.RARE,
			AbilityData.Type.MELEE_ONLY,
			[{effect_type = AbilityData.EffectType.ARMOR_BREAKER, value = 0.2}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.ARMOR_BREAKER, value = 0.2}],
			[{effect_type = AbilityData.EffectType.ARMOR_BREAKER, value = 0.3}],
			[{effect_type = AbilityData.EffectType.ARMOR_BREAKER, value = 0.4}]
		).with_rank_descriptions(
			"Attacks ignore armor on enemies below 20% HP",
			"Attacks ignore armor on enemies below 30% HP",
			"Attacks ignore armor on enemies below 40% HP"
		),

		# Finisher's Instinct
		AbilityData.new(
			"finishers_instinct",
			"Finisher's Instinct",
			"Guaranteed critical hit on enemies below 25% HP",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.FINISHERS_INSTINCT, value = 0.25}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.FINISHERS_INSTINCT, value = 0.25}],
			[{effect_type = AbilityData.EffectType.FINISHERS_INSTINCT, value = 0.35}],
			[{effect_type = AbilityData.EffectType.FINISHERS_INSTINCT, value = 0.50}]
		).with_rank_descriptions(
			"Guaranteed critical hit on enemies below 25% HP",
			"Guaranteed critical hit on enemies below 35% HP",
			"Guaranteed critical hit on enemies below 50% HP"
		),

		# Vengeance
		AbilityData.new(
			"vengeance",
			"Vengeance",
			"After taking damage, next attack deals +50%",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.VENGEANCE, value = 0.5}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.VENGEANCE, value = 0.5}],
			[{effect_type = AbilityData.EffectType.VENGEANCE, value = 1.0}],
			[{effect_type = AbilityData.EffectType.VENGEANCE, value = 1.5}]
		).with_rank_descriptions(
			"After taking damage, next attack deals +50%",
			"After taking damage, next attack deals +100%",
			"After taking damage, next attack deals +150%"
		),

		# Last Resort
		AbilityData.new(
			"last_resort",
			"Last Resort",
			"+30% damage when at critical HP",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.LAST_RESORT, value = 0.3}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.LAST_RESORT, value = 0.3}],
			[{effect_type = AbilityData.EffectType.LAST_RESORT, value = 0.5}],
			[{effect_type = AbilityData.EffectType.LAST_RESORT, value = 0.75}]
		).with_rank_descriptions(
			"+30% damage when at critical HP",
			"+50% damage when at critical HP",
			"+75% damage when at critical HP"
		),

		# Horde Breaker
		AbilityData.new(
			"horde_breaker",
			"Horde Breaker",
			"+1% damage per nearby enemy (max 10%)",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.HORDE_BREAKER, value = 0.01}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.HORDE_BREAKER, value = 0.01}],
			[{effect_type = AbilityData.EffectType.HORDE_BREAKER, value = 0.015}],
			[{effect_type = AbilityData.EffectType.HORDE_BREAKER, value = 0.02}]
		).with_rank_descriptions(
			"+1% damage per nearby enemy (max 10%)",
			"+1.5% damage per nearby enemy (max 15%)",
			"+2% damage per nearby enemy (max 20%)"
		),

		# Arcane Absorption
		AbilityData.new(
			"arcane_absorption",
			"Arcane Absorption",
			"Kills reduce ability cooldowns by 0.3s",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.ARCANE_ABSORPTION, value = 0.3}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.ARCANE_ABSORPTION, value = 0.3}],
			[{effect_type = AbilityData.EffectType.ARCANE_ABSORPTION, value = 0.5}],
			[{effect_type = AbilityData.EffectType.ARCANE_ABSORPTION, value = 0.75}]
		).with_rank_descriptions(
			"Kills reduce ability cooldowns by 0.3s",
			"Kills reduce ability cooldowns by 0.5s",
			"Kills reduce ability cooldowns by 0.75s"
		),

		# Adrenaline Rush (Melee)
		AbilityData.new(
			"adrenaline_rush",
			"Adrenaline Rush",
			"20% chance to dash on hit",
			AbilityData.Rarity.RARE,
			AbilityData.Type.MELEE_ONLY,
			[{effect_type = AbilityData.EffectType.ADRENALINE_RUSH, value = 0.20}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.ADRENALINE_RUSH, value = 0.20}],
			[{effect_type = AbilityData.EffectType.ADRENALINE_RUSH, value = 0.30}],
			[{effect_type = AbilityData.EffectType.ADRENALINE_RUSH, value = 0.40}]
		).with_rank_descriptions(
			"20% chance to dash on hit",
			"30% chance to dash on hit",
			"40% chance to dash on hit"
		),

		# Phalanx (Melee)
		AbilityData.new(
			"phalanx",
			"Phalanx",
			"10% chance to block frontal projectiles",
			AbilityData.Rarity.RARE,
			AbilityData.Type.MELEE_ONLY,
			[{effect_type = AbilityData.EffectType.PHALANX, value = 0.10}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.PHALANX, value = 0.10}],
			[{effect_type = AbilityData.EffectType.PHALANX, value = 0.15}],
			[{effect_type = AbilityData.EffectType.PHALANX, value = 0.25}]
		).with_rank_descriptions(
			"10% chance to block frontal projectiles",
			"15% chance to block frontal projectiles",
			"25% chance to block frontal projectiles"
		),

		# Homing Instinct (Ranged)
		AbilityData.new(
			"homing_instinct",
			"Homing Instinct",
			"Projectiles curve toward enemies",
			AbilityData.Rarity.RARE,
			AbilityData.Type.RANGED_ONLY,
			[{effect_type = AbilityData.EffectType.HOMING, value = 0.5}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.HOMING, value = 0.5}],
			[{effect_type = AbilityData.EffectType.HOMING, value = 0.75}],
			[{effect_type = AbilityData.EffectType.HOMING, value = 1.0}]
		).with_rank_descriptions(
			"Projectiles curve slightly toward enemies",
			"Projectiles curve moderately toward enemies",
			"Projectiles strongly home toward enemies"
		),

		# Far Shot (Ranged) - Attack Range Upgrade Tree
		AbilityData.new(
			"far_shot",
			"Far Shot",
			"+25% attack range",
			AbilityData.Rarity.COMMON,
			AbilityData.Type.RANGED_ONLY,
			[{effect_type = AbilityData.EffectType.ATTACK_RANGE, value = 0.25}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.ATTACK_RANGE, value = 0.25}],
			[{effect_type = AbilityData.EffectType.ATTACK_RANGE, value = 0.50}],
			[{effect_type = AbilityData.EffectType.ATTACK_RANGE, value = 0.75}]
		).with_rank_descriptions(
			"+25% attack range",
			"+50% attack range",
			"+75% attack range"
		),

		# Kill Streak Passives
		AbilityData.new(
			"rampage",
			"Rampage",
			"+2% damage per kill, resets after 4s",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.RAMPAGE, value = 0.02}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.RAMPAGE, value = 0.02}],
			[{effect_type = AbilityData.EffectType.RAMPAGE, value = 0.03}],
			[{effect_type = AbilityData.EffectType.RAMPAGE, value = 0.05}]
		).with_rank_descriptions(
			"+2% damage per kill, resets after 4s",
			"+3% damage per kill, resets after 4s",
			"+5% damage per kill, resets after 4s"
		),

		AbilityData.new(
			"killing_frenzy",
			"Killing Frenzy",
			"+3% attack speed per kill (max 30%), resets after 4s",
			AbilityData.Rarity.RARE,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.KILLING_FRENZY, value = 0.03}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.KILLING_FRENZY, value = 0.03}],
			[{effect_type = AbilityData.EffectType.KILLING_FRENZY, value = 0.05}],
			[{effect_type = AbilityData.EffectType.KILLING_FRENZY, value = 0.07}]
		).with_rank_descriptions(
			"+3% attack speed per kill (max 30%), resets after 4s",
			"+5% attack speed per kill (max 50%), resets after 4s",
			"+7% attack speed per kill (max 70%), resets after 4s"
		),

		AbilityData.new(
			"massacre",
			"Massacre",
			"+1% damage and speed per kill, resets after 3s",
			AbilityData.Rarity.EPIC,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.MASSACRE, value = 0.01}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.MASSACRE, value = 0.01}],
			[{effect_type = AbilityData.EffectType.MASSACRE, value = 0.02}],
			[{effect_type = AbilityData.EffectType.MASSACRE, value = 0.03}]
		).with_rank_descriptions(
			"+1% damage and speed per kill, resets after 3s",
			"+2% damage and speed per kill, resets after 3s",
			"+3% damage and speed per kill, resets after 3s"
		),

		AbilityData.new(
			"cooldown_killer",
			"Cooldown Killer",
			"Kills reduce active ability cooldowns by 0.25s",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.COOLDOWN_KILLER, value = 0.25}]
		).with_rank_effects(
			[{effect_type = AbilityData.EffectType.COOLDOWN_KILLER, value = 0.25}],
			[{effect_type = AbilityData.EffectType.COOLDOWN_KILLER, value = 0.35}],
			[{effect_type = AbilityData.EffectType.COOLDOWN_KILLER, value = 0.5}]
		).with_rank_descriptions(
			"Kills reduce active ability cooldowns by 0.25s",
			"Kills reduce active ability cooldowns by 0.35s",
			"Kills reduce active ability cooldowns by 0.5s"
		),
	]
