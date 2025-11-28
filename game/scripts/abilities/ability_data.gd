extends RefCounted
class_name AbilityData

enum Rarity {
	COMMON,
	RARE,
	LEGENDARY,
	MYTHIC,
	ULTIMATE
}

enum Type {
	STAT_BOOST,
	PASSIVE,
	SUMMON,
	ON_KILL,
	PERIODIC,
	RANGED_ONLY,
	MELEE_ONLY
}

enum EffectType {
	# Stat modifiers
	ATTACK_SPEED,
	DAMAGE,
	MAX_HP,
	MAX_HP_PERCENT,
	XP_GAIN,
	MOVE_SPEED,
	PICKUP_RANGE,
	PROJECTILE_SPEED,
	PROJECTILE_COUNT,
	PROJECTILE_PIERCE,
	PROJECTILE_SPREAD,
	CRIT_CHANCE,
	LUCK,
	SIZE,

	# Special effects
	REGEN,
	THORNS,
	ORBITAL,
	TESLA_COIL,
	CULL_WEAK,
	VAMPIRISM,
	KNOCKBACK,
	RING_OF_FIRE,
	TOXIC_CLOUD,
	DEATH_EXPLOSION,
	LIGHTNING_STRIKE,
	DRONE,
	ADRENALINE,
	FRENZY,
	DOUBLE_XP_CHANCE,
	RUBBER_WALLS,
	REAR_SHOT,
	SNIPER_DAMAGE,

	# Melee effects
	MELEE_AREA,
	MELEE_RANGE,
	BLEEDING,
	DEFLECT,
	WHIRLWIND,
	DOUBLE_STRIKE,      # Trigger a second melee attack

	# New effects
	ARMOR,              # Flat damage reduction
	COIN_GAIN,          # Percentage coin gain increase
	FOCUS_REGEN,        # Regen while standing still
	MOMENTUM,           # Damage increase while moving
	MELEE_KNOCKBACK,    # Knockback force for melee
	RETRIBUTION,        # Explode when taking damage
	TIME_DILATION,      # Slow enemies permanently
	GIANT_SLAYER,       # Bonus damage to high HP enemies
	BACKSTAB,           # Bonus crit chance
	PARRY,              # Chance to block damage entirely
	SEISMIC_SLAM,       # Chance to stun enemies
	BLOODTHIRST,        # Attack speed boost on kill
	DOUBLE_TAP,         # Chance to fire twice
	POINT_BLANK,        # Bonus damage at close range
	BLADE_BEAM,         # Melee fires projectile
	BLOOD_MONEY,        # Coins heal you
	DIVINE_SHIELD,      # Invulnerability after taking damage
	RICOCHET,           # Arrows bounce to nearby enemy
	PHOENIX,            # Revive once
	BOOMERANG,          # Projectiles return

	# Elemental On-Hit Effects
	IGNITE,             # Chance to burn enemies
	FROSTBITE,          # Chance to freeze/chill enemies
	TOXIC_TIP,          # Chance to poison enemies
	LIGHTNING_PROC,     # Chance to call lightning on hit
	CHAOTIC_STRIKES,    # Random elemental damage
	STATIC_CHARGE,      # Periodic stun

	# Combat Mechanics
	BERSERKER_FURY,     # Stacking damage when hit
	COMBAT_MOMENTUM,    # Stacking damage on same target
	EXECUTIONER,        # Bonus damage to low HP enemies
	OVERHEAL_SHIELD,    # Excess healing becomes shield
	ARCANE_ABSORPTION,  # Cooldown reduction on kill
	VENGEANCE,          # Big damage after being hit
	MIRROR_IMAGE,       # Spawn decoy when hit
	HORDE_BREAKER,      # Damage scales with nearby enemies
	BATTLE_MEDIC,       # Health pickup triggers heal nova
	LAST_RESORT,        # Huge damage at 1 HP

	# Trade-off & Conditional
	FLEET_FOOTED,       # Speed for armor trade
	WARMUP,             # Timed early game buff
	PRACTICED_STANCE,   # Damage while stationary
	GUARDIAN_HEART,     # Increased healing received
	EARLY_BIRD,         # XP boost early, penalty late

	# Advanced Mechanics
	ADRENALINE_RUSH,    # Dash on kill (melee)
	PHALANX,            # Block frontal projectiles
	HOMING,             # Mild homing projectiles

	# Kill Streak Effects
	RAMPAGE,            # Stacking damage on kill, decays
	KILLING_FRENZY,     # Stacking attack speed on kill, decays
	MASSACRE,           # Stacking both damage and speed on kill
	COOLDOWN_KILLER,    # Reduce active cooldowns on kill

	# Legendary Effects
	CEREMONIAL_DAGGER,  # Homing daggers on kill
	MISSILE_BARRAGE,    # Random homing missiles
	SOUL_REAPER,        # Heal + stacking damage on kill
	SUMMONER,           # Periodic minion summon
	THUNDERSHOCK,       # Lightning revenge
	MIRROR_SHIELD,      # Reflect projectiles
	MIND_CONTROL,       # Chance to charm
	BLOOD_DEBT,         # Damage boost, self-damage
	CHRONO_TRIGGER,     # Periodic freeze all
	CHAIN_REACTION,     # Status spread on death
	UNLIMITED_POWER,    # Permanent stacking damage
	WIND_DANCER,        # No dodge cooldown
	EMPATHIC_BOND,      # Double aura effects
	FORTUNE_FAVOR,      # Loot tier upgrade

	# Mythic Effects
	IMMORTAL_OATH,      # Death immunity window
	ALL_FOR_ONE,        # All actives, longer cooldowns
	TRANSCENDENCE,      # HP to shields conversion
	SYMBIOSIS,          # Double passive choices
	PANDEMONIUM,        # Double spawns, double damage

	# Active Ability Synergy Effects
	QUICK_REFLEXES,     # Reduce all active ability cooldowns by 15%
	ADRENALINE_SURGE,   # Taking damage reduces active cooldowns by 0.5s
	EMPOWERED_ABILITIES, # Active abilities deal 20% more damage
	ELEMENTAL_INFUSION, # Active abilities apply your elemental effects
	DOUBLE_CHARGE,      # Dodge gains a second charge
	COMBO_MASTER,       # Using active grants 15% auto-attack damage for 3s
	ABILITY_ECHO,       # 10% chance for active abilities to trigger twice
	SWIFT_DODGE,        # Dodging grants 30% move speed for 2s
	PHANTOM_STRIKE,     # Dodge through enemies deals area damage
	KILL_ACCELERANT,    # Kills reduce ultimate cooldown by 0.5s

	# Passive Ability Enhancement
	PASSIVE_AMPLIFIER,  # Passive abilities deal 20% more damage
}

# Rarity weights for random selection (out of 100)
const RARITY_WEIGHTS = {
	Rarity.COMMON: 55,
	Rarity.RARE: 28,
	Rarity.LEGENDARY: 12,
	Rarity.MYTHIC: 5
}

var id: String
var name: String
var description: String
var rarity: Rarity
var type: Type
var effects: Array  # Array of {effect_type: EffectType, value: float}
var icon_path: String = ""

func _init(p_id: String, p_name: String, p_desc: String, p_rarity: Rarity, p_type: Type, p_effects: Array) -> void:
	id = p_id
	name = p_name
	description = p_desc
	rarity = p_rarity
	type = p_type
	effects = p_effects

static func get_rarity_color(rarity: Rarity) -> Color:
	match rarity:
		Rarity.COMMON:
			return Color(0.8, 0.8, 0.8)  # Gray/white
		Rarity.RARE:
			return Color(0.3, 0.5, 1.0)  # Blue
		Rarity.LEGENDARY:
			return Color(1.0, 0.8, 0.2)  # Gold
		Rarity.MYTHIC:
			return Color(1.0, 0.2, 0.3)  # Red
		Rarity.ULTIMATE:
			return Color(1.0, 0.84, 0.0)  # Pure divine gold
	return Color.WHITE

static func get_rarity_name(rarity: Rarity) -> String:
	match rarity:
		Rarity.COMMON:
			return "Common"
		Rarity.RARE:
			return "Rare"
		Rarity.LEGENDARY:
			return "Legendary"
		Rarity.MYTHIC:
			return "Mythic"
		Rarity.ULTIMATE:
			return "Ultimate"
	return "Unknown"
