extends Resource
class_name CharacterData

enum CharacterType {
	ARCHER,
	KNIGHT
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

# Spritesheet configuration
@export_group("Sprite")
@export var sprite_texture: Texture2D
@export var frame_size: Vector2 = Vector2(32, 32)  # Size of each frame in the spritesheet
@export var hframes: int = 8
@export var vframes: int = 8
@export var sprite_scale: Vector2 = Vector2(1.875, 1.875)

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
	data.display_name = "Ranger"
	data.description = "Fast and agile. Attacks from range with deadly precision."
	data.character_type = CharacterType.ARCHER
	data.attack_type = AttackType.RANGED

	# Balanced damage, faster, less health
	data.base_health = 25.0
	data.base_speed = 180.0
	data.base_attack_cooldown = 0.79
	data.base_damage = 1.0
	data.attack_range = 440.0

	# Sprite config (archer is 32x32 per frame)
	data.frame_size = Vector2(32, 32)
	data.hframes = 8
	data.vframes = 8
	data.sprite_scale = Vector2(1.875, 1.875)

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
	data.passive_name = "Eagle Eye"
	data.passive_description = "+15% Crit Chance, +10% Projectile Speed"

	return data

static func create_knight() -> CharacterData:
	var data = CharacterData.new()
	data.id = "knight"
	data.display_name = "Knight"
	data.description = "Slow but powerful. Cleaves through enemies with melee attacks."
	data.character_type = CharacterType.KNIGHT
	data.attack_type = AttackType.MELEE

	# Slower, tankier, higher damage
	data.base_health = 40.0
	data.base_speed = 140.0
	data.base_attack_cooldown = 1.0
	data.base_damage = 1.5
	data.attack_range = 60.0  # Melee reach (reduced by 25% from 80)

	# Sprite config (knight is 128x64 per frame based on user specification)
	# Ranger is 32x32 at 1.875 scale = 60px. Knight should be 10% bigger = ~2.06 uniform scale
	# Using uniform scale to preserve proportions
	data.frame_size = Vector2(128, 64)
	data.hframes = 8
	data.vframes = 7
	data.sprite_scale = Vector2(1.5, 1.5)  # Slightly smaller than ranger's 1.875

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
	data.passive_name = "Iron Will"
	data.passive_description = "+20% Max HP, -10% Damage Taken below 50% HP"

	return data
