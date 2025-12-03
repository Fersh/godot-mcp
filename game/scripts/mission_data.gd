class_name MissionData
extends RefCounted

# Mission Data - Defines a single mission/challenge
# Used by MissionsManager to track progress and rewards

enum MissionType {
	KILL,              # Kill X enemies (cumulative or single run)
	ELITE_KILL,        # Kill X elite enemies
	BOSS_KILL,         # Kill X bosses
	SPECIFIC_ENEMY,    # Kill X of a specific enemy type
	DIFFICULTY,        # Beat a specific difficulty
	CHARACTER,         # Complete/win as specific character
	SURVIVAL,          # Survive X minutes or reach X wave
	ABILITY,           # Unlock or use abilities
	EQUIPMENT,         # Find or equip items
	ECONOMY,           # Earn or spend coins
	SCORE,             # Achieve score/combo milestones
	CURSE,             # Princess/curse related
	SOCIAL,            # Social engagement (Twitter, Discord)
	MISC,              # Miscellaneous (runs completed, etc.)
	SECRET             # Hidden achievements
}

enum MissionCategory {
	DAILY,             # Resets daily
	PERMANENT,         # One-time completion
	SOCIAL             # Social engagement missions
}

enum TrackingMode {
	CUMULATIVE,        # Progress persists across runs
	SINGLE_RUN,        # Must complete in one run (resets each run)
	INSTANT            # Triggered by specific event (difficulty beat, etc.)
}

# Mission definition
var id: String = ""
var title: String = ""
var description: String = ""
var type: MissionType = MissionType.KILL
var category: MissionCategory = MissionCategory.PERMANENT
var tracking_mode: TrackingMode = TrackingMode.CUMULATIVE

# Target and progress
var target_value: int = 1
var current_progress: int = 0

# Optional filters
var enemy_type: String = ""         # For SPECIFIC_ENEMY missions
var character_id: String = ""       # For CHARACTER missions
var difficulty_tier: int = -1       # For DIFFICULTY missions
var ability_id: String = ""         # For ABILITY missions
var game_mode: int = -1             # 0 = Endless, 1 = Challenge, -1 = Any
var requires_victory: bool = false  # Must win the run

# Rewards
var reward_coins: int = 0
var reward_unlock_id: String = ""   # Ability/character ID to unlock
var reward_unlock_type: String = "" # "passive", "active", "ultimate", "character"

# State
var is_completed: bool = false
var is_claimed: bool = false
var is_secret: bool = false

# Prerequisites (mission IDs that must be completed first)
var prerequisites: Array = []

# For daily missions
var daily_seed: int = 0  # Used for daily rotation

func _init(mission_id: String = "") -> void:
	id = mission_id

func get_progress_percent() -> float:
	if target_value <= 0:
		return 1.0 if is_completed else 0.0
	return clampf(float(current_progress) / float(target_value), 0.0, 1.0)

func get_progress_text() -> String:
	if is_completed:
		return "COMPLETE"
	return "%d/%d" % [mini(current_progress, target_value), target_value]

func check_completion() -> bool:
	if is_completed:
		return true
	if current_progress >= target_value:
		is_completed = true
		return true
	return false

func add_progress(amount: int = 1) -> bool:
	"""Add progress and return true if mission was just completed."""
	if is_completed:
		return false
	var was_complete = is_completed
	current_progress += amount
	check_completion()
	return is_completed and not was_complete

func reset_progress() -> void:
	"""Reset progress (for single-run or daily missions)."""
	current_progress = 0
	is_completed = false
	is_claimed = false

func to_dict() -> Dictionary:
	"""Serialize mission state for saving."""
	return {
		"id": id,
		"progress": current_progress,
		"completed": is_completed,
		"claimed": is_claimed
	}

func from_dict(data: Dictionary) -> void:
	"""Load mission state from save data."""
	current_progress = data.get("progress", 0)
	is_completed = data.get("completed", false)
	is_claimed = data.get("claimed", false)

# ============================================
# STATIC FACTORY METHODS
# ============================================

static func create_kill_mission(mission_id: String, title: String, desc: String, target: int, coins: int, tracking: TrackingMode = TrackingMode.CUMULATIVE) -> MissionData:
	var m = MissionData.new(mission_id)
	m.title = title
	m.description = desc
	m.type = MissionType.KILL
	m.category = MissionCategory.PERMANENT
	m.tracking_mode = tracking
	m.target_value = target
	m.reward_coins = coins
	return m

static func create_elite_mission(mission_id: String, title: String, desc: String, target: int, coins: int) -> MissionData:
	var m = MissionData.new(mission_id)
	m.title = title
	m.description = desc
	m.type = MissionType.ELITE_KILL
	m.category = MissionCategory.PERMANENT
	m.tracking_mode = TrackingMode.CUMULATIVE
	m.target_value = target
	m.reward_coins = coins
	return m

static func create_boss_mission(mission_id: String, title: String, desc: String, target: int, coins: int) -> MissionData:
	var m = MissionData.new(mission_id)
	m.title = title
	m.description = desc
	m.type = MissionType.BOSS_KILL
	m.category = MissionCategory.PERMANENT
	m.tracking_mode = TrackingMode.CUMULATIVE
	m.target_value = target
	m.reward_coins = coins
	return m

static func create_enemy_mission(mission_id: String, title: String, desc: String, enemy: String, target: int, coins: int) -> MissionData:
	var m = MissionData.new(mission_id)
	m.title = title
	m.description = desc
	m.type = MissionType.SPECIFIC_ENEMY
	m.category = MissionCategory.PERMANENT
	m.tracking_mode = TrackingMode.CUMULATIVE
	m.enemy_type = enemy
	m.target_value = target
	m.reward_coins = coins
	return m

static func create_difficulty_mission(mission_id: String, title: String, desc: String, tier: int, coins: int, unlock_id: String = "", unlock_type: String = "") -> MissionData:
	var m = MissionData.new(mission_id)
	m.title = title
	m.description = desc
	m.type = MissionType.DIFFICULTY
	m.category = MissionCategory.PERMANENT
	m.tracking_mode = TrackingMode.INSTANT
	m.difficulty_tier = tier
	m.target_value = 1
	m.reward_coins = coins
	m.reward_unlock_id = unlock_id
	m.reward_unlock_type = unlock_type
	return m

static func create_character_mission(mission_id: String, title: String, desc: String, char_id: String, coins: int, requires_win: bool = false) -> MissionData:
	var m = MissionData.new(mission_id)
	m.title = title
	m.description = desc
	m.type = MissionType.CHARACTER
	m.category = MissionCategory.PERMANENT
	m.tracking_mode = TrackingMode.INSTANT
	m.character_id = char_id
	m.requires_victory = requires_win
	m.target_value = 1
	m.reward_coins = coins
	return m

static func create_survival_mission(mission_id: String, title: String, desc: String, target: int, coins: int, mode: int = 0, is_time: bool = true) -> MissionData:
	var m = MissionData.new(mission_id)
	m.title = title
	m.description = desc
	m.type = MissionType.SURVIVAL
	m.category = MissionCategory.PERMANENT
	m.tracking_mode = TrackingMode.SINGLE_RUN
	m.game_mode = mode
	m.target_value = target
	m.reward_coins = coins
	return m

static func create_social_mission(mission_id: String, title: String, desc: String, coins: int, unlock_id: String = "", unlock_type: String = "") -> MissionData:
	var m = MissionData.new(mission_id)
	m.title = title
	m.description = desc
	m.type = MissionType.SOCIAL
	m.category = MissionCategory.SOCIAL
	m.tracking_mode = TrackingMode.INSTANT
	m.target_value = 1
	m.reward_coins = coins
	m.reward_unlock_id = unlock_id
	m.reward_unlock_type = unlock_type
	return m

static func create_daily_mission(mission_id: String, title: String, desc: String, type: MissionType, target: int, coins: int) -> MissionData:
	var m = MissionData.new(mission_id)
	m.title = title
	m.description = desc
	m.type = type
	m.category = MissionCategory.DAILY
	m.tracking_mode = TrackingMode.CUMULATIVE  # Cumulative within the day
	m.target_value = target
	m.reward_coins = coins
	return m

static func create_secret_mission(mission_id: String, title: String, desc: String, type: MissionType, target: int, coins: int) -> MissionData:
	var m = MissionData.new(mission_id)
	m.title = title
	m.description = desc
	m.type = type
	m.category = MissionCategory.PERMANENT
	m.tracking_mode = TrackingMode.INSTANT
	m.target_value = target
	m.reward_coins = coins
	m.is_secret = true
	return m
