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

# Killstreak tracking
var current_killstreak: int = 0
var best_killstreak: int = 0
var last_kill_time: float = 0.0
const KILLSTREAK_TIMEOUT: float = 2.0  # Seconds between kills to maintain streak

# Damage tracking for no-hit achievements
var run_damage_taken: int = 0
var run_final_hp: int = 0
var run_max_hp: int = 0

# Ability tracking
var run_abilities_collected: int = 0
var run_legendary_abilities: int = 0
var run_ability_declines: int = 0

func _ready() -> void:
	_initialize_all_missions()
	load_progress()
	_check_daily_refresh()
	# Connect signal to track run completions
	mission_completed.connect(_on_mission_just_completed)

# ============================================
# MISSION INITIALIZATION
# ============================================

func _initialize_all_missions() -> void:
	"""Create all mission definitions."""

	# Kill missions (cumulative)
	_add_mission(MissionData.create_kill_mission("kill_1", "First Blood", "Kill your first enemy", 1, 50))
	_add_mission(MissionData.create_kill_mission("kill_50", "Getting Started", "Kill 50 enemies", 50, 50))
	_add_mission(MissionData.create_kill_mission("kill_100", "Century Club", "Kill 100 enemies", 100, 50))
	_add_mission(MissionData.create_kill_mission("kill_250", "Monster Hunter", "Kill 250 enemies", 250, 50))
	_add_mission(MissionData.create_kill_mission("kill_500", "Slayer", "Kill 500 enemies", 500, 50))
	_add_mission(MissionData.create_kill_mission("kill_1000", "Exterminator", "Kill 1,000 enemies", 1000, 60))
	_add_mission(MissionData.create_kill_mission("kill_2500", "Mass Extinction", "Kill 2,500 enemies", 2500, 100))
	_add_mission(MissionData.create_kill_mission("kill_5000", "Genocide", "Kill 5,000 enemies", 5000, 150))
	_add_mission(MissionData.create_kill_mission("kill_10000", "Apocalypse Bringer", "Kill 10,000 enemies", 10000, 250))
	_add_mission(MissionData.create_kill_mission("kill_25000", "Death Incarnate", "Kill 25,000 enemies", 25000, 400))
	_add_mission(MissionData.create_kill_mission("kill_50000", "World Ender", "Kill 50,000 enemies", 50000, 600))
	_add_mission(MissionData.create_kill_mission("kill_100000", "Infinity Killer", "Kill 100,000 enemies", 100000, 1000))

	# Kill missions (single run)
	_add_mission(MissionData.create_kill_mission("run_kill_100", "Warm Up", "Kill 100 enemies in a single run", 100, 50, MissionData.TrackingMode.SINGLE_RUN))
	_add_mission(MissionData.create_kill_mission("run_kill_250", "Hot Streak", "Kill 250 enemies in a single run", 250, 50, MissionData.TrackingMode.SINGLE_RUN))
	_add_mission(MissionData.create_kill_mission("run_kill_500", "Rampage", "Kill 500 enemies in a single run", 500, 70, MissionData.TrackingMode.SINGLE_RUN))
	_add_mission(MissionData.create_kill_mission("run_kill_1000", "Unstoppable", "Kill 1,000 enemies in a single run", 1000, 120, MissionData.TrackingMode.SINGLE_RUN))
	_add_mission(MissionData.create_kill_mission("run_kill_1500", "One Man Army", "Kill 1,500 enemies in a single run", 1500, 200, MissionData.TrackingMode.SINGLE_RUN))

	# Elite kills
	_add_mission(MissionData.create_elite_mission("elite_1", "Elite Hunter", "Kill your first elite enemy", 1, 50))
	_add_mission(MissionData.create_elite_mission("elite_10", "Elite Slayer", "Kill 10 elite enemies", 10, 50))
	_add_mission(MissionData.create_elite_mission("elite_50", "Elite Exterminator", "Kill 50 elite enemies", 50, 80))
	_add_mission(MissionData.create_elite_mission("elite_100", "Elite Nightmare", "Kill 100 elite enemies", 100, 150))

	# Boss kills - reduced rewards
	_add_mission(MissionData.create_boss_mission("boss_1", "Boss Killer", "Defeat the Minotaur", 1, 50))
	_add_mission(MissionData.create_boss_mission("boss_5", "Boss Slayer", "Defeat 5 bosses", 5, 100))
	_add_mission(MissionData.create_boss_mission("boss_25", "Boss Hunter", "Defeat 25 bosses", 25, 250))
	_add_mission(MissionData.create_boss_mission("boss_100", "Boss Exterminator", "Defeat 100 bosses", 100, 500))

	# Specific enemy kills
	_add_mission(MissionData.create_enemy_mission("kill_ratfolk_100", "Rat Catcher", "Kill 100 Ratfolk", "ratfolk", 100, 50))
	_add_mission(MissionData.create_enemy_mission("kill_skeleton_100", "Skeleton Smasher", "Kill 100 Skeletons", "skeleton", 100, 50))
	_add_mission(MissionData.create_enemy_mission("kill_slime_100", "Slime Splatter", "Kill 100 Slimes", "slime", 100, 50))
	_add_mission(MissionData.create_enemy_mission("kill_imp_50", "Imp Impaler", "Kill 50 Imps", "imp", 50, 50))
	_add_mission(MissionData.create_enemy_mission("kill_ghoul_50", "Ghoul Grinder", "Kill 50 Ghouls", "ghoul", 50, 50))
	_add_mission(MissionData.create_enemy_mission("kill_kobold_50", "Kobold Crusher", "Kill 50 Kobold Priests", "kobold_priest", 50, 50))
	_add_mission(MissionData.create_enemy_mission("kill_eye_25", "Eye Spy", "Kill 25 Eye Monsters", "eye_monster", 25, 50))
	_add_mission(MissionData.create_enemy_mission("kill_bat_50", "Bat Basher", "Kill 50 Bats", "bat", 50, 50))
	_add_mission(MissionData.create_enemy_mission("kill_golem_25", "Golem Breaker", "Kill 25 Golems", "golem", 25, 50))
	_add_mission(MissionData.create_enemy_mission("kill_ratfolk_500", "Vermin Exterminator", "Kill 500 Ratfolk", "ratfolk", 500, 60))
	_add_mission(MissionData.create_enemy_mission("kill_skeleton_500", "Bone Collector", "Kill 500 Skeletons", "skeleton", 500, 60))
	_add_mission(MissionData.create_enemy_mission("kill_slime_500", "Slime Time", "Kill 500 Slimes", "slime", 500, 60))

	# Difficulty missions
	_add_mission(MissionData.create_difficulty_mission("beat_pitiful", "Baby Steps", "Beat Pitiful difficulty", 0, 50))
	_add_mission(MissionData.create_difficulty_mission("beat_easy", "Easy Peasy", "Beat Easy difficulty", 1, 50))
	_add_mission(MissionData.create_difficulty_mission("beat_normal", "Normal Day", "Beat Normal difficulty", 2, 60))
	_add_mission(MissionData.create_difficulty_mission("beat_nightmare", "Nightmare Fuel", "Beat Nightmare difficulty", 3, 100))
	_add_mission(MissionData.create_difficulty_mission("beat_hell", "Hell Raiser", "Beat Hell difficulty", 4, 200))
	_add_mission(MissionData.create_difficulty_mission("beat_inferno", "Inferno Walker", "Beat Inferno difficulty", 5, 350))
	_add_mission(MissionData.create_difficulty_mission("beat_thanksgiving", "Thanksgiving Champion", "Beat Thanksgiving Dinner difficulty", 6, 500))

	# Character missions - Play as
	_add_mission(MissionData.create_character_mission("play_archer", "Robin's Hood", "Complete a run as Archer", "archer", 50))
	_add_mission(MissionData.create_character_mission("play_knight", "Knight's Honor", "Complete a run as Knight", "knight", 50))
	_add_mission(MissionData.create_character_mission("play_beast", "Unleash the Beast", "Complete a run as Beast", "beast", 50))
	_add_mission(MissionData.create_character_mission("play_mage", "Arcane Master", "Complete a run as Mage", "mage", 50))
	_add_mission(MissionData.create_character_mission("play_monk", "Inner Peace", "Complete a run as Monk", "monk", 50))
	_add_mission(MissionData.create_character_mission("play_barbarian", "Chad Energy", "Complete a run as Barbarian", "barbarian", 50))
	_add_mission(MissionData.create_character_mission("play_assassin", "Shadow Walker", "Complete a run as Assassin", "assassin", 50))

	# Character missions - Win Challenge Mode - reduced rewards
	_add_mission(MissionData.create_character_mission("win_archer", "Archer Ace", "Win Challenge Mode with Archer", "archer", 50, true))
	_add_mission(MissionData.create_character_mission("win_knight", "Knight Champion", "Win Challenge Mode with Knight", "knight", 50, true))
	_add_mission(MissionData.create_character_mission("win_beast", "Beast Master", "Win Challenge Mode with Beast", "beast", 50, true))
	_add_mission(MissionData.create_character_mission("win_mage", "Archmage", "Win Challenge Mode with Mage", "mage", 50, true))
	_add_mission(MissionData.create_character_mission("win_monk", "Grandmaster Monk", "Win Challenge Mode with Monk", "monk", 50, true))
	_add_mission(MissionData.create_character_mission("win_barbarian", "Barbarian King", "Win Challenge Mode with Barbarian", "barbarian", 60, true))
	_add_mission(MissionData.create_character_mission("win_assassin", "Master Assassin", "Win Challenge Mode with Assassin", "assassin", 50, true))

	# Survival missions (Endless) - Time-based only
	_add_mission(MissionData.create_survival_mission("survive_5min", "Survivor", "Survive 5 minutes in Endless Mode", 300, 50, 0))
	_add_mission(MissionData.create_survival_mission("survive_10min", "Endurance", "Survive 10 minutes in Endless Mode", 600, 60, 0))
	_add_mission(MissionData.create_survival_mission("survive_15min", "Marathon", "Survive 15 minutes in Endless Mode", 900, 100, 0))
	_add_mission(MissionData.create_survival_mission("survive_20min", "Iron Will", "Survive 20 minutes in Endless Mode", 1200, 150, 0))
	_add_mission(MissionData.create_survival_mission("survive_25min", "Relentless", "Survive 25 minutes in Endless Mode", 1500, 200, 0))
	_add_mission(MissionData.create_survival_mission("survive_30min", "Immortal", "Survive 30 minutes in Endless Mode", 1800, 300, 0))
	_add_mission(MissionData.create_survival_mission("survive_45min", "Eternal", "Survive 45 minutes in Endless Mode", 2700, 500, 0))
	_add_mission(MissionData.create_survival_mission("survive_60min", "Godlike", "Survive 60 minutes in Endless Mode", 3600, 1000, 0))

	# Economy missions
	var econ_100 = MissionData.new("earn_100")
	econ_100.title = "First Coins"
	econ_100.description = "Earn 100 coins total"
	econ_100.type = MissionData.MissionType.ECONOMY
	econ_100.category = MissionData.MissionCategory.PERMANENT
	econ_100.tracking_mode = MissionData.TrackingMode.CUMULATIVE
	econ_100.target_value = 100
	econ_100.reward_coins = 50
	_add_mission(econ_100)

	var econ_1000 = MissionData.new("earn_1000")
	econ_1000.title = "Penny Pincher"
	econ_1000.description = "Earn 1,000 coins total"
	econ_1000.type = MissionData.MissionType.ECONOMY
	econ_1000.category = MissionData.MissionCategory.PERMANENT
	econ_1000.tracking_mode = MissionData.TrackingMode.CUMULATIVE
	econ_1000.target_value = 1000
	econ_1000.reward_coins = 50
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

	# Run count missions
	var runs_1 = MissionData.new("runs_1")
	runs_1.title = "First Run"
	runs_1.description = "Complete your first run"
	runs_1.type = MissionData.MissionType.MISC
	runs_1.category = MissionData.MissionCategory.PERMANENT
	runs_1.tracking_mode = MissionData.TrackingMode.CUMULATIVE
	runs_1.target_value = 1
	runs_1.reward_coins = 50
	_add_mission(runs_1)

	var runs_10 = MissionData.new("runs_10")
	runs_10.title = "10 Runs"
	runs_10.description = "Complete 10 runs"
	runs_10.type = MissionData.MissionType.MISC
	runs_10.category = MissionData.MissionCategory.PERMANENT
	runs_10.tracking_mode = MissionData.TrackingMode.CUMULATIVE
	runs_10.target_value = 10
	runs_10.reward_coins = 50
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

	# ============================================
	# KILLSTREAK ACHIEVEMENTS
	# ============================================
	var streak_50 = MissionData.new("killstreak_50")
	streak_50.title = "Combo Starter"
	streak_50.description = "Get a 50 kill streak in a single run"
	streak_50.type = MissionData.MissionType.MISC
	streak_50.category = MissionData.MissionCategory.PERMANENT
	streak_50.tracking_mode = MissionData.TrackingMode.SINGLE_RUN
	streak_50.target_value = 50
	streak_50.reward_coins = 50
	_add_mission(streak_50)

	var streak_250 = MissionData.new("killstreak_250")
	streak_250.title = "Combo Master"
	streak_250.description = "Get a 250 kill streak in a single run"
	streak_250.type = MissionData.MissionType.MISC
	streak_250.category = MissionData.MissionCategory.PERMANENT
	streak_250.tracking_mode = MissionData.TrackingMode.SINGLE_RUN
	streak_250.target_value = 250
	streak_250.reward_coins = 150
	_add_mission(streak_250)

	var streak_500 = MissionData.new("killstreak_500")
	streak_500.title = "Combo God"
	streak_500.description = "Get a 500 kill streak in a single run"
	streak_500.type = MissionData.MissionType.MISC
	streak_500.category = MissionData.MissionCategory.PERMANENT
	streak_500.tracking_mode = MissionData.TrackingMode.SINGLE_RUN
	streak_500.target_value = 500
	streak_500.reward_coins = 300
	_add_mission(streak_500)

	var streak_1000 = MissionData.new("killstreak_1000")
	streak_1000.title = "Unstoppable Force"
	streak_1000.description = "Get a 1,000 kill streak in a single run"
	streak_1000.type = MissionData.MissionType.MISC
	streak_1000.category = MissionData.MissionCategory.PERMANENT
	streak_1000.tracking_mode = MissionData.TrackingMode.SINGLE_RUN
	streak_1000.target_value = 1000
	streak_1000.reward_coins = 500
	_add_mission(streak_1000)

	# ============================================
	# COINS IN SINGLE RUN ACHIEVEMENTS
	# ============================================
	var run_coins_500 = MissionData.new("run_coins_500")
	run_coins_500.title = "Coin Collector"
	run_coins_500.description = "Earn 500 coins in a single run"
	run_coins_500.type = MissionData.MissionType.ECONOMY
	run_coins_500.category = MissionData.MissionCategory.PERMANENT
	run_coins_500.tracking_mode = MissionData.TrackingMode.SINGLE_RUN
	run_coins_500.target_value = 500
	run_coins_500.reward_coins = 100
	_add_mission(run_coins_500)

	var run_coins_1000 = MissionData.new("run_coins_1000")
	run_coins_1000.title = "Treasure Hunter"
	run_coins_1000.description = "Earn 1,000 coins in a single run"
	run_coins_1000.type = MissionData.MissionType.ECONOMY
	run_coins_1000.category = MissionData.MissionCategory.PERMANENT
	run_coins_1000.tracking_mode = MissionData.TrackingMode.SINGLE_RUN
	run_coins_1000.target_value = 1000
	run_coins_1000.reward_coins = 200
	_add_mission(run_coins_1000)

	var run_coins_2500 = MissionData.new("run_coins_2500")
	run_coins_2500.title = "Gold Rush"
	run_coins_2500.description = "Earn 2,500 coins in a single run"
	run_coins_2500.type = MissionData.MissionType.ECONOMY
	run_coins_2500.category = MissionData.MissionCategory.PERMANENT
	run_coins_2500.tracking_mode = MissionData.TrackingMode.SINGLE_RUN
	run_coins_2500.target_value = 2500
	run_coins_2500.reward_coins = 400
	_add_mission(run_coins_2500)

	var run_coins_5000 = MissionData.new("run_coins_5000")
	run_coins_5000.title = "Dragon's Hoard"
	run_coins_5000.description = "Earn 5,000 coins in a single run"
	run_coins_5000.type = MissionData.MissionType.ECONOMY
	run_coins_5000.category = MissionData.MissionCategory.PERMANENT
	run_coins_5000.tracking_mode = MissionData.TrackingMode.SINGLE_RUN
	run_coins_5000.target_value = 5000
	run_coins_5000.reward_coins = 750
	_add_mission(run_coins_5000)

	# ============================================
	# DIFFICULT ASPIRATIONAL ACHIEVEMENTS
	# ============================================

	# No damage achievements
	var no_damage_5min = MissionData.new("no_damage_5min")
	no_damage_5min.title = "Untouchable"
	no_damage_5min.description = "Survive 5 minutes without taking damage"
	no_damage_5min.type = MissionData.MissionType.MISC
	no_damage_5min.category = MissionData.MissionCategory.PERMANENT
	no_damage_5min.tracking_mode = MissionData.TrackingMode.SINGLE_RUN
	no_damage_5min.target_value = 1
	no_damage_5min.reward_coins = 500
	_add_mission(no_damage_5min)

	var no_damage_win = MissionData.new("no_damage_win")
	no_damage_win.title = "Flawless Victory"
	no_damage_win.description = "Win Challenge Mode without taking any damage"
	no_damage_win.type = MissionData.MissionType.MISC
	no_damage_win.category = MissionData.MissionCategory.PERMANENT
	no_damage_win.tracking_mode = MissionData.TrackingMode.SINGLE_RUN
	no_damage_win.target_value = 1
	no_damage_win.reward_coins = 2000
	_add_mission(no_damage_win)

	# Multi-kill achievements
	var multi_kill_10 = MissionData.new("multi_kill_10")
	multi_kill_10.title = "Multi-Kill"
	multi_kill_10.description = "Kill 10 enemies within 2 seconds"
	multi_kill_10.type = MissionData.MissionType.MISC
	multi_kill_10.category = MissionData.MissionCategory.PERMANENT
	multi_kill_10.tracking_mode = MissionData.TrackingMode.INSTANT
	multi_kill_10.target_value = 1
	multi_kill_10.reward_coins = 75
	_add_mission(multi_kill_10)

	var multi_kill_25 = MissionData.new("multi_kill_25")
	multi_kill_25.title = "Mega Kill"
	multi_kill_25.description = "Kill 25 enemies within 3 seconds"
	multi_kill_25.type = MissionData.MissionType.MISC
	multi_kill_25.category = MissionData.MissionCategory.PERMANENT
	multi_kill_25.tracking_mode = MissionData.TrackingMode.INSTANT
	multi_kill_25.target_value = 1
	multi_kill_25.reward_coins = 200
	_add_mission(multi_kill_25)

	var screen_wipe = MissionData.new("screen_wipe")
	screen_wipe.title = "Screen Wipe"
	screen_wipe.description = "Kill 50 enemies within 5 seconds"
	screen_wipe.type = MissionData.MissionType.MISC
	screen_wipe.category = MissionData.MissionCategory.PERMANENT
	screen_wipe.tracking_mode = MissionData.TrackingMode.INSTANT
	screen_wipe.target_value = 1
	screen_wipe.reward_coins = 500
	_add_mission(screen_wipe)

	# Character mastery - Win with all characters
	var all_chars_win = MissionData.new("all_chars_win")
	all_chars_win.title = "Renaissance Hero"
	all_chars_win.description = "Win Challenge Mode with every character"
	all_chars_win.type = MissionData.MissionType.CHARACTER
	all_chars_win.category = MissionData.MissionCategory.PERMANENT
	all_chars_win.tracking_mode = MissionData.TrackingMode.CUMULATIVE
	all_chars_win.target_value = 7  # All 7 characters
	all_chars_win.reward_coins = 1000
	_add_mission(all_chars_win)

	# Beat all difficulties with all characters
	var all_chars_hell = MissionData.new("all_chars_hell")
	all_chars_hell.title = "Hell Conqueror"
	all_chars_hell.description = "Beat Hell difficulty with every character"
	all_chars_hell.type = MissionData.MissionType.CHARACTER
	all_chars_hell.category = MissionData.MissionCategory.PERMANENT
	all_chars_hell.tracking_mode = MissionData.TrackingMode.CUMULATIVE
	all_chars_hell.target_value = 7
	all_chars_hell.reward_coins = 2500
	_add_mission(all_chars_hell)

	var all_chars_inferno = MissionData.new("all_chars_inferno")
	all_chars_inferno.title = "Inferno Legend"
	all_chars_inferno.description = "Beat Inferno difficulty with every character"
	all_chars_inferno.type = MissionData.MissionType.CHARACTER
	all_chars_inferno.category = MissionData.MissionCategory.PERMANENT
	all_chars_inferno.tracking_mode = MissionData.TrackingMode.CUMULATIVE
	all_chars_inferno.target_value = 7
	all_chars_inferno.reward_coins = 5000
	_add_mission(all_chars_inferno)

	# Ultimate kill milestones
	_add_mission(MissionData.create_kill_mission("kill_250000", "Extinction Event", "Kill 250,000 enemies", 250000, 2000))
	_add_mission(MissionData.create_kill_mission("kill_500000", "Harbinger of Doom", "Kill 500,000 enemies", 500000, 5000))
	_add_mission(MissionData.create_kill_mission("kill_1000000", "Million Kill Club", "Kill 1,000,000 enemies", 1000000, 10000))

	# Ultimate single-run achievements
	_add_mission(MissionData.create_kill_mission("run_kill_2000", "Legendary Warrior", "Kill 2,000 enemies in a single run", 2000, 400, MissionData.TrackingMode.SINGLE_RUN))
	_add_mission(MissionData.create_kill_mission("run_kill_3000", "Mythic Slayer", "Kill 3,000 enemies in a single run", 3000, 750, MissionData.TrackingMode.SINGLE_RUN))
	_add_mission(MissionData.create_kill_mission("run_kill_5000", "God of War", "Kill 5,000 enemies in a single run", 5000, 1500, MissionData.TrackingMode.SINGLE_RUN))

	# Elite mastery
	_add_mission(MissionData.create_elite_mission("elite_250", "Elite Annihilator", "Kill 250 elite enemies", 250, 300))
	_add_mission(MissionData.create_elite_mission("elite_500", "Elite Destroyer", "Kill 500 elite enemies", 500, 600))
	_add_mission(MissionData.create_elite_mission("elite_1000", "Elite Obliterator", "Kill 1,000 elite enemies", 1000, 1500))

	# Boss mastery
	_add_mission(MissionData.create_boss_mission("boss_250", "Boss Nightmare", "Defeat 250 bosses", 250, 1000))
	_add_mission(MissionData.create_boss_mission("boss_500", "Boss Annihilator", "Defeat 500 bosses", 500, 2500))

	# Secret difficult achievements
	var secret_one_hp = MissionData.create_secret_mission("secret_one_hp_50", "Death's Door", "Kill 50 enemies while at 1 HP", MissionData.MissionType.SECRET, 1, 300)
	_add_mission(secret_one_hp)

	var secret_pacifist = MissionData.create_secret_mission("secret_pacifist", "Pacifist", "Survive 1 minute without killing anything", MissionData.MissionType.SECRET, 1, 200)
	_add_mission(secret_pacifist)

	var secret_no_abilities = MissionData.create_secret_mission("secret_no_abilities", "Ascetic", "Win without picking any abilities", MissionData.MissionType.SECRET, 1, 1000)
	_add_mission(secret_no_abilities)

	# ============================================
	# DAILY MISSIONS POOL
	# ============================================

	# Easy tier (100 coins)
	_add_mission(MissionData.create_daily_mission("daily_kill_50", "Daily Slayer", "Kill 50 enemies today", MissionData.MissionType.KILL, 50, 100))
	_add_mission(MissionData.create_daily_mission("daily_kill_100", "Centurion", "Kill 100 enemies today", MissionData.MissionType.KILL, 100, 100))
	_add_mission(MissionData.create_daily_mission("daily_play_1", "Show Up", "Complete 1 run today", MissionData.MissionType.MISC, 1, 100))
	_add_mission(MissionData.create_daily_mission("daily_coins_100", "Coin Grabber", "Earn 100 coins in runs today", MissionData.MissionType.ECONOMY, 100, 100))
	_add_mission(MissionData.create_daily_mission("daily_elite_1", "Elite Encounter", "Kill 1 elite enemy today", MissionData.MissionType.ELITE_KILL, 1, 100))

	# Medium tier (200 coins)
	_add_mission(MissionData.create_daily_mission("daily_kill_250", "Slaughter", "Kill 250 enemies today", MissionData.MissionType.KILL, 250, 200))
	_add_mission(MissionData.create_daily_mission("daily_play_3", "Dedicated", "Complete 3 runs today", MissionData.MissionType.MISC, 3, 200))
	_add_mission(MissionData.create_daily_mission("daily_elite_3", "Elite Hunter", "Kill 3 elite enemies today", MissionData.MissionType.ELITE_KILL, 3, 200))
	_add_mission(MissionData.create_daily_mission("daily_boss_1", "Boss Slayer", "Defeat a boss today", MissionData.MissionType.BOSS_KILL, 1, 200))
	_add_mission(MissionData.create_daily_mission("daily_survive_5", "Daily Survivor", "Survive 5 minutes in Endless", MissionData.MissionType.SURVIVAL, 300, 200))
	_add_mission(MissionData.create_daily_mission("daily_coins_300", "Gold Digger", "Earn 300 coins in runs today", MissionData.MissionType.ECONOMY, 300, 200))

	# Hard tier (500 coins)
	_add_mission(MissionData.create_daily_mission("daily_kill_500", "Massacre", "Kill 500 enemies today", MissionData.MissionType.KILL, 500, 500))
	_add_mission(MissionData.create_daily_mission("daily_play_5", "Grinder", "Complete 5 runs today", MissionData.MissionType.MISC, 5, 500))
	_add_mission(MissionData.create_daily_mission("daily_elite_5", "Elite Purge", "Kill 5 elite enemies today", MissionData.MissionType.ELITE_KILL, 5, 500))
	_add_mission(MissionData.create_daily_mission("daily_boss_3", "Boss Hunter", "Defeat 3 bosses today", MissionData.MissionType.BOSS_KILL, 3, 500))
	_add_mission(MissionData.create_daily_mission("daily_survive_10", "Daily Endurance", "Survive 10 minutes in Endless", MissionData.MissionType.SURVIVAL, 600, 500))
	_add_mission(MissionData.create_daily_mission("daily_challenge_win", "Daily Champion", "Win a Challenge Mode run today", MissionData.MissionType.DIFFICULTY, 1, 500))
	_add_mission(MissionData.create_daily_mission("daily_coins_500", "Daily Fortune", "Earn 500 coins in runs today", MissionData.MissionType.ECONOMY, 500, 500))

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

# Multi-kill tracking (time-windowed)
var recent_kills: Array = []  # Array of kill timestamps

func track_kill(enemy_type: String = "") -> void:
	"""Called when any enemy is killed."""
	run_kills += 1
	var current_time = Time.get_ticks_msec() / 1000.0

	# Track killstreak
	if current_time - last_kill_time <= KILLSTREAK_TIMEOUT or current_killstreak == 0:
		current_killstreak += 1
	else:
		current_killstreak = 1

	last_kill_time = current_time
	best_killstreak = maxi(best_killstreak, current_killstreak)

	# Track multi-kills (time-windowed)
	recent_kills.append(current_time)
	# Remove kills older than 5 seconds
	while recent_kills.size() > 0 and current_time - recent_kills[0] > 5.0:
		recent_kills.pop_front()

	# Check multi-kill achievements
	_check_multi_kill_achievements(current_time)

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
			var completed = mission.add_progress(1)
			mission_progress_updated.emit(mission)
			if completed:
				mission_completed.emit(mission)
				save_progress()

	# Update specific enemy missions (cumulative)
	if enemy_type != "":
		for mission in all_missions.values():
			if mission.is_completed or mission.type != MissionData.MissionType.SPECIFIC_ENEMY:
				continue
			if mission.enemy_type == enemy_type and mission.tracking_mode == MissionData.TrackingMode.CUMULATIVE:
				var completed = mission.add_progress(1)
				mission_progress_updated.emit(mission)
				if completed:
					mission_completed.emit(mission)
					save_progress()

	# Update daily kill missions
	_update_daily_progress(MissionData.MissionType.KILL, 1)

func _check_multi_kill_achievements(current_time: float) -> void:
	"""Check for multi-kill achievements based on recent kills."""
	# Count kills in last 2 seconds
	var kills_2s = 0
	for kill_time in recent_kills:
		if current_time - kill_time <= 2.0:
			kills_2s += 1

	# Count kills in last 3 seconds
	var kills_3s = 0
	for kill_time in recent_kills:
		if current_time - kill_time <= 3.0:
			kills_3s += 1

	# Count kills in last 5 seconds (full window)
	var kills_5s = recent_kills.size()

	# Multi-Kill (10 in 2s)
	if kills_2s >= 10:
		var mission = all_missions.get("multi_kill_10")
		if mission and not mission.is_completed:
			mission.current_progress = 1
			if mission.check_completion():
				mission_completed.emit(mission)
				save_progress()

	# Mega Kill (25 in 3s)
	if kills_3s >= 25:
		var mission = all_missions.get("multi_kill_25")
		if mission and not mission.is_completed:
			mission.current_progress = 1
			if mission.check_completion():
				mission_completed.emit(mission)
				save_progress()

	# Screen Wipe (50 in 5s)
	if kills_5s >= 50:
		var mission = all_missions.get("screen_wipe")
		if mission and not mission.is_completed:
			mission.current_progress = 1
			if mission.check_completion():
				mission_completed.emit(mission)
				save_progress()

	# Secret Speedster (10 in 5s) - original
	if kills_5s >= 10:
		var mission = all_missions.get("secret_speedster")
		if mission and not mission.is_completed:
			mission.current_progress = 1
			if mission.check_completion():
				mission_completed.emit(mission)
				save_progress()

func track_elite_kill() -> void:
	"""Called when an elite enemy is killed."""
	run_elite_kills += 1

	for mission in all_missions.values():
		if mission.is_completed or mission.type != MissionData.MissionType.ELITE_KILL:
			continue
		var completed = mission.add_progress(1)
		mission_progress_updated.emit(mission)
		if completed:
			mission_completed.emit(mission)
			save_progress()

	# Update daily elite missions
	_update_daily_progress(MissionData.MissionType.ELITE_KILL, 1)

func track_boss_kill() -> void:
	"""Called when a boss is killed."""
	run_boss_kills += 1

	for mission in all_missions.values():
		if mission.is_completed or mission.type != MissionData.MissionType.BOSS_KILL:
			continue
		var completed = mission.add_progress(1)
		mission_progress_updated.emit(mission)
		if completed:
			mission_completed.emit(mission)
			save_progress()

	# Update daily boss missions
	_update_daily_progress(MissionData.MissionType.BOSS_KILL, 1)

func track_coins_earned(amount: int) -> void:
	"""Called when coins are earned."""
	run_coins_earned += amount

	for mission in all_missions.values():
		if mission.is_completed or mission.type != MissionData.MissionType.ECONOMY:
			continue
		if mission.tracking_mode == MissionData.TrackingMode.CUMULATIVE:
			var completed = mission.add_progress(amount)
			mission_progress_updated.emit(mission)
			if completed:
				mission_completed.emit(mission)
				save_progress()

	# Update daily economy missions
	_update_daily_progress(MissionData.MissionType.ECONOMY, amount)

func track_damage_taken(amount: int, current_hp: int, max_hp: int) -> void:
	"""Called when player takes damage."""
	run_damage_taken += amount
	run_final_hp = current_hp
	run_max_hp = max_hp

func track_ability_collected(is_legendary: bool = false) -> void:
	"""Called when an ability is picked up."""
	run_abilities_collected += 1
	if is_legendary:
		run_legendary_abilities += 1

func track_ability_declined() -> void:
	"""Called when player skips/declines an ability choice."""
	run_ability_declines += 1

func _update_daily_progress(mission_type: MissionData.MissionType, amount: int) -> void:
	"""Update progress for active daily missions of the given type."""
	for mission_id in active_daily_missions:
		var mission = all_missions.get(mission_id)
		if mission and not mission.is_completed and mission.type == mission_type:
			var completed = mission.add_progress(amount)
			mission_progress_updated.emit(mission)
			if completed:
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
		var completed = mission.add_progress(1)
		mission_progress_updated.emit(mission)
		if completed:
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

	# Reset killstreak tracking
	current_killstreak = 0
	best_killstreak = 0
	last_kill_time = 0.0
	recent_kills.clear()

	# Reset damage tracking
	run_damage_taken = 0
	run_final_hp = 0
	run_max_hp = 0

	# Reset ability tracking
	run_abilities_collected = 0
	run_legendary_abilities = 0
	run_ability_declines = 0

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
				# All survival missions are time-based now
				mission.current_progress = int(run_time)
				if mission.check_completion():
					mission_completed.emit(mission)
			MissionData.MissionType.SPECIFIC_ENEMY:
				var count = run_enemy_kills.get(mission.enemy_type, 0)
				mission.current_progress = maxi(mission.current_progress, count)
				if mission.check_completion():
					mission_completed.emit(mission)
			MissionData.MissionType.ECONOMY:
				# Single-run coins achievements
				if mission.id.begins_with("run_coins_"):
					mission.current_progress = run_coins_earned
					if mission.check_completion():
						mission_completed.emit(mission)

	# Check killstreak achievements
	_check_killstreak_achievements()

	# Check no-damage achievements
	_check_no_damage_achievements(victory)

	# Check secret achievements
	_check_secret_achievements(victory)

	# Update daily run count missions
	_update_daily_progress(MissionData.MissionType.MISC, 1)

	# Update daily survival missions (check if survived long enough)
	for mission_id in active_daily_missions:
		var mission = all_missions.get(mission_id)
		if mission and not mission.is_completed and mission.type == MissionData.MissionType.SURVIVAL:
			if int(run_time) >= mission.target_value:
				mission.current_progress = mission.target_value
				if mission.check_completion():
					mission_completed.emit(mission)
					save_progress()

	# Update daily challenge win mission
	if victory and run_game_mode == 1:  # Challenge mode
		_update_daily_progress(MissionData.MissionType.DIFFICULTY, 1)

	# Track character completion
	track_character_run(run_character, victory)

	# Track difficulty completion
	if victory and run_game_mode == 1:  # Challenge mode
		track_difficulty_completed(run_difficulty, victory)

	# Track run completed
	track_run_completed()

	save_progress()

func _check_killstreak_achievements() -> void:
	"""Check killstreak achievements at end of run."""
	for mission in all_missions.values():
		if mission.is_completed:
			continue
		if not mission.id.begins_with("killstreak_"):
			continue
		mission.current_progress = best_killstreak
		if mission.check_completion():
			mission_completed.emit(mission)

func _check_no_damage_achievements(victory: bool) -> void:
	"""Check no-damage achievements."""
	# Untouchable - 5 min without damage (checked during run via run_time and damage tracking)
	if run_damage_taken == 0 and run_time >= 300:  # 5 minutes
		var mission = all_missions.get("no_damage_5min")
		if mission and not mission.is_completed:
			mission.current_progress = 1
			if mission.check_completion():
				mission_completed.emit(mission)

	# Flawless Victory - Win challenge mode without taking damage
	if victory and run_game_mode == 1 and run_damage_taken == 0:
		var mission = all_missions.get("no_damage_win")
		if mission and not mission.is_completed:
			mission.current_progress = 1
			if mission.check_completion():
				mission_completed.emit(mission)

func _check_secret_achievements(victory: bool) -> void:
	"""Check secret achievements at end of run."""
	# Close Call - Win with 1 HP
	if victory and run_final_hp == 1:
		var mission = all_missions.get("secret_close_call")
		if mission and not mission.is_completed:
			mission.current_progress = 1
			if mission.check_completion():
				mission_completed.emit(mission)

	# Ascetic - Win without picking abilities
	if victory and run_abilities_collected == 0:
		var mission = all_missions.get("secret_no_abilities")
		if mission and not mission.is_completed:
			mission.current_progress = 1
			if mission.check_completion():
				mission_completed.emit(mission)

	# Pacifist - Survive 1 minute without killing (checked if run_time >= 60 and run_kills == 0 at that point)
	# Note: This would need to be tracked during the run, setting a flag when 60s passes with 0 kills
	# For now, check if entire run was pacifist and lasted at least 60s
	if run_kills == 0 and run_time >= 60:
		var mission = all_missions.get("secret_pacifist")
		if mission and not mission.is_completed:
			mission.current_progress = 1
			if mission.check_completion():
				mission_completed.emit(mission)

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
			# Exclude hidden social missions that can't be claimed in UI
			if mission.id in ["rate_game", "youtube_sub"]:
				continue
			return true
	return false

func get_unclaimed_count() -> int:
	"""Get count of missions with unclaimed rewards."""
	var count = 0
	for mission in all_missions.values():
		if mission.is_completed and not mission.is_claimed:
			# Exclude hidden social missions that can't be claimed in UI
			if mission.id in ["rate_game", "youtube_sub"]:
				continue
			print("[MissionsManager] Unclaimed mission: ", mission.id, " - ", mission.title)
			count += 1
	return count

func claim_all_unclaimed() -> int:
	"""Claim all unclaimed rewards. Returns number of rewards claimed."""
	var claimed_count = 0
	for mission in all_missions.values():
		if mission.is_completed and not mission.is_claimed:
			if claim_reward(mission.id):
				claimed_count += 1
	return claimed_count

# ============================================
# DAILY MISSIONS
# ============================================

func _check_daily_refresh() -> void:
	"""Check if daily missions need to be refreshed."""
	var today = Time.get_date_string_from_system()

	# Refresh if date changed OR if active missions are invalid/empty
	var needs_refresh = daily_date != today

	# Also check if current active missions are valid
	if not needs_refresh and active_daily_missions.size() > 0:
		for id in active_daily_missions:
			if not all_missions.has(id):
				needs_refresh = true
				break

	# Also refresh if we have no active daily missions
	if active_daily_missions.is_empty():
		needs_refresh = true

	if needs_refresh:
		_refresh_daily_missions()

func _refresh_daily_missions() -> void:
	"""Generate new daily missions for today - one from each tier."""
	daily_date = Time.get_date_string_from_system()
	active_daily_missions.clear()

	# Reset all daily mission progress
	for mission in daily_missions:
		mission.reset_progress()

	# Organize missions by tier based on reward coins
	var easy_tier: Array = []    # 100 coins
	var medium_tier: Array = []  # 200 coins
	var hard_tier: Array = []    # 500 coins

	for mission in daily_missions:
		match mission.reward_coins:
			100:
				easy_tier.append(mission)
			200:
				medium_tier.append(mission)
			500:
				hard_tier.append(mission)

	# Shuffle each tier
	easy_tier.shuffle()
	medium_tier.shuffle()
	hard_tier.shuffle()

	# Pick one from each tier
	if easy_tier.size() > 0:
		active_daily_missions.append(easy_tier[0].id)
	if medium_tier.size() > 0:
		active_daily_missions.append(medium_tier[0].id)
	if hard_tier.size() > 0:
		active_daily_missions.append(hard_tier[0].id)

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

func get_in_progress_missions(max_count: int = 3) -> Array:
	"""Get missions that are closest to completion (most likely to complete next)."""
	var candidates: Array = []

	# Collect all incomplete, unclaimed missions
	for mission in permanent_missions:
		if not mission.is_completed and not mission.is_claimed:
			candidates.append(mission)

	# Sort by closeness to completion:
	# 1. Higher completion percentage first
	# 2. If same percentage (including 0%), smaller target value first (easier missions)
	candidates.sort_custom(func(a, b):
		var a_pct = float(a.current_progress) / float(a.target_value) if a.target_value > 0 else 0
		var b_pct = float(b.current_progress) / float(b.target_value) if b.target_value > 0 else 0

		# If percentages differ significantly, sort by percentage
		if abs(a_pct - b_pct) > 0.001:
			return a_pct > b_pct

		# If same percentage, prefer smaller target (easier to complete)
		return a.target_value < b.target_value
	)

	return candidates.slice(0, max_count)

# Track missions completed during this run (for game over celebration)
var run_completed_missions: Array = []

func get_run_completed_missions() -> Array:
	"""Get missions that were completed during the current run."""
	return run_completed_missions

func clear_run_completed_missions() -> void:
	"""Clear the list of run-completed missions (call at run start)."""
	run_completed_missions.clear()

func _on_mission_just_completed(mission: MissionData) -> void:
	"""Track that a mission was completed during this run."""
	if not run_completed_missions.has(mission):
		run_completed_missions.append(mission)

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
