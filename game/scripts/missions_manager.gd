extends Node

# Missions Manager - Tracks mission progress and rewards
# Add to autoload as "MissionsManager"

const SAVE_PATH = "user://missions.save"

signal mission_completed(mission: MissionData)
signal mission_progress_updated(mission: MissionData)
signal reward_claimed(mission: MissionData)
signal daily_missions_refreshed()

# All mission definitions
var all_missions: Dictionary = {}  # id -> MissionData

# Cached arrays for quick access
var permanent_missions: Array = []
var daily_missions: Array = []
var social_missions: Array = []

# Daily mission state
var daily_date: String = ""
var active_daily_missions: Array = []  # IDs of today's daily missions

# Single-run tracking (reset each run)
var run_kills: int = 0
var run_elite_kills: int = 0
var run_boss_kills: int = 0
var run_enemy_kills: Dictionary = {}  # enemy_type -> count
var run_coins_earned: int = 0
var run_time: float = 0.0
var run_wave: int = 0
var run_character: String = ""
var run_difficulty: int = 0
var run_game_mode: int = 0

func _ready() -> void:
	_initialize_all_missions()
	load_progress()
	_check_daily_refresh()

# ============================================
# MISSION INITIALIZATION
# ============================================

func _initialize_all_missions() -> void:
	"""Create all mission definitions."""

	# Kill missions (cumulative) - reduced rewards
	_add_mission(MissionData.create_kill_mission("kill_1", "First Blood", "Kill your first enemy", 1, 5))
	_add_mission(MissionData.create_kill_mission("kill_50", "Getting Started", "Kill 50 enemies", 50, 10))
	_add_mission(MissionData.create_kill_mission("kill_100", "Century Club", "Kill 100 enemies", 100, 15))
	_add_mission(MissionData.create_kill_mission("kill_250", "Monster Hunter", "Kill 250 enemies", 250, 25))
	_add_mission(MissionData.create_kill_mission("kill_500", "Slayer", "Kill 500 enemies", 500, 40))
	_add_mission(MissionData.create_kill_mission("kill_1000", "Exterminator", "Kill 1,000 enemies", 1000, 60))
	_add_mission(MissionData.create_kill_mission("kill_2500", "Mass Extinction", "Kill 2,500 enemies", 2500, 100))
	_add_mission(MissionData.create_kill_mission("kill_5000", "Genocide", "Kill 5,000 enemies", 5000, 150))
	_add_mission(MissionData.create_kill_mission("kill_10000", "Apocalypse Bringer", "Kill 10,000 enemies", 10000, 250))
	_add_mission(MissionData.create_kill_mission("kill_25000", "Death Incarnate", "Kill 25,000 enemies", 25000, 400))
	_add_mission(MissionData.create_kill_mission("kill_50000", "World Ender", "Kill 50,000 enemies", 50000, 600))
	_add_mission(MissionData.create_kill_mission("kill_100000", "Infinity Killer", "Kill 100,000 enemies", 100000, 1000))

	# Kill missions (single run) - reduced rewards
	_add_mission(MissionData.create_kill_mission("run_kill_100", "Warm Up", "Kill 100 enemies in a single run", 100, 20, MissionData.TrackingMode.SINGLE_RUN))
	_add_mission(MissionData.create_kill_mission("run_kill_250", "Hot Streak", "Kill 250 enemies in a single run", 250, 40, MissionData.TrackingMode.SINGLE_RUN))
	_add_mission(MissionData.create_kill_mission("run_kill_500", "Rampage", "Kill 500 enemies in a single run", 500, 70, MissionData.TrackingMode.SINGLE_RUN))
	_add_mission(MissionData.create_kill_mission("run_kill_1000", "Unstoppable", "Kill 1,000 enemies in a single run", 1000, 120, MissionData.TrackingMode.SINGLE_RUN))
	_add_mission(MissionData.create_kill_mission("run_kill_1500", "One Man Army", "Kill 1,500 enemies in a single run", 1500, 200, MissionData.TrackingMode.SINGLE_RUN))

	# Elite kills - reduced rewards
	_add_mission(MissionData.create_elite_mission("elite_1", "Elite Hunter", "Kill your first elite enemy", 1, 10))
	_add_mission(MissionData.create_elite_mission("elite_10", "Elite Slayer", "Kill 10 elite enemies", 10, 30))
	_add_mission(MissionData.create_elite_mission("elite_50", "Elite Exterminator", "Kill 50 elite enemies", 50, 80))
	_add_mission(MissionData.create_elite_mission("elite_100", "Elite Nightmare", "Kill 100 elite enemies", 100, 150))

	# Boss kills - reduced rewards
	_add_mission(MissionData.create_boss_mission("boss_1", "Boss Killer", "Defeat the Minotaur", 1, 50))
	_add_mission(MissionData.create_boss_mission("boss_5", "Boss Slayer", "Defeat 5 bosses", 5, 100))
	_add_mission(MissionData.create_boss_mission("boss_25", "Boss Hunter", "Defeat 25 bosses", 25, 250))
	_add_mission(MissionData.create_boss_mission("boss_100", "Boss Exterminator", "Defeat 100 bosses", 100, 500))

	# Specific enemy kills - reduced rewards
	_add_mission(MissionData.create_enemy_mission("kill_ratfolk_100", "Rat Catcher", "Kill 100 Ratfolk", "ratfolk", 100, 20))
	_add_mission(MissionData.create_enemy_mission("kill_skeleton_100", "Skeleton Smasher", "Kill 100 Skeletons", "skeleton", 100, 20))
	_add_mission(MissionData.create_enemy_mission("kill_slime_100", "Slime Splatter", "Kill 100 Slimes", "slime", 100, 20))
	_add_mission(MissionData.create_enemy_mission("kill_imp_50", "Imp Impaler", "Kill 50 Imps", "imp", 50, 20))
	_add_mission(MissionData.create_enemy_mission("kill_ghoul_50", "Ghoul Grinder", "Kill 50 Ghouls", "ghoul", 50, 20))
	_add_mission(MissionData.create_enemy_mission("kill_kobold_50", "Kobold Crusher", "Kill 50 Kobold Priests", "kobold_priest", 50, 25))
	_add_mission(MissionData.create_enemy_mission("kill_eye_25", "Eye Spy", "Kill 25 Eye Monsters", "eye_monster", 25, 25))
	_add_mission(MissionData.create_enemy_mission("kill_bat_50", "Bat Basher", "Kill 50 Bats", "bat", 50, 20))
	_add_mission(MissionData.create_enemy_mission("kill_golem_25", "Golem Breaker", "Kill 25 Golems", "golem", 25, 30))
	_add_mission(MissionData.create_enemy_mission("kill_ratfolk_500", "Vermin Exterminator", "Kill 500 Ratfolk", "ratfolk", 500, 60))
	_add_mission(MissionData.create_enemy_mission("kill_skeleton_500", "Bone Collector", "Kill 500 Skeletons", "skeleton", 500, 60))
	_add_mission(MissionData.create_enemy_mission("kill_slime_500", "Slime Time", "Kill 500 Slimes", "slime", 500, 60))

	# Difficulty missions - reduced rewards
	_add_mission(MissionData.create_difficulty_mission("beat_pitiful", "Baby Steps", "Beat Pitiful difficulty", 0, 10))
	_add_mission(MissionData.create_difficulty_mission("beat_easy", "Easy Peasy", "Beat Easy difficulty", 1, 30))
	_add_mission(MissionData.create_difficulty_mission("beat_normal", "Normal Day", "Beat Normal difficulty", 2, 60))
	_add_mission(MissionData.create_difficulty_mission("beat_nightmare", "Nightmare Fuel", "Beat Nightmare difficulty", 3, 100))
	_add_mission(MissionData.create_difficulty_mission("beat_hell", "Hell Raiser", "Beat Hell difficulty", 4, 200))
	_add_mission(MissionData.create_difficulty_mission("beat_inferno", "Inferno Walker", "Beat Inferno difficulty", 5, 350))
	_add_mission(MissionData.create_difficulty_mission("beat_thanksgiving", "Thanksgiving Champion", "Beat Thanksgiving Dinner difficulty", 6, 500))

	# Character missions - Play as - reduced rewards
	_add_mission(MissionData.create_character_mission("play_archer", "Robin's Hood", "Complete a run as Archer", "archer", 15))
	_add_mission(MissionData.create_character_mission("play_knight", "Knight's Honor", "Complete a run as Knight", "knight", 15))
	_add_mission(MissionData.create_character_mission("play_beast", "Unleash the Beast", "Complete a run as Beast", "beast", 15))
	_add_mission(MissionData.create_character_mission("play_mage", "Arcane Master", "Complete a run as Mage", "mage", 15))
	_add_mission(MissionData.create_character_mission("play_monk", "Inner Peace", "Complete a run as Monk", "monk", 15))
	_add_mission(MissionData.create_character_mission("play_barbarian", "Chad Energy", "Complete a run as Barbarian", "barbarian", 20))
	_add_mission(MissionData.create_character_mission("play_assassin", "Shadow Walker", "Complete a run as Assassin", "assassin", 15))

	# Character missions - Win Challenge Mode - reduced rewards
	_add_mission(MissionData.create_character_mission("win_archer", "Archer Ace", "Win Challenge Mode with Archer", "archer", 50, true))
	_add_mission(MissionData.create_character_mission("win_knight", "Knight Champion", "Win Challenge Mode with Knight", "knight", 50, true))
	_add_mission(MissionData.create_character_mission("win_beast", "Beast Master", "Win Challenge Mode with Beast", "beast", 50, true))
	_add_mission(MissionData.create_character_mission("win_mage", "Archmage", "Win Challenge Mode with Mage", "mage", 50, true))
	_add_mission(MissionData.create_character_mission("win_monk", "Grandmaster Monk", "Win Challenge Mode with Monk", "monk", 50, true))
	_add_mission(MissionData.create_character_mission("win_barbarian", "Barbarian King", "Win Challenge Mode with Barbarian", "barbarian", 60, true))
	_add_mission(MissionData.create_character_mission("win_assassin", "Master Assassin", "Win Challenge Mode with Assassin", "assassin", 50, true))

	# Survival missions (Endless) - reduced rewards
	_add_mission(MissionData.create_survival_mission("survive_5min", "Survivor", "Survive 5 minutes in Endless Mode", 300, 30, 0))
	_add_mission(MissionData.create_survival_mission("survive_10min", "Endurance", "Survive 10 minutes in Endless Mode", 600, 60, 0))
	_add_mission(MissionData.create_survival_mission("survive_15min", "Marathon", "Survive 15 minutes in Endless Mode", 900, 100, 0))
	_add_mission(MissionData.create_survival_mission("survive_20min", "Iron Will", "Survive 20 minutes in Endless Mode", 1200, 150, 0))
	_add_mission(MissionData.create_survival_mission("survive_30min", "Immortal", "Survive 30 minutes in Endless Mode", 1800, 300, 0))

	# Wave missions (Endless) - reduced rewards
	var wave_mission_5 = MissionData.new("wave_5")
	wave_mission_5.title = "Wave 5"
	wave_mission_5.description = "Reach Wave 5 in Endless Mode"
	wave_mission_5.type = MissionData.MissionType.SURVIVAL
	wave_mission_5.category = MissionData.MissionCategory.PERMANENT
	wave_mission_5.tracking_mode = MissionData.TrackingMode.SINGLE_RUN
	wave_mission_5.game_mode = 0
	wave_mission_5.target_value = 5
	wave_mission_5.reward_coins = 20
	_add_mission(wave_mission_5)

	var wave_mission_10 = MissionData.new("wave_10")
	wave_mission_10.title = "Wave 10"
	wave_mission_10.description = "Reach Wave 10 in Endless Mode"
	wave_mission_10.type = MissionData.MissionType.SURVIVAL
	wave_mission_10.category = MissionData.MissionCategory.PERMANENT
	wave_mission_10.tracking_mode = MissionData.TrackingMode.SINGLE_RUN
	wave_mission_10.game_mode = 0
	wave_mission_10.target_value = 10
	wave_mission_10.reward_coins = 40
	_add_mission(wave_mission_10)

	var wave_mission_15 = MissionData.new("wave_15")
	wave_mission_15.title = "Wave 15"
	wave_mission_15.description = "Reach Wave 15 in Endless Mode"
	wave_mission_15.type = MissionData.MissionType.SURVIVAL
	wave_mission_15.category = MissionData.MissionCategory.PERMANENT
	wave_mission_15.tracking_mode = MissionData.TrackingMode.SINGLE_RUN
	wave_mission_15.game_mode = 0
	wave_mission_15.target_value = 15
	wave_mission_15.reward_coins = 70
	_add_mission(wave_mission_15)

	var wave_mission_20 = MissionData.new("wave_20")
	wave_mission_20.title = "Wave 20"
	wave_mission_20.description = "Reach Wave 20 in Endless Mode"
	wave_mission_20.type = MissionData.MissionType.SURVIVAL
	wave_mission_20.category = MissionData.MissionCategory.PERMANENT
	wave_mission_20.tracking_mode = MissionData.TrackingMode.SINGLE_RUN
	wave_mission_20.game_mode = 0
	wave_mission_20.target_value = 20
	wave_mission_20.reward_coins = 120
	_add_mission(wave_mission_20)

	# Economy missions - reduced rewards
	var econ_100 = MissionData.new("earn_100")
	econ_100.title = "First Coins"
	econ_100.description = "Earn 100 coins total"
	econ_100.type = MissionData.MissionType.ECONOMY
	econ_100.category = MissionData.MissionCategory.PERMANENT
	econ_100.tracking_mode = MissionData.TrackingMode.CUMULATIVE
	econ_100.target_value = 100
	econ_100.reward_coins = 10
	_add_mission(econ_100)

	var econ_1000 = MissionData.new("earn_1000")
	econ_1000.title = "Penny Pincher"
	econ_1000.description = "Earn 1,000 coins total"
	econ_1000.type = MissionData.MissionType.ECONOMY
	econ_1000.category = MissionData.MissionCategory.PERMANENT
	econ_1000.tracking_mode = MissionData.TrackingMode.CUMULATIVE
	econ_1000.target_value = 1000
	econ_1000.reward_coins = 25
	_add_mission(econ_1000)

	var econ_10000 = MissionData.new("earn_10000")
	econ_10000.title = "Money Bags"
	econ_10000.description = "Earn 10,000 coins total"
	econ_10000.type = MissionData.MissionType.ECONOMY
	econ_10000.category = MissionData.MissionCategory.PERMANENT
	econ_10000.tracking_mode = MissionData.TrackingMode.CUMULATIVE
	econ_10000.target_value = 10000
	econ_10000.reward_coins = 50
	_add_mission(econ_10000)

	var econ_50000 = MissionData.new("earn_50000")
	econ_50000.title = "Wealthy"
	econ_50000.description = "Earn 50,000 coins total"
	econ_50000.type = MissionData.MissionType.ECONOMY
	econ_50000.category = MissionData.MissionCategory.PERMANENT
	econ_50000.tracking_mode = MissionData.TrackingMode.CUMULATIVE
	econ_50000.target_value = 50000
	econ_50000.reward_coins = 150
	_add_mission(econ_50000)

	var econ_100000 = MissionData.new("earn_100000")
	econ_100000.title = "Rich"
	econ_100000.description = "Earn 100,000 coins total"
	econ_100000.type = MissionData.MissionType.ECONOMY
	econ_100000.category = MissionData.MissionCategory.PERMANENT
	econ_100000.tracking_mode = MissionData.TrackingMode.CUMULATIVE
	econ_100000.target_value = 100000
	econ_100000.reward_coins = 300
	_add_mission(econ_100000)

	# Run count missions - reduced rewards
	var runs_1 = MissionData.new("runs_1")
	runs_1.title = "First Run"
	runs_1.description = "Complete your first run"
	runs_1.type = MissionData.MissionType.MISC
	runs_1.category = MissionData.MissionCategory.PERMANENT
	runs_1.tracking_mode = MissionData.TrackingMode.CUMULATIVE
	runs_1.target_value = 1
	runs_1.reward_coins = 10
	_add_mission(runs_1)

	var runs_10 = MissionData.new("runs_10")
	runs_10.title = "10 Runs"
	runs_10.description = "Complete 10 runs"
	runs_10.type = MissionData.MissionType.MISC
	runs_10.category = MissionData.MissionCategory.PERMANENT
	runs_10.tracking_mode = MissionData.TrackingMode.CUMULATIVE
	runs_10.target_value = 10
	runs_10.reward_coins = 25
	_add_mission(runs_10)

	var runs_50 = MissionData.new("runs_50")
	runs_50.title = "50 Runs"
	runs_50.description = "Complete 50 runs"
	runs_50.type = MissionData.MissionType.MISC
	runs_50.category = MissionData.MissionCategory.PERMANENT
	runs_50.tracking_mode = MissionData.TrackingMode.CUMULATIVE
	runs_50.target_value = 50
	runs_50.reward_coins = 50
	_add_mission(runs_50)

	var runs_100 = MissionData.new("runs_100")
	runs_100.title = "100 Runs"
	runs_100.description = "Complete 100 runs"
	runs_100.type = MissionData.MissionType.MISC
	runs_100.category = MissionData.MissionCategory.PERMANENT
	runs_100.tracking_mode = MissionData.TrackingMode.CUMULATIVE
	runs_100.target_value = 100
	runs_100.reward_coins = 100
	_add_mission(runs_100)

	# Social missions - reduced rewards
	_add_mission(MissionData.create_social_mission("twitter_follow", "Follow us on Twitter/X", "Follow us on Twitter/X for updates", 50))
	_add_mission(MissionData.create_social_mission("discord_join", "Join our Discord Server", "Join the community Discord server", 50))
	_add_mission(MissionData.create_social_mission("rate_game", "Rate Us", "Rate the game on the app store", 75))
	_add_mission(MissionData.create_social_mission("youtube_sub", "YouTube Subscriber", "Subscribe to our YouTube channel", 50))

	# Secret missions - reduced rewards
	var secret_close_call = MissionData.create_secret_mission("secret_close_call", "Close Call", "Win with 1 HP remaining", MissionData.MissionType.SECRET, 1, 100)
	_add_mission(secret_close_call)

	var secret_speedster = MissionData.create_secret_mission("secret_speedster", "Speedster", "Kill 10 enemies in 5 seconds", MissionData.MissionType.SECRET, 1, 50)
	_add_mission(secret_speedster)

	# Categorize missions
	for mission in all_missions.values():
		match mission.category:
			MissionData.MissionCategory.PERMANENT:
				permanent_missions.append(mission)
			MissionData.MissionCategory.DAILY:
				daily_missions.append(mission)
			MissionData.MissionCategory.SOCIAL:
				social_missions.append(mission)

func _add_mission(mission: MissionData) -> void:
	all_missions[mission.id] = mission

# ============================================
# PROGRESS TRACKING - Called from game events
# ============================================

func track_kill(enemy_type: String = "") -> void:
	"""Called when any enemy is killed."""
	run_kills += 1

	# Track specific enemy type
	if enemy_type != "":
		if not run_enemy_kills.has(enemy_type):
			run_enemy_kills[enemy_type] = 0
		run_enemy_kills[enemy_type] += 1

	# Update cumulative kill missions
	for mission in all_missions.values():
		if mission.is_completed or mission.type != MissionData.MissionType.KILL:
			continue
		if mission.tracking_mode == MissionData.TrackingMode.CUMULATIVE:
			if mission.add_progress(1):
				mission_completed.emit(mission)
				save_progress()

	# Update specific enemy missions (cumulative)
	if enemy_type != "":
		for mission in all_missions.values():
			if mission.is_completed or mission.type != MissionData.MissionType.SPECIFIC_ENEMY:
				continue
			if mission.enemy_type == enemy_type and mission.tracking_mode == MissionData.TrackingMode.CUMULATIVE:
				if mission.add_progress(1):
					mission_completed.emit(mission)
					save_progress()

func track_elite_kill() -> void:
	"""Called when an elite enemy is killed."""
	run_elite_kills += 1

	for mission in all_missions.values():
		if mission.is_completed or mission.type != MissionData.MissionType.ELITE_KILL:
			continue
		if mission.add_progress(1):
			mission_completed.emit(mission)
			save_progress()

func track_boss_kill() -> void:
	"""Called when a boss is killed."""
	run_boss_kills += 1

	for mission in all_missions.values():
		if mission.is_completed or mission.type != MissionData.MissionType.BOSS_KILL:
			continue
		if mission.add_progress(1):
			mission_completed.emit(mission)
			save_progress()

func track_coins_earned(amount: int) -> void:
	"""Called when coins are earned."""
	run_coins_earned += amount

	for mission in all_missions.values():
		if mission.is_completed or mission.type != MissionData.MissionType.ECONOMY:
			continue
		if mission.tracking_mode == MissionData.TrackingMode.CUMULATIVE:
			if mission.add_progress(amount):
				mission_completed.emit(mission)
				save_progress()

func track_difficulty_completed(tier: int, victory: bool) -> void:
	"""Called when a difficulty tier is completed."""
	if not victory:
		return

	for mission in all_missions.values():
		if mission.is_completed or mission.type != MissionData.MissionType.DIFFICULTY:
			continue
		if mission.difficulty_tier == tier:
			mission.current_progress = 1
			if mission.check_completion():
				mission_completed.emit(mission)
				save_progress()

func track_character_run(char_id: String, victory: bool) -> void:
	"""Called when a run ends with a specific character."""
	for mission in all_missions.values():
		if mission.is_completed or mission.type != MissionData.MissionType.CHARACTER:
			continue
		if mission.character_id != char_id:
			continue
		if mission.requires_victory and not victory:
			continue
		mission.current_progress = 1
		if mission.check_completion():
			mission_completed.emit(mission)
			save_progress()

func track_run_completed() -> void:
	"""Called when any run ends."""
	for mission in all_missions.values():
		if mission.is_completed or mission.type != MissionData.MissionType.MISC:
			continue
		if mission.add_progress(1):
			mission_completed.emit(mission)
			save_progress()

func track_social_action(action_id: String) -> void:
	"""Called when a social action is completed (e.g., clicked Twitter link)."""
	if not all_missions.has(action_id):
		return
	var mission = all_missions[action_id]
	if mission.is_completed:
		return
	mission.current_progress = 1
	if mission.check_completion():
		mission_completed.emit(mission)
		save_progress()

# ============================================
# RUN LIFECYCLE
# ============================================

func start_run(char_id: String, difficulty: int, game_mode: int) -> void:
	"""Called when a new run starts."""
	run_kills = 0
	run_elite_kills = 0
	run_boss_kills = 0
	run_enemy_kills.clear()
	run_coins_earned = 0
	run_time = 0.0
	run_wave = 0
	run_character = char_id
	run_difficulty = difficulty
	run_game_mode = game_mode

	# Reset single-run mission progress
	for mission in all_missions.values():
		if mission.tracking_mode == MissionData.TrackingMode.SINGLE_RUN and not mission.is_completed:
			mission.current_progress = 0

func update_run_time(time: float) -> void:
	"""Update current run time."""
	run_time = time

func update_run_wave(wave: int) -> void:
	"""Update current wave in endless mode."""
	run_wave = wave

func end_run(victory: bool) -> void:
	"""Called when a run ends. Evaluates single-run missions."""

	# Check single-run kill missions
	for mission in all_missions.values():
		if mission.is_completed:
			continue
		if mission.tracking_mode != MissionData.TrackingMode.SINGLE_RUN:
			continue

		match mission.type:
			MissionData.MissionType.KILL:
				mission.current_progress = run_kills
				if mission.check_completion():
					mission_completed.emit(mission)
			MissionData.MissionType.SURVIVAL:
				# Check if correct game mode
				if mission.game_mode >= 0 and mission.game_mode != run_game_mode:
					continue
				# For time-based, target is in seconds
				if mission.id.begins_with("survive_"):
					mission.current_progress = int(run_time)
				# For wave-based
				elif mission.id.begins_with("wave_"):
					mission.current_progress = run_wave
				if mission.check_completion():
					mission_completed.emit(mission)
			MissionData.MissionType.SPECIFIC_ENEMY:
				var count = run_enemy_kills.get(mission.enemy_type, 0)
				mission.current_progress = maxi(mission.current_progress, count)
				if mission.check_completion():
					mission_completed.emit(mission)

	# Track character completion
	track_character_run(run_character, victory)

	# Track difficulty completion
	if victory and run_game_mode == 1:  # Challenge mode
		track_difficulty_completed(run_difficulty, victory)

	# Track run completed
	track_run_completed()

	save_progress()

# ============================================
# REWARD CLAIMING
# ============================================

func claim_reward(mission_id: String) -> bool:
	"""Claim reward for a completed mission. Returns true if successful."""
	if not all_missions.has(mission_id):
		return false

	var mission = all_missions[mission_id]
	if not mission.is_completed or mission.is_claimed:
		return false

	# Award coins
	if mission.reward_coins > 0 and StatsManager:
		StatsManager.spendable_coins += mission.reward_coins
		StatsManager.save_stats()

	# Award ability unlock
	if mission.reward_unlock_id != "" and UnlocksManager:
		match mission.reward_unlock_type:
			"passive":
				if mission.reward_unlock_id not in UnlocksManager.unlocked_passives:
					UnlocksManager.unlocked_passives.append(mission.reward_unlock_id)
			"active":
				if mission.reward_unlock_id not in UnlocksManager.unlocked_actives:
					UnlocksManager.unlocked_actives.append(mission.reward_unlock_id)
			"ultimate":
				if mission.reward_unlock_id not in UnlocksManager.unlocked_ultimates:
					UnlocksManager.unlocked_ultimates.append(mission.reward_unlock_id)
		UnlocksManager.save_unlocks()

	mission.is_claimed = true
	reward_claimed.emit(mission)
	save_progress()
	return true

func has_unclaimed_rewards() -> bool:
	"""Check if any missions have unclaimed rewards."""
	for mission in all_missions.values():
		if mission.is_completed and not mission.is_claimed:
			return true
	return false

func get_unclaimed_count() -> int:
	"""Get count of missions with unclaimed rewards."""
	var count = 0
	for mission in all_missions.values():
		if mission.is_completed and not mission.is_claimed:
			count += 1
	return count

# ============================================
# DAILY MISSIONS
# ============================================

func _check_daily_refresh() -> void:
	"""Check if daily missions need to be refreshed."""
	var today = Time.get_date_string_from_system()
	if daily_date != today:
		_refresh_daily_missions()

func _refresh_daily_missions() -> void:
	"""Generate new daily missions for today."""
	daily_date = Time.get_date_string_from_system()
	active_daily_missions.clear()

	# Reset all daily mission progress
	for mission in daily_missions:
		mission.reset_progress()

	# Select 3 random daily missions
	var available = daily_missions.duplicate()
	available.shuffle()

	for i in range(mini(3, available.size())):
		active_daily_missions.append(available[i].id)

	daily_missions_refreshed.emit()
	save_progress()

func get_active_daily_missions() -> Array:
	"""Get the currently active daily missions."""
	var result: Array = []
	for id in active_daily_missions:
		if all_missions.has(id):
			result.append(all_missions[id])
	return result

# ============================================
# GETTERS
# ============================================

func get_mission(id: String) -> MissionData:
	return all_missions.get(id, null)

func get_all_permanent_missions() -> Array:
	return permanent_missions

func get_all_social_missions() -> Array:
	return social_missions

func get_completed_count() -> int:
	var count = 0
	for mission in permanent_missions:
		if mission.is_completed:
			count += 1
	return count

func get_total_permanent_count() -> int:
	return permanent_missions.size()

# ============================================
# PERSISTENCE
# ============================================

func save_progress() -> void:
	var mission_states: Dictionary = {}
	for id in all_missions:
		mission_states[id] = all_missions[id].to_dict()

	var save_data = {
		"mission_states": mission_states,
		"daily_date": daily_date,
		"active_daily_missions": active_daily_missions
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
			var mission_states = data.get("mission_states", {})
			for id in mission_states:
				if all_missions.has(id):
					all_missions[id].from_dict(mission_states[id])

			daily_date = data.get("daily_date", "")
			active_daily_missions = data.get("active_daily_missions", [])

func reset_all_progress() -> void:
	"""Reset all mission progress."""
	for mission in all_missions.values():
		mission.reset_progress()
	daily_date = ""
	active_daily_missions.clear()
	save_progress()
