extends RefCounted
class_name ActiveAbilityData

enum Rarity {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY,
	MYTHIC
}

enum TargetType {
	SELF,           # Affects the player (buffs, dodge)
	NEAREST_ENEMY,  # Auto-targets closest enemy
	AREA_AROUND_SELF,  # AoE centered on player
	DIRECTION,      # Fires in attack direction
	CLUSTER,        # Targets enemy clusters
}

enum ClassType {
	GLOBAL,  # Available to all classes
	MELEE,   # Knight only
	RANGED,  # Archer only
}

# Rarity weights for random selection
const RARITY_WEIGHTS_LEVEL_1 = {
	Rarity.COMMON: 55,
	Rarity.RARE: 35,
	Rarity.EPIC: 10
}

const RARITY_WEIGHTS_LEVEL_5 = {
	Rarity.COMMON: 35,
	Rarity.RARE: 45,
	Rarity.EPIC: 20
}

const RARITY_WEIGHTS_LEVEL_10 = {
	Rarity.COMMON: 15,
	Rarity.RARE: 45,
	Rarity.EPIC: 40
}

# Core properties
var id: String
var name: String
var description: String
var rarity: Rarity
var class_type: ClassType
var target_type: TargetType
var icon_path: String = ""

# Cooldown and timing
var cooldown: float = 10.0  # Seconds
var cast_time: float = 0.0  # Instant by default
var duration: float = 0.0   # For effects that last over time

# Damage and effects
var base_damage: float = 0.0
var damage_multiplier: float = 1.0  # Scales with player damage
var radius: float = 0.0      # For AoE abilities
var range_distance: float = 0.0  # For projectile/targeted abilities
var projectile_count: int = 1
var projectile_speed: float = 400.0

# Status effects
var stun_duration: float = 0.0
var slow_percent: float = 0.0
var slow_duration: float = 0.0
var knockback_force: float = 0.0

# Special flags
var is_movement_ability: bool = false
var grants_invulnerability: bool = false
var invulnerability_duration: float = 0.0

# Visual effect identifier (for spawning correct VFX)
var effect_id: String = ""

func _init(
	p_id: String,
	p_name: String,
	p_desc: String,
	p_rarity: Rarity,
	p_class_type: ClassType,
	p_target_type: TargetType,
	p_cooldown: float = 10.0
) -> void:
	id = p_id
	name = p_name
	description = p_desc
	rarity = p_rarity
	class_type = p_class_type
	target_type = p_target_type
	cooldown = p_cooldown
	effect_id = p_id  # Default effect ID matches ability ID

# Builder pattern methods for clean initialization
func with_damage(base: float, multiplier: float = 1.0) -> ActiveAbilityData:
	base_damage = base
	damage_multiplier = multiplier
	return self

func with_aoe(p_radius: float) -> ActiveAbilityData:
	radius = p_radius
	return self

func with_range(p_range: float) -> ActiveAbilityData:
	range_distance = p_range
	return self

func with_projectiles(count: int, speed: float = 400.0) -> ActiveAbilityData:
	projectile_count = count
	projectile_speed = speed
	return self

func with_stun(p_duration: float) -> ActiveAbilityData:
	stun_duration = p_duration
	return self

func with_slow(percent: float, p_duration: float) -> ActiveAbilityData:
	slow_percent = percent
	slow_duration = p_duration
	return self

func with_knockback(force: float) -> ActiveAbilityData:
	knockback_force = force
	return self

func with_movement() -> ActiveAbilityData:
	is_movement_ability = true
	return self

func with_invulnerability(p_duration: float) -> ActiveAbilityData:
	grants_invulnerability = true
	invulnerability_duration = p_duration
	return self

func with_duration(p_duration: float) -> ActiveAbilityData:
	duration = p_duration
	return self

func with_cast_time(p_cast_time: float) -> ActiveAbilityData:
	cast_time = p_cast_time
	return self

func with_effect(p_effect_id: String) -> ActiveAbilityData:
	effect_id = p_effect_id
	return self

func with_icon(p_icon_path: String) -> ActiveAbilityData:
	icon_path = p_icon_path
	return self

# Utility methods
static func get_rarity_color(p_rarity: Rarity) -> Color:
	match p_rarity:
		Rarity.COMMON:
			return Color(0.9, 0.9, 0.9)  # White
		Rarity.RARE:
			return Color(0.3, 0.5, 1.0)  # Blue
		Rarity.EPIC:
			return Color(0.6, 0.2, 0.8)  # Purple
		Rarity.LEGENDARY:
			return Color(1.0, 0.85, 0.0)  # Yellow
		Rarity.MYTHIC:
			return Color(1.0, 0.2, 0.3)  # Red
	return Color.WHITE

static func get_rarity_name(p_rarity: Rarity) -> String:
	match p_rarity:
		Rarity.COMMON:
			return "Common"
		Rarity.RARE:
			return "Rare"
		Rarity.EPIC:
			return "Epic"
		Rarity.LEGENDARY:
			return "Legendary"
		Rarity.MYTHIC:
			return "Mythic"
	return "Unknown"

static func get_rarity_weights_for_level(level: int) -> Dictionary:
	if level >= 10:
		return RARITY_WEIGHTS_LEVEL_10
	elif level >= 5:
		return RARITY_WEIGHTS_LEVEL_5
	else:
		return RARITY_WEIGHTS_LEVEL_1
