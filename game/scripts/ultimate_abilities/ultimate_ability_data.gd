extends RefCounted
class_name UltimateAbilityData

enum CharacterClass {
	ARCHER,
	KNIGHT,
	BEAST,
	MAGE,
	MONK
}

enum TargetType {
	SELF,              # Affects the player (buffs, transformations)
	NEAREST_ENEMY,     # Auto-targets closest enemy
	AREA_AROUND_SELF,  # AoE centered on player
	DIRECTION,         # Fires in attack direction
	ALL_ENEMIES,       # Affects all enemies on screen
	GLOBAL,            # World-altering effect
}

# Core properties
var id: String
var name: String
var description: String
var character_class: CharacterClass
var target_type: TargetType
var icon_path: String = ""

# Cooldown (minimum 90 seconds, up to 300 for powerful ones)
var cooldown: float = 90.0

# Duration for effects that last over time
var duration: float = 0.0

# Damage properties
var base_damage: float = 0.0
var damage_multiplier: float = 1.0
var radius: float = 0.0
var range_distance: float = 0.0

# Projectile properties
var projectile_count: int = 1
var projectile_speed: float = 400.0

# Status effects
var stun_duration: float = 0.0
var slow_percent: float = 0.0
var slow_duration: float = 0.0
var knockback_force: float = 0.0

# Special flags
var grants_invulnerability: bool = false
var invulnerability_duration: float = 0.0
var is_transformation: bool = false
var heals_player: bool = false
var heal_amount: float = 0.0

# Visual effect identifier
var effect_id: String = ""

# Activation sequence timing
var activation_pause_duration: float = 0.75  # How long the comic book freeze lasts

func _init(
	p_id: String,
	p_name: String,
	p_desc: String,
	p_class: CharacterClass,
	p_target_type: TargetType,
	p_cooldown: float = 90.0
) -> void:
	id = p_id
	name = p_name
	description = p_desc
	character_class = p_class
	target_type = p_target_type
	cooldown = p_cooldown
	effect_id = p_id

# Builder pattern methods
func with_damage(base: float, multiplier: float = 1.0) -> UltimateAbilityData:
	base_damage = base
	damage_multiplier = multiplier
	return self

func with_aoe(p_radius: float) -> UltimateAbilityData:
	radius = p_radius
	return self

func with_range(p_range: float) -> UltimateAbilityData:
	range_distance = p_range
	return self

func with_projectiles(count: int, speed: float = 400.0) -> UltimateAbilityData:
	projectile_count = count
	projectile_speed = speed
	return self

func with_stun(p_duration: float) -> UltimateAbilityData:
	stun_duration = p_duration
	return self

func with_slow(percent: float, p_duration: float) -> UltimateAbilityData:
	slow_percent = percent
	slow_duration = p_duration
	return self

func with_knockback(force: float) -> UltimateAbilityData:
	knockback_force = force
	return self

func with_invulnerability(p_duration: float) -> UltimateAbilityData:
	grants_invulnerability = true
	invulnerability_duration = p_duration
	return self

func with_duration(p_duration: float) -> UltimateAbilityData:
	duration = p_duration
	return self

func with_transformation() -> UltimateAbilityData:
	is_transformation = true
	return self

func with_healing(amount: float) -> UltimateAbilityData:
	heals_player = true
	heal_amount = amount
	return self

func with_effect(p_effect_id: String) -> UltimateAbilityData:
	effect_id = p_effect_id
	return self

func with_activation_pause(p_duration: float) -> UltimateAbilityData:
	activation_pause_duration = p_duration
	return self

# Utility methods
static func get_class_name(p_class: CharacterClass) -> String:
	match p_class:
		CharacterClass.ARCHER:
			return "Archer"
		CharacterClass.KNIGHT:
			return "Knight"
		CharacterClass.BEAST:
			return "Beast"
		CharacterClass.MAGE:
			return "Mage"
		CharacterClass.MONK:
			return "Monk"
	return "Unknown"

static func get_class_color(p_class: CharacterClass) -> Color:
	match p_class:
		CharacterClass.ARCHER:
			return Color(0.2, 0.8, 0.2)  # Green
		CharacterClass.KNIGHT:
			return Color(0.7, 0.7, 0.9)  # Silver/Steel
		CharacterClass.BEAST:
			return Color(0.9, 0.3, 0.2)  # Red/Blood
		CharacterClass.MAGE:
			return Color(0.6, 0.3, 0.9)  # Purple
		CharacterClass.MONK:
			return Color(1.0, 0.85, 0.4)  # Gold/Yellow
	return Color.WHITE

# Ultimate rarity color - golden/divine
static func get_ultimate_color() -> Color:
	return Color(1.0, 0.84, 0.0)  # Pure gold

static func get_ultimate_glow_color() -> Color:
	return Color(1.0, 0.9, 0.5, 0.8)  # Bright golden glow
