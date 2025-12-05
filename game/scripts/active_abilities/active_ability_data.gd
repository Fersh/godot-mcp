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

# Ability tier for branching upgrade system
enum AbilityTier {
	BASE,       # Tier 1 - Starting abilities
	BRANCH,     # Tier 2 - Specialization branches
	SIGNATURE   # Tier 3 - Ultimate form with unique mechanics
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

# ============================================
# TIER SYSTEM PROPERTIES (for branching upgrades)
# ============================================
var tier: AbilityTier = AbilityTier.BASE
var prerequisite_id: String = ""        # ID of required base/previous tier ability
var branch_index: int = 0               # Which branch path (0, 1, 2...)
var replaces_ability: bool = true       # If true, replaces parent ability; if false, adds alongside
var unique_mechanic: String = ""        # Description of signature move's special behavior
var visual_override: String = ""        # Custom VFX path for signature abilities

# Compound naming system - builds names like "Fiery Whirlwind of Chaos"
var base_name: String = ""              # Core ability name (e.g., "Whirlwind") - inherited from base
var name_prefix: String = ""            # Adjective for T2 (e.g., "Fiery")
var name_suffix: String = ""            # Suffix for T3 (e.g., "of Chaos")
var base_ability_id: String = ""        # ID of the root base ability (for icon lookup)

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
	base_name = p_name  # Default base_name is the full name (for base abilities)
	description = p_desc
	rarity = p_rarity
	class_type = p_class_type
	target_type = p_target_type
	cooldown = p_cooldown
	effect_id = p_id  # Default effect ID matches ability ID
	base_ability_id = p_id  # Default to self (overridden for upgrades)

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

# ============================================
# TIER SYSTEM BUILDER METHODS
# ============================================

func with_tier(p_tier: AbilityTier) -> ActiveAbilityData:
	tier = p_tier
	return self

func with_prerequisite(p_prereq_id: String, p_branch: int = 0) -> ActiveAbilityData:
	prerequisite_id = p_prereq_id
	branch_index = p_branch
	if tier == AbilityTier.BASE:
		tier = AbilityTier.BRANCH
	return self

func with_signature(p_mechanic: String) -> ActiveAbilityData:
	tier = AbilityTier.SIGNATURE
	unique_mechanic = p_mechanic
	return self

func with_visual_override(p_visual: String) -> ActiveAbilityData:
	visual_override = p_visual
	return self

func without_replacement() -> ActiveAbilityData:
	replaces_ability = false
	return self

# ============================================
# COMPOUND NAMING BUILDER METHODS
# ============================================

func with_prefix(p_prefix: String, p_base_name: String, p_base_id: String) -> ActiveAbilityData:
	## Set prefix for T2 ability (e.g., "Fiery" for "Fiery Whirlwind")
	name_prefix = p_prefix
	base_name = p_base_name
	base_ability_id = p_base_id
	name = get_display_name()  # Update the name field
	return self

func with_suffix(p_suffix: String, p_base_name: String, p_prefix: String, p_base_id: String) -> ActiveAbilityData:
	## Set suffix for T3 ability (e.g., "of Chaos" for "Fiery Whirlwind of Chaos")
	name_suffix = p_suffix
	base_name = p_base_name
	name_prefix = p_prefix
	base_ability_id = p_base_id
	name = get_display_name()  # Update the name field
	return self

func get_display_name() -> String:
	## Build the full display name from prefix + base + suffix
	var display = ""
	if not name_prefix.is_empty():
		display = name_prefix + " "
	display += base_name
	if not name_suffix.is_empty():
		display += " " + name_suffix
	return display

func get_icon_ability_id() -> String:
	## Get the base ability ID for icon lookup (upgrades use base ability's icon)
	if base_ability_id.is_empty():
		return id
	return base_ability_id

# Utility methods for tier system
func is_base() -> bool:
	return tier == AbilityTier.BASE

func is_branch() -> bool:
	return tier == AbilityTier.BRANCH

func is_signature() -> bool:
	return tier == AbilityTier.SIGNATURE

func is_upgrade() -> bool:
	## Returns true if this is a Tier 2 or Tier 3 ability (not base)
	return tier != AbilityTier.BASE

func supports_skillshot() -> bool:
	## Determines if this ability can be aimed via skillshot (hold + drag).
	## Returns true for projectiles, location-based effects, and directional abilities.
	## Returns false for self-buffs, summons, orbitals, and non-directional melee.

	# Self-targeting abilities (buffs, heals, transforms) - NO skillshot
	if target_type == TargetType.SELF:
		return false

	# AoE around self without projectile or direction - NO skillshot
	# (e.g., cleave, frost_nova, ground_slam, whirlwind)
	if target_type == TargetType.AREA_AROUND_SELF:
		# Check if it's a movement ability (like quick_roll) - those don't need aiming
		if is_movement_ability:
			return false
		# Non-movement AoE around self = no aiming needed
		return false

	# Direction-based abilities - YES skillshot (dash_strike, multi_shot, flame_wall, etc.)
	if target_type == TargetType.DIRECTION:
		return true

	# Nearest enemy targeting with projectiles - YES skillshot (fireball, power_shot, etc.)
	if target_type == TargetType.NEAREST_ENEMY:
		if projectile_count > 0 and projectile_speed > 0:
			return true
		# Chain lightning, shadowstep-like abilities without projectiles - NO
		return false

	# Cluster targeting (location-based like rain_of_arrows, throwing_bomb, glue_bomb) - YES skillshot
	if target_type == TargetType.CLUSTER:
		return true

	return false

func has_prerequisite() -> bool:
	return prerequisite_id != ""

func get_prerequisite_id() -> String:
	## Returns the ID of the prerequisite ability
	return prerequisite_id

func get_root_ability_id() -> String:
	## Get the root base ability ID (for icon lookup)
	if base_ability_id.is_empty():
		return id
	return base_ability_id

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
