extends Node

# Stats Manager - Tracks current run and lifetime stats
# Add to autoload as "StatsManager"

const SAVE_PATH = "user://stats.save"

# Current run stats
var run_kills: int = 0
var run_coins: int = 0
var run_time: float = 0.0
var run_level: int = 1
var run_wave: int = 0
var run_points: int = 0
var run_game_mode: int = 0  # 0 = Endless, 1 = Challenge
var run_difficulty: int = 0  # DifficultyTier enum value
var run_victory: bool = false  # Did player complete challenge mode?

# Lifetime stats (persisted)
var total_kills: int = 0
var total_coins: int = 0
var total_runs: int = 0
var total_time_played: float = 0.0
var best_time: float = 0.0
var best_kills: int = 0
var best_level: int = 0
var best_wave: int = 0
var best_coins: int = 0
var best_points: int = 0

# Spendable currency (earned from runs, spent in shop)
var spendable_coins: int = 0

func _ready() -> void:
	load_stats()

# Current run tracking
func add_kill() -> void:
	run_kills += 1

func add_coin() -> void:
	run_coins += 1

func set_time(time: float) -> void:
	run_time = time

func set_level(level: int) -> void:
	run_level = level

func set_wave(wave: int) -> void:
	run_wave = wave

func set_points(points: int) -> void:
	run_points = points

# Call when run ends
func end_run() -> void:
	total_runs += 1
	total_kills += run_kills
	total_coins += run_coins
	total_time_played += run_time

	# Sync monster kills to UnlocksManager
	if UnlocksManager:
		UnlocksManager.add_monster_kills(run_kills)
		UnlocksManager.reset_run_kills()

	# Track run end for missions
	if MissionsManager:
		MissionsManager.end_run(run_victory)
		MissionsManager.track_coins_earned(run_coins)

		# Update endless stats if in endless mode
		if run_game_mode == 0:  # Endless mode
			UnlocksManager.update_endless_stats(run_time, run_wave, run_points)

	# Add coins earned this run to spendable currency
	# Apply coin gain bonus from permanent upgrades
	var coin_bonus = 1.0
	if PermanentUpgrades:
		coin_bonus += PermanentUpgrades.get_all_bonuses().get("coin_gain", 0.0)

	# Apply curse multiplier (stacking bonus from princesses)
	if CurseEffects:
		coin_bonus *= CurseEffects.get_points_multiplier()

	spendable_coins += int(run_coins * coin_bonus)

	# Update best records
	if run_time > best_time:
		best_time = run_time
	if run_kills > best_kills:
		best_kills = run_kills
	if run_level > best_level:
		best_level = run_level
	if run_wave > best_wave:
		best_wave = run_wave
	if run_coins > best_coins:
		best_coins = run_coins
	if run_points > best_points:
		best_points = run_points

	save_stats()

# Reset for new run
func reset_run() -> void:
	run_kills = 0
	run_coins = 0
	run_time = 0.0
	run_level = 1
	run_wave = 0
	run_points = 0
	run_victory = false
	# Capture current mode/difficulty from DifficultyManager
	if DifficultyManager:
		run_game_mode = DifficultyManager.current_mode
		run_difficulty = DifficultyManager.current_difficulty
	else:
		run_game_mode = 0
		run_difficulty = 0

	# Start run tracking for missions
	if MissionsManager and CharacterManager:
		var char_id = CharacterManager.selected_character_id
		MissionsManager.start_run(char_id, run_difficulty, run_game_mode)

# Get current run stats as dictionary
func get_run_stats() -> Dictionary:
	return {
		"kills": run_kills,
		"coins": run_coins,
		"time": run_time,
		"level": run_level,
		"wave": run_wave,
		"points": run_points,
		"game_mode": run_game_mode,
		"difficulty": run_difficulty,
		"victory": run_victory,
	}

func set_victory(value: bool) -> void:
	"""Mark the current run as a victory (for challenge mode)."""
	run_victory = value

# Get lifetime stats as dictionary
func get_lifetime_stats() -> Dictionary:
	return {
		"total_kills": total_kills,
		"total_coins": total_coins,
		"total_runs": total_runs,
		"total_time_played": total_time_played,
		"best_time": best_time,
		"best_kills": best_kills,
		"best_level": best_level,
		"best_wave": best_wave,
		"best_coins": best_coins,
		"best_points": best_points
	}

# Save stats to file
func save_stats() -> void:
	var save_data = {
		"total_kills": total_kills,
		"total_coins": total_coins,
		"total_runs": total_runs,
		"total_time_played": total_time_played,
		"best_time": best_time,
		"best_kills": best_kills,
		"best_level": best_level,
		"best_wave": best_wave,
		"best_coins": best_coins,
		"best_points": best_points,
		"spendable_coins": spendable_coins
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

# Load stats from file
func load_stats() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()

		if data is Dictionary:
			total_kills = data.get("total_kills", 0)
			total_coins = data.get("total_coins", 0)
			total_runs = data.get("total_runs", 0)
			total_time_played = data.get("total_time_played", 0.0)
			best_time = data.get("best_time", 0.0)
			best_kills = data.get("best_kills", 0)
			best_level = data.get("best_level", 0)
			best_wave = data.get("best_wave", 0)
			best_coins = data.get("best_coins", 0)
			best_points = data.get("best_points", 0)
			spendable_coins = data.get("spendable_coins", 0)

# Format time as MM:SS
func format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]

# Reset all progress (for settings reset)
func reset_all_progress() -> void:
	total_kills = 0
	total_coins = 0
	total_runs = 0
	total_time_played = 0.0
	best_time = 0.0
	best_kills = 0
	best_level = 0
	best_wave = 0
	best_coins = 0
	best_points = 0
	spendable_coins = 0
	reset_run()
	save_stats()
