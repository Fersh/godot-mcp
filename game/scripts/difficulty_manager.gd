extends Node

# Difficulty Manager - Central manager for difficulty settings and challenge mode
# Add to autoload as "DifficultyManager"

const SAVE_PATH = "user://difficulty.save"

# Game modes
enum GameMode { ENDLESS, CHALLENGE }

# Difficulty tiers
enum DifficultyTier { JUVENILE, VERY_EASY, EASY, NORMAL, NIGHTMARE, INFERNO, THANKSGIVING_DINNER }

# Current selection
var current_mode: GameMode = GameMode.ENDLESS
var current_difficulty: DifficultyTier = DifficultyTier.JUVENILE

# Endless mode tracking
var endless_game_time: float = 0.0

# Endless mode base values (120% of Thanksgiving - end-game difficulty)
# These start 20% harder than Thanksgiving and scale up infinitely over time
const ENDLESS_BASE = {
	"health_mult": 82.1,      # 68.42 * 1.2
	"damage_mult": 29.86,     # 24.88 * 1.2
	"speed_mult": 8.82,       # 7.35 * 1.2
	"spawn_rate_mult": 1.0,   # No increase (performance concern)
	"points_mult": 12.0,      # 10.0 * 1.2
	"starting_hp": 0.25,      # Same as Thanksgiving
	"healing_mult": 0.25,     # Same as Thanksgiving
	"champion_chance": 0.35,  # Same as Thanksgiving
	"xp_requirement_mult": 4.58,  # 3.815 * 1.2
	"elite_health_bonus": 7.2,    # 6.0 * 1.2
	"elite_damage_bonus": 3.6,    # 3.0 * 1.2
	"boss_health_bonus": 10.8,    # 9.0 * 1.2
	"boss_damage_bonus": 7.2,     # 6.0 * 1.2
	"percent_hp_damage": 0.03,    # 0.025 * 1.2
}

# Endless mode scaling: 5% increase per minute, compounding
# After 10 min: ~1.63x, After 20 min: ~2.65x, After 30 min: ~4.32x
const ENDLESS_SCALING_PER_MINUTE: float = 0.05

# Unlocked difficulties (persisted)
var unlocked_difficulties: Array[DifficultyTier] = [DifficultyTier.JUVENILE]

# Completed difficulties (persisted) - tracks which difficulties have been beaten
# Legacy array format for backwards compatibility
var completed_difficulties: Array[DifficultyTier] = []

# Detailed completion records - maps tier -> Array of {class_id, class_name, curse_count}
var completion_records: Dictionary = {}

# Difficulty configuration data
# 2025-12-04: Major rebalance - 20% compounding scaling, XP requirements, elite/boss bonuses, %HP damage
const DIFFICULTY_DATA = {
	DifficultyTier.JUVENILE: {
		"name": "Pitiful",
		"description": "For those who fear the dark.\n1x Points.",
		"health_mult": 1.0,
		"damage_mult": 1.0,
		"speed_mult": 1.0,
		"spawn_rate_mult": 2.75,
		"points_mult": 1.0,
		"starting_hp": 1.0,
		"healing_mult": 1.0,
		"champion_chance": 0.0,
		"xp_requirement_mult": 1.0,
		"elite_health_bonus": 0.0,
		"elite_damage_bonus": 0.0,
		"boss_health_bonus": 0.0,
		"boss_damage_bonus": 0.0,
		"percent_hp_damage": 0.0,
		"color": Color(0.5, 0.8, 0.5),  # Soft green
		"modifiers": [],
	},
	DifficultyTier.VERY_EASY: {
		"name": "Easy",
		"description": "Enemies apply Slow on hit.\n2x Points.",
		"health_mult": 3.52,
		"damage_mult": 2.7,
		"speed_mult": 1.24,
		"spawn_rate_mult": 3.3,
		"points_mult": 2.0,
		"starting_hp": 1.0,
		"healing_mult": 1.0,
		"champion_chance": 0.0,
		"xp_requirement_mult": 1.25,
		"elite_health_bonus": 1.0,  # +100%
		"elite_damage_bonus": 0.5,  # +50%
		"boss_health_bonus": 1.5,   # +150%
		"boss_damage_bonus": 1.0,   # +100%
		"percent_hp_damage": 0.0,
		"color": Color(0.6, 0.7, 0.9),  # Light blue
		"modifiers": ["enemy_slow_on_hit"],
	},
	DifficultyTier.EASY: {
		"name": "Normal",
		"description": "+ Elites gain affixes. 5% champions. +0.5% HP/hit.\n3x Points.",
		"health_mult": 6.34,   # 5.28 * 1.2
		"damage_mult": 3.96,   # 3.3 * 1.2
		"speed_mult": 1.73,    # 1.44 * 1.2
		"spawn_rate_mult": 4.235,
		"points_mult": 3.0,
		"starting_hp": 0.85,
		"healing_mult": 0.85,
		"champion_chance": 0.05,
		"xp_requirement_mult": 1.5625,  # 1.25^2
		"elite_health_bonus": 2.0,  # +200%
		"elite_damage_bonus": 1.0,  # +100%
		"boss_health_bonus": 3.0,   # +300%
		"boss_damage_bonus": 2.0,   # +200%
		"percent_hp_damage": 0.005, # 0.5%
		"color": Color(0.9, 0.9, 0.5),  # Yellow
		"modifiers": ["enemy_slow_on_hit", "elite_affixes"],
	},
	DifficultyTier.NORMAL: {
		"name": "Nightmare",
		"description": "+ 70% HP/Healing. Boss enrages faster. +1% HP/hit.\n4x Points.",
		"health_mult": 12.04,  # 8.36 * 1.44
		"damage_mult": 6.05,   # 4.2 * 1.44
		"speed_mult": 2.36,    # 1.64 * 1.44
		"spawn_rate_mult": 4.84,
		"points_mult": 4.0,
		"starting_hp": 0.70,
		"healing_mult": 0.70,
		"champion_chance": 0.08,
		"xp_requirement_mult": 1.953,  # 1.25^3
		"elite_health_bonus": 3.0,  # +300%
		"elite_damage_bonus": 1.5,  # +150%
		"boss_health_bonus": 4.5,   # +450%
		"boss_damage_bonus": 3.0,   # +300%
		"percent_hp_damage": 0.01,  # 1.0%
		"color": Color(0.9, 0.6, 0.3),  # Orange
		"modifiers": ["enemy_slow_on_hit", "elite_affixes", "faster_enrage"],
	},
	DifficultyTier.NIGHTMARE: {
		"name": "Hell",
		"description": "+ 55% HP, 50% Healing. 12% champions. +1.5% HP/hit.\n5x Points.",
		"health_mult": 20.91,  # 12.1 * 1.728
		"damage_mult": 9.50,   # 5.5 * 1.728
		"speed_mult": 3.28,    # 1.9 * 1.728
		"spawn_rate_mult": 5.6,
		"points_mult": 5.0,
		"starting_hp": 0.55,
		"healing_mult": 0.50,
		"champion_chance": 0.12,
		"xp_requirement_mult": 2.441,  # 1.25^4
		"elite_health_bonus": 4.0,  # +400%
		"elite_damage_bonus": 2.0,  # +200%
		"boss_health_bonus": 6.0,   # +600%
		"boss_damage_bonus": 4.0,   # +400%
		"percent_hp_damage": 0.015, # 1.5%
		"color": Color(0.9, 0.2, 0.2),  # Red
		"modifiers": ["enemy_slow_on_hit", "elite_affixes", "faster_enrage"],
	},
	DifficultyTier.INFERNO: {
		"name": "Inferno",
		"description": "+ 40% HP, 35% Healing. 25% champions. +2% HP/hit.\n6x Points.",
		"health_mult": 37.64,  # 18.15 * 2.074
		"damage_mult": 15.56,  # 7.5 * 2.074
		"speed_mult": 4.98,    # 2.4 * 2.074
		"spawn_rate_mult": 6.655,
		"points_mult": 6.0,
		"starting_hp": 0.40,
		"healing_mult": 0.35,
		"champion_chance": 0.25,
		"xp_requirement_mult": 3.052,  # 1.25^5
		"elite_health_bonus": 5.0,  # +500%
		"elite_damage_bonus": 2.5,  # +250%
		"boss_health_bonus": 7.5,   # +750%
		"boss_damage_bonus": 5.0,   # +500%
		"percent_hp_damage": 0.02,  # 2.0%
		"color": Color(1.0, 0.4, 0.0),  # Bright orange/fire
		"modifiers": ["enemy_slow_on_hit", "elite_affixes", "faster_enrage"],
	},
	DifficultyTier.THANKSGIVING_DINNER: {
		"name": "Thanksgiving",
		"description": "+ 25% HP/Healing. 35% champions. +2.5% HP/hit.\n10x Points.",
		"health_mult": 68.42,  # 27.5 * 2.488
		"damage_mult": 24.88,  # 10.0 * 2.488
		"speed_mult": 7.35,    # 3.0 * 2.45 (slightly adjusted)
		"spawn_rate_mult": 8.47,
		"points_mult": 10.0,
		"starting_hp": 0.25,
		"healing_mult": 0.25,
		"champion_chance": 0.35,
		"xp_requirement_mult": 3.815,  # 1.25^6
		"elite_health_bonus": 6.0,  # +600%
		"elite_damage_bonus": 3.0,  # +300%
		"boss_health_bonus": 9.0,   # +900%
		"boss_damage_bonus": 6.0,   # +600%
		"percent_hp_damage": 0.025, # 2.5%
		"color": Color(0.8, 0.5, 0.2),  # Turkey brown/orange
		"modifiers": ["enemy_slow_on_hit", "elite_affixes", "faster_enrage"],
	},
}

# ============================================
# MODIFIER DEFINITIONS
# ============================================
# Modifiers are cumulative - higher difficulties include all lower modifiers

const MODIFIER_DATA = {
	# Very Easy+: Enemies apply slow on hit
	"enemy_slow_on_hit": {
		"name": "Chilling Touch",
		"description": "Enemy attacks slow you by 15% for 1.5s",
		"icon": "slow",
	},
	# Easy+: Elites get random affixes
	"elite_affixes": {
		"name": "Elite Affixes",
		"description": "Elites spawn with random powers: Vampiric, Shielded, or Berserker",
		"icon": "skull",
	},
	# Normal+: Start with reduced HP
	"reduced_starting_hp": {
		"name": "Battle Worn",
		"description": "Start each run at 75% HP",
		"icon": "heart_broken",
	},
	# Normal+: Bosses enrage faster
	"faster_enrage": {
		"name": "Bloodlust",
		"description": "Bosses enrage at 35% HP instead of 20%",
		"icon": "rage",
	},
	# Nightmare+: Reduced healing effectiveness
	"reduced_healing": {
		"name": "Cursed Blood",
		"description": "All healing reduced by 50%",
		"icon": "poison",
	},
	# Nightmare+: Champion (buffed) normal enemies can spawn
	"champion_enemies": {
		"name": "Champions Rise",
		"description": "Rare champion enemies spawn with 9x HP and random effects",
		"icon": "crown",
	},
	# Inferno+: Start at 50% HP instead of 75%
	"severely_reduced_starting_hp": {
		"name": "Near Death",
		"description": "Start each run at 50% HP",
		"icon": "skull",
	},
	# Thanksgiving Dinner: Healing reduced by 75%
	"severely_reduced_healing": {
		"name": "Feast Denied",
		"description": "All healing reduced by 75%",
		"icon": "skull",
	},
	# Thanksgiving Dinner: Double champion spawn rate
	"double_champions": {
		"name": "Champion Horde",
		"description": "Champions spawn twice as often",
		"icon": "crown",
	},
}

# Signals
signal difficulty_changed(tier: DifficultyTier)
signal mode_changed(mode: GameMode)
signal difficulty_unlocked(tier: DifficultyTier)
signal difficulty_completed(tier: DifficultyTier)

func _ready() -> void:
	load_progress()

# ============================================
# MODE & DIFFICULTY GETTERS
# ============================================

func get_current_mode() -> GameMode:
	return current_mode

func get_current_difficulty() -> DifficultyTier:
	return current_difficulty

func is_challenge_mode() -> bool:
	return current_mode == GameMode.CHALLENGE

func is_endless_mode() -> bool:
	return current_mode == GameMode.ENDLESS

# ============================================
# ENDLESS MODE TIME SCALING
# ============================================

func update_endless_time(time: float) -> void:
	"""Update the elapsed game time for Endless mode scaling."""
	endless_game_time = time

func reset_endless_time() -> void:
	"""Reset endless game time (called at game start)."""
	endless_game_time = 0.0

func get_endless_scaling_multiplier() -> float:
	"""Get the current scaling multiplier based on time elapsed.
	Returns 1.0 at start, increases by 5% per minute compounding (no cap)."""
	var minutes = endless_game_time / 60.0
	return pow(1.0 + ENDLESS_SCALING_PER_MINUTE, minutes)

# ============================================
# DIFFICULTY DATA GETTERS
# ============================================

func get_difficulty_name(tier: DifficultyTier = current_difficulty) -> String:
	return DIFFICULTY_DATA[tier]["name"]

func get_difficulty_description(tier: DifficultyTier = current_difficulty) -> String:
	return DIFFICULTY_DATA[tier]["description"]

func get_difficulty_color(tier: DifficultyTier = current_difficulty) -> Color:
	return DIFFICULTY_DATA[tier]["color"]

# ============================================
# MULTIPLIER GETTERS (apply these to enemies)
# ============================================

func get_health_multiplier() -> float:
	if current_mode == GameMode.ENDLESS:
		return ENDLESS_BASE["health_mult"] * get_endless_scaling_multiplier()
	return DIFFICULTY_DATA[current_difficulty]["health_mult"]

func get_damage_multiplier() -> float:
	if current_mode == GameMode.ENDLESS:
		return ENDLESS_BASE["damage_mult"] * get_endless_scaling_multiplier()
	return DIFFICULTY_DATA[current_difficulty]["damage_mult"]

func get_speed_multiplier() -> float:
	if current_mode == GameMode.ENDLESS:
		# Cap speed at 2x the base to prevent enemies from becoming impossible to dodge
		var scale = min(get_endless_scaling_multiplier(), 2.0)
		return ENDLESS_BASE["speed_mult"] * scale
	return DIFFICULTY_DATA[current_difficulty]["speed_mult"]

func get_spawn_rate_multiplier() -> float:
	if current_mode == GameMode.ENDLESS:
		return ENDLESS_BASE["spawn_rate_mult"]  # No scaling for performance
	return DIFFICULTY_DATA[current_difficulty]["spawn_rate_mult"]

func get_points_multiplier() -> float:
	if current_mode == GameMode.ENDLESS:
		return ENDLESS_BASE["points_mult"] * get_endless_scaling_multiplier()
	return DIFFICULTY_DATA[current_difficulty]["points_mult"]

func get_xp_requirement_multiplier() -> float:
	"""Get XP requirement multiplier for leveling (compounds with curse effects)."""
	if current_mode == GameMode.ENDLESS:
		return ENDLESS_BASE["xp_requirement_mult"]  # No time scaling
	return DIFFICULTY_DATA[current_difficulty].get("xp_requirement_mult", 1.0)

func get_elite_health_bonus() -> float:
	"""Get elite health bonus multiplier (0.0 = no bonus, 1.0 = +100%)."""
	if current_mode == GameMode.ENDLESS:
		return ENDLESS_BASE["elite_health_bonus"] * get_endless_scaling_multiplier()
	return DIFFICULTY_DATA[current_difficulty].get("elite_health_bonus", 0.0)

func get_elite_damage_bonus() -> float:
	"""Get elite damage bonus multiplier (0.0 = no bonus, 0.5 = +50%)."""
	if current_mode == GameMode.ENDLESS:
		return ENDLESS_BASE["elite_damage_bonus"] * get_endless_scaling_multiplier()
	return DIFFICULTY_DATA[current_difficulty].get("elite_damage_bonus", 0.0)

func get_boss_health_bonus() -> float:
	"""Get boss health bonus multiplier (0.0 = no bonus, 1.5 = +150%)."""
	if current_mode == GameMode.ENDLESS:
		return ENDLESS_BASE["boss_health_bonus"] * get_endless_scaling_multiplier()
	return DIFFICULTY_DATA[current_difficulty].get("boss_health_bonus", 0.0)

func get_boss_damage_bonus() -> float:
	"""Get boss damage bonus multiplier (0.0 = no bonus, 1.0 = +100%)."""
	if current_mode == GameMode.ENDLESS:
		return ENDLESS_BASE["boss_damage_bonus"] * get_endless_scaling_multiplier()
	return DIFFICULTY_DATA[current_difficulty].get("boss_damage_bonus", 0.0)

func get_percent_hp_damage() -> float:
	"""Get percent of max HP dealt as bonus damage per hit (0.0 = none, 0.025 = 2.5%)."""
	if current_mode == GameMode.ENDLESS:
		# Cap at 10% per hit to prevent instant kills
		var scaled = ENDLESS_BASE["percent_hp_damage"] * get_endless_scaling_multiplier()
		return min(scaled, 0.10)
	return DIFFICULTY_DATA[current_difficulty].get("percent_hp_damage", 0.0)

# ============================================
# MODIFIER CHECKS
# ============================================

func get_active_modifiers() -> Array:
	"""Get list of active modifier IDs for current difficulty."""
	if current_mode == GameMode.ENDLESS:
		# Endless mode has all Thanksgiving modifiers
		return ["enemy_slow_on_hit", "elite_affixes", "faster_enrage"]
	return DIFFICULTY_DATA[current_difficulty]["modifiers"]

func has_modifier(modifier_id: String) -> bool:
	"""Check if a specific modifier is active."""
	if current_mode == GameMode.ENDLESS:
		# Endless mode has all Thanksgiving modifiers
		return modifier_id in ["enemy_slow_on_hit", "elite_affixes", "faster_enrage"]
	return modifier_id in DIFFICULTY_DATA[current_difficulty]["modifiers"]

func get_modifier_info(modifier_id: String) -> Dictionary:
	"""Get info about a specific modifier."""
	if modifier_id in MODIFIER_DATA:
		return MODIFIER_DATA[modifier_id]
	return {}

# Convenience functions for specific modifiers
func has_enemy_slow_on_hit() -> bool:
	return has_modifier("enemy_slow_on_hit")

func has_elite_affixes() -> bool:
	return has_modifier("elite_affixes")

func has_reduced_starting_hp() -> bool:
	return has_modifier("reduced_starting_hp")

func get_starting_hp_percent() -> float:
	"""Get starting HP percentage from difficulty data."""
	if current_mode == GameMode.ENDLESS:
		return ENDLESS_BASE["starting_hp"]  # 25% like Thanksgiving
	return DIFFICULTY_DATA[current_difficulty].get("starting_hp", 1.0)

func has_faster_enrage() -> bool:
	return has_modifier("faster_enrage")

func get_enrage_threshold() -> float:
	"""Get boss enrage HP threshold (0.2 = 20%, 0.35 = 35%)."""
	if has_faster_enrage():
		return 0.35
	return 0.20

func has_reduced_healing() -> bool:
	return has_modifier("reduced_healing")

func get_healing_multiplier() -> float:
	"""Get healing effectiveness multiplier from difficulty data."""
	if current_mode == GameMode.ENDLESS:
		return ENDLESS_BASE["healing_mult"]  # 25% like Thanksgiving
	return DIFFICULTY_DATA[current_difficulty].get("healing_mult", 1.0)

func has_champion_enemies() -> bool:
	return get_champion_chance() > 0.0

func get_champion_chance() -> float:
	"""Get champion spawn chance from difficulty data."""
	if current_mode == GameMode.ENDLESS:
		# Cap at 50% champion chance
		var scaled = ENDLESS_BASE["champion_chance"] * get_endless_scaling_multiplier()
		return min(scaled, 0.50)
	return DIFFICULTY_DATA[current_difficulty].get("champion_chance", 0.0)

# ============================================
# MODE & DIFFICULTY SETTERS
# ============================================

func set_mode(mode: GameMode) -> void:
	current_mode = mode
	mode_changed.emit(mode)

func set_difficulty(tier: DifficultyTier) -> void:
	# Temporarily allow all difficulties to be set (bypass unlock check)
	current_difficulty = tier
	difficulty_changed.emit(tier)

# ============================================
# UNLOCK SYSTEM
# ============================================

func is_difficulty_unlocked(tier: DifficultyTier) -> bool:
	return tier in unlocked_difficulties

# Character ID to display name mapping
const CLASS_DISPLAY_NAMES = {
	"archer": "Ranger",
	"knight": "Knight",
	"mage": "Mage",
	"monk": "Monk",
	"barbarian": "Barbarian",
	"assassin": "Assassin",
	"beast": "Beast",
}

func is_difficulty_completed(tier: DifficultyTier) -> bool:
	return tier in completed_difficulties

func get_completion_records(tier: DifficultyTier) -> Array:
	"""Get all completion records for a difficulty tier."""
	return completion_records.get(tier, [])

func get_completion_summary(tier: DifficultyTier) -> String:
	"""Get a formatted string like 'Beat with Ranger (+0), Monk (+2)'"""
	var records = get_completion_records(tier)
	if records.is_empty():
		return ""

	var parts = []
	for record in records:
		var char_class = record.get("class_name", "Unknown")
		var curses = record.get("curse_count", 0)
		parts.append("%s (+%d)" % [char_class, curses])

	return "Beat with " + ", ".join(parts)

func mark_difficulty_completed(tier: DifficultyTier, class_id: String = "", curse_count: int = 0) -> void:
	# Add to legacy array if not already there
	if tier not in completed_difficulties:
		completed_difficulties.append(tier)
		difficulty_completed.emit(tier)

	# Get class display name
	var display_name = CLASS_DISPLAY_NAMES.get(class_id, class_id.capitalize())

	# Initialize records array for this tier if needed
	if not completion_records.has(tier):
		completion_records[tier] = []

	# Check if we already have a record for this class
	var existing_index = -1
	for i in completion_records[tier].size():
		if completion_records[tier][i].get("class_id") == class_id:
			existing_index = i
			break

	var new_record = {
		"class_id": class_id,
		"class_name": display_name,
		"curse_count": curse_count
	}

	if existing_index >= 0:
		# Update if new curse count is higher (harder challenge)
		if curse_count > completion_records[tier][existing_index].get("curse_count", 0):
			completion_records[tier][existing_index] = new_record
	else:
		# Add new record for this class
		completion_records[tier].append(new_record)

	save_progress()

func get_unlock_requirement(tier: DifficultyTier) -> DifficultyTier:
	# Returns which difficulty must be completed to unlock this one
	match tier:
		DifficultyTier.JUVENILE:
			return DifficultyTier.JUVENILE  # Always unlocked
		DifficultyTier.VERY_EASY:
			return DifficultyTier.JUVENILE
		DifficultyTier.EASY:
			return DifficultyTier.VERY_EASY
		DifficultyTier.NORMAL:
			return DifficultyTier.EASY
		DifficultyTier.NIGHTMARE:
			return DifficultyTier.NORMAL
		DifficultyTier.INFERNO:
			return DifficultyTier.NIGHTMARE
		DifficultyTier.THANKSGIVING_DINNER:
			return DifficultyTier.INFERNO
		_:
			return DifficultyTier.JUVENILE

func unlock_difficulty(tier: DifficultyTier) -> void:
	if tier not in unlocked_difficulties:
		unlocked_difficulties.append(tier)
		difficulty_unlocked.emit(tier)
		save_progress()

func unlock_next_difficulty() -> bool:
	"""Unlock the next difficulty tier after the current one. Returns true if a new difficulty was unlocked."""
	var next_tier = get_next_difficulty(current_difficulty)
	if next_tier != current_difficulty and not is_difficulty_unlocked(next_tier):
		unlock_difficulty(next_tier)
		return true
	return false

func get_next_difficulty(tier: DifficultyTier) -> DifficultyTier:
	"""Get the next difficulty tier after the given one."""
	match tier:
		DifficultyTier.JUVENILE:
			return DifficultyTier.VERY_EASY
		DifficultyTier.VERY_EASY:
			return DifficultyTier.EASY
		DifficultyTier.EASY:
			return DifficultyTier.NORMAL
		DifficultyTier.NORMAL:
			return DifficultyTier.NIGHTMARE
		DifficultyTier.NIGHTMARE:
			return DifficultyTier.INFERNO
		DifficultyTier.INFERNO:
			return DifficultyTier.THANKSGIVING_DINNER
		DifficultyTier.THANKSGIVING_DINNER:
			return DifficultyTier.THANKSGIVING_DINNER  # Max tier
		_:
			return DifficultyTier.JUVENILE

func get_all_difficulties() -> Array[DifficultyTier]:
	return [
		DifficultyTier.JUVENILE,
		DifficultyTier.VERY_EASY,
		DifficultyTier.EASY,
		DifficultyTier.NORMAL,
		DifficultyTier.NIGHTMARE,
		DifficultyTier.INFERNO,
		DifficultyTier.THANKSGIVING_DINNER,
	]

# ============================================
# PERSISTENCE
# ============================================

func save_progress() -> void:
	var save_data = {
		"unlocked_difficulties": [],
		"completed_difficulties": [],
		"completion_records": {},
	}

	for tier in unlocked_difficulties:
		save_data["unlocked_difficulties"].append(tier)

	for tier in completed_difficulties:
		save_data["completed_difficulties"].append(tier)

	# Save completion records (convert tier keys to int for JSON compatibility)
	for tier in completion_records:
		save_data["completion_records"][tier] = completion_records[tier]

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		# Ensure Juvenile is always unlocked
		if DifficultyTier.JUVENILE not in unlocked_difficulties:
			unlocked_difficulties.append(DifficultyTier.JUVENILE)
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()

		if data is Dictionary:
			unlocked_difficulties.clear()
			var saved_unlocks = data.get("unlocked_difficulties", [])
			for tier_val in saved_unlocks:
				if tier_val is int and tier_val in DifficultyTier.values():
					unlocked_difficulties.append(tier_val as DifficultyTier)

			# Load completed difficulties
			completed_difficulties.clear()
			var saved_completed = data.get("completed_difficulties", [])
			for tier_val in saved_completed:
				if tier_val is int and tier_val in DifficultyTier.values():
					completed_difficulties.append(tier_val as DifficultyTier)

			# Load completion records
			completion_records.clear()
			var saved_records = data.get("completion_records", {})
			for tier_key in saved_records:
				var tier_val = int(tier_key) if tier_key is String else tier_key
				if tier_val in DifficultyTier.values():
					completion_records[tier_val] = saved_records[tier_key]

			# Ensure Juvenile is always unlocked
			if DifficultyTier.JUVENILE not in unlocked_difficulties:
				unlocked_difficulties.append(DifficultyTier.JUVENILE)

# ============================================
# DEBUG FUNCTIONS
# ============================================

func debug_unlock_all() -> void:
	"""Debug function to unlock all difficulties."""
	for tier in get_all_difficulties():
		if tier not in unlocked_difficulties:
			unlocked_difficulties.append(tier)
	save_progress()

func debug_reset_progress() -> void:
	"""Reset all difficulty progress."""
	unlocked_difficulties.clear()
	unlocked_difficulties.append(DifficultyTier.JUVENILE)
	completed_difficulties.clear()
	completion_records.clear()
	save_progress()
