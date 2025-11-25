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

func _ready() -> void:
	_init_characters()
	load_selection()

func _init_characters() -> void:
	# Load textures
	archer_texture = load("res://assets/sprites/archer.png")
	knight_texture = load("res://assets/sprites/knightred.png")

	# Create archer
	var archer = CharacterData.create_archer()
	archer.sprite_texture = archer_texture
	characters["archer"] = archer

	# Create knight
	var knight = CharacterData.create_knight()
	knight.sprite_texture = knight_texture
	characters["knight"] = knight

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
		"damage_reduction_threshold": 0.0  # HP percentage threshold for damage reduction
	}

	if selected_character == null:
		return bonuses

	match selected_character.id:
		"archer":
			# Eagle Eye: +15% crit chance, +10% projectile speed
			bonuses["crit_chance"] = 0.15
			bonuses["projectile_speed"] = 0.10
		"knight":
			# Iron Will: +20% max HP, -10% damage taken below 50% HP
			bonuses["max_hp"] = 0.20
			bonuses["damage_reduction"] = 0.10
			bonuses["damage_reduction_threshold"] = 0.50

	return bonuses
