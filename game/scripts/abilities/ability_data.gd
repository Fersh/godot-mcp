extends RefCounted
class_name AbilityData

enum Rarity {
	COMMON,
	RARE,
	LEGENDARY,
	MYTHIC
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
	return "Unknown"
