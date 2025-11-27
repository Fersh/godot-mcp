extends Node

# Character Manager - Handles character selection and persistence
# Add to autoload as "CharacterManager"

signal character_changed(character_data: CharacterData)

const SAVE_PATH = "user://character.save"

# Available characters
var characters: Dictionary = {}

# Currently selected character
var selected_character_id: String = "archer"
var selected_character: CharacterData = null

# Texture references (loaded on demand)
var archer_texture: Texture2D
var knight_texture: Texture2D
var beast_texture: Texture2D
var mage_texture: Texture2D
var monk_texture: Texture2D

func _ready() -> void:
	_init_characters()
	load_selection()

func _init_characters() -> void:
	# Load textures
	archer_texture = load("res://assets/sprites/archer.png")
	knight_texture = load("res://assets/sprites/knightred.png")
	beast_texture = load("res://assets/sprites/The Beast Sprite Sheet v1.1 Fixed.png")
	mage_texture = load("res://assets/sprites/BlueMage_Sprites.png")
	monk_texture = load("res://assets/sprites/Monk Sprite Sheet.png")

	# Create archer
	var archer = CharacterData.create_archer()
	archer.sprite_texture = archer_texture
	characters["archer"] = archer

	# Create knight
	var knight = CharacterData.create_knight()
	knight.sprite_texture = knight_texture
	characters["knight"] = knight

	# Create beast
	var beast = CharacterData.create_beast()
	beast.sprite_texture = beast_texture
	characters["beast"] = beast

	# Create mage
	var mage = CharacterData.create_mage()
	mage.sprite_texture = mage_texture
	characters["mage"] = mage

	# Create monk
	var monk = CharacterData.create_monk()
	monk.sprite_texture = monk_texture
	characters["monk"] = monk

	# Set default selection
	selected_character = characters.get(selected_character_id, characters["archer"])

func get_character(id: String) -> CharacterData:
	return characters.get(id)

func get_all_characters() -> Array:
	return characters.values()

func get_selected_character() -> CharacterData:
	return selected_character

func select_character(id: String) -> void:
	if characters.has(id):
		selected_character_id = id
		selected_character = characters[id]
		save_selection()
		emit_signal("character_changed", selected_character)

func is_ranged_character() -> bool:
	return selected_character.attack_type == CharacterData.AttackType.RANGED

func is_melee_character() -> bool:
	return selected_character.attack_type == CharacterData.AttackType.MELEE

# Save selected character to file
func save_selection() -> void:
	var save_data = {
		"selected_character_id": selected_character_id
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

# Load selected character from file
func load_selection() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()

		if data is Dictionary:
			var loaded_id = data.get("selected_character_id", "archer")
			if characters.has(loaded_id):
				selected_character_id = loaded_id
				selected_character = characters[loaded_id]

# Get passive bonuses for the selected character
func get_passive_bonuses() -> Dictionary:
	var bonuses = {
		"crit_chance": 0.0,
		"projectile_speed": 0.0,
		"max_hp": 0.0,
		"damage_reduction": 0.0,
		"damage_reduction_threshold": 0.0,  # HP percentage threshold for damage reduction
		"block_chance": 0.0,
		"dodge_chance": 0.0,
		"attack_speed": 0.0,
		"lifesteal_on_crit": 0.0
	}

	if selected_character == null:
		return bonuses

	match selected_character.id:
		"archer":
			# Heartseeker: Consecutive hits on same target +10% DMG per stack (max 5)
			bonuses["has_heartseeker"] = 1.0
			bonuses["heartseeker_damage_per_stack"] = 0.10
			bonuses["heartseeker_max_stacks"] = 5
		"knight":
			# Retribution: After taking damage, next attack +50% DMG and stuns
			bonuses["has_retribution"] = 1.0
			bonuses["retribution_damage_bonus"] = 0.50
			bonuses["retribution_duration"] = 2.0
			bonuses["retribution_stun_duration"] = 0.5
		"beast":
			# Bloodlust: +25% attack speed, +10% lifesteal on crit
			bonuses["attack_speed"] = 0.25
			bonuses["lifesteal_on_crit"] = 0.10
		"mage":
			# Arcane Focus: Standing still builds stacks (+10% dmg dealt & taken per stack, max 5)
			bonuses["has_arcane_focus"] = 1.0
			bonuses["arcane_focus_per_stack"] = 0.10  # +10% per stack
			bonuses["arcane_focus_max_stacks"] = 5  # Max 50%
			bonuses["arcane_focus_decay_time"] = 5.0  # Decay over 5s when moving
		"monk":
			# Flowing Strikes: stack-based bonuses handled in player.gd
			# Flag to enable the flow system
			bonuses["has_flow"] = 1.0  # Boolean as float
			bonuses["flow_damage_per_stack"] = 0.05  # +5% damage per stack
			bonuses["flow_speed_per_stack"] = 0.05  # +5% attack speed per stack
			bonuses["flow_dash_threshold"] = 3  # Dash at 3+ stacks
			bonuses["flow_max_stacks"] = 4  # Max 4 stacks
			bonuses["flow_decay_time"] = 1.5  # Stacks decay after 1.5s

	return bonuses

# Get the selected character's base combat stats
func get_base_combat_stats() -> Dictionary:
	var stats = {
		"crit_rate": 0.0,
		"block_rate": 0.0,
		"dodge_rate": 0.0
	}

	if selected_character == null:
		return stats

	stats["crit_rate"] = selected_character.base_crit_rate
	stats["block_rate"] = selected_character.base_block_rate
	stats["dodge_rate"] = selected_character.base_dodge_rate

	return stats
