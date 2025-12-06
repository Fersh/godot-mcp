extends Node

# Unlocks Manager - Tracks ability unlocks, stats, and progression
# Add to autoload as "UnlocksManager"

const SAVE_PATH = "user://unlocks.save"

signal abilities_unlocked(passives: Array, actives: Array, ultimates: Array)
signal stats_updated()

# ============================================
# LOCKED ABILITY DEFINITIONS
# ============================================

# Passive abilities that start locked - organized by unlock tier
const TIER_1_PASSIVES = [  # Unlock after beating Normal
	"giant_slayer", "time_dilation", "critical_eye", "vampirism",
	"chain_reaction", "double_charge", "elemental_infusion", "backstab"
]
const TIER_2_PASSIVES = [  # Unlock after beating Nightmare
	"cull_the_weak", "glass_cannon", "tesla_coil", "death_detonation",
	"divine_shield", "thundercaller", "ring_of_fire", "drone_support"
]
const TIER_3_PASSIVES = [  # Unlock after beating Hell
	"ceremonial_dagger", "soul_reaper", "missile_barrage", "chrono_trigger",
	"unlimited_power", "wind_dancer"
]
const TIER_4_PASSIVES = [  # Unlock after beating Inferno
	"transcendence", "pandemonium"
]

# Active abilities that start locked
const TIER_1_ACTIVES = [  # Unlock after beating Normal
	"time_slow", "frost_nova", "meteor_strike", "battle_cry"
]
const TIER_2_ACTIVES = [  # Unlock after beating Nightmare
	"black_hole", "time_stop", "thunderstorm", "avatar_of_war"
]
const TIER_3_ACTIVES = [  # Unlock after beating Hell
	"army_of_the_dead", "summon_golem", "omnislash", "sentry_network"
]

# Ultimate abilities that start locked
const TIER_2_ULTIMATES = [  # Unlock after beating Nightmare
	"time_rewind", "meteor_swarm"
]
const TIER_3_ULTIMATES = [  # Unlock after beating Hell
	"arcane_singularity", "unbreakable_will"
]
const TIER_4_ULTIMATES = [  # Unlock after beating Inferno
	"apex_predator", "perfect_harmony"
]

# ============================================
# TRACKED DATA (Persisted)
# ============================================

# Unlocked abilities (by ID)
var unlocked_passives: Array = []
var unlocked_actives: Array = []
var unlocked_ultimates: Array = []

# Unlock counter (for every-other-game ultimate unlocks)
var games_completed: int = 0

# Combat stats
var total_monsters_killed: int = 0
var total_elites_killed: int = 0
var total_bosses_killed: int = 0

# Run stats
var current_run_elites: int = 0
var current_run_bosses: int = 0

# Achievement stats
var hardest_difficulty_beaten: int = -1  # DifficultyTier enum value
var hardest_with_curses: Dictionary = {}  # {difficulty: curse_count}

# Endless mode stats
var longest_endless_time: float = 0.0
var highest_endless_wave: int = 0
var highest_endless_points: int = 0

# Challenge mode stats
var fastest_challenge_time: float = 999999.0
var highest_challenge_points: int = 0

# Unique elites beaten (by elite_name)
var unique_elites_beaten: Array = []

# All possible elites (17 elites + 7 bosses = 24 total)
const ALL_ELITE_NAMES = [
	# Elites
	"One Eyed Monster", "Goblin King", "The Supervisor", "Rat Daddy", "Bone Daddy",
	"Blobulous the Magnificent", "Infernal Intern", "The Grand Poobah", "Archmage Whiskersnatch",
	"Dreadwing the Eclipsed", "The Plague Licker", "Rotfather", "The All-Seeing",
	"Stoneheart the Immovable", "The Mind Ripper", "Lich King Mortanius", "Vexroth the Soulrender",
	# Bosses
	"Minotaur", "Skeleton King", "Kobold King", "Giant Golem", "Lizardfolk King", "Wendigo", "Elder Dragon"
]

# ============================================
# INITIALIZATION
# ============================================

func _ready() -> void:
	load_unlocks()

# ============================================
# ABILITY UNLOCK CHECKS
# ============================================

func is_passive_unlocked(ability_id: String) -> bool:
	# Check if ability is in any locked tier
	var all_locked = TIER_1_PASSIVES + TIER_2_PASSIVES + TIER_3_PASSIVES + TIER_4_PASSIVES
	if ability_id not in all_locked:
		return true  # Not a locked ability, always available
	return ability_id in unlocked_passives

func is_active_unlocked(ability_id: String) -> bool:
	var all_locked = TIER_1_ACTIVES + TIER_2_ACTIVES + TIER_3_ACTIVES
	if ability_id not in all_locked:
		return true
	return ability_id in unlocked_actives

func is_ultimate_unlocked(ability_id: String) -> bool:
	var all_locked = TIER_2_ULTIMATES + TIER_3_ULTIMATES + TIER_4_ULTIMATES
	if ability_id not in all_locked:
		return true
	return ability_id in unlocked_ultimates

# ============================================
# CHARACTER UNLOCK CHECKS
# ============================================

func is_character_unlocked(character_id: String) -> bool:
	# Chad (barbarian) requires beating Hell difficulty
	if character_id == "barbarian":
		return has_beaten_difficulty(DifficultyManager.DifficultyTier.NIGHTMARE)  # Hell is NIGHTMARE enum
	# All other characters (including new ones) are unlocked by default
	return true

func has_beaten_difficulty(tier: int) -> bool:
	if not DifficultyManager:
		return false
	return DifficultyManager.is_difficulty_completed(tier)

# ============================================
# UNLOCK REWARDS ON GAME COMPLETION
# ============================================

func on_game_completed() -> void:
	"""Called when a challenge mode game is completed. Awards random ability unlocks."""
	games_completed += 1

	var newly_unlocked_passives: Array = []
	var newly_unlocked_actives: Array = []
	var newly_unlocked_ultimates: Array = []

	# Unlock 2 random passives
	for i in range(2):
		var unlocked = _unlock_random_passive()
		if unlocked != "":
			newly_unlocked_passives.append(unlocked)

	# Unlock 1 random active
	var active_unlocked = _unlock_random_active()
	if active_unlocked != "":
		newly_unlocked_actives.append(active_unlocked)

	# Unlock 1 random ultimate every other game
	if games_completed % 2 == 0:
		var ultimate_unlocked = _unlock_random_ultimate()
		if ultimate_unlocked != "":
			newly_unlocked_ultimates.append(ultimate_unlocked)

	save_unlocks()

	if newly_unlocked_passives.size() > 0 or newly_unlocked_actives.size() > 0 or newly_unlocked_ultimates.size() > 0:
		abilities_unlocked.emit(newly_unlocked_passives, newly_unlocked_actives, newly_unlocked_ultimates)

func _unlock_random_passive() -> String:
	"""Unlock a random locked passive ability. Returns the ability ID or empty string."""
	var available = _get_available_locked_passives()
	if available.is_empty():
		return ""

	available.shuffle()
	var to_unlock = available[0]
	unlocked_passives.append(to_unlock)
	return to_unlock

func _unlock_random_active() -> String:
	"""Unlock a random locked active ability. Returns the ability ID or empty string."""
	var available = _get_available_locked_actives()
	if available.is_empty():
		return ""

	available.shuffle()
	var to_unlock = available[0]
	unlocked_actives.append(to_unlock)
	return to_unlock

func _unlock_random_ultimate() -> String:
	"""Unlock a random locked ultimate ability. Returns the ability ID or empty string."""
	var available = _get_available_locked_ultimates()
	if available.is_empty():
		return ""

	available.shuffle()
	var to_unlock = available[0]
	unlocked_ultimates.append(to_unlock)
	return to_unlock

func _get_available_locked_passives() -> Array:
	"""Get passives that are still locked and available based on difficulty progress."""
	var available: Array = []

	# Tier 1 always available to unlock
	for id in TIER_1_PASSIVES:
		if id not in unlocked_passives:
			available.append(id)

	# Tier 2 requires Normal beaten
	if has_beaten_difficulty(DifficultyManager.DifficultyTier.EASY):
		for id in TIER_2_PASSIVES:
			if id not in unlocked_passives:
				available.append(id)

	# Tier 3 requires Nightmare beaten
	if has_beaten_difficulty(DifficultyManager.DifficultyTier.NORMAL):
		for id in TIER_3_PASSIVES:
			if id not in unlocked_passives:
				available.append(id)

	# Tier 4 requires Hell beaten
	if has_beaten_difficulty(DifficultyManager.DifficultyTier.NIGHTMARE):
		for id in TIER_4_PASSIVES:
			if id not in unlocked_passives:
				available.append(id)

	return available

func _get_available_locked_actives() -> Array:
	"""Get actives that are still locked and available based on difficulty progress."""
	var available: Array = []

	# Tier 1 always available
	for id in TIER_1_ACTIVES:
		if id not in unlocked_actives:
			available.append(id)

	# Tier 2 requires Normal beaten
	if has_beaten_difficulty(DifficultyManager.DifficultyTier.EASY):
		for id in TIER_2_ACTIVES:
			if id not in unlocked_actives:
				available.append(id)

	# Tier 3 requires Nightmare beaten
	if has_beaten_difficulty(DifficultyManager.DifficultyTier.NORMAL):
		for id in TIER_3_ACTIVES:
			if id not in unlocked_actives:
				available.append(id)

	return available

func _get_available_locked_ultimates() -> Array:
	"""Get ultimates that are still locked and available based on difficulty progress."""
	var available: Array = []

	# Tier 2 requires Normal beaten
	if has_beaten_difficulty(DifficultyManager.DifficultyTier.EASY):
		for id in TIER_2_ULTIMATES:
			if id not in unlocked_ultimates:
				available.append(id)

	# Tier 3 requires Nightmare beaten
	if has_beaten_difficulty(DifficultyManager.DifficultyTier.NORMAL):
		for id in TIER_3_ULTIMATES:
			if id not in unlocked_ultimates:
				available.append(id)

	# Tier 4 requires Hell beaten
	if has_beaten_difficulty(DifficultyManager.DifficultyTier.NIGHTMARE):
		for id in TIER_4_ULTIMATES:
			if id not in unlocked_ultimates:
				available.append(id)

	return available

# ============================================
# KILL TRACKING
# ============================================

func add_elite_kill(elite_name: String = "") -> void:
	current_run_elites += 1
	total_elites_killed += 1
	# Track unique elite beaten
	if elite_name != "" and elite_name not in unique_elites_beaten:
		unique_elites_beaten.append(elite_name)
		save_unlocks()

func add_boss_kill(boss_name: String = "") -> void:
	current_run_bosses += 1
	total_bosses_killed += 1
	# Track unique boss beaten (bosses count as elites for completion)
	if boss_name != "" and boss_name not in unique_elites_beaten:
		unique_elites_beaten.append(boss_name)
		save_unlocks()

func get_unique_elites_beaten_count() -> int:
	return unique_elites_beaten.size()

func get_total_unique_elites() -> int:
	return ALL_ELITE_NAMES.size()

func add_monster_kills(count: int) -> void:
	total_monsters_killed += count

func reset_run_kills() -> void:
	current_run_elites = 0
	current_run_bosses = 0

# ============================================
# STATS TRACKING
# ============================================

func update_endless_stats(time: float, wave: int, points: int) -> void:
	if time > longest_endless_time:
		longest_endless_time = time
	if wave > highest_endless_wave:
		highest_endless_wave = wave
	if points > highest_endless_points:
		highest_endless_points = points
	save_unlocks()

func update_challenge_stats(time: float, points: int, difficulty: int, curse_count: int) -> void:
	if time < fastest_challenge_time:
		fastest_challenge_time = time
	if points > highest_challenge_points:
		highest_challenge_points = points

	# Track hardest difficulty beaten
	if difficulty > hardest_difficulty_beaten:
		hardest_difficulty_beaten = difficulty

	# Track highest curse count per difficulty
	if not hardest_with_curses.has(difficulty) or curse_count > hardest_with_curses[difficulty]:
		hardest_with_curses[difficulty] = curse_count

	save_unlocks()

# ============================================
# PROGRESS GETTERS
# ============================================

func get_total_locked_passives() -> int:
	return TIER_1_PASSIVES.size() + TIER_2_PASSIVES.size() + TIER_3_PASSIVES.size() + TIER_4_PASSIVES.size()

func get_total_locked_actives() -> int:
	return TIER_1_ACTIVES.size() + TIER_2_ACTIVES.size() + TIER_3_ACTIVES.size()

func get_total_locked_ultimates() -> int:
	return TIER_2_ULTIMATES.size() + TIER_3_ULTIMATES.size() + TIER_4_ULTIMATES.size()

func get_unlocked_passive_count() -> int:
	return unlocked_passives.size()

func get_unlocked_active_count() -> int:
	return unlocked_actives.size()

func get_unlocked_ultimate_count() -> int:
	return unlocked_ultimates.size()

func get_overall_unlock_progress() -> float:
	"""Returns 0.0-1.0 progress for overall unlocks."""
	var total_princesses = 21
	var total_difficulties = 7
	var total_characters = 13  # Updated (4 characters commented out)
	var total_locked_abilities = get_total_locked_passives() + get_total_locked_actives() + get_total_locked_ultimates()
	var total_elites = get_total_unique_elites()

	var unlocked_princesses = PrincessManager.get_unlocked_count() if PrincessManager else 0
	var unlocked_difficulties = DifficultyManager.completed_difficulties.size() if DifficultyManager else 0
	var unlocked_characters = _count_unlocked_characters()
	var unlocked_abilities = unlocked_passives.size() + unlocked_actives.size() + unlocked_ultimates.size()
	var beaten_elites = get_unique_elites_beaten_count()

	var total = total_princesses + total_difficulties + total_characters + total_locked_abilities + total_elites
	var unlocked = unlocked_princesses + unlocked_difficulties + unlocked_characters + unlocked_abilities + beaten_elites

	if total == 0:
		return 1.0
	return float(unlocked) / float(total)

func get_maxed_upgrades_count() -> int:
	"""Returns number of upgrades at max rank."""
	if not PermanentUpgrades:
		return 0
	var count = 0
	for upgrade in PermanentUpgrades.get_all_upgrades():
		if PermanentUpgrades.get_rank(upgrade.id) >= upgrade.max_rank:
			count += 1
	return count

func get_total_upgrades() -> int:
	"""Returns total number of upgrades available."""
	if not PermanentUpgrades:
		return 0
	return PermanentUpgrades.get_all_upgrades().size()

func _count_unlocked_characters() -> int:
	var count = 0
	# COMMENTED OUT: orc, minotaur, cyclops, skeleton_king
	var character_ids = [
		"archer", "knight", "beast", "mage", "monk", "barbarian", "assassin",
		"golem", "lizardfolk_king", "shardsoul_slayer", "necromancer", "kobold_priest", "ratfolk"
	]
	for id in character_ids:
		if is_character_unlocked(id):
			count += 1
	return count

func get_stats_dictionary() -> Dictionary:
	"""Get all stats for display."""
	return {
		"total_monsters_killed": total_monsters_killed,
		"total_elites_killed": total_elites_killed,
		"total_bosses_killed": total_bosses_killed,
		"games_completed": games_completed,
		"hardest_difficulty_beaten": hardest_difficulty_beaten,
		"hardest_with_curses": hardest_with_curses,
		"longest_endless_time": longest_endless_time,
		"highest_endless_wave": highest_endless_wave,
		"highest_endless_points": highest_endless_points,
		"fastest_challenge_time": fastest_challenge_time,
		"highest_challenge_points": highest_challenge_points,
		"unlocked_passives": unlocked_passives.size(),
		"total_locked_passives": get_total_locked_passives(),
		"unlocked_actives": unlocked_actives.size(),
		"total_locked_actives": get_total_locked_actives(),
		"unlocked_ultimates": unlocked_ultimates.size(),
		"total_locked_ultimates": get_total_locked_ultimates(),
	}

# ============================================
# PERSISTENCE
# ============================================

func save_unlocks() -> void:
	var save_data = {
		"unlocked_passives": unlocked_passives,
		"unlocked_actives": unlocked_actives,
		"unlocked_ultimates": unlocked_ultimates,
		"games_completed": games_completed,
		"total_monsters_killed": total_monsters_killed,
		"total_elites_killed": total_elites_killed,
		"total_bosses_killed": total_bosses_killed,
		"hardest_difficulty_beaten": hardest_difficulty_beaten,
		"hardest_with_curses": hardest_with_curses,
		"longest_endless_time": longest_endless_time,
		"highest_endless_wave": highest_endless_wave,
		"highest_endless_points": highest_endless_points,
		"fastest_challenge_time": fastest_challenge_time,
		"highest_challenge_points": highest_challenge_points,
		"unique_elites_beaten": unique_elites_beaten,
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

func load_unlocks() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()

		if data is Dictionary:
			unlocked_passives = data.get("unlocked_passives", [])
			unlocked_actives = data.get("unlocked_actives", [])
			unlocked_ultimates = data.get("unlocked_ultimates", [])
			games_completed = data.get("games_completed", 0)
			total_monsters_killed = data.get("total_monsters_killed", 0)
			total_elites_killed = data.get("total_elites_killed", 0)
			total_bosses_killed = data.get("total_bosses_killed", 0)
			hardest_difficulty_beaten = data.get("hardest_difficulty_beaten", -1)
			hardest_with_curses = data.get("hardest_with_curses", {})
			longest_endless_time = data.get("longest_endless_time", 0.0)
			highest_endless_wave = data.get("highest_endless_wave", 0)
			highest_endless_points = data.get("highest_endless_points", 0)
			fastest_challenge_time = data.get("fastest_challenge_time", 999999.0)
			highest_challenge_points = data.get("highest_challenge_points", 0)
			unique_elites_beaten = data.get("unique_elites_beaten", [])

func reset_all_unlocks() -> void:
	"""Reset all unlock progress (for settings reset)."""
	unlocked_passives.clear()
	unlocked_actives.clear()
	unlocked_ultimates.clear()
	games_completed = 0
	total_monsters_killed = 0
	total_elites_killed = 0
	total_bosses_killed = 0
	hardest_difficulty_beaten = -1
	hardest_with_curses.clear()
	longest_endless_time = 0.0
	highest_endless_wave = 0
	highest_endless_points = 0
	fastest_challenge_time = 999999.0
	highest_challenge_points = 0
	unique_elites_beaten.clear()
	current_run_elites = 0
	current_run_bosses = 0
	save_unlocks()
