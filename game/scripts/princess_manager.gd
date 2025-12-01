extends Node

# Princess Manager - Handles princess unlocks and curse modifiers
# Add to autoload as "PrincessManager"

const SAVE_PATH = "user://princess_data.save"
const SPRITE_SHEET_PATH = "res://assets/sprites/Medieval Townsfolk 3 Sprite Sheet.png"
const FRAME_SIZE = Vector2(32, 32)

# Signals
signal princess_unlocked(princess_id: String)
signal curses_changed()

# Princess data structure
class PrincessData:
	var id: String
	var name: String
	var curse_name: String
	var curse_description: String
	var sprite_character: int      # 0 = green dress, 1 = red dress
	var tier: int                  # 1 or 2
	var difficulty_pool: int       # DifficultyTier enum value
	var bonus_multiplier: float    # e.g., 1.15 = +15% points/coins
	var curse_effect: Dictionary   # Effect parameters

	func _init(p_id: String, p_name: String, p_curse_name: String, p_curse_desc: String,
			   p_sprite_char: int, p_tier: int, p_diff_pool: int, p_multiplier: float,
			   p_effect: Dictionary):
		id = p_id
		name = p_name
		curse_name = p_curse_name
		curse_description = p_curse_desc
		sprite_character = p_sprite_char
		tier = p_tier
		difficulty_pool = p_diff_pool
		bonus_multiplier = p_multiplier
		curse_effect = p_effect

# Animation data for sprite sheet
# Princess 1 (green dress): Rows 0-4, frame counts: 4, 4, 4, 8, 4
# Princess 2 (red dress): Rows 5-9, frame counts: 4, 8, 8, 8, 4
const ANIMATION_DATA = {
	0: {  # Princess 1 (green dress)
		"idle": {"row": 0, "frames": 4},
		"walk": {"row": 1, "frames": 4},
		"run_away": {"row": 2, "frames": 4},
		"give_gold": {"row": 3, "frames": 8},
		"distressed": {"row": 4, "frames": 4},
	},
	1: {  # Princess 2 (red dress)
		"idle": {"row": 5, "frames": 4},
		"walk": {"row": 6, "frames": 8},
		"run_away": {"row": 7, "frames": 8},
		"give_gold": {"row": 8, "frames": 8},
		"distressed": {"row": 9, "frames": 4},
	},
}

# All princess definitions
var princess_definitions: Dictionary = {}

# Unlocked princess IDs (persisted)
var unlocked_princesses: Array[String] = []

# Currently enabled curse IDs (persisted)
var enabled_curses: Array[String] = []

func _ready() -> void:
	_init_princess_definitions()
	load_progress()

func _init_princess_definitions() -> void:
	# ============================================
	# TIER 1 - Core Curses (8 total)
	# Unlocked from lower difficulties
	# ============================================

	# Juvenile pool (2 princesses)
	_add_princess("bloodprice", "Princess Crimson", "Bloodprice",
		"Lose 1 HP when collecting coins",
		0, 1, 0, 1.15,  # sprite_char=0, tier=1, diff=JUVENILE
		{"type": "bloodprice", "hp_loss": 1})

	_add_princess("fragile", "Princess Glass", "Fragile",
		"Take +50% damage from all sources",
		1, 1, 0, 1.20,
		{"type": "damage_taken_mult", "value": 1.5})

	# Very Easy pool (3 princesses)
	_add_princess("famine", "Princess Hollow", "Famine",
		"All healing reduced by 50%",
		0, 1, 1, 1.15,
		{"type": "healing_mult", "value": 0.5})

	_add_princess("chaos_spawn", "Princess Chaos", "Chaos Spawn",
		"Elite enemies spawn 50% more often",
		1, 1, 1, 1.18,
		{"type": "elite_spawn_mult", "value": 0.5})

	_add_princess("temporal_pressure", "Princess Haste", "Temporal Pressure",
		"Game speed increases 5% per minute (max +25%)",
		0, 1, 1, 1.20,
		{"type": "time_scale_increase", "per_minute": 0.05, "max": 0.25})

	# Easy pool (3 princesses)
	_add_princess("glass_cannon", "Princess Fury", "Glass Cannon",
		"+40% damage dealt, -25% max HP",
		1, 1, 2, 1.12,
		{"type": "glass_cannon", "damage_bonus": 0.4, "hp_reduction": 0.25})

	_add_princess("horde_mode", "Princess Swarm", "Horde Mode",
		"+40% enemy spawn rate",
		0, 1, 2, 1.18,
		{"type": "spawn_rate_mult", "value": 1.4})

	_add_princess("sealed_fate", "Princess Silence", "Sealed Fate",
		"Only 2 ability choices when leveling (instead of 3)",
		1, 1, 2, 1.15,
		{"type": "ability_choices", "value": 2})

	# ============================================
	# TIER 2 - Advanced Curses (12 total)
	# Unlocked from higher difficulties
	# ============================================

	# Normal pool (6 princesses)
	_add_princess("cursed_gold", "Princess Greed", "Cursed Gold",
		"Enemies drop 40% less gold",
		0, 2, 3, 1.10,
		{"type": "gold_drop_mult", "value": 0.6})

	_add_princess("brittle_armor", "Princess Rust", "Brittle Armor",
		"Equipment bonuses reduced by 25%",
		1, 2, 3, 1.12,
		{"type": "equipment_mult", "value": 0.75})

	_add_princess("champions_gauntlet", "Princess Crown", "Champion's Gauntlet",
		"20% of enemies spawn as champions",
		0, 2, 3, 1.20,
		{"type": "champion_chance", "value": 0.2})

	_add_princess("weakened", "Princess Frail", "Weakened",
		"Start each run at 70% HP",
		1, 2, 3, 1.10,
		{"type": "starting_hp", "value": 0.7})

	_add_princess("shrouded", "Princess Shadow", "Shrouded",
		"Reduced visibility radius by 30%",
		0, 2, 3, 1.08,
		{"type": "visibility_mult", "value": 0.7})

	_add_princess("berserk_enemies", "Princess Rage", "Berserk Enemies",
		"Enemies move 20% faster",
		1, 2, 3, 1.12,
		{"type": "enemy_speed_mult", "value": 1.2})

	# Nightmare pool (6 princesses)
	_add_princess("exhaustion", "Princess Weary", "Exhaustion",
		"Base move speed reduced by 15%",
		0, 2, 4, 1.12,
		{"type": "player_speed_mult", "value": 0.85})

	_add_princess("corrupted_xp", "Princess Void", "Corrupted XP",
		"Level ups require 25% more XP",
		1, 2, 4, 1.15,
		{"type": "xp_requirement_mult", "value": 1.25})

	_add_princess("unstable_ground", "Princess Quake", "Unstable Ground",
		"Damaging hazard zones appear randomly",
		0, 2, 4, 1.15,
		{"type": "hazard_zones", "interval": 10.0, "damage": 5})

	_add_princess("blood_moon", "Princess Eclipse", "Blood Moon",
		"Bosses have +30% HP and enrage at 40%",
		1, 2, 4, 1.18,
		{"type": "boss_buff", "hp_mult": 1.3, "enrage_threshold": 0.4})

	_add_princess("jinxed", "Princess Hex", "Jinxed",
		"-50% luck stat for drops and crits",
		0, 2, 4, 1.10,
		{"type": "luck_mult", "value": 0.5})

	_add_princess("marked_for_death", "Princess Doom", "Marked for Death",
		"Every 30s enemies gain +15% damage (stacks)",
		1, 2, 4, 1.20,
		{"type": "enemy_damage_scaling", "interval": 30.0, "increment": 0.15})

func _add_princess(id: String, name: String, curse_name: String, curse_desc: String,
				   sprite_char: int, tier: int, diff_pool: int, multiplier: float,
				   effect: Dictionary) -> void:
	princess_definitions[id] = PrincessData.new(
		id, name, curse_name, curse_desc, sprite_char, tier, diff_pool, multiplier, effect
	)

# ============================================
# GETTERS
# ============================================

func get_princess(id: String) -> PrincessData:
	return princess_definitions.get(id)

func get_all_princesses() -> Array:
	return princess_definitions.values()

func get_princesses_by_difficulty(diff_tier: int) -> Array:
	var result: Array = []
	for id in princess_definitions:
		if princess_definitions[id].difficulty_pool == diff_tier:
			result.append(princess_definitions[id])
	return result

func get_princesses_by_tier(tier: int) -> Array:
	var result: Array = []
	for id in princess_definitions:
		if princess_definitions[id].tier == tier:
			result.append(princess_definitions[id])
	return result

# ============================================
# UNLOCK SYSTEM
# ============================================

func is_princess_unlocked(id: String) -> bool:
	return id in unlocked_princesses

func get_unlocked_count() -> int:
	return unlocked_princesses.size()

func get_total_count() -> int:
	return princess_definitions.size()

func unlock_princess(id: String) -> void:
	if id in princess_definitions and id not in unlocked_princesses:
		unlocked_princesses.append(id)
		princess_unlocked.emit(id)
		save_progress()

func unlock_random_princess(difficulty_tier: int) -> String:
	"""Unlock a random princess from the pool for this difficulty tier.
	Returns the ID of the unlocked princess, or empty string if none available."""

	# Get all princesses in this difficulty pool that aren't unlocked yet
	var available: Array = []
	for id in princess_definitions:
		var princess = princess_definitions[id]
		if princess.difficulty_pool == difficulty_tier and id not in unlocked_princesses:
			available.append(id)

	if available.is_empty():
		# No princesses available in this pool, try lower pools
		for lower_tier in range(difficulty_tier - 1, -1, -1):
			for id in princess_definitions:
				var princess = princess_definitions[id]
				if princess.difficulty_pool == lower_tier and id not in unlocked_princesses:
					available.append(id)
			if not available.is_empty():
				break

	if available.is_empty():
		return ""  # All princesses unlocked

	# Pick a random one
	var chosen_id = available[randi() % available.size()]
	unlock_princess(chosen_id)
	return chosen_id

# ============================================
# CURSE SYSTEM
# ============================================

func is_curse_enabled(id: String) -> bool:
	return id in enabled_curses

func is_curse_active(id: String) -> bool:
	"""Alias for is_curse_enabled - used in gameplay code."""
	return is_curse_enabled(id)

func enable_curse(id: String) -> void:
	if id in unlocked_princesses and id not in enabled_curses:
		enabled_curses.append(id)
		curses_changed.emit()
		save_progress()

func disable_curse(id: String) -> void:
	if id in enabled_curses:
		enabled_curses.erase(id)
		curses_changed.emit()
		save_progress()

func toggle_curse(id: String) -> void:
	if is_curse_enabled(id):
		disable_curse(id)
	else:
		enable_curse(id)

func disable_all_curses() -> void:
	enabled_curses.clear()
	curses_changed.emit()
	save_progress()

func get_enabled_curses() -> Array[String]:
	return enabled_curses.duplicate()

func get_enabled_curse_count() -> int:
	return enabled_curses.size()

# ============================================
# MULTIPLIER & EFFECT GETTERS
# ============================================

func get_total_multiplier() -> float:
	"""Get the stacking multiplier from all enabled curses."""
	var total: float = 1.0
	for id in enabled_curses:
		var princess = get_princess(id)
		if princess:
			total *= princess.bonus_multiplier
	return total

func get_total_bonus_percent() -> int:
	"""Get the total bonus as a percentage (e.g., 45 for +45%)."""
	return int((get_total_multiplier() - 1.0) * 100)

func get_active_curse_effects() -> Dictionary:
	"""Get a dictionary of all active curse effects for gameplay application."""
	var effects: Dictionary = {
		# Damage/survival
		"damage_taken_mult": 1.0,
		"healing_mult": 1.0,
		"starting_hp": 1.0,
		"player_speed_mult": 1.0,
		"visibility_mult": 1.0,
		"luck_mult": 1.0,

		# Glass cannon special
		"damage_dealt_bonus": 0.0,
		"max_hp_reduction": 0.0,

		# Spawning
		"elite_spawn_mult": 1.0,
		"spawn_rate_mult": 1.0,
		"champion_chance": 0.0,
		"enemy_speed_mult": 1.0,

		# Economy/progression
		"gold_drop_mult": 1.0,
		"equipment_mult": 1.0,
		"xp_requirement_mult": 1.0,
		"ability_choices": 3,

		# Special effects
		"bloodprice": false,
		"time_scale_increase": 0.0,
		"time_scale_max": 0.0,
		"hazard_zones": false,
		"hazard_interval": 0.0,
		"hazard_damage": 0,
		"boss_hp_mult": 1.0,
		"boss_enrage_threshold": 0.2,
		"enemy_damage_scaling": false,
		"enemy_damage_interval": 0.0,
		"enemy_damage_increment": 0.0,
	}

	for id in enabled_curses:
		var princess = get_princess(id)
		if not princess:
			continue

		var effect = princess.curse_effect
		match effect.get("type", ""):
			"bloodprice":
				effects["bloodprice"] = true

			"damage_taken_mult":
				effects["damage_taken_mult"] *= effect.get("value", 1.0)

			"healing_mult":
				effects["healing_mult"] *= effect.get("value", 1.0)

			"elite_spawn_mult":
				effects["elite_spawn_mult"] *= (1.0 - effect.get("value", 0.0))

			"time_scale_increase":
				effects["time_scale_increase"] = effect.get("per_minute", 0.05)
				effects["time_scale_max"] = effect.get("max", 0.25)

			"glass_cannon":
				effects["damage_dealt_bonus"] += effect.get("damage_bonus", 0.0)
				effects["max_hp_reduction"] += effect.get("hp_reduction", 0.0)

			"spawn_rate_mult":
				effects["spawn_rate_mult"] *= effect.get("value", 1.0)

			"ability_choices":
				effects["ability_choices"] = mini(effects["ability_choices"], effect.get("value", 3))

			"gold_drop_mult":
				effects["gold_drop_mult"] *= effect.get("value", 1.0)

			"equipment_mult":
				effects["equipment_mult"] *= effect.get("value", 1.0)

			"champion_chance":
				effects["champion_chance"] = maxf(effects["champion_chance"], effect.get("value", 0.0))

			"starting_hp":
				effects["starting_hp"] = minf(effects["starting_hp"], effect.get("value", 1.0))

			"visibility_mult":
				effects["visibility_mult"] *= effect.get("value", 1.0)

			"enemy_speed_mult":
				effects["enemy_speed_mult"] *= effect.get("value", 1.0)

			"player_speed_mult":
				effects["player_speed_mult"] *= effect.get("value", 1.0)

			"xp_requirement_mult":
				effects["xp_requirement_mult"] *= effect.get("value", 1.0)

			"hazard_zones":
				effects["hazard_zones"] = true
				effects["hazard_interval"] = effect.get("interval", 10.0)
				effects["hazard_damage"] = effect.get("damage", 5)

			"boss_buff":
				effects["boss_hp_mult"] *= effect.get("hp_mult", 1.0)
				effects["boss_enrage_threshold"] = maxf(effects["boss_enrage_threshold"], effect.get("enrage_threshold", 0.2))

			"luck_mult":
				effects["luck_mult"] *= effect.get("value", 1.0)

			"enemy_damage_scaling":
				effects["enemy_damage_scaling"] = true
				effects["enemy_damage_interval"] = effect.get("interval", 30.0)
				effects["enemy_damage_increment"] = effect.get("increment", 0.15)

	return effects

# Convenience functions for specific curse checks
func has_bloodprice() -> bool:
	return is_curse_enabled("bloodprice")

func has_glass_cannon() -> bool:
	return is_curse_enabled("glass_cannon")

func has_temporal_pressure() -> bool:
	return is_curse_enabled("temporal_pressure")

func has_hazard_zones() -> bool:
	return is_curse_enabled("unstable_ground")

func has_marked_for_death() -> bool:
	return is_curse_enabled("marked_for_death")

# ============================================
# SPRITE HELPERS
# ============================================

func get_sprite_sheet() -> Texture2D:
	return load(SPRITE_SHEET_PATH)

func get_animation_info(sprite_char: int, anim_name: String) -> Dictionary:
	"""Get animation row and frame count for a princess sprite."""
	if sprite_char in ANIMATION_DATA and anim_name in ANIMATION_DATA[sprite_char]:
		return ANIMATION_DATA[sprite_char][anim_name]
	return {"row": 0, "frames": 4}

func get_sprite_region(sprite_char: int, anim_name: String, frame: int) -> Rect2:
	"""Get the region rect for a specific frame of a princess animation."""
	var anim = get_animation_info(sprite_char, anim_name)
	var row = anim["row"]
	var col = frame % anim["frames"]
	return Rect2(col * FRAME_SIZE.x, row * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)

# ============================================
# PERSISTENCE
# ============================================

func save_progress() -> void:
	var save_data = {
		"unlocked": unlocked_princesses.duplicate(),
		"enabled": enabled_curses.duplicate(),
		"version": 1,
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()

		if data is Dictionary:
			# Load unlocked princesses
			unlocked_princesses.clear()
			var saved_unlocked = data.get("unlocked", [])
			for id in saved_unlocked:
				if id is String and id in princess_definitions:
					unlocked_princesses.append(id)

			# Load enabled curses (only if unlocked)
			enabled_curses.clear()
			var saved_enabled = data.get("enabled", [])
			for id in saved_enabled:
				if id is String and id in unlocked_princesses:
					enabled_curses.append(id)

# ============================================
# DEBUG FUNCTIONS
# ============================================

func debug_unlock_all() -> void:
	"""Debug function to unlock all princesses."""
	for id in princess_definitions:
		if id not in unlocked_princesses:
			unlocked_princesses.append(id)
	save_progress()

func debug_reset_progress() -> void:
	"""Debug function to reset all progress."""
	unlocked_princesses.clear()
	enabled_curses.clear()
	save_progress()
