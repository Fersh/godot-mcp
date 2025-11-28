extends Resource
class_name CharacterData

enum CharacterType {
	ARCHER,
	KNIGHT,
	BEAST,
	MAGE,
	MONK
}

enum AttackType {
	RANGED,
	MELEE
}

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var character_type: CharacterType = CharacterType.ARCHER
@export var attack_type: AttackType = AttackType.RANGED

# Stats
@export_group("Stats")
@export var base_health: float = 25.0
@export var base_speed: float = 180.0
@export var base_attack_cooldown: float = 0.79
@export var base_damage: float = 1.0
@export var attack_range: float = 440.0  # For ranged, this is fire range. For melee, this is melee reach.

# Combat stats
@export var base_crit_rate: float = 0.0  # Base crit chance
@export var base_block_rate: float = 0.0  # Chance to block incoming damage
@export var base_dodge_rate: float = 0.0  # Chance to dodge attacks entirely

# Spritesheet configuration
@export_group("Sprite")
@export var sprite_texture: Texture2D
@export var frame_size: Vector2 = Vector2(32, 32)  # Size of each frame in the spritesheet
@export var hframes: int = 8
@export var vframes: int = 8
@export var sprite_scale: Vector2 = Vector2(1.875, 1.875)
@export var sprite_offset: Vector2 = Vector2(0, 0)  # Offset to center sprite if frames are off-center

# Animation row indices (0-indexed)
@export_group("Animation Rows")
@export var row_idle: int = 0
@export var row_move: int = 1
@export var row_attack: int = 2  # For archer: shoot straight. For knight: attack
@export var row_attack_up: int = 3  # For archer: shoot up (optional for knight)
@export var row_attack_down: int = 4  # For archer: shoot down (optional for knight)
@export var row_damage: int = 5
@export var row_death: int = 6

# Frame counts per animation row
@export_group("Frame Counts")
@export var frames_idle: int = 4
@export var frames_move: int = 8
@export var frames_attack: int = 8
@export var frames_attack_up: int = 8
@export var frames_attack_down: int = 8
@export var frames_damage: int = 4
@export var frames_death: int = 4

# Beast-specific animation rows
@export_group("Beast Animations")
@export var row_spawn: int = -1  # Emerge/spawn animation
@export var row_taunt: int = -1  # Taunt animation
@export var row_attack_alt: int = -1  # Alternate attack (randomly chosen)
@export var row_damage_hard: int = -1  # Heavy damage animation
@export var frames_spawn: int = 8
@export var frames_taunt: int = 7
@export var frames_attack_alt: int = 8
@export var frames_damage_hard: int = 5
@export var has_alt_attack: bool = false  # Whether to randomly pick between attacks

# Mage-specific (death animation uses every-other-frame across 2 rows)
@export_group("Mage Animations")
@export var death_frame_skip: int = 1  # Skip N frames (1 = every frame, 2 = every other)
@export var death_spans_rows: bool = false  # Death animation spans multiple rows
@export var death_row_2: int = -1  # Second row for death if spans rows
@export var frames_death_row_2: int = 0  # Frames in second death row

# Monk-specific (triple attack animations)
@export_group("Monk Animations")
@export var row_attack_2: int = -1  # Second attack animation
@export var row_attack_3: int = -1  # Third attack animation
@export var frames_attack_2: int = 8
@export var frames_attack_3: int = 8
@export var has_triple_attack: bool = false  # Randomly pick between 3 attacks

# Passive ability (unique to each character)
@export_group("Passive")
@export var passive_name: String = ""
@export var passive_description: String = ""

# Suggested passives:
# Archer - "Eagle Eye": +15% crit chance, +10% projectile speed
# Knight - "Iron Will": +20% max HP, take 10% less damage when below 50% HP

static func create_archer() -> CharacterData:
	var data = CharacterData.new()
	data.id = "archer"
	data.display_name = "The Robbin' Hood"
	data.description = "Fast and agile. Attacks from range with deadly precision."
	data.character_type = CharacterType.ARCHER
	data.attack_type = AttackType.RANGED

	# Balanced damage, faster, less health
	data.base_health = 25.0
	data.base_speed = 180.0
	data.base_attack_cooldown = 1.07
	data.base_damage = 1.0
	data.attack_range = 440.0

	# Combat stats - Ranger has higher crit and dodge
	data.base_crit_rate = 0.08  # 8% base crit
	data.base_block_rate = 0.0  # 0% block
	data.base_dodge_rate = 0.10  # 10% dodge

	# Sprite config (archer is 32x32 per frame)
	data.frame_size = Vector2(32, 32)
	data.hframes = 8
	data.vframes = 8
	data.sprite_scale = Vector2(1.6875, 1.6875)  # Reduced 10% from 1.875

	# Animation rows
	data.row_idle = 0
	data.row_move = 1
	data.row_attack = 2  # Shoot straight
	data.row_attack_up = 3
	data.row_attack_down = 4
	data.row_damage = 5
	data.row_death = 6

	# Frame counts
	data.frames_idle = 4
	data.frames_move = 8
	data.frames_attack = 8
	data.frames_attack_up = 8
	data.frames_attack_down = 8
	data.frames_damage = 4
	data.frames_death = 4

	# Passive
	data.passive_name = "Heartseeker"
	data.passive_description = "Consecutive hits on same target: +10% Damage per hit (max 5 stacks)."

	return data

static func create_knight() -> CharacterData:
	var data = CharacterData.new()
	data.id = "knight"
	data.display_name = "The Armored One"
	data.description = "Slow but powerful. Cleaves through enemies with melee attacks."
	data.character_type = CharacterType.KNIGHT
	data.attack_type = AttackType.MELEE

	# Slower, tankier, higher damage
	data.base_health = 40.0
	data.base_speed = 140.0
	data.base_attack_cooldown = 1.1  # 10% slower attack speed (was 1.0)
	data.base_damage = 1.5
	data.attack_range = 54.0  # Melee reach (reduced 10% from 60)

	# Combat stats - Knight has crit, block, and some dodge
	data.base_crit_rate = 0.05  # 5% base crit
	data.base_block_rate = 0.05  # 5% block
	data.base_dodge_rate = 0.05  # 5% dodge

	# Sprite config (knight is 128x64 per frame based on user specification)
	data.frame_size = Vector2(128, 64)
	data.hframes = 8
	data.vframes = 7
	data.sprite_scale = Vector2(1.575, 1.575)  # Increased 5% from 1.5

	# Animation rows (based on knight spritesheet: idle, walk, block, block hit, attack, damage, death)
	data.row_idle = 0
	data.row_move = 1
	data.row_attack = 4  # Attack row
	data.row_attack_up = 4  # Knight uses same attack for all directions
	data.row_attack_down = 4
	data.row_damage = 5
	data.row_death = 6

	# Frame counts
	data.frames_idle = 8
	data.frames_move = 8
	data.frames_attack = 8
	data.frames_attack_up = 8
	data.frames_attack_down = 8
	data.frames_damage = 6  # Take damage has 6 frames
	data.frames_death = 8

	# Passive
	data.passive_name = "Retribution"
	data.passive_description = "After taking damage, next attack within 2s deals +50% DMG and stuns."

	return data

static func create_beast() -> CharacterData:
	var data = CharacterData.new()
	data.id = "beast"
	data.display_name = "The Beast"
	data.description = "Feral and unhinged. Hits fast and hard, dies faster and harder."
	data.character_type = CharacterType.BEAST
	data.attack_type = AttackType.MELEE

	# Glass cannon - very fast, high damage, low health
	data.base_health = 18.0
	data.base_speed = 220.0
	data.base_attack_cooldown = 0.65  # Very fast attacks
	data.base_damage = 1.8
	data.attack_range = 65.0  # Melee reach

	# Combat stats - High crit, high dodge, no block (too feral to block)
	data.base_crit_rate = 0.12  # 12% base crit
	data.base_block_rate = 0.0  # 0% block - doesn't know how to block
	data.base_dodge_rate = 0.15  # 15% dodge - very agile

	# Sprite config (128x128 per frame, 11 cols x 9 rows)
	# Note: 1408/11=128, 1152/9=128
	data.frame_size = Vector2(128, 128)
	data.hframes = 11
	data.vframes = 9
	data.sprite_scale = Vector2(0.83, 0.83)  # Scaled for visibility (reduced 5% from original 0.918 * 0.95)
	data.sprite_offset = Vector2(35, -40)  # Center the beast frames

	# Animation rows (based on Beast spritesheet)
	# Row 0: emerge (8), Row 1: taunt (7), Row 2: idle (6), Row 3: leap (11 - skip)
	# Row 4: attack (8), Row 5: move (8), Row 6: damage (4), Row 7: damage2 (5), Row 8: death (10)
	data.row_idle = 2
	data.row_move = 5
	data.row_attack = 4
	data.row_attack_up = 4  # Beast uses same attack for all directions
	data.row_attack_down = 4
	data.row_damage = 6
	data.row_death = 8

	# Frame counts - adjusted to actual frame counts in spritesheet
	data.frames_idle = 6
	data.frames_move = 8
	data.frames_attack = 8
	data.frames_attack_up = 8
	data.frames_attack_down = 8
	data.frames_damage = 4
	data.frames_death = 10

	# Beast-specific animations
	data.row_spawn = 0  # Emerge
	data.row_taunt = 1
	data.row_attack_alt = 3  # Leap attack (don't use)
	data.row_damage_hard = 7  # Damage 2
	data.frames_spawn = 8
	data.frames_taunt = 7
	data.frames_attack_alt = 11
	data.frames_damage_hard = 5
	data.has_alt_attack = false  # Disabled - leap attack not used

	# Passive
	data.passive_name = "Bloodlust"
	data.passive_description = "Heal 5% of damage dealt on critical hits"

	return data

static func create_mage() -> CharacterData:
	var data = CharacterData.new()
	data.id = "mage"
	data.display_name = "The Smart One"
	data.description = "Calculating and precise. Slow but devastating magical attacks."
	data.character_type = CharacterType.MAGE
	data.attack_type = AttackType.RANGED

	# Slow but powerful - glass cannon caster
	data.base_health = 20.0
	data.base_speed = 145.0  # Slowest character
	data.base_attack_cooldown = 1.4  # Slow attacks
	data.base_damage = 2.5  # Highest damage multiplier
	data.attack_range = 440.0  # Same as archer

	# Combat stats - High crit damage potential, fragile
	data.base_crit_rate = 0.10  # 10% base crit
	data.base_block_rate = 0.0  # No block - squishy
	data.base_dodge_rate = 0.05  # 5% dodge - slow

	# Sprite config (32x32 per frame, 12x12 grid)
	data.frame_size = Vector2(32, 32)
	data.hframes = 12
	data.vframes = 12
	data.sprite_scale = Vector2(2.0, 2.0)

	# Animation rows (based on Mage spritesheet)
	# Row 0: walk, Row 1: idle, Row 2: cast/attack, Row 3: damaged, Row 4-5: death
	data.row_idle = 1
	data.row_move = 0
	data.row_attack = 2  # Cast spell
	data.row_attack_up = 2  # Mage uses same attack for all directions
	data.row_attack_down = 2
	data.row_damage = 3
	data.row_death = 4

	# Frame counts
	data.frames_idle = 11
	data.frames_move = 8
	data.frames_attack = 5
	data.frames_attack_up = 5
	data.frames_attack_down = 5
	data.frames_damage = 9
	data.frames_death = 6  # First 6 frames from row 4 (every other)

	# Mage-specific: death uses every-other-frame across 2 rows
	data.death_frame_skip = 2  # Every other frame
	data.death_spans_rows = true
	data.death_row_2 = 5
	data.frames_death_row_2 = 3  # 3 more frames in row 5

	# Passive
	data.passive_name = "Arcane Focus"
	data.passive_description = "Standing still: +10% Damage dealt & taken/sec (max 50%). Decays over 5s when moving."

	return data

static func create_monk() -> CharacterData:
	var data = CharacterData.new()
	data.id = "monk"
	data.display_name = "The One Always Meditating"
	data.description = "Swift and precise. Chains varied staff strikes into devastating combos."
	data.character_type = CharacterType.MONK
	data.attack_type = AttackType.MELEE

	# Monk stats - fast, combo-focused, medium survivability
	data.base_health = 22.0
	data.base_speed = 185.0
	data.base_attack_cooldown = 0.75  # Fast attacks for combos
	data.base_damage = 1.15
	data.attack_range = 58.0  # Medium melee reach

	# Combat stats - balanced with slight crit/dodge lean
	data.base_crit_rate = 0.08  # 8% base crit
	data.base_block_rate = 0.03  # 3% block
	data.base_dodge_rate = 0.08  # 8% dodge

	# Sprite config (96x96 per frame, 16 cols x 8 rows)
	data.frame_size = Vector2(96, 96)
	data.hframes = 16
	data.vframes = 8
	data.sprite_scale = Vector2(1.75, 1.75)  # Scaled up for visibility

	# Animation rows
	# Row 0: Idle 1 (skip)
	# Row 1: Idle 2 (use this)
	# Row 2: Movement
	# Row 3: Spin the Staff / Taunt (use as Attack 3)
	# Row 4: Attack 1
	# Row 5: Attack 2
	# Row 6: Damage
	# Row 7: Death
	data.row_idle = 1  # Use Idle 2
	data.row_move = 2
	data.row_attack = 4  # Attack 1
	data.row_attack_up = 4  # Monk uses same attack for all directions
	data.row_attack_down = 4
	data.row_damage = 6
	data.row_death = 7

	# Frame counts
	data.frames_idle = 8
	data.frames_move = 6
	data.frames_attack = 15
	data.frames_attack_up = 15
	data.frames_attack_down = 15
	data.frames_damage = 6
	data.frames_death = 6

	# Monk-specific: Triple attack system
	data.row_attack_2 = 5  # Attack 2 row
	data.row_attack_3 = 3  # Staff spin (taunt) as Attack 3
	data.frames_attack_2 = 13
	data.frames_attack_3 = 4
	data.has_triple_attack = true

	# Passive
	data.passive_name = "Flowing Strikes"
	data.passive_description = "Each attack builds Flow. Gain 5% damage and speed per stack (max 4). At 3 stacks, dash toward enemies."

	return data
