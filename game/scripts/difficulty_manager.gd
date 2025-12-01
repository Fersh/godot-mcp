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

# Difficulty configuration data
const DIFFICULTY_DATA = {
	DifficultyTier.JUVENILE: {
		"name": "Juvenile",
		"description": "For those who fear the dark.",
		"health_mult": 1.0,
		"damage_mult": 1.0,
		"speed_mult": 1.0,
		"spawn_rate_mult": 1.0,
		"color": Color(0.5, 0.8, 0.5),  # Soft green
	},
	DifficultyTier.VERY_EASY: {
		"name": "Very Easy",
		"description": "Training wheels are off.",
		"health_mult": 1.5,
		"damage_mult": 1.25,
		"speed_mult": 1.1,
		"spawn_rate_mult": 1.15,
		"color": Color(0.6, 0.7, 0.9),  # Light blue
	},
	DifficultyTier.EASY: {
		"name": "Easy",
		"description": "A fair challenge awaits.",
		"health_mult": 2.25,
		"damage_mult": 1.5,
		"speed_mult": 1.2,
		"spawn_rate_mult": 1.3,
		"color": Color(0.9, 0.9, 0.5),  # Yellow
	},
	DifficultyTier.NORMAL: {
		"name": "Normal",
		"description": "This is how it was meant to be played.",
		"health_mult": 3.5,
		"damage_mult": 2.0,
		"speed_mult": 1.3,
		"spawn_rate_mult": 1.5,
		"color": Color(0.9, 0.6, 0.3),  # Orange
	},
	DifficultyTier.NIGHTMARE: {
		"name": "Nightmare",
		"description": "Only the worthy survive.",
		"health_mult": 5.0,
		"damage_mult": 2.5,
		"speed_mult": 1.4,
		"spawn_rate_mult": 1.75,
		"color": Color(0.9, 0.2, 0.2),  # Red
	},
}

# Signals
signal difficulty_changed(tier: DifficultyTier)
signal mode_changed(mode: GameMode)
signal difficulty_unlocked(tier: DifficultyTier)

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

# ============================================
# MODE & DIFFICULTY SETTERS
# ============================================

func set_mode(mode: GameMode) -> void:
	current_mode = mode
	mode_changed.emit(mode)

func set_difficulty(tier: DifficultyTier) -> void:
	if is_difficulty_unlocked(tier):
		current_difficulty = tier
		difficulty_changed.emit(tier)

# ============================================
# UNLOCK SYSTEM
# ============================================

func is_difficulty_unlocked(tier: DifficultyTier) -> bool:
	return tier in unlocked_difficulties

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
	}

	for tier in unlocked_difficulties:
		save_data["unlocked_difficulties"].append(tier)

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
