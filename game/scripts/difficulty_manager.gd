extends Node

# Difficulty Manager - Central manager for difficulty settings and challenge mode
# Add to autoload as "DifficultyManager"

const SAVE_PATH = "user://difficulty.save"

# Game modes
enum GameMode { ENDLESS, CHALLENGE }

# Difficulty tiers
enum DifficultyTier { JUVENILE, VERY_EASY, EASY, NORMAL, NIGHTMARE }

# Current selection
var current_mode: GameMode = GameMode.ENDLESS
var current_difficulty: DifficultyTier = DifficultyTier.JUVENILE

# Unlocked difficulties (persisted)
var unlocked_difficulties: Array[DifficultyTier] = [DifficultyTier.JUVENILE]

# Completed difficulties (persisted) - tracks which difficulties have been beaten
var completed_difficulties: Array[DifficultyTier] = []

# Difficulty configuration data
const DIFFICULTY_DATA = {
	DifficultyTier.JUVENILE: {
		"name": "Pitiful",
		"description": "For those who fear the dark.",
		"health_mult": 1.0,
		"damage_mult": 1.0,
		"speed_mult": 1.0,
		"spawn_rate_mult": 1.0,
		"points_mult": 1.0,
		"color": Color(0.5, 0.8, 0.5),  # Soft green
		"modifiers": [],
	},
	DifficultyTier.VERY_EASY: {
		"name": "Easy",
		"description": "Enemies apply Slow on hit. 4x Points.",
		"health_mult": 3.2,
		"damage_mult": 2.7,
		"speed_mult": 1.24,
		"spawn_rate_mult": 2.4,
		"points_mult": 4.0,
		"color": Color(0.6, 0.7, 0.9),  # Light blue
		"modifiers": ["enemy_slow_on_hit"],
	},
	DifficultyTier.EASY: {
		"name": "Normal",
		"description": "+ Elites gain random affixes. 6x Points.",
		"health_mult": 4.8,
		"damage_mult": 3.3,
		"speed_mult": 1.44,
		"spawn_rate_mult": 2.8,
		"points_mult": 6.0,
		"color": Color(0.9, 0.9, 0.5),  # Yellow
		"modifiers": ["enemy_slow_on_hit", "elite_affixes"],
	},
	DifficultyTier.NORMAL: {
		"name": "Nightmare",
		"description": "+ Start at 75% HP. Boss enrages faster. 8x Points.",
		"health_mult": 7.6,
		"damage_mult": 4.2,
		"speed_mult": 1.64,
		"spawn_rate_mult": 3.2,
		"points_mult": 8.0,
		"color": Color(0.9, 0.6, 0.3),  # Orange
		"modifiers": ["enemy_slow_on_hit", "elite_affixes", "reduced_starting_hp", "faster_enrage"],
	},
	DifficultyTier.NIGHTMARE: {
		"name": "Hell",
		"description": "+ Healing reduced 50%. Champion enemies. 10x Points.",
		"health_mult": 11.0,
		"damage_mult": 5.5,
		"speed_mult": 1.9,
		"spawn_rate_mult": 3.7,
		"points_mult": 10.0,
		"color": Color(0.9, 0.2, 0.2),  # Red
		"modifiers": ["enemy_slow_on_hit", "elite_affixes", "reduced_starting_hp", "faster_enrage", "reduced_healing", "champion_enemies"],
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
		"description": "Rare champion enemies spawn with 2x HP and random effects",
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
		return 1.0  # Endless mode uses base stats
	return DIFFICULTY_DATA[current_difficulty]["health_mult"]

func get_damage_multiplier() -> float:
	if current_mode == GameMode.ENDLESS:
		return 1.0
	return DIFFICULTY_DATA[current_difficulty]["damage_mult"]

func get_speed_multiplier() -> float:
	if current_mode == GameMode.ENDLESS:
		return 1.0
	return DIFFICULTY_DATA[current_difficulty]["speed_mult"]

func get_spawn_rate_multiplier() -> float:
	if current_mode == GameMode.ENDLESS:
		return 1.0
	return DIFFICULTY_DATA[current_difficulty]["spawn_rate_mult"]

func get_points_multiplier() -> float:
	if current_mode == GameMode.ENDLESS:
		return 1.0
	return DIFFICULTY_DATA[current_difficulty]["points_mult"]

# ============================================
# MODIFIER CHECKS
# ============================================

func get_active_modifiers() -> Array:
	"""Get list of active modifier IDs for current difficulty."""
	if current_mode == GameMode.ENDLESS:
		return []
	return DIFFICULTY_DATA[current_difficulty]["modifiers"]

func has_modifier(modifier_id: String) -> bool:
	"""Check if a specific modifier is active."""
	if current_mode == GameMode.ENDLESS:
		return false
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
	"""Get starting HP percentage (1.0 = full, 0.75 = 75%)."""
	if has_reduced_starting_hp():
		return 0.75
	return 1.0

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
	"""Get healing effectiveness multiplier (1.0 = full, 0.5 = 50%)."""
	if has_reduced_healing():
		return 0.5
	return 1.0

func has_champion_enemies() -> bool:
	return has_modifier("champion_enemies")

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

func is_difficulty_completed(tier: DifficultyTier) -> bool:
	return tier in completed_difficulties

func mark_difficulty_completed(tier: DifficultyTier) -> void:
	if tier not in completed_difficulties:
		completed_difficulties.append(tier)
		difficulty_completed.emit(tier)
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
			return DifficultyTier.NIGHTMARE  # Max tier
		_:
			return DifficultyTier.JUVENILE

func get_all_difficulties() -> Array[DifficultyTier]:
	return [
		DifficultyTier.JUVENILE,
		DifficultyTier.VERY_EASY,
		DifficultyTier.EASY,
		DifficultyTier.NORMAL,
		DifficultyTier.NIGHTMARE,
	]

# ============================================
# PERSISTENCE
# ============================================

func save_progress() -> void:
	var save_data = {
		"unlocked_difficulties": [],
		"completed_difficulties": [],
	}

	for tier in unlocked_difficulties:
		save_data["unlocked_difficulties"].append(tier)

	for tier in completed_difficulties:
		save_data["completed_difficulties"].append(tier)

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
	"""Debug function to reset all progress."""
	unlocked_difficulties.clear()
	unlocked_difficulties.append(DifficultyTier.JUVENILE)
	save_progress()
