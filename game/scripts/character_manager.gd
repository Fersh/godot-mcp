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
var barbarian_texture: Texture2D
var assassin_texture: Texture2D
# New enemy-based characters
var golem_texture: Texture2D
var orc_texture: Texture2D
var minotaur_texture: Texture2D
var cyclops_texture: Texture2D
var lizardfolk_king_texture: Texture2D
var skeleton_king_texture: Texture2D
var shardsoul_slayer_texture: Texture2D
var necromancer_texture: Texture2D
var kobold_priest_texture: Texture2D
var ratfolk_texture: Texture2D

func _ready() -> void:
	_init_characters()
	load_selection()
	# Ensure we always have a valid selected character
	if selected_character == null or not (selected_character is CharacterData):
		print("CharacterManager: Resetting to default character (archer)")
		selected_character_id = "archer"
		selected_character = characters.get("archer")

func _init_characters() -> void:
	print("CharacterManager: Initializing characters...")

	# Load textures - Original characters
	archer_texture = load("res://assets/sprites/archer.png")
	knight_texture = load("res://assets/sprites/knightred.png")
	beast_texture = load("res://assets/sprites/The Beast Sprite Sheet v1.1 Fixed.png")
	mage_texture = load("res://assets/sprites/BlueMage_Sprites.png")
	monk_texture = load("res://assets/sprites/Monk Sprite Sheet.png")
	barbarian_texture = load("res://assets/sprites/Barbarian Sprite Sheet-Sheet.png")
	assassin_texture = load("res://assets/sprites/Elven Assassin Sprite Sheet.png")

	# Load textures - New enemy-based characters
	golem_texture = load("res://assets/sprites/Golem_Sprites.png")
	orc_texture = load("res://assets/sprites/Orc Warrior Sprite Sheet.png")
	minotaur_texture = load("res://assets/sprites/Minotaur - Sprite Sheet.png")
	cyclops_texture = load("res://assets/sprites/Cyclops Sprite Sheet.png")
	lizardfolk_king_texture = load("res://assets/sprites/Lizardfolk King Sprite Sheet.png")
	skeleton_king_texture = load("res://assets/sprites/Skeleton King Sprite Sheet 96x96px.png")
	shardsoul_slayer_texture = load("res://assets/sprites/Shardsoul Slayer Sprite Sheet.png")
	necromancer_texture = load("res://assets/sprites/Bandit Necromancer Sprite Sheet.png")
	kobold_priest_texture = load("res://assets/sprites/Kobold Priest Sprite Sheet.png")
	ratfolk_texture = load("res://assets/sprites/ratfolk.png")

	print("CharacterManager: Textures loaded")

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

	# Create barbarian
	var barbarian = CharacterData.create_barbarian()
	barbarian.sprite_texture = barbarian_texture
	characters["barbarian"] = barbarian

	# Create assassin
	var assassin = CharacterData.create_assassin()
	assassin.sprite_texture = assassin_texture
	characters["assassin"] = assassin

	# ============================================
	# NEW ENEMY-BASED PLAYABLE CHARACTERS
	# ============================================

	# Create golem - The Monolith
	var golem = CharacterData.create_golem()
	golem.sprite_texture = golem_texture
	characters["golem"] = golem

	# Create orc - The Grunt
	var orc = CharacterData.create_orc()
	orc.sprite_texture = orc_texture
	characters["orc"] = orc

	# Create minotaur - The Bullsh*t
	var minotaur = CharacterData.create_minotaur()
	minotaur.sprite_texture = minotaur_texture
	characters["minotaur"] = minotaur

	# Create cyclops - The One Eyed Monster
	var cyclops = CharacterData.create_cyclops()
	cyclops.sprite_texture = cyclops_texture
	characters["cyclops"] = cyclops

	# Create lizardfolk king - The Cold Blood
	var lizardfolk_king = CharacterData.create_lizardfolk_king()
	lizardfolk_king.sprite_texture = lizardfolk_king_texture
	characters["lizardfolk_king"] = lizardfolk_king

	# Create skeleton king - The Leech King
	var skeleton_king = CharacterData.create_skeleton_king()
	skeleton_king.sprite_texture = skeleton_king_texture
	characters["skeleton_king"] = skeleton_king

	# Create shardsoul slayer - The Reaper
	var shardsoul_slayer = CharacterData.create_shardsoul_slayer()
	shardsoul_slayer.sprite_texture = shardsoul_slayer_texture
	characters["shardsoul_slayer"] = shardsoul_slayer

	# Create necromancer - The Lonely One
	var necromancer = CharacterData.create_necromancer()
	necromancer.sprite_texture = necromancer_texture
	characters["necromancer"] = necromancer

	# Create kobold priest - The Hexweaver
	var kobold_priest = CharacterData.create_kobold_priest()
	kobold_priest.sprite_texture = kobold_priest_texture
	characters["kobold_priest"] = kobold_priest

	# Create ratfolk - The Skittering Blade
	var ratfolk = CharacterData.create_ratfolk()
	ratfolk.sprite_texture = ratfolk_texture
	characters["ratfolk"] = ratfolk

	# Set default selection - use safe .get() for both lookups
	selected_character = characters.get(selected_character_id)
	if selected_character == null:
		selected_character = characters.get("archer")

	print("CharacterManager: Initialized %d characters: %s" % [characters.size(), characters.keys()])

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
	if not file:
		return

	var data = file.get_var()
	file.close()

	# Validate data structure - must be a simple Dictionary with selected_character_id key
	if not (data is Dictionary):
		print("CharacterManager: Invalid save data type, deleting save file")
		DirAccess.remove_absolute(SAVE_PATH.replace("user://", OS.get_user_data_dir() + "/"))
		return

	# Make sure data only has expected keys
	if data.size() > 1 or (data.size() == 1 and not data.has("selected_character_id")):
		print("CharacterManager: Corrupted save data format, deleting save file")
		DirAccess.remove_absolute(SAVE_PATH.replace("user://", OS.get_user_data_dir() + "/"))
		return

	var loaded_id = data.get("selected_character_id", "archer")

	# Validate loaded_id is a string
	if not (loaded_id is String):
		print("CharacterManager: Invalid character ID type in save, defaulting to archer")
		selected_character_id = "archer"
		selected_character = characters.get("archer")
		return

	if characters.has(loaded_id):
		selected_character_id = loaded_id
		selected_character = characters.get(loaded_id)
	else:
		# Character not found (maybe new character not yet in dictionary)
		# Fall back to archer
		print("CharacterManager: Character '%s' not found, defaulting to archer" % loaded_id)
		selected_character_id = "archer"
		selected_character = characters.get("archer")

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
		print("CharacterManager: WARNING - selected_character is null in get_passive_bonuses")
		return bonuses

	if not (selected_character is CharacterData):
		print("CharacterManager: ERROR - selected_character is not CharacterData, type: %s" % typeof(selected_character))
		return bonuses

	var char_id = selected_character.id
	match char_id:
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
			# Bloodlust: +25% attack speed, +5% lifesteal on crit
			bonuses["attack_speed"] = 0.25
			bonuses["lifesteal_on_crit"] = 0.05
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
		"barbarian":
			# Berserker Rage: 10% chance for AOE spin attack
			bonuses["has_berserker_rage"] = 1.0
			bonuses["berserker_rage_chance"] = 0.10  # 10% chance
			bonuses["berserker_rage_aoe_radius"] = 120.0  # AOE radius
			bonuses["berserker_rage_damage_multiplier"] = 2.0  # Double damage on spin
		"assassin":
			# Shadow Dance: After hitting 5 enemies, vanish and dash attack with +100% damage
			bonuses["has_shadow_dance"] = 1.0
			bonuses["shadow_dance_hits_required"] = 5  # Hits to trigger vanish
			bonuses["shadow_dance_duration"] = 1.5  # Vanish duration
			bonuses["shadow_dance_damage_bonus"] = 1.0  # +100% damage from stealth
			bonuses["is_hybrid_attacker"] = 1.0  # Flag for hybrid melee/ranged
			bonuses["assassin_melee_range"] = 70.0  # Within this range, use melee

		# ============================================
		# NEW ENEMY-BASED CHARACTER PASSIVES
		# ============================================

		"golem":
			# Tectonic Endurance: 20% damage reduction, ground pound every 5 hits taken
			bonuses["has_tectonic_endurance"] = 1.0
			bonuses["tectonic_damage_reduction"] = 0.20  # 20% damage reduction
			bonuses["tectonic_hits_required"] = 5  # Hits to trigger ground pound
			bonuses["tectonic_aoe_radius"] = 100.0  # Ground pound radius
			bonuses["tectonic_aoe_damage"] = 2.0  # Damage multiplier for AOE

		"orc":
			# Bloodrage: +5% damage per kill (max 25%), resets between rooms
			bonuses["has_bloodrage"] = 1.0
			bonuses["bloodrage_damage_per_kill"] = 0.05  # +5% per kill
			bonuses["bloodrage_max_stacks"] = 5  # Max 25%

		"minotaur":
			# Stampede: 15% chance for ground slam AOE on attack
			bonuses["has_stampede"] = 1.0
			bonuses["stampede_chance"] = 0.15  # 15% chance
			bonuses["stampede_aoe_radius"] = 120.0  # AOE radius
			bonuses["stampede_damage_multiplier"] = 1.5  # 150% damage on slam

		"cyclops":
			# All-Seeing Eye: Fire laser beam every 8 seconds
			bonuses["has_all_seeing_eye"] = 1.0
			bonuses["eye_beam_cooldown"] = 8.0  # 8 second cooldown
			bonuses["eye_beam_damage"] = 1.5  # Damage multiplier
			bonuses["eye_beam_range"] = 300.0  # Beam range

		"lizardfolk_king":
			# Cold Blooded: Regen 2% HP/sec after 2s not hit, attacks apply poison
			bonuses["has_cold_blooded"] = 1.0
			bonuses["cold_blooded_regen"] = 0.02  # 2% HP/sec
			bonuses["cold_blooded_delay"] = 2.0  # 2 second delay
			bonuses["cold_blooded_poison_damage"] = 3.0  # Poison damage per tick
			bonuses["cold_blooded_poison_duration"] = 4.0  # Poison duration

		"skeleton_king":
			# Soul Leech: 8% lifesteal, summon skeleton every 15 seconds
			bonuses["has_soul_leech"] = 1.0
			bonuses["soul_leech_percent"] = 0.08  # 8% lifesteal
			bonuses["soul_leech_summon_cooldown"] = 15.0  # Summon every 15s
			bonuses["soul_leech_max_summons"] = 2  # Max 2 summons at a time

		"shardsoul_slayer":
			# Death's Embrace: +30% damage to low HP, +15% speed on kill
			bonuses["has_deaths_embrace"] = 1.0
			bonuses["execute_threshold"] = 0.40  # Below 40% HP
			bonuses["execute_damage_bonus"] = 0.30  # +30% damage
			bonuses["kill_speed_bonus"] = 0.15  # +15% speed
			bonuses["kill_speed_duration"] = 3.0  # 3 second duration

		"necromancer":
			# Eternal Legion: Summon up to 3 skeletons that fight for you
			bonuses["has_eternal_legion"] = 1.0
			bonuses["legion_max_summons"] = 3  # Max 3 summons
			bonuses["legion_summon_cooldown"] = 10.0  # Summon every 10s

		"kobold_priest":
			# Life Exchange: Attacks apply corruption, heal at 5 stacks
			bonuses["has_life_exchange"] = 1.0
			bonuses["corruption_max_stacks"] = 5  # Max stacks before trigger
			bonuses["corruption_heal_percent"] = 0.15  # Heal 15% HP
			bonuses["corruption_damage_reduction"] = 0.03  # Enemies deal 3% less per stack

		"ratfolk":
			# Scurry: +20% dodge after attacking, every 3rd attack deals double damage
			bonuses["has_scurry"] = 1.0
			bonuses["scurry_dodge_bonus"] = 0.20  # +20% dodge after attack
			bonuses["scurry_duration"] = 1.0  # 1 second duration
			bonuses["scurry_combo_hits"] = 3  # Every 3rd hit
			bonuses["scurry_combo_damage"] = 2.0  # Double damage on combo hit

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
